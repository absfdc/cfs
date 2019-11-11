public without sharing class APStatusTransitionForAmendment extends AbstractAPStatusTransition {
    public APStatusTransitionForAmendment(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Amendment failed on action plan. Action plan details missing');
        }        
    }
    
    public override void performTransition() {
        if(!GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Amendment failed on action plan. Action plan type is other than ' 
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
        if(!GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Amendment failed on action plan. Current status of action plan is other than ' + GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG);
        }
        
        if(actionPlan.OwnerId != UserInfo.getUserId()) {
            throw new InvalidDataException('Amendment failed on action plan. Only current owner of action plan can perform amendment.');
        }
        if(actionPlan.Amendment__c == null) {
            actionPlan.Amendment__c = 0;
        }
        actionPlan.Amendment__c = actionPlan.Amendment__c + 1;
        actionPlan.Amendment_Date__c = System.today();
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
        update actionPlan;
    }
        
    private void processAgencyResponseChildActionPlan() {
    
    }
    
    public class InvalidDataException extends Exception {}
}