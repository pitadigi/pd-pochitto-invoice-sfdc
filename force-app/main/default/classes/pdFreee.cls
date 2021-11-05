public with sharing class pdFreee {
    /**
     * freeeに請求書を登録する
     * プロセスビルダー、フローからApexクラスを呼び出すにはstaticである必要があるため、専用に作成
     */
    @InvocableMethod(label='注文を元にfreeeに請求書を登録' description='注文を元にfreeeに請求書を登録する')
    public static void registInvoiceByOrder(List<Id> lstOrderId) {
        pdFreee.registInvoiceByOrders(lstOrderId);
    }

    @future(callout = true)
    private static void registInvoiceByOrders(List<Id> lstOrderId) {
        pdPIFreee freee = new pdPIFreee();
        for (Id orderId : lstOrderId) {
            freee.registInvoiceByOrder(orderId);
        }
    }
}
