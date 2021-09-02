public with sharing class pdPIRegistration {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * ポチッと請求の申込情報を登録する
     * サービス申込の登録があったらプロセスビルダーから実行される
     */
    @InvocableMethod(label='サービス登録' description='サービス登録処理')
    public static void regist(List<ServiceApplication__c> lstServiceApplication) {
        for (ServiceApplication__c serviceApplication : lstServiceApplication) {
            pdPIRegistration.registEnv(serviceApplication.Id);
        }
    }

    @future (callout=true)
    private static void registEnv(ID id) {
        ServiceApplication__c serviceApplication = [SELECT Id, ServiceName__c, CompanyName__c, PostalCode__c, State__c, City__c,
                                                            Street__c, Bill__c, Department__c, LastName__c, FirstName__c, Phone__c, MailAddress__c
                                                            FROM ServiceApplication__c
                                                            WHERE Id = :id
                                                            LIMIT 1];

        String contractId = pdPIRegistration.createContractId();

        Boolean result = pdPIAuth0.createUser(contractId, serviceApplication.MailAddress__c, serviceApplication.CompanyName__c);

        if (result) {
            pdPISvf piSvf = new pdPISvf();
            piSvf.regist(contractId);

            pdPIAzure.buildUserEnv(contractId);

            pdPIRegistration.registContract(contractId, serviceApplication);
        }
    }

    /**
     * Salesforceに申込情報を登録する
     * * 同じメールアドレスの取引先責任者が存在しないかをチェックする
     * * 同じメールアドレスの取引先責任者が存在したら、その取引先責任者と取引先を対象とする
     * * 取引先責任者が存在しなかったら、取引先と取引先責任者を作成する
     * * 請求先が別途指定であれば、同じ取引先に同じメールアドレスを持つ取引先責任者がいるかをチェックする ※SATORIでチェックできないので保留
     * * 同じ取引先責任者が存在しなければ追加する ※SATORIでチェックできないので保留
     * * 取引先に対して契約を作成する(状況はトライアル)
     * * サービス申込に登録した契約をリンクする
     */
    private static void registContract(String contractId, ServiceApplication__c serviceApplication) {
        Account account;
        Contact contact;

        String companyName = serviceApplication.CompanyName__c;
        companyName = companyName.replace('（', '(');
        companyName = companyName.replace('）', ')');
        companyName = companyName.remove('株式会社');
        companyName = companyName.remove('(株)');
        companyName = companyName.remove('合同会社');
        companyName = companyName.remove('(合)');
        companyName = companyName.remove('有限会社');
        companyName = companyName.remove('(有)');
        String companyFullName = serviceApplication.CompanyName__c;
        companyFullName = companyFullName.replace('（', '(');
        companyFullName = companyFullName.replace('）', ')');
        companyFullName = companyFullName.replace('(株)', '株式会社');
        companyFullName = companyFullName.replace('(合)', '合同会社');
        companyFullName = companyFullName.replace('(有)', '有限会社');

        List<Contact> lstContact = [SELECT Id,LastName,FirstName,MailingPostalCode,MailingState,MailingCity,MailingStreet,
                                    Email,Phone,Fax,Title,AccountId,Department,NameKana__c
                                    FROM Contact 
                                    WHERE Email=:serviceApplication.MailAddress__c
                                    ORDER BY LastModifiedDate DESC];
        if (lstContact.size() != 0) {
            contact = lstContact[0];
            account = [SELECT Id,Name,FullName__c,BillingPostalCode,BillingState,BillingCity,BillingStreet,Phone,Fax
                        FROM Account
                        WHERE Id=:contact.AccountId
                        LIMIT 1];
        }
        else {
            contact = new Contact();
            account = new Account();
        }

        account.Name = companyName;
        account.FullName__c = companyFullName;
        account.BillingPostalCode = serviceApplication.PostalCode__c;
        account.BillingState = serviceApplication.State__c;
        account.BillingCity = serviceApplication.City__c;
        account.BillingStreet = pdPIRegistration.getStreet(serviceApplication);
        account.Phone = serviceApplication.Phone__c;
        if (String.isBlank(account.AccountCode__c)) {
            account.AccountCode__c = ContractId;
        }
        upsert account;

        contact.LastName = serviceApplication.LastName__c;
        contact.FirstName = serviceApplication.FirstName__c;
        contact.MailingPostalCode = serviceApplication.PostalCode__c;
        contact.MailingState = serviceApplication.State__c;
        contact.MailingCity = serviceApplication.City__c;
        contact.MailingStreet = pdPIRegistration.getStreet(serviceApplication);
        contact.Email = serviceApplication.MailAddress__c;
        contact.Phone = serviceApplication.Phone__c;
        contact.Department = serviceApplication.Department__c;
        contact.AccountId = account.Id;
        upsert contact;

        PriceBook2 priceBook2 = [SELECT Id FROM PriceBook2 WHERE Name='Standard Price Book' LIMIT 1];
        ID recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType='Contract' AND DeveloperName='CloudService'].Id;

        Contract contract = new Contract();
        contract.Status = 'Draft';
        contract.recordTypeId = recordTypeId;
        contract.ShippingPostalCode = serviceApplication.PostalCode__c;
        contract.ShippingState = serviceApplication.State__c;
        contract.ShippingCity = serviceApplication.City__c;
        contract.ShippingStreet = pdPIRegistration.getStreet(serviceApplication);
        contract.BillingPostalCode = serviceApplication.PostalCode__c;
        contract.BillingState = serviceApplication.State__c;
        contract.BillingCity = serviceApplication.City__c;
        contract.BillingStreet = pdPIRegistration.getStreet(serviceApplication);
        contract.AccountId = account.Id;
        contract.BillingContact__c = contact.Id;
        contract.Name = companyName + ' - ' + serviceApplication.ServiceName__c;
        contract.StartDate = Date.Today();
        contract.BillingIsSameContact__c = true;
        contract.CustomerSignedId = contact.Id;
        contract.CustomerSignedTitle = contact.Title;
        contract.Pricebook2Id = priceBook2.Id;
        contract.Type__c = '月額';
        contract.CloudService__c = serviceApplication.ServiceName__c;
        contract.ContractId__c = contractId;
        insert contract;

        Order order = new Order();
        order.Pricebook2Id = priceBook2.Id;
        order.AccountId = account.Id;
        order.ContractId = contract.Id;
        order.Name = companyName + ' - ' + serviceApplication.ServiceName__c;
        order.Type = '月額';
        order.EffectiveDate = Date.Today();
        order.Status = 'Draft';
        order.ShipToContactId = contact.Id;
        order.BillToContactId = contact.Id;
        order.CustomerAuthorizedById = contact.Id;
        insert order;

        PricebookEntry pricebookEntry = [SELECT Id,UnitPrice,OvertimeRate__c,OptionUnitPrice__c,OptionOvertimeRate__c FROM PricebookEntry WHERE ProductCode='PI0001' LIMIT 1];
        Product2 product2 = [SELECT Id FROM Product2 WHERE ProductCode='PI0001' LIMIT 1];
        OrderItem orderItem = new OrderItem();
        orderItem.ListPrice = pricebookEntry.UnitPrice;
        orderItem.UnitPrice = pricebookEntry.UnitPrice;
        orderItem.Product2Id = product2.Id;
        orderItem.Quantity = 1;
        orderItem.OrderId = order.Id;
        orderItem.OptionUnitPrice__c = pricebookEntry.OptionUnitPrice__c;
        orderItem.OvertimeRate__c = pricebookEntry.OvertimeRate__c;
        orderItem.OptionOvertimeRate__c = pricebookEntry.OptionOvertimeRate__c;
        orderItem.PricebookEntryId = pricebookEntry.Id;
        insert orderItem;

        serviceApplication.Contract__c = contract.Id;
        update serviceApplication;
    }

    /**
     * 町名番地を取得する
     */
    private static String getStreet(ServiceApplication__c serviceApplication) {
        return serviceApplication.Street__c + '\r\n' + serviceApplication.Bill__c;
    }

    /**
     * エラーメッセージを設定する
    */
    private static String getApiErrorMessage(String body) {
        String errorMessage = 'APIでエラーが発生しました: ' + body;
        system.debug(errorMessage);
        return errorMessage;
    }

    /**
     * 契約IDを生成する
     */
    public static String createContractId() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8) + h.SubString(8,12) + h.SubString(12,16) + h.SubString(16,20) + h.substring(20);

        return guid.toLowerCase();
    }
}
