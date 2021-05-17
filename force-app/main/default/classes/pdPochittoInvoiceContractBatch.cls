public with sharing class pdPochittoInvoiceContractBatch implements Database.Batchable<Contract> {
    /**
     * 契約の環境を削除する
     */
    public void execute(Database.BatchableContext bc, List<Contract> lstContract) {
        for (Contract contract: lstContract) {
            if (String.isBlank(contract.contractId__c)) {
                continue;
            }

            pdPochittoInvoiceAuth0.deleteUser(contract.ContractId__c);
            pdPochittoInvoiceAzure.deleteUserEnv(contract.ContractId__c);
        }
    }
}
