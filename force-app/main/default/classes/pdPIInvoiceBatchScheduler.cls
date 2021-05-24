global with sharing class pdPIInvoiceBatchScheduler implements Schedulable {
    /**
     * 請求ジョブを起動する
     */
    global void execute(SchedulableContext sc) {
        pdPIInvoiceBatch b = new pdPIInvoiceBatch();

        Database.executeBatch(b);
    }
}
