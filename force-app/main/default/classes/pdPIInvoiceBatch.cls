public with sharing class pdPIInvoiceBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    Date startDate;
    Date endDate;

    /**
     * 以下の条件に合致する注文商品を処理対象とする
     * 注文商品の商品がポチッと請求(商品コードがPI0001)
     * 注文商品の注文に対する契約が有効
     * 契約のステータスが有効または終了で契約終了日が先月
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        this.setAggregateRange();

        List<Invoice__c> lstExistInvoice = [SELECT Id FROM Invoice__c WHERE InvoiceDate__c=:this.endDate];
        if (lstExistInvoice.size() != 0) {
            delete lstExistInvoice;
        }

        return Database.getQueryLocator(
            [
                SELECT Id,Order.ContractId,Order.Contract.ContractId__c,UnitPrice,OvertimeRate__c,Product2.Name,OptionUnitPrice__c,OptionOvertimeRate__c,InitCount__c,InitUnitPrice__c,
                    Order.Contract.Account.Name,Order.Contract.Account.FullName__c,Order.Contract.Account.AccountCode__c,Order.Contract.Account.Phone,Order.Contract.InvoiceStartDate__c,
                    Order.Contract.BillingPostalCode,Order.Contract.BillingState,Order.Contract.BillingCity,Order.Contract.BillingStreet,Order.Contract.IsFirstBilled__c,
                    Order.Contract.BillingContact__r.FirstName,Order.Contract.BillingContact__r.LastName,Order.Contract.BillingContact__r.Department,Order.Contract.BillingContact__r.Email
                FROM OrderItem
                WHERE Product2.ProductCode = 'PI0001'
                    AND Order.ContractId != null
                    AND Order.Contract.NoInvoice__c != true
                    AND ((Order.Contract.Status = 'Activated' AND Order.Contract.InvoiceStartDate__c <= :this.startDate) OR (Order.Contract.Status = 'Closed' AND Order.Contract.EndDate >= :this.startDate AND Order.Contract.EndDate <= :this.endDate))
            ]
        );
    }

    /**
     * 契約ごとの請求書を作成する
     * APIに前月の利用料を問い合わせ、注文商品の単価で請求金額を算出する
     * 請求書はfreeeに登録する
     * 発行数が0だったら請求書は作成しない(請求履歴は作成する)
     */
    public void execute(Database.BatchableContext bc, List<OrderItem> lstOrderItem) {
        this.setAggregateRange();

        List<Invoice__c> lstInvoice = new List<Invoice__c>();
        List<Contract> lstContract = new List<Contract>();

        pdPIFreee piFreee = new pdPIFreee();

        for (OrderItem orderItem: lstOrderItem) {
            Date invoiceStartDate = this.startDate;
            if (this.startDate.year() == orderItem.Order.Contract.InvoiceStartDate__c.year()
                && this.startDate.month() == orderItem.Order.Contract.InvoiceStartDate__c.month()) {
                    invoiceStartDate = orderItem.Order.Contract.InvoiceStartDate__c;
            }

            Invoice__c invoice = this.aggregateInvoice(orderItem, invoiceStartDate);

            if (invoice.IssueCount__c != 0) {
                Account account = new Account(
                    Name = orderItem.Order.Contract.Account.Name,
                    FullName__c = orderItem.Order.Contract.Account.FullName__c,
                    AccountCode__c = orderItem.Order.Contract.Account.AccountCode__c,
                    Phone = orderItem.Order.Contract.Account.Phone,
                    BillingPostalCode = orderItem.Order.Contract.BillingPostalCode,
                    BillingState = orderItem.Order.Contract.BillingState,
                    BillingCity = orderItem.Order.Contract.BillingCity,
                    BillingStreet = orderItem.Order.Contract.BillingStreet
                );
                Contact contact = new Contact(
                    FirstName = orderItem.Order.Contract.BillingContact__r.FirstName,
                    LastName = orderItem.Order.Contract.BillingContact__r.LastName,
                    Department = orderItem.Order.Contract.BillingContact__r.Department,
                    Email = orderItem.Order.Contract.BillingContact__r.Email
                );

                piFreee.registInvoice(this.startDate, this.endDate, invoiceStartDate, account, contact, invoice);
            }

            lstInvoice.add(invoice);

            Contract contract = orderItem.Order.Contract;
            contract.IssueCount__c = invoice.IssueCount__c;
            contract.PageCount__c = invoice.PageCount__c;
            contract.OptionIssueCount__c = invoice.OptionIssueCount__c;
            contract.OptionPageCount__c = invoice.OptionPageCount__c;
            contract.IsFirstBilled__c = true;

            lstContract.add(contract);
        }

        insert lstInvoice;
        update lstContract;
    }

    /**
     * 終了処理を行う
     */
    public void finish(Database.BatchableContext bc) {
    }

    /**
     * APIから先月分の発行数とページ数を取得する
     * 発行数 x 単価 + ページ数 x 超過単価で利用料金を算出する
     * 集計開始日が契約情報の請求開始日と同月の場合は契約開始日を集計開始日とする
     */
    private Invoice__c aggregateInvoice(OrderItem orderItem, Date invoiceStartDate) {
        String accessToken = pdPIAuth0.getAccessToken('API');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        String param = 'contract_id=' + orderItem.Order.Contract.ContractId__c + 
            '&startDate=' + this.getDateString(invoiceStartDate) +
            '&endDate=' + this.getDateString(this.endDate);
        req.setEndpoint('callout:PochittoInvoiceApi/api/maintenance/invoice?' + param);
        req.setHeader('content-type', 'application/json');
        req.setHeader('authorization', accessToken);

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String result = (String)mapRes.get('result');
            if (result == 'OK') {
                Invoice__c invoice = new Invoice__c();
                invoice.Name = orderItem.Product2.Name + ' ' + this.getDateString(this.endDate) + '請求分';
                invoice.InvoiceDate__c = this.endDate;
                invoice.Contract__c = orderItem.Order.ContractId;
                invoice.IssueCount__c = (Integer)mapRes.get('issueCount');
                invoice.PageCount__c = (Integer)mapRes.get('pageCount');
                invoice.OptionIssueCount__c = (Integer)mapRes.get('issuePostalCount');
                invoice.OptionPageCount__c = (Integer)mapRes.get('pagePostalCount');
                invoice.IssueUnitPrice__c = orderItem.UnitPrice;
                invoice.PageUnitPrice__c = orderItem.OvertimeRate__c;
                invoice.OptionIssueUnitPrice__c = orderItem.OptionUnitPrice__c;
                invoice.OptionPageUnitPrice__c = orderItem.OptionOvertimeRate__c;
                Decimal issuePrice = (Decimal)invoice.IssueCount__c * invoice.IssueUnitPrice__c;
                Decimal pagePrice = (Decimal)invoice.PageCount__c * invoice.PageUnitPrice__c;
                Decimal optionIssuePrice = (Decimal)invoice.OptionIssueCount__c * invoice.OptionIssueUnitPrice__c;
                Decimal optionPagePrice = (Decimal)invoice.OptionPageCount__c * invoice.OptionPageUnitPrice__c;
                Decimal initPrice = 0;
                if (!orderItem.Order.Contract.IsFirstBilled__c) {
                    invoice.InitUnitPrice__c = orderItem.InitUnitPrice__c;
                    invoice.InitCount__c = orderItem.InitCount__c;
                    initPrice = orderItem.InitUnitPrice__c * (Decimal)orderItem.InitCount__c;
                } else {
                    invoice.InitUnitPrice__c = 0;
                    invoice.InitCount__c = 0;
                }
                invoice.InvoicePrice__c = issuePrice + pagePrice + optionIssuePrice + optionPagePrice + initPrice;
                return invoice;
            } else {
                throw new OtherException('発行数、ページ数取得でエラーが発生しました: ' + (String)mapRes.get('errorMessage'));
            }
        }
        else {
            throw new OtherException(this.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * 日付を文字列に変換する
     */
    private String getDateString(Date dt) {
        return String.valueOf(dt.year()) + '-' + String.valueOf(dt.month()).leftPad(2, '0') + '-' + String.valueOf(dt.day()).leftPad(2, '0');
    }

    /**
     * エラーメッセージを設定する
    */
    private String getApiErrorMessage(String body) {
        String errorMessage = '発行数、ページ数取得APIでエラーが発生しました: ' + body;
        return errorMessage;
    }

    /**
     * 集計対象日範囲を設定する
     */
    private void setAggregateRange() {
        Date today = Date.today();
        this.startDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-1);
        this.endDate = startDate.addMonths(1).addDays(-1);
    }
}
