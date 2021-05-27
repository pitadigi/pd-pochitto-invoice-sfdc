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
    static void test_setStateToAzure() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        List<Contract> lstContact = new List<Contract>();
        lstContact.add(new Contract(ContractId__c='dev', Status='Draft'));

        Test.startTest();

        pdPIAzure.setStateToAzure(lstContact);

        Test.stopTest();
    }
}
