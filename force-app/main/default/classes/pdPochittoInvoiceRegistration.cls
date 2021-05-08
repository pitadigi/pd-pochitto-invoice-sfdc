public with sharing class pdPochittoInvoiceRegistration {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * ポチッと請求の申込情報を登録する
     */
    public void Regist() {
        String contractId = this.createContractId();
        
        this.BuildUserEnv(contractId);
    }

    /**
     * Azureのユーザ環境を構築する
     */
    private void BuildUserEnv(String contractId) {
        String accessToken = this.getAccessToken();
        system.debug(accessToken);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:PochittoInvoiceApi/api/registration');
        req.setHeader('content-type', 'application/json');
        req.setHeader('authorization', accessToken);
        
        JSONGenerator data = JSON.createGenerator(false);
        data.writeStartObject();
        data.writeStringField('contract_id', contractId);
        data.writeEndObject();
        req.setBody(data.getAsString());

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 201) {
            Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String result = (String)mapRes.get('result');
            if (result != 'OK') {
                throw new OtherException('ユーザ環境構築でエラーが発生しました: ' + (String)mapRes.get('errorMessage'));
            }
        }
        else {
            throw new OtherException(this.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * Auth0からアクセストークンを取得する
     */
    private String getAccessToken() {
        Auth0__mdt auth0 = [SELECT URL__c,ClientId__c,Secret__c,Audience__c,GrantType__c FROM Auth0__mdt WHERE DeveloperName='Current'];

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(auth0.URL__c);
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
            throw new OtherException(this.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * エラーメッセージを設定する
    */
    private String getApiErrorMessage(String body) {
        Map<String, Object> mapError = (Map<String, Object>)JSON.deserializeUntyped(body);
        List<Object> lstError = (List<Object>)(mapError.get('errors'));
        String errorMessage = 'APIでエラーが発生しました\n';
        for(Object mapErrorContent : lstError) {
            List<Object> lstMessage = (List<Object>)((Map<String, Object>)mapErrorContent).get('messages');
            for(Object message : lstMessage) {
                errorMessage += message.toString() + '\n';
            }
        }
 
        return errorMessage;
    }

    /**
     * 契約IDを生成する
     */
    private String createContractId() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8) + h.SubString(8,12) + h.SubString(12,16) + h.SubString(16,20) + h.substring(20);

        return guid.toLowerCase();
    }
}
