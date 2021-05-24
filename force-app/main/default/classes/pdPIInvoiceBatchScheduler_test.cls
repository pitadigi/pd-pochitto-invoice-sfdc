@isTest
class pdPIInvoiceBatchScheduler_test {
    @TestSetup
    static void setup(){
        Pricebook2 pricebook2 = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update pricebook2;

        Product2 product2 = new Product2(
            Name = 'ポチッと請求',
            ProductCode = 'PI0001'
        );
        insert product2;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = pricebook2.Id,
            Product2Id = product2.Id,
            UnitPrice = 35,
            OvertimeRate__c = 15,
            IsActive = true
        );
        insert pricebookEntry;

        Account account = new Account(
            Name = 'Test',
            FullName__c = 'Test',
            AccountCode__c = 'test',
            Phone = '000-0000-0000',
            BillingPostalCode = '020-0611',
            BillingState = '岩手県',
            BillingCity = '滝沢市',
            BillingStreet = '巣子１５２番地４０９滝沢市第２イノベーションセンター'
        );
        insert account;

        Contact contact = new Contact(
            FirstName = 'test',
            LastName = 'test',
            Department = 'test',
            Email = 'test@test.jp',
            AccountId = account.Id
        );
        insert contact;

        Contract contract = new Contract(
            Name = '契約',
            AccountId = account.Id,
            StartDate = Date.today().addDays(-60),
            Status = 'Draft',
            ContractId__c = 'test',
            piDeletedUserEnv__c = false,
            BillingContact__c = contact.Id,
            BillingPostalCode = '020-0611',
            BillingState = '岩手県',
            BillingCity = '滝沢市',
            BillingStreet = '巣子１５２番地４０９滝沢市第２イノベーションセンター'
        );
        insert contract;
        contract.Status = 'Activated';
        contract.EndDate = Date.today().addDays(-33);
        update contract;

        Order order = new Order(
            ContractId = contract.Id,
            Status = 'Draft',
            EffectiveDate = Date.today().addDays(-60),
            Pricebook2Id = pricebook2.Id
        );
        insert order;

        OrderItem orderItem = new OrderItem(
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product2.Id,
            UnitPrice = 35,
            OvertimeRate__c = 15,
            orderId = order.Id,
            Quantity = 1
        );
        insert orderItem;
    }

    @isTest
    static void test_pdPIInvoiceBatchScheduler() {
        Test.startTest();

        String sch = '0 0 4 * * ?';

        String jobId = System.schedule('pdPIInvoiceBatchScheduler', sch, new pdPIInvoiceBatchScheduler());

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];

        System.assertEquals(sch, ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);

        Datetime dt = Datetime.now();
        dt = dt.addDays(1);
        String nextFirstTime = dt.format('yyyy-MM-dd 04:00:00');
        System.assertEquals(nextFirstTime, String.valueOf(ct.NextFireTime));
    }
}
