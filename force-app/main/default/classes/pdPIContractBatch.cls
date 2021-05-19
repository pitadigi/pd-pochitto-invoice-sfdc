public class pdPIContractBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    /**
     * 以下の条件に合致する契約を返す
     * * 契約レコードタイプがクラウドサービス
     * * 契約のクラウドサービスがポチッと請求
     * * クラウドサービス契約IDがnull以外
     * * クラウドサービス環境削除フラグがfalse
     * * 契約終了日から32日が経過
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        ID recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType='Contract' AND DeveloperName='CloudService'].Id;

        Date startDate = Date.today();
        startDate = startDate.addDays(-32);

        return Database.getQueryLocator(
            [
                SELECT Id,ContractId__c,piDeletedUserEnv__c
                FROM Contract
                WHERE RecordTypeId = :recordTypeId
                    AND CloudService__c = 'PochittoInvoice'
                    AND ContractId__c != null
                    AND EndDate < :startDate
                    AND piDeletedUserEnv__c = false
            ]
        );
    }

    /**
     * 契約の環境を削除する
     * 環境を削除したら、ポチッと請求環境削除フラグを設定する
     */
    public void execute(Database.BatchableContext bc, List<Contract> lstContract) {
        for (Contract contract: lstContract) {
            pdPIAuth0.deleteUser(contract.ContractId__c);
            pdPIAzure.deleteUserEnv(contract.ContractId__c);

            contract.piDeletedUserEnv__c = true;
        }

        update lstContract;
    }

    /**
     * 終了処理を行う
     */
    public void finish(Database.BatchableContext bc) {
    }
}
