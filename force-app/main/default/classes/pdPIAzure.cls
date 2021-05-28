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
     * 契約ステータスを変更する
     */
    @InvocableMethod(label='契約ステータスを変更' description='Azureの契約IDのステータスを変更する')
    public static void setStateToAzure(List<Contract> lstContract) {
        for (Contract contract: lstContract) {
            if (String.isBlank(contract.ContractId__c)) {
                continue;
            }

            String state;
            if (contract.Status == 'Draft'
                || contract.Status == 'Trial') {
                state = 'trial';
            } else if (contract.Status == 'In Progress'
                || contract.Status == 'In Confirm'
                || contract.Status == 'In Approval Process') {
                state = 'inprep';
            } else if (contract.Status == 'Activated') {
                state = 'inuse';
            } else if (contract.Status == 'Closed') {
                state = 'end';
            }

            pdPIAzure.setState(contract.ContractId__c, state);

            pdPIAuth0.setUserBlockState(contract.ContractId__c, state == 'end');
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
        req.setTimeout(30 * 1000);
        
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
                system.debug((String)mapRes.get('errorMessage'));
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
