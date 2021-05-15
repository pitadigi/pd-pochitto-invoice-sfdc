public with sharing class pdPochittoInvoiceAuth0 {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * Auth0のユーザIDを作成する
     * * ユーザがすでに存在する場合はエラーにしない(ステータスコード = 409)
     */
    public static Boolean createUserOfAuth0(String contractId, String email, String companyName) {
        String accessToken = pdPochittoInvoiceAuth0.getAccessToken('Management');
        String password = pdPochittoInvoiceRegistration.createContractId();
        password += '@PI';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:Auth0/api/v2/users');
        req.setHeader('content-type', 'application/json');
        req.setHeader('authorization', accessToken);
        
        JSONGenerator data = JSON.createGenerator(false);
        data.writeStartObject();
        data.writeStringField('email', email);
        data.writeStringField('name', contractId);
        data.writeStringField('connection', 'pd-pochitto-invoice');
        data.writeStringField('password', password);
        data.writeBooleanField('verify_email', true);
        data.writeFieldName('app_metadata');
        data.writeStartObject();
        data.writeStringField('contract_id', contractId);
        data.writeEndObject();
        data.writeFieldName('user_metadata');
        data.writeStartObject();
        data.writeStringField('company_name', companyName);
        data.writeEndObject();
        data.writeEndObject();
        req.setBody(data.getAsString());

        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 409) {
            return false;
        }
        else if (res.getStatusCode() != 201) {
            throw new OtherException(pdPochittoInvoiceAuth0.getApiErrorMessage(res.getBody()));
        }

        return true;
    }

    /**
     * Auth0からアクセストークンを取得する
     */
    public static String getAccessToken(String developerName) {
        Auth0__mdt auth0 = [SELECT Url__c,ClientId__c,Secret__c,Audience__c,GrantType__c FROM Auth0__mdt WHERE DeveloperName=:developerName LIMIT 1];

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(auth0.Url__c);
        req.setHeader('content-type', 'application/json');

        JSONGenerator data = JSON.createGenerator(false);
        data.writeStartObject();
        data.writeStringField('client_id', auth0.ClientId__c);
        data.writeStringField('client_secret', auth0.Secret__c);
        data.writeStringField('audience', auth0.Audience__c);
        data.writeStringField('grant_type', auth0.GrantType__c);
        data.writeEndObject();
        req.setBody(data.getAsString());

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return (String)mapRes.get('token_type') + ' ' + (String)mapRes.get('access_token');
        }
        else {
            throw new OtherException(pdPochittoInvoiceAuth0.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * エラーメッセージを設定する
    */
    private static String getApiErrorMessage(String body) {
        String errorMessage = 'Auth0 APIでエラーが発生しました: ' + body;
        system.debug(errorMessage);
        return errorMessage;
    }
}
