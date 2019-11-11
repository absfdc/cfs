global  without sharing class ClosureTargetUpdaterBatch implements Database.Batchable<sObject>{
    
    global final String query = 'SELECT Id, CaseId__c FROM Cases_for_batch_processing__c LIMIT 200';

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Cases_for_batch_processing__c> scope){
        Set<Id> caseIDs = new Set<Id>();
        for(Cases_for_batch_processing__c record : scope) {
            caseIDs.add(record.CaseId__c);
        }
        CaseEntitlementUtil.updateCaseTargetDateSync(caseIDs);
        
        delete scope;
    }

    global void finish(Database.BatchableContext BC){
        List<Cases_for_batch_processing__c> records = (List<Cases_for_batch_processing__c>) Database.query(query);
        if(!records.isEmpty()) {
            ClosureTargetUpdaterBatch closureTrgtUpdBatch = new ClosureTargetUpdaterBatch();
            Database.executeBatch(closureTrgtUpdBatch);
        }
    }
}