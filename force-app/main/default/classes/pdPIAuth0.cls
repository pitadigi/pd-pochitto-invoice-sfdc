public with sharing class pdPIAuth0 {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * Auth0のユーザIDを作成する
     * * ユーザがすでに存在する場合はエラーにしない(ステータスコード = 409)
     */
    public static Boolean createUser(String contractId, String email, String companyName) {
        String accessToken = pdPIAuth0.getAccessToken('Management');
        String password = pdPIRegistration.createContractId();
        password += '@P1tadigi';

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
            throw new OtherException(pdPIAuth0.getApiErrorMessage(res.getBody()));
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
            throw new OtherException(pdPIAuth0.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * 契約IDに該当するユーザをブロック状態を設定する
     */
    @future(callout = true)
    public static void setUserBlockState(String contractId, Boolean isBlock) {
        List<String> lstUserId = pdPIAuth0.getUserIdByContractId(contractId);

        String accessToken = pdPIAuth0.getAccessToken('Management');
        Http http = new Http();

        for (String userId : lstUserId) {
            userId = EncodingUtil.urlEncode(userId, 'UTF-8');
            HttpRequest req = new HttpRequest();
            req.setMethod('PATCH');
            req.setEndpoint('callout:Auth0/api/v2/users/' + userId);
            req.setHeader('content-type', 'application/json');
            req.setHeader('authorization', accessToken);
    
            JSONGenerator data = JSON.createGenerator(false);
            data.writeStartObject();
            data.writeBooleanField('blocked', isBlock);
            data.writeEndObject();
            req.setBody(data.getAsString());
    
            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 200) {
                throw new OtherException(pdPIAuth0.getApiErrorMessage(res.getBody()));
            }
        }
    }

    /**
     * 契約IDに該当するユーザを削除する
     */
    public static void deleteUser(String contractId) {
        List<String> lstUserId = pdPIAuth0.getUserIdByContractId(contractId);

        String accessToken = pdPIAuth0.getAccessToken('Management');
        Http http = new Http();

        for (String userId : lstUserId) {
            userId = EncodingUtil.urlEncode(userId, 'UTF-8');
            HttpRequest req = new HttpRequest();
            req.setMethod('DELETE');
            req.setEndpoint('callout:Auth0/api/v2/users/' + userId);
            req.setHeader('content-type', 'application/json');
            req.setHeader('authorization', accessToken);
    
            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 204) {
                throw new OtherException(pdPIAuth0.getApiErrorMessage(res.getBody()));
            }
        }
    }

    /**
     * 契約IDに該当するユーザを取得する
     */
    private static List<String> getUserIdByContractId(String contractId) {
        String accessToken = pdPIAuth0.getAccessToken('Management');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('callout:Auth0/api/v2/users?q=name:' + contractId);
        req.setHeader('content-type', 'application/json');
        req.setHeader('authorization', accessToken);

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            List<Object> lstRes = (List<Object>)JSON.deserializeUntyped(res.getBody());
            List<String> lstUserId = new List<String>();
            for (Object objRes : lstRes) {
                Map<String, Object> mapRes = (Map<String, Object>)objRes;
                lstUserId.add((String)mapRes.get('user_id'));
            }
            return lstUserId;
        }
        else {
            throw new OtherException(pdPIAuth0.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * エラーメッセージを設定する
    */
    private static String getApiErrorMessage(String body) {
        String errorMessage = 'Auth0 APIでエラーが発生しました: ' + body;
        return errorMessage;
    }
}
