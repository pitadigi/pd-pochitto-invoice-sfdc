global with sharing class pdPochittoInvoiceContractBatchScheduler implements Schedulable {
    /**
     * 契約ジョブを起動する
     */
    global void execute(SchedulableContext sc) {
        pdPochittoInvoiceContractBatch b = new pdPochittoInvoiceContractBatch();

        Database.executeBatch(b);
    }
}
