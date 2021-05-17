global with sharing class pdPIContractBatchScheduler implements Schedulable {
    /**
     * 契約ジョブを起動する
     */
    global void execute(SchedulableContext sc) {
        pdPIContractBatch b = new pdPIContractBatch();

        Database.executeBatch(b);
    }
}
