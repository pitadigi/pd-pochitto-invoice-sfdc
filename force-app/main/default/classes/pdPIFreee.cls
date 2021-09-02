public with sharing class pdPIFreee {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
    * 会社情報を取得する
     */
    private Long getCompanyId() {    
        Freee__mdt freee = [SELECT CompanyName__c FROM Freee__mdt WHERE DeveloperName='Target' LIMIT 1];

        // 会社情報を取得する
        Http http = new Http();
        String path = 'callout:Freee/companies';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setMethod('GET');

        HttpResponse res = http.send(req);
        // 会社情報が返ってきたらIIDと名称を設定する
        if (res.getStatusCode() == 200) {
            Map<String, Object> mapCompany = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> lstCompany = (List<Object>)mapCompany.get('companies');
            if (lstCompany.size() == 0) {
                throw new OtherException('会社情報が取得できません');
            }
            else {
                Long companyId = 0;
                for (Object obj : lstCompany) {
                    Map<String, Object> mapObj = (Map<String, Object>)obj;

                    if ((String)mapObj.get('display_name') == freee.CompanyName__c) {
                        companyId = (Long)mapObj.get('id');
                        break;
                    }
                }
                return companyId;
            }
        }
        // エラーで返ってきたら例外をスローする
        else {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
    }

    /**
    * 同じ取引先が存在するかをチェックする
    */
    private Long isExist(Long companyId, String accountCode) {
        // 取引先名を指定して取引先情報を取得する
        Http http = new Http();
        String path = 'callout:Freee/partners';
        String parameters = 'company_id=' + String.valueOf(companyId) + '&';
        parameters += 'keyword=' + EncodingUtil.urlEncode(accountCode, 'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path + '?' + parameters);
        req.setMethod('GET');

        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200) {
            // 取引先情報が存在すればtrue、存在しなければfalseを返す
            Map<String, Object> mapBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> lstBody = (List<Object>)mapBody.get('partners');
            if (lstBody.size() == 0) {
                return 0;
            }
            else {
                Map<String, Object> mapPartner = (Map<String, Object>)lstBody[0];
                return (Long)mapPartner.get('id');
            }
        }
        // エラーだったら例外をスローする
        else {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
    }

    /**
    * 取引先をFreeeに登録する
    * 取引先コード(Freee上ではショートカット2)で取引先を検索し、すでに存在すれば更新、存在しなければ追加する
    */
    private Long registPartner(Long companyId, Account acc, Contact con) {
        Long partnerId = this.isExist(companyId, acc.AccountCode__c);

        JSONGenerator j = JSON.createGenerator(false);
        j.writeStartObject();
        j.writeNumberField('company_id', companyId);
        j.writeStringField('name', acc.Name);
        j.writeStringField('long_name', acc.FullName__c);
        if (partnerId == 0) {
            j.writeStringField('code', acc.AccountCode__c);
        }
        j.writeStringField('shortcut2', acc.AccountCode__c);
        j.writeStringField('default_title', '御中');
        j.writeStringField('phone', acc.Phone);
        String contactName;
        if (!String.isBlank(con.Department)) {
            contactName = con.Department + ' / ';
        }
        contactName += con.LastName + ' ' + con.FirstName;
        j.writeStringField('contact_name', contactName);
        j.writeStringField('email', con.Email);
        j.writeFieldName('address_attributes');
        j.writeStartObject();
        j.writeStringField('zipcode', acc.BillingPostalCode);
        Integer prefCode = getPrefCode(acc.BillingState);
        j.writeStringField('prefecture_code', ((prefCode == null) ? 'null' : String.valueOf(prefCode)) + '');
        if(acc.BillingStreet != null) {
            String[] billingStreet = acc.BillingStreet.split('\r\n');
            if(billingStreet.size() == 0) {
                j.writeStringField('street_name1', acc.BillingCity);
            }
            else {
                j.writeStringField('street_name1', acc.BillingCity + billingStreet[0]);
                if (billingStreet.size() >= 2) {
                    j.writeStringField('street_name2', billingStreet[1]);
                }
            }
        }
        j.writeEndObject();
        j.writeEndObject();

        Http http = new Http();
        String path = 'callout:Freee/partners';

        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setBody(j.getAsString());

        if (partnerId == 0) {
            req.setMethod('POST');
            req.setEndpoint(path);
        }
        else {
            req.setMethod('PUT');
            req.setEndpoint(path + '/' + String.valueOf(partnerId));
        }

        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 201
            && res.getStatusCode() != 200) {
            throw new OtherException(this.getApiErrorMessage(res.getBody()));
        }
        else {
            Map<String, Object> mapBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            Map<String, Object> mapPartner = (Map<String, Object>)mapBody.get('partner');
            return (Long)mapPartner.get('id');
        }
    }

    /**
     * 勘定科目情報
     */
    private class AccountItem {
        /**
         * 勘定科目ID
         */
        Long accountId;
        /**
         * 勘定科目名
         */
        String accountName;
        /**
         * 税区分コード
         */
        Long taxCode;
    }

    /**
     * 売上高勘定科目情報を取得する
     */
    private AccountItem getSalesAccount(Long companyId, Date endDate) {
        String param = 'company_id=' + String.valueOf(companyId);
        param += '&base_date=' + this.getDateString(endDate);

        Http http = new Http();
        String path = 'callout:Freee/account_items?' + param;

        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        req.setEndpoint(path);

        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            throw new OtherException(this.getApiErrorMessage(res.getBody()));
        }
        else {
            Map<String, Object> mapBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> lstAccountItem = (List<Object>)mapBody.get('account_items');

            AccountItem accountItem = new AccountItem();
            for (Object objAccountItem : lstAccountItem) {
                Map<String, Object> mapAccountItem = (Map<String, Object>)objAccountItem;
                if ((String)mapAccountItem.get('name') == '売上高') {
                    accountItem.accountId = (Long)mapAccountItem.get('id');
                    accountItem.accountName = (String)mapAccountItem.get('name');
                    accountItem.taxCode = (Long)mapAccountItem.get('tax_code');
                    break;
                }
            }

            return accountItem;
        }

    }

    /**
     * 請求書情報をFreeeに登録する
     */
    public void registInvoice(Date startDate, Date endDate, Account acc, Contact con, Invoice__c inv) {
        Long companyId = this.getCompanyId();

        AccountItem accountItem = this.getSalesAccount(companyId, endDate);

        Long partnerId = this.registPartner(companyId, acc, con);

        JSONGenerator j = JSON.createGenerator(false);
        j.writeStartObject();
        j.writeNumberField('company_id', companyId);
        j.writeStringField('issue_date', this.getDateString(inv.InvoiceDate__c));
        j.writeNumberField('partner_id', partnerId);
        Date dueDate = startDate.addMonths(2).addDays(-1);
        j.writeStringField('due_date', this.getDateString(dueDate));
        j.writeStringField('booking_date', this.getDateString(inv.InvoiceDate__c));
        j.writeStringField('description', inv.Name);
        j.writeStringField('invoice_status', 'draft');
        j.writeStringField('partner_display_name', acc.FullName__c);
        j.writeStringField('partner_title', '御中');
        j.writeStringField('partner_contact_info', con.LastName + ' ' + con.FirstName);
        j.writeStringField('payment_type', 'transfer');
        j.writeStringField('notes', 'ご利用期間: ' + this.getDateString(startDate) + ' 〜 ' + this.getDateString(endDate));
        j.writeFieldName('invoice_contents');
        j.writeStartArray();
        Integer order = 0;
        j.writeStartObject();
        j.writeNumberField('order', order++);
        j.writeStringField('type', 'normal');
        j.writeStringField('description', inv.Name + ' 発行料金');
        j.writeNumberField('qty', inv.IssueCount__c);
        j.writeStringField('unit', '回');
        j.writeNumberField('unit_price', inv.IssueUnitPrice__c + inv.PageUnitPrice__c);
        j.writeNumberField('account_item_id', accountItem.accountId);
        j.writeNumberField('tax_code', accountItem.taxCode);
        j.writeEndObject();
        if (inv.PageCount__c != inv.IssueCount__c) {
            j.writeStartObject();
            j.writeNumberField('order', order++);
            j.writeStringField('type', 'normal');
            j.writeStringField('description', inv.Name + ' 超過ページ料金');
            j.writeNumberField('qty', inv.PageCount__c - inv.IssueCount__c);
            j.writeStringField('unit', '枚');
            j.writeNumberField('unit_price', inv.PageUnitPrice__c);
            j.writeNumberField('account_item_id', accountItem.accountId);
            j.writeNumberField('tax_code', accountItem.taxCode);
            j.writeEndObject();
        }
        if (inv.OptionIssueCount__c != 0) {
            j.writeStartObject();
            j.writeNumberField('order', order++);
            j.writeStringField('type', 'normal');
            j.writeStringField('description', inv.Name + ' 郵送発行料金');
            j.writeNumberField('qty', inv.OptionIssueCount__c);
            j.writeStringField('unit', '回');
            j.writeNumberField('unit_price', inv.OptionIssueUnitPrice__c + inv.OptionPageUnitPrice__c);
            j.writeNumberField('account_item_id', accountItem.accountId);
            j.writeNumberField('tax_code', accountItem.taxCode);
            j.writeEndObject();
            if (inv.OptionPageCount__c != inv.OptionIssueCount__c) {
                j.writeStartObject();
                j.writeNumberField('order', order++);
                j.writeStringField('type', 'normal');
                j.writeStringField('description', inv.Name + ' 郵送超過ページ料金');
                j.writeNumberField('qty', inv.OptionPageCount__c - inv.OptionIssueCount__c);
                j.writeStringField('unit', '枚');
                j.writeNumberField('unit_price', inv.OptionPageUnitPrice__c);
                j.writeNumberField('account_item_id', accountItem.accountId);
                j.writeNumberField('tax_code', accountItem.taxCode);
                j.writeEndObject();
            }
        }
        j.writeEndArray();
        j.writeEndObject();

        Http http = new Http();
        String path = 'callout:Freee/invoices';

        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setBody(j.getAsString());
        req.setMethod('POST');
        req.setEndpoint(path);
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 201) {
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
    * 都道府県コード変換
     */
    private Integer getPrefCode(String prefName) {
        List<String> pref = new List<String> {
            '北海道',
            '青森県',
            '岩手県',
            '宮城県',
            '秋田県',
            '山形県',
            '福島県',
            '茨城県',
            '栃木県',
            '群馬県',
            '埼玉県',
            '千葉県',
            '東京都',
            '神奈川県',
            '新潟県',
            '富山県',
            '石川県',
            '福井県',
            '山梨県',
            '長野県',
            '岐阜県',
            '静岡県',
            '愛知県',
            '三重県',
            '滋賀県',
            '京都府',
            '大阪府',
            '兵庫県',
            '奈良県',
            '和歌山県',
            '鳥取県',
            '島根県',
            '岡山県',
            '広島県',
            '山口県',
            '徳島県',
            '香川県',
            '愛媛県',
            '高知県',
            '福岡県',
            '佐賀県',
            '長崎県',
            '熊本県',
            '大分県',
            '宮崎県',
            '鹿児島県',
            '沖縄県'
        };

        Integer prefCode = null;
        for(Integer i=0 ; i<pref.size() ; i++) {
            if(pref[i] == prefName) {
                prefCode = i;
                break;
            }
        }

        return prefCode;
    }

    /**
     * エラーメッセージを設定する
    */
    private String getApiErrorMessage(String body) {
        String errorMessage = 'Freee APIでエラーが発生しました: ' + body;
        return errorMessage;
    }
}
