@isTest
class pdPIContractBatchScheduler_test {
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
        contract.Status = 'Closed';
        contract.EndDate = Date.today().addDays(-33);
        update contract;
    }

    @isTest
    static void test_pdPIContractBatchScheduler() {
        Test.startTest();

        String sch = '0 0 4 * * ?';

        String jobId = System.schedule('pdPIContractBatchScheduler', sch, new pdPIContractBatchScheduler());

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];

        System.assertEquals(sch, ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);

        Datetime dt = Datetime.now();
        dt = dt.addDays(1);
        String nextFirstTime = dt.format('yyyy-MM-dd 04:00:00');
        System.assertEquals(nextFirstTime, String.valueOf(ct.NextFireTime));
    }
}
