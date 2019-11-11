public without sharing class IncomingSnswToRmsCaseProcessor {

    private Map<Id, Case> newCaseMap;
    private Map<Id, Case> oldCaseMap;
    private Id snswTriageQueue;
    
    public IncomingSnswToRmsCaseProcessor(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
        if(newCases == null || oldCases == null || oldCases.isEmpty() || newCases.isEmpty()) {
            throw new InvalidDataException('Failed to process case. Case details missing');
        }
        for(Case caseRecord : newCases.values()) {
            if(!oldCases.containsKey(caseRecord.Id)) {
                throw new InvalidDataException('Failed to process case. Case details missing');
            }
        }
        this.newCaseMap = newCases;
        this.oldCaseMap = oldCases;
        List<Group> groups = [  SELECT Id, Name 
                                FROM Group 
                                WHERE Name = :GlobalConstants.SNSW_TRIAGE_QUEUE
                                    AND Type = 'Queue'];
        if(!groups.isEmpty()) {
            snswTriageQueue = groups[0].Id;
        }
    }
    
    public void processCases() {
        List<Case> newCases = newCaseMap.values();
        List<Entitlement> entitlementsForRMS = [SELECT Name, Id FROM Entitlement WHERE Name = :GlobalConstants.RMS_AGENCY];
        for(Case caseRecord : newCases) {
            if(GlobalConstants.RESPONSIBLE_PARTY_SNSW.equalsIgnoreCase(oldCaseMap.get(caseRecord.Id).Responsible_Party__c) 
                && GlobalConstants.RESPONSIBLE_PARTY_RMS.equalsIgnoreCase(caseRecord.Responsible_Party__c)) {
                caseRecord.Status = GlobalConstants.CASE_STATUS_NEW;
                caseRecord.Shared__c = false;
                caseRecord.Agency__c = GlobalConstants.RMS_AGENCY;
                caseRecord.OwnerAgency__c = GlobalConstants.RMS_AGENCY;
                if(!entitlementsForRMS.isEmpty()) {
                    caseRecord.EntitlementId = entitlementsForRMS[0].Id;
                }
                if(!String.isBlank(snswTriageQueue))
                    caseRecord.OwnerId = snswTriageQueue;
            }
        }
    }
    
    public class InvalidDataException extends Exception {}
}