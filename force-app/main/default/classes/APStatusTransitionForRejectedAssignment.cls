public without sharing class APStatusTransitionForRejectedAssignment extends AbstractAPStatusTransition {
    public APStatusTransitionForRejectedAssignment(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to update status to ' + GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT + '. Action plan details missing');
        }
    }
    
    public override void performTransition() {
        if(!GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)
                && !GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT 
            + '. Action plan type is other than ' + GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST + ' and ' +  GlobalConstants.AP_TYPE_AGENCY_RESPONSE);
        }
        processAdviceRequestAP();
    }
        
    private void processAdviceRequestAP() {     
        if(String.isBlank(actionPlan.Response__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT + '. Response is not populated on action plan.');
        }
        
        System.debug('Action plan current status: ' + actionPlan.Status__c);
        if(String.isBlank(actionPlan.Parent_Action_Plan__c)) {
            processAdviceRequestParentActionPlan();
        } else {
            processAdviceRequestChildActionPlan();
        }
    }
    
    private void processAdviceRequestParentActionPlan() {
        if(!GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT + '. Current status of action plan is other than ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + ' and ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }
        //Manish Damle : 12 October, 2015
        //if(!String.isBlank(actionPlan.Parent_Case__c)) {
            //List<Case> cases = [SELECT Id, OwnerId FROM Case WHERE Id =:actionPlan.Parent_Case__c];
            //actionPlan.OwnerId = cases[0].OwnerId;
        //} Ownership change will happen after 1 hour for parent action plan.
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT;
        update actionPlan;
    }
        
    private void processAdviceRequestChildActionPlan() { 
        if(!GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT + '. Current status of action plan is other than ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + ' and ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }
        Action_Plan__c parent = [SELECT Id, OwnerId FROM Action_Plan__c WHERE Id = :actionPlan.Parent_Action_Plan__c];
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT;
        actionPlan.OwnerId = parent.OwnerId; 
        update actionPlan;
    }
    
    public class InvalidDataException extends Exception {}
}