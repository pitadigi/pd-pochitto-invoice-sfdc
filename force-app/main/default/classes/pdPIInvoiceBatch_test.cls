@isTest
class pdPIInvoiceBatch_test {
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
            InitUnitPrice__c = 50000,
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

        Date today = Date.today();
        Date startDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-1);
        Date endDate = startDate.addMonths(1).addDays(-1);
        Contract contract = new Contract(
            Name = '契約',
            AccountId = account.Id,
            StartDate = startDate,
            Status = 'Draft',
            ContractId__c = 'test',
            piDeletedUserEnv__c = false,
            BillingContact__c = contact.Id,
            BillingPostalCode = '020-0611',
            BillingState = '岩手県',
            BillingCity = '滝沢市',
            BillingStreet = '巣子１５２番地４０９滝沢市第２イノベーションセンター',
            IsFirstBilled__c = false,
            TrialSpanMonths__c = 0,
            ServiceInDate__c = startDate
        );
        insert contract;
        contract.Status = 'Activated';
        contract.EndDate = endDate;
        update contract;

        Order order = new Order(
            ContractId = contract.Id,
            Status = 'Draft',
            EffectiveDate = startDate,
            Pricebook2Id = pricebook2.Id
        );
        insert order;

        OrderItem orderItem = new OrderItem(
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product2.Id,
            UnitPrice = 35,
            OvertimeRate__c = 15,
            OrderId = order.Id,
            Quantity = 1,
            InitCount__c = 1,
            InitUnitPrice__c = 50000,
            OptionUnitPrice__c = 130,
            OptionOvertimeRate__c = 20
        );
        insert orderItem;
    }

    @isTest
    static void test_pdPIInvoiceBatch() {
        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIInvoiceBatch b = new pdPIInvoiceBatch();
        Database.executeBatch(b);

        Test.stopTest();
    }
}
