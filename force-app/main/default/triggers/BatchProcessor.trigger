trigger BatchProcessor on Cases_for_batch_processing__c (after insert) {
    Set<String> inProgressJobStatus = new Set<String>();
    Map<String, AsyncJobInProgressStatus__c> asyncStatuses = AsyncJobInProgressStatus__c.getAll();
    if(!asyncStatuses.isEmpty()) {
        inProgressJobStatus = asyncStatuses.keySet();
    }
    List<ApexClass> batchClass = [SELECT Id FROM ApexClass WHERE Name = 'ClosureTargetUpdaterBatch'];
    
    List<AsyncApexJob> existingJobs = [ SELECT Id, Status 
                                        FROM AsyncApexJob 
                                        WHERE Status IN :inProgressJobStatus
                                            AND ApexClassId = :batchClass[0].Id];
    if(existingJobs.isEmpty()) {
        System.debug(LoggingLevel.INFO, 'Execute batch to update closure target date');
        ClosureTargetUpdaterBatch closureTrgtUpd = new ClosureTargetUpdaterBatch();
        System.scheduleBatch(closureTrgtUpd, 'Update Closure Target Date ' + Trigger.new[0].CaseId__c,  1);
    }

}