@isTest
class pdPochittoInvoiceContractBatch_test {
    @TestSetup
    static void setup(){
        Account account = new Account(
            Name = 'ぴたデジ株式会社'
        );
        insert account;

        Contract contract = new Contract(
            Name = '契約',
            AccountId = account.Id,
            StartDate = Date.today().addDays(-60),
            Status = 'Draft',
            ContractId__c = 'test',
            piDeletedUserEnv__c = false
        );
        insert contract;
        contract.Status = 'End';
        contract.EndDate = Date.today().addDays(-33);
        update contract;

    }

    @isTest
    static void test_pdPochittoInvoiceContractBatch() {
        Test.setMock(HttpCalloutMock.class, new pdPochittoInvoice_mock());

        Test.startTest();

        pdPochittoInvoiceContractBatch b = new pdPochittoInvoiceContractBatch();
        Database.executeBatch(b);

        Test.stopTest();
    }
}
