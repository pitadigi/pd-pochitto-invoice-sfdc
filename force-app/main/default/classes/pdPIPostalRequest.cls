@RestResource(urlMapping='/pi-postal-request/*')
global with sharing class pdPIPostalRequest {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    @future(callout = true)
    public static void aggregatePostal() {
        String accessToken = pdPIAuth0.getAccessToken('API');

        Date yesterday = Date.today().addDays(-1);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        String param = 'contract_id=build_user_env' + 
            '&targetDate=' + String.valueOf(yesterday);
        req.setEndpoint('callout:PochittoInvoiceApi/api/maintenance/postal?' + param);
        req.setHeader('content-type', 'application/json');
        req.setHeader('authorization', accessToken);

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            List<PostalRequest__c> del = [SELECT Id FROM PostalRequest__c WHERE PostalRequestDate__c=:yesterday];
            if (del.size() != 0) {
                delete del;
            }

            Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String result = (String)mapRes.get('result');
            if (result == 'OK') {
                List<Object> lstIssuePostal = (List<Object>)mapRes.get('issuePostal');
                if (lstIssuePostal.size() != 0) {
                    PostalRequest__c postalRequest = new PostalRequest__c();
                    postalRequest.PostalRequestDate__c = yesterday;
                    insert postalRequest;
                    List<PostalRequestDetail__c> lstPostalRequestDetail = new List<PostalRequestDetail__c>();
                    for (Object obj : lstIssuePostal) {
                        Map<String,Object> item = (Map<String,Object>)obj;
                        PostalRequestDetail__c postalRequestDetail = new PostalRequestDetail__c();
                        postalRequestDetail.PostalRequest__c = postalRequest.Id;
                        postalRequestDetail.Name = (String)item.get('contractId');
                        postalRequestDetail.PostalRequestCount__c = (Long)item.get('issueCount');
                        lstPostalRequestDetail.add(postalRequestDetail);
                    }
    
                    insert lstPostalRequestDetail;
                }
            } else {
                throw new OtherException('郵送依頼状況取得でエラーが発生しました: ' + (String)mapRes.get('errorMessage'));
            }
        }
        else {
            throw new OtherException(pdPIPostalRequest.getApiErrorMessage(res.getBody()));
        }
    }

    /**
     * エラーメッセージを設定する
    */
    private static String getApiErrorMessage(String body) {
        String errorMessage = '郵送依頼状況取得APIでエラーが発生しました: ' + body;
        return errorMessage;
    }

    /**
     * 過去30回分の郵送依頼情報を取得する
     */
    @HttpGet
    global static String getPostalRequest() {
        List<PostalRequest__c> lstPostalRequest = [SELECT PostalRequestDate__c,PostalRequestCount__c,IssueCount__c,Completed__c
                                                    FROM PostalRequest__c ORDER BY PostalRequestDate__c DESC LIMIT 30];

        System.JSONGenerator j = JSON.createGenerator(false);
        j.writeStartObject();
        j.writeFieldName('postal_request');
        j.writeStartArray();
        for (PostalRequest__c postalRequest : lstPostalRequest) {
            j.writeStartObject();
            j.writeDateField('postal_request_date', postalRequest.PostalRequestDate__c);
            j.writeNumberField('postal_request_count', (postalRequest.PostalRequestCount__c == null) ? 0 : postalRequest.PostalRequestCount__c);
            j.writeNumberField('issue_count', (postalRequest.IssueCount__c == null) ? 0 : postalRequest.IssueCount__c);
            j.writeBooleanField('completed', (postalRequest.Completed__c == null) ? false : postalRequest.Completed__c);
            j.writeEndObject();
        }
        j.writeEndArray();
        j.writeEndObject();

        return j.getAsString();
    }
}
