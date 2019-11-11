public without sharing class APStatusTransitionForAwaitingSig extends AbstractAPStatusTransition {
    public APStatusTransitionForAwaitingSig(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG + '. Action plan details missing');
        }        
    }
    
    public override void performTransition() {
        if(!GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG + '. Action plan type is other than ' 
                + GlobalConstants.AP_TYPE_AGENCY_RESPONSE);
        }
        processAgencyResponseAP();        
    }
    
    private void processAgencyResponseAP() {
        System.debug('Action plan current status: ' + actionPlan.Status__c);
        if(String.isBlank(actionPlan.Parent_Action_Plan__c)) {
            processAgencyResponseParentActionPlan();
        } else {
            processAgencyResponseChildActionPlan();
        }
    }
    
    private void processAgencyResponseParentActionPlan() {
        if(!GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG + '. Current status of action plan is other than ' + GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT + ', ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS + ' and ' + GlobalConstants.ACTION_PLAN_NEW_APPROVED);
        }
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG;
        update actionPlan;
    }
        
    private void processAgencyResponseChildActionPlan() {
    
    }
    
    public class InvalidDataException extends Exception {}
}