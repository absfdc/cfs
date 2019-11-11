public without sharing class APStatusTransitionForReview extends AbstractAPStatusTransition {
    public APStatusTransitionForReview(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to submit action plan for review. Action plan details missing');
        }        
    }
    
    public override void performTransition() {
        if(!GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)
                && !GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to submit action plan for review. Action plan type is other than ' 
                + GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST + ' and ' + GlobalConstants.AP_TYPE_AGENCY_RESPONSE);
        }
        processAdviceRequestAP();        
    }
    
    private void processAdviceRequestAP() {
        System.debug('Action plan current status: ' + actionPlan.Status__c);
        if(String.isBlank(actionPlan.Parent_Action_Plan__c)) {
            processAdviceRequestParentActionPlan();
        } else {
            processAdviceRequestChildActionPlan();
        }
    }
    
    private void processAdviceRequestParentActionPlan() {
        throw new InvalidDataException('Failed to submit action plan for review. Only child action plan can be submitted for review');
    }
        
    private void processAdviceRequestChildActionPlan() { 
        if(!GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.status__c)) {
            throw new InvalidDataException('Failed to submit action plan for review. Current status of action plan is other than ' 
                + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }
        List<Action_Plan__c> parentActionPlan = [SELECT Id, OwnerId FROM Action_Plan__c WHERE Id = :actionPlan.Parent_Action_Plan__c];
        actionPlan.OwnerId = parentActionPlan[0].OwnerId;
        actionPlan.status__c = GlobalConstants.ACTION_PLAN_NEW_APPROVED;
        update actionPlan;
    }
    
    public class InvalidDataException extends Exception {}
}