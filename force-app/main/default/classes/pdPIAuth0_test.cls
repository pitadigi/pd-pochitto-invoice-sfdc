@isTest
class pdPIAuth0_test {
    @isTest
    static void test_createUser() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIAuth0.createUser('test', 'test@pitadigi.jp', 'ぴたデジ株式会社');

        Test.stopTest();
    }

    @isTest
    static void test_setUserBlockState() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIAuth0.setUserBlockState('test', true);

        Test.stopTest();
    }

    @isTest
    static void test_deleteUser() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIAuth0.deleteUser('test');

        Test.stopTest();
    }
}
