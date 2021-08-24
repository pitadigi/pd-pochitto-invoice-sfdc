@RestResource(urlMapping='/pochitto_invoice/*')
global with sharing class pdPIRegistration {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * ポチッと請求の申込情報を登録する
     * @param customer
     * {
     *   "Company": "会社名",
     *   "Department": "部署",
     *   "Title": "役職",
     *   "PostalCode": "郵便番号",
     *   "State": "都道府県",
     *   "City": "市区町村",
     *   "Address": "住所",
     *   "Bill": "ビル名",
     *   "LastName": "名",
     *   "FirstName": "姓",
     *   "LastNameKana": "名カナ",
     *   "FirstNameKana": "姓カナ",
     *   "Email": "メールアドレス",
     *   "Phone": "電話番号",
     *   "Fax": "FAX",
     *   "Payment": "支払方法",
     *   "BillingIsSameContact": "true: 取引先責任者と同じ, false: 別途指定",
     *   "BillingDepartment": "部署(請求先)",
     *   "BillingTitle": "役職(請求先)",
     *   "BillingPostalCode": "郵便番号(請求先)",
     *   "BillingState": "都道府県(請求先)",
     *   "BillingCity": "市区町村(請求先)",
     *   "BillingStreet": "住所(請求先)",
     *   "BillingLastName": "名(請求先)",
     *   "BillingFirstName": "姓(請求先)",
     *   "BillingLastNameKana": "名カナ(請求先)",
     *   "BillingFirstNameKana": "姓カナ(請求先)",
     *   "BillingEmail": "メールアドレス(請求先)",
     *   "BillingPhone": "電話番号(請求先)",
     *   "BillingFax": "FAX(請求先)",
     *   "Tags": "タグ",
     *   "Satori": "SATORI URL",
     * }
     * 
     * @returns
     * {
     *   result: true / false
     *   message: エラーメッセージ
     * }
     */
    @HttpPost
    global static String regist(String customer) {
        System.JSONGenerator jsonResult = JSON.createGenerator(false);
        jsonResult.writeStartObject();

        try {
            String contractId = pdPIRegistration.createContractId();

            Map<String, Object> mapCustomer = (Map<String, Object>)JSON.deserializeUntyped(customer);

            Boolean result = pdPIAuth0.createUser(contractId, (String)mapCustomer.get('Email'), (String)mapCustomer.get('Company'));

            if (result) {
                pdPISvf piSvf = new pdPISvf();
                piSvf.regist(contractId);

                pdPIAzure.buildUserEnv(contractId);
    
                pdPIRegistration.registContract(contractId, mapCustomer);
            }

            jsonResult.writeBooleanField('result', true);
            jsonResult.writeStringField('message', '');
        }
        catch(DmlException e) {
            jsonResult.writeBooleanField('result', false);
            jsonResult.writeStringField('message', e.getMessage());
        }

        jsonResult.writeEndObject();
        return jsonResult.getAsString();        
    }

    /**
     * Salesforceに申込情報を登録する
     * * 同じメールアドレスの取引先責任者が存在しないかをチェックする
     * * 同じメールアドレスの取引先責任者が存在したら、その取引先責任者と取引先を対象とする
     * * 取引先責任者が存在しなかったら、取引先と取引先責任者を作成する
     * * 請求先が別途指定であれば、同じ取引先に同じメールアドレスを持つ取引先責任者がいるかをチェックする ※SATORIでチェックできないので保留
     * * 同じ取引先責任者が存在しなければ追加する ※SATORIでチェックできないので保留
     * * 取引先に対して契約を作成する(状況はトライアル)
     */
    private static void registContract(String contractId, Map<String, Object> mapCustomer) {
        Account account;
        Contact contact;

        String companyName = (String)mapCustomer.get('Company');
        companyName = companyName.replace('（', '(');
        companyName = companyName.replace('）', ')');
        companyName = companyName.remove('株式会社');
        companyName = companyName.remove('(株)');
        companyName = companyName.remove('合同会社');
        companyName = companyName.remove('(合)');
        companyName = companyName.remove('有限会社');
        companyName = companyName.remove('(有)');
        String companyFullName = (String)mapCustomer.get('Company');
        companyFullName = companyFullName.replace('（', '(');
        companyFullName = companyFullName.replace('）', ')');
        companyFullName = companyFullName.replace('(株)', '株式会社');
        companyFullName = companyFullName.replace('(合)', '合同会社');
        companyFullName = companyFullName.replace('(有)', '有限会社');

        List<Contact> lstContact = [SELECT Id,LastName,FirstName,MailingPostalCode,MailingState,MailingCity,MailingStreet,
                                    Email,Phone,Fax,Title,AccountId,Department,NameKana__c
                                    FROM Contact 
                                    WHERE Email=:(String)mapCustomer.get('Email')
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
        account.BillingPostalCode = (String)mapCustomer.get('PostalCode');
        account.BillingState = (String)mapCustomer.get('State');
        account.BillingCity = (String)mapCustomer.get('City');
        account.BillingStreet = pdPIRegistration.getStreet(mapCustomer);
        account.Phone = (String)mapCustomer.get('Phone');
        account.Fax = (String)mapCustomer.get('Fax');
        if (String.isBlank(account.AccountCode__c)) {
            account.AccountCode__c = ContractId;
        }
        upsert account;

        contact.LastName = (String)mapCustomer.get('LastName');
        contact.FirstName = (String)mapCustomer.get('FirstName');
        contact.MailingPostalCode = (String)mapCustomer.get('PostalCode');
        contact.MailingState = (String)mapCustomer.get('State');
        contact.MailingCity = (String)mapCustomer.get('City');
        contact.MailingStreet = pdPIRegistration.getStreet(mapCustomer);
        contact.Email = (String)mapCustomer.get('Email');
        contact.Phone = (String)mapCustomer.get('Phone');
        contact.Fax = (String)mapCustomer.get('Fax');
        contact.Title = (String)mapCustomer.get('Title');
        contact.Department = (String)mapCustomer.get('Department');
        contact.SatoriUrl__c = (String)mapCustomer.get('Satori');
        contact.SatoriTags__c = (String)mapCustomer.get('Tags');
        contact.NameKana__c = (String)mapCustomer.get('LastNameKana') + ' ' + (String)mapCustomer.get('FirstNameKana');
        contact.AccountId = account.Id;
        upsert contact;

        PriceBook2 priceBook2 = [SELECT Id FROM PriceBook2 WHERE Name='Standard Price Book' LIMIT 1];
        ID recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType='Contract' AND DeveloperName='CloudService'].Id;

        Contract contract = new Contract();
        contract.Status = 'Draft';
        contract.recordTypeId = recordTypeId;
        contract.ShippingPostalCode = (String)mapCustomer.get('PostalCode');
        contract.ShippingState = (String)mapCustomer.get('State');
        contract.ShippingCity = (String)mapCustomer.get('City');
        contract.ShippingStreet = pdPIRegistration.getStreet(mapCustomer);
        contract.BillingPostalCode = (String)mapCustomer.get('PostalCode');
        contract.BillingState = (String)mapCustomer.get('State');
        contract.BillingCity = (String)mapCustomer.get('City');
        contract.BillingStreet = pdPIRegistration.getStreet(mapCustomer);
        contract.AccountId = account.Id;
        contract.BillingContact__c = contact.Id;
        contract.Name = companyName + ' - ' + 'ポチッと請求';
        contract.StartDate = Date.Today();
        contract.Payment__c = (String)mapCustomer.get('Payment');
        contract.BillingIsSameContact__c = true;
        contract.CustomerSignedId = contact.Id;
        contract.CustomerSignedTitle = contact.Title;
        contract.Pricebook2Id = priceBook2.Id;
        contract.Type__c = '月額';
        contract.CloudService__c = 'PochittoInvoice';
        contract.ContractId__c = contractId;
        insert contract;

        Order order = new Order();
        order.Pricebook2Id = priceBook2.Id;
        order.AccountId = account.Id;
        order.ContractId = contract.Id;
        order.Name = companyName + ' - ' + 'ポチッと請求';
        order.Type = '月額';
        order.EffectiveDate = Date.Today();
        order.Status = 'Draft';
        order.ShipToContactId = contact.Id;
        order.BillToContactId = contact.Id;
        order.CustomerAuthorizedById = contact.Id;
        insert order;

        PricebookEntry pricebookEntry = [SELECT Id,UnitPrice,OvertimeRate__c FROM PricebookEntry WHERE ProductCode='PI0001' LIMIT 1];
        Product2 product2 = [SELECT Id FROM Product2 WHERE ProductCode='PI0001' LIMIT 1];
        OrderItem orderItem = new OrderItem();
        orderItem.ListPrice = pricebookEntry.UnitPrice;
        orderItem.UnitPrice = pricebookEntry.UnitPrice;
        orderItem.Product2Id = product2.Id;
        orderItem.Quantity = 1;
        orderItem.OrderId = order.Id;
        orderItem.OvertimeRate__c = pricebookEntry.OvertimeRate__c;
        orderItem.PricebookEntryId = pricebookEntry.Id;
        insert orderItem;
    }

    /**
     * 町名番地を取得する
     */
    private static String getStreet(Map<String, Object> mapCustomer) {
        return (String)mapCustomer.get('Address') + '\r\n' + (String)mapCustomer.get('Bill');
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
