public with sharing class ReopenedCaseReassigner {
    
    private Map<Id,Case> oldCases;
    private Map<Id,Case> newCases;
    private Map<String,Id> queues;
    
    public ReopenedCaseReassigner(Map<Id,Case> oldCases, Map<Id,Case> newCases, Map<Id,Group> queues) {
        if(oldCases == null || oldCases.isEmpty() || newCases == null || newCases.isEmpty()) {
            throw new InvalidDataException('Failed to reassign opened case. Case details missing');
        }
        if(queues == null) {
            throw new InvalidDataException('Failed to reassign opened case. Queue details missing');
        }
        this.queues = new Map<String,Id>();
        for(Group grp : queues.values()) {
            this.queues.put(grp.DeveloperName, grp.Id);
        }
        this.oldCases = oldCases;
        this.newCases = newCases;
    }
    
    public void reassignCaseOwner() {
        for(Case caseRecord : newCases.values()) {
            if(caseRecord.Status == GlobalConstants.REOPENED_CASE_STATUS_CUSTOMER_COMMUNICATION 
                    && oldCases.get(caseRecord.Id).Status != GlobalConstants.REOPENED_CASE_STATUS_CUSTOMER_COMMUNICATION && caseRecord.Last_Queue_Assigned__c != null && !caseRecord.IsMinCorroCase__c) {
                if(queues.containsKey(caseRecord.Last_Queue_Assigned__c))
                caseRecord.OwnerId = queues.get(caseRecord.Last_Queue_Assigned__c);
            }
        }
    }
    
    public class InvalidDataException extends Exception {}
}