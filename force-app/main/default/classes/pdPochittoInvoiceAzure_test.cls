@isTest
class pdPochittoInvoiceAzure_test {
    @isTest
    static void test_buildUserEnv() {
        Test.setMock(HttpCalloutMock.class, new pdPochittoInvoice_mock());

        Test.startTest();

        pdPochittoInvoiceAzure.buildUserEnv('test');

        Test.stopTest();
    }

    @isTest
    static void test_setStateToEnd() {
        Test.setMock(HttpCalloutMock.class, new pdPochittoInvoice_mock());

        List<Contract> lstContact = new List<Contract>();
        lstContact.add(new Contract(ContractId__c='dev'));

        Test.startTest();

        pdPochittoInvoiceAzure.setStateToEnd(lstContact);

        Test.stopTest();
    }
}
