@isTest
class pdPIRegistration_test {
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
            UnitPrice = 0,
            IsActive = true,
            InitUnitPrice__c = 50000
        );
        insert pricebookEntry;

        ServiceApplication__c serviceApplication = new ServiceApplication__c();
        serviceApplication.ServiceName__c = 'ポチッと請求';
        serviceApplication.CompanyName__c = '**テスト株式会社';
        serviceApplication.PostalCode__c = '020-0611';
        serviceApplication.State__c = '岩手県';
        serviceApplication.City__c = '滝沢市';
        serviceApplication.Street__c = '巣子152-409';
        serviceApplication.Bill__c = '滝沢市第2イノベーションセンター';
        serviceApplication.Department__c = '経理部';
        serviceApplication.LastName__c = '俣江';
        serviceApplication.FirstName__c = '幸治';
        serviceApplication.Phone__c = '019-618-0161';
        serviceApplication.MailAddress__c = 'test@test.jp';
        insert serviceApplication;
    }

    @isTest
    static void test_regist() {
        List<ServiceApplication__c> lstServiceApplication = [SELECT Id, ServiceName__c, CompanyName__c, PostalCode__c, State__c, City__c,
                                                            Street__c, Bill__c, Department__c, LastName__c, FirstName__c, Phone__c, MailAddress__c
                                                            FROM ServiceApplication__c];

        Test.setMock(HttpCalloutMock.class, new pdPIHttpCallout_mock());

        Test.startTest();
        pdPIRegistration.regist(lstServiceApplication);
        Test.stopTest();

        List<Account> lstAccount = [SELECT Id,Name FROM Account];
        System.assertEquals(lstAccount.size(), 1, '取引先が作成されていません');

        List<Contact> lstContact = [SELECT Id,Name FROM Contact];
        System.assertEquals(lstContact.size(), 1, '取引先責任者が作成されていません');

        List<Contract> lstContract = [SELECT Id,Name FROM Contract];
        System.assertEquals(lstContract.size(), 1, '契約が作成されていません');

        List<Order> lstOrder = [SELECT Id,Name FROM Order];
        System.assertEquals(lstOrder.size(), 1, '注文が作成されていません');

        List<OrderItem> lstOrderItem = [SELECT Id FROM OrderItem];
        System.assertEquals(lstOrderItem.size(), 1, '注文商品が作成されていません');
    }

    class TestParam {
        public String customer;
    }
}
