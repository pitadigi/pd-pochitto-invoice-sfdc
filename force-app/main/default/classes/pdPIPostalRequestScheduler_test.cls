@isTest
class pdPIPostalRequestScheduler_test {
    @isTest
    static void test_pdPIPostalRequestScheduler() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        String sch = '0 0 1 * * ?';

        String jobId = System.schedule('pdPIPostalRequestScheduler', sch, new pdPIPostalRequestScheduler());

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];

        System.assertEquals(sch, ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);

        Datetime dt = Datetime.now();
        dt = dt.addDays(1);
        String nextFirstTime = dt.format('yyyy-MM-dd 01:00:00');
        System.assertEquals(nextFirstTime, String.valueOf(ct.NextFireTime));
    }
}
