global with sharing class pdPIPostalRequestScheduler implements Schedulable {
    /**
     * 郵送依頼ジョブを起動する
     */
    global void execute(SchedulableContext sc) {
        pdPIPostalRequest.aggregatePostal();
    }
}
