public with sharing class pdFreee {
    /**
     * freeeに請求書を登録する
     * プロセスビルダー、フローからApexクラスを呼び出すにはstaticである必要があるため、専用に作成
     */
    @InvocableMethod(label='注文を元にfreeeに請求書を登録' description='注文を元にfreeeに請求書を登録する')
    public static void registInvoiceByOrders(List<Id> lstOrderId) {
        for (Id orderId : lstOrderId) {
            pdFreee.registInvoiceByOrder(orderId);
        }
    }

    @future(callout = true)
    private static void registInvoiceByOrder(Id orderId) {
        pdPIFreee freee = new pdPIFreee();
        freee.registInvoiceByOrder(orderId);
    }
}
