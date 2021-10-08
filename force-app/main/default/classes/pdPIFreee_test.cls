@isTest
class pdPIFreee_test {
    @isTest
    static void test_registInvoice() {
        Date startDate = Date.newInstance(2021, 5, 1);
        Date endDate = Date.newInstance(2021, 5, 31);
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
        Contact contact = new Contact(
            FirstName = 'test',
            LastName = 'test',
            Department = 'test',
            Email = 'test@test.jp'
        );
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
            OptionPageUnitPrice__c = 20
        );

        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();

        pdPIFreee piFreee = new pdPIFreee();
        piFreee.registInvoice(startDate, endDate, account, contact, invoice);

        Test.stopTest();
    }
}
