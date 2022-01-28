@isTest
class pdPIPostalRequest_test {
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
    static void getPiPostal_test() {
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

        Test.startTest();

        List<PostalRequest__c> lstPostalRequest = pdPIPostalRequest.getPostalRequest();

        System.assertEquals(lstPostalRequest.size(), 1, '取得した郵送依頼が１件ではありません');

        Test.stopTest();
    }
}
