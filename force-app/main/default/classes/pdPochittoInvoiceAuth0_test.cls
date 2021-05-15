@isTest
class pdPochittoInvoiceAuth0_test {
    @isTest
    static void test_createUserOfAuth0() {
        Test.setMock(HttpCalloutMock.class, new pdPochittoInvoice_mock());

        Test.startTest();

        pdPochittoInvoiceAuth0.createUserOfAuth0('test', 'test@pitadigi.jp', 'ぴたデジ株式会社');

        Test.stopTest();
    }
}
