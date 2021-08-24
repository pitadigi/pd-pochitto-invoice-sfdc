@isTest
class pdPISvf_test {
    @isTest
    static void test_regist() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPISvf piSvf = new pdPISvf();
        piSvf.regist('test');

        Test.stopTest();
    }

    @isTest
    static void test_remove() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPISvf piSvf = new pdPISvf();
        piSvf.remove('test');

        Test.stopTest();
    }
}
