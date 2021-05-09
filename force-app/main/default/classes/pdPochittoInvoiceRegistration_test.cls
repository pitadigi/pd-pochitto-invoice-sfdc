@isTest()
class pdPochittoInvoiceRegistration_test {
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
            IsActive = true
        );
        insert pricebookEntry;
    }

    @isTest
    static void test_regist() {
        JSONGenerator data = JSON.createGenerator(false);
        data.writeStartObject();
        data.writeStringField('Company', 'ぴたデジ株式会社');
        data.writeStringField('Department', '役員');
        data.writeStringField('Title', '代表取締役');
        data.writeStringField('PostalCode', '020-0611');
        data.writeStringField('State', '岩手県');
        data.writeStringField('City', '滝沢市');
        data.writeStringField('Street', '巣子152-409');
        data.writeStringField('LastName', '俣江');
        data.writeStringField('FirstName', '幸治');
        data.writeStringField('LastNameKana', 'マタエ');
        data.writeStringField('FirstNameKana', 'コウジ');
        data.writeStringField('Email', 'kmatae@pitadigi.jp');
        data.writeStringField('Phone', '019-618-0161');
        data.writeStringField('Fax', '019-619-0427');
        data.writeStringField('Payment', 'PayPal');
        data.writeStringField('Tags', 'ポチッと請求');
        data.writeStringField('Satori', 'https://satr.jp');
        data.writeEndObject();

        TestParam testParam = new TestParam();
        testParam.customer = data.getAsString();

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new pdPochittoInvoiceRegistration_mock());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/pi';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(testParam));

        String result = pdPochittoInvoiceRegistration.regist(testParam.customer);

        Map<String, Object> mapResult = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assertEquals((Boolean)mapResult.get('result'), true, '結果がtrueではありません: ' + (String)mapResult.get('message'));
        System.assertEquals((String)mapResult.get('message'), '', 'メッセージが空ではありません');

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

        Test.stopTest();
    }

    class TestParam {
        public String customer;
    }
}
