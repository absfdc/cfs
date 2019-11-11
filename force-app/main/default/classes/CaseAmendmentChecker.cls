public with sharing class CaseAmendmentChecker {
    
    private List<Action_Plan__c> newActionPlans;
    
    public CaseAmendmentChecker(List<Action_Plan__c> actionPlans) {
        if(actionPlans == null || actionPlans.isEmpty()) {
            throw new InvalidDataException('Failed to check amendment cases. Action plan details missing');
        }
        this.newActionPlans = actionPlans;
    }
    
    public void checkForAmendment() {
        Set<Id> caseIds = new Set<Id>();
        for(Action_Plan__c ap : newActionPlans) {
            caseIds.add(ap.Parent_Case__c);
        }
        Map<Id, Case> parentCaseMap = new Map<Id, Case> ([SELECT Id FROM Case WHERE Id IN :caseIds AND Amendment_Count__c > 0]);
        for(Action_Plan__c ap : newActionPlans) {
            if(parentCaseMap.containsKey(ap.Parent_Case__c)) {
                ap.IsAmendment__c = true;
            }
        }
    }
    
    public class InvalidDataException extends Exception {}
}