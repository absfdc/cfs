public without sharing class StampDateFirstChildAssignedOnParent {
    
    private Set<Id> parentActionPlanIds;
    
    public StampDateFirstChildAssignedOnParent(Set<Id> parentActionPlanIds) {
        if(parentActionPlanIds == null || parentActionPlanIds.isEmpty()) {
            throw new InvalidDataException('Failed to stamp date first child action plan assigned on parent. Action plan details missing');
        }
        this.parentActionPlanIds = parentActionPlanIds;
    }
    
    public void stampDate() {
        List<Action_Plan__c> parents = [SELECT Id, Date_First_Child_AP_Assigned__c 
                                        FROM Action_Plan__c 
                                        WHERE Id IN :parentActionPlanIds
                                            AND Date_First_Child_AP_Assigned__c = NULL];
        for(Action_Plan__c ap : parents) {
            ap.Date_First_Child_AP_Assigned__c = System.today();
        }
        if(!parents.isEmpty()) {
            update parents;
        }
    }
    
    public class InvalidDataException extends Exception {}
}