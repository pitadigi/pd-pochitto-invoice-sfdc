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
}
