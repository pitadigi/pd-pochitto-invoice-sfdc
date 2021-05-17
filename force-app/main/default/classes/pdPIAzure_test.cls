@isTest
class pdPIAzure_test {
    @isTest
    static void test_buildUserEnv() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIAzure.buildUserEnv('test');

        Test.stopTest();
    }

    @isTest
    static void test_setStateToEnd() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        List<Contract> lstContact = new List<Contract>();
        lstContact.add(new Contract(ContractId__c='dev'));

        Test.startTest();

        pdPIAzure.setStateToEnd(lstContact);

        Test.stopTest();
    }
}
