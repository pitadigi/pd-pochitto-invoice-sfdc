@isTest
class pdPIPostalRequest_test {
    @TestSetup
    static void setup(){
        PostalRequest__c postalRequest = new PostalRequest__c(
            PostalRequestDate__c = Date.today()
        );
        insert postalRequest;
        PostalRequestDetail__c postalRequestDetail = new PostalRequestDetail__c(
            PostalRequest__c = postalRequest.Id,
            Name = 'test',
            PostalRequestCount__c = 10
        );
        insert postalRequestDetail;
    }

    @isTest
    static void aggregatePostal_test() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();
    
        pdPIPostalRequest.aggregatePostal();

        String yesterday = String.valueOf(Date.today().addDays(-1));
        /*
        List<PostalRequest__c> lstp = [SELECT Id FROM PostalRequest__c WHERE NAME=:yesterday];
        System.assertEquals(1, lstp.size(), '郵送依頼データが１件ではありません。');

        List<PostalRequestDetail__c> lstd = [SELECT Id FROM PostalRequestDetail__c WHERE PostalRequest__c=:lstp[0].Id];
        System.assertEquals(2, lstd.size(), '郵送依頼明細データが１件ではありません。');
        */
        Test.stopTest();
    }

    @isTest
    static void getPostalRequest_test() {
        Test.startTest();

        List<PostalRequest__c> lstPostalRequest = pdPIPostalRequest.getPostalRequest(false);

        System.assertEquals(lstPostalRequest.size(), 1, '取得した郵送依頼が１件ではありません');

        Test.stopTest();
    }

    @isTest
    static void registPostalRequest_test() {
        Date today = Date.today();
        Id id = [SELECT Id FROM PostalRequest__c WHERE PostalRequestDate__c=today LIMIT 1].Id;

        Test.startTest();

        pdPIPostalRequest.registPostalRequest(id, 10, true);

        List<PostalRequest__c> lstPostalRequest = [SELECT Id FROM PostalRequest__c WHERE PostalRequestDate__c=today AND Completed__c=true AND IssueCount__c=10];
        System.assertEquals(lstPostalRequest.size(), 1, '取得した郵送依頼が１件ではありません');

        Test.stopTest();
    }
}
