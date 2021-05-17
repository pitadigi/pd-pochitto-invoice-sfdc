public with sharing class pdPIAzure {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * Azureのユーザ環境を構築する
     */
    public static void buildUserEnv(String contractId) {
        String accessToken = pdPIAuth0.getAccessToken('API');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:PochittoInvoiceApi/api/maintenance/userenv');
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
            throw new OtherException(pdPIAzure.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * Azureのユーザ環境を削除する
     */
    public static void deleteUserEnv(String contractId) {
        String accessToken = pdPIAuth0.getAccessToken('API');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('DELETE');
        req.setEndpoint('callout:PochittoInvoiceApi/api/maintenance/userenv');
        req.setHeader('content-type', 'application/json');
        req.setHeader('authorization', accessToken);
        
        system.debug(accessToken);

        JSONGenerator data = JSON.createGenerator(false);
        data.writeStartObject();
        data.writeStringField('contract_id', contractId);
        data.writeEndObject();
        req.setBody(data.getAsString());

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String result = (String)mapRes.get('result');
            if (result != 'OK') {
                throw new OtherException('ユーザ環境削除でエラーが発生しました: ' + (String)mapRes.get('errorMessage'));
            }
        }
        else {
            throw new OtherException(pdPIAzure.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * 契約ステータスを終了にする
     */
    @InvocableMethod(label='契約ステータスを終了' description='Azureの契約IDのステータスを終了に変更する')
    public static void setStateToEnd(List<Contract> lstContract) {
        for (Contract contract: lstContract) {
            if (String.isBlank(contract.ContractId__c)) {
                continue;
            }

            pdPIAzure.setState(contract.ContractId__c, 'end');
            pdPIAuth0.blockUser(contract.ContractId__c);
        }
    }

    /**
     * 契約ステータスを指定されたステータスに変更する
     */
    @future(callout = true)
    private static void setState(String contractId, String state) {
        String accessToken = pdPIAuth0.getAccessToken('API');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setEndpoint('callout:PochittoInvoiceApi/api/maintenance/userenv');
        req.setHeader('content-type', 'application/json');
        req.setHeader('authorization', accessToken);
        
        JSONGenerator data = JSON.createGenerator(false);
        data.writeStartObject();
        data.writeStringField('contract_id', contractId);
        data.writeFieldName('param');
        data.writeStartObject();
        data.writeStringField('state', state);
        data.writeEndObject();
        data.writeEndObject();
        req.setBody(data.getAsString());

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String result = (String)mapRes.get('result');
            if (result != 'OK') {
                throw new OtherException('ステータス変更でエラーが発生しました: ' + (String)mapRes.get('errorMessage'));
            }
        }
        else {
            throw new OtherException(pdPIAzure.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * エラーメッセージを設定する
    */
    private static String getApiErrorMessage(String body) {
        String errorMessage = 'Azure APIでエラーが発生しました: ' + body;
        return errorMessage;
    }
}
