@isTest
class pdPIFreee_test {
    @TestSetup
    static void setup(){
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
    
        Pricebook2 pricebook2 = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update pricebook2;

        Product2 product2 = new Product2(
            Name = 'システム開発',
            ProductCode = 'DV0001'
        );
        insert product2;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = pricebook2.Id,
            Product2Id = product2.Id,
            UnitPrice = 600000,
            IsActive = true
        );
        insert pricebookEntry;

        Contract contract = new Contract(
            Name = 'Test',
            Status = 'Draft',
            StartDate =  Date.newInstance(2021, 10, 1),
            AccountId = account.Id
        );
        insert contract;

        Invoice__c invoice = new Invoice__c(
            Name = 'test',
            IssueCount__c = 100,
            IssueUnitPrice__c = 35,
            PageCount__c = 200,
            PageUnitPrice__c = 15,
            InvoiceDate__c = Date.newInstance(2021, 5, 31),
            InitCount__c = 1,
            InitUnitPrice__c = 50000,
            OptionIssueCount__c = 1,
            OptionPageCount__c = 2,
            OptionIssueUnitPrice__c = 130,
            OptionPageUnitPrice__c = 20,
            Contract__c = contract.Id
        );
        insert invoice;

        Order order = new Order(
            Name = 'Test',
            Status = 'Draft',
            EffectiveDate = Date.newInstance(2021, 10, 1),
            EndDate = Date.newInstance(2021, 12, 31),
            AccountId = account.Id,
            BillToContactId = contact.Id,
            Pricebook2Id = pricebook2.Id
        );
        insert order;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Description = 'Test',
            Quantity = 1,
            Unit__c = '式',
            UnitPrice = 200,
            SortOrder__c = 1,
            PricebookEntryId = pricebookEntry.Id
        );
        insert orderItem;

    }

    @isTest
    static void test_registInvoice() {
        Date startDate = Date.newInstance(2021, 5, 1);
        Date endDate = Date.newInstance(2021, 5, 31);

        Account account = [SELECT Id,Name,FullName__c,Phone,BillingPostalCode,BillingState,BillingCity,BillingStreet,AccountCode__c FROM Account WHERE Name='Test' LIMIT 1];
        Contact contact = [SELECT Id,FirstName,LastName,Email,Department FROM Contact WHERE AccountId=:account.Id AND FirstName='test' AND LastName='test'];
        Invoice__c invoice = [SELECT Id,Name,IssueCount__c,IssueUnitPrice__c,PageCount__c,PageUnitPrice__c,InvoiceDate__c,InitCount__c,InitUnitPrice__c,
                                OptionIssueCount__c,OptionPageCount__c,OptionIssueUnitPrice__c,OptionPageUnitPrice__c
                                FROM Invoice__c WHERE Name='Test' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIFreee piFreee = new pdPIFreee();
        piFreee.registInvoice(startDate, endDate, startDate, account, contact, invoice);

        Test.stopTest();
    }

    @isTest
    static void test_registInvoiceByOrder() {
        Id orderId = [SELECT Id FROM Order WHERE Name='Test' LIMIT 1].Id;

        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIFreee piFreee = new pdPIFreee();
        piFreee.registInvoiceByOrder(orderId);

        Test.stopTest();
    }
}
