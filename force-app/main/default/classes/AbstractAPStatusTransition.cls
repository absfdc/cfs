public with sharing abstract class AbstractAPStatusTransition {
    
    protected Action_Plan__c actionPlan;
    private static final String ACTION_PLAN_DETAILS_MISSING='Action plan details missing';
    
    protected void validateActionPlan(Id actionPlanId) {
        if(String.isBlank(actionPlanId)) {
            throw new InvalidDataException(ACTION_PLAN_DETAILS_MISSING);
        }
        List<Action_Plan__c> actionPlans = [SELECT Id, Status__c, Divisions__c, Parent_Case__c, Type__c, Agency__c, Parent_Action_Plan__c, AssignedSME__c, AgencyVsQueueMapping__c,
                                                Response__c, Approval_Date__c, Approver_Name__c, Approver_Role__c, Printing_Location__c, OwnerId, Amendment__c, Has_Corro_Officer_Permissions__c, Has_Liaison_Officer_Permissions__c
                                            FROM Action_Plan__c 
                                            WHERE Id = :actionPlanId];
        if(actionPlans.isEmpty()) {
            throw new InvalidDataException(ACTION_PLAN_DETAILS_MISSING);
        }
        actionPlan = actionPlans[0];
    }
    
    public abstract void performTransition();
    
    public class InvalidDataException extends Exception {}
}