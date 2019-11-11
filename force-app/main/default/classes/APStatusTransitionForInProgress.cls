public without sharing class APStatusTransitionForInProgress extends AbstractAPStatusTransition {
    public APStatusTransitionForInProgress(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS + '. Action plan details missing');
        }        
    }
    
    public override void performTransition() {
        if(!GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)
                && !GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS + '. Action plan type is other than ' 
                + GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST + ' and ' + GlobalConstants.AP_TYPE_AGENCY_RESPONSE);
        }
        if(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)) {
            processAdviceRequestAP();
        } else {
            processAgencyResponseAP();
        }
    }
    
    private void processAgencyResponseAP() {
        processAdviceRequestAP();
    }
    
    private void processAdviceRequestAP() {
        System.debug('Action plan current status: ' + actionPlan.Status__c);
        if(!GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS 
                + '. Current status is other than ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '.');
        }
    
        if(String.isBlank(actionPlan.Parent_Action_Plan__c)) {
            processAdviceRequestParentActionPlan();
        } else {
            processAdviceRequestChildActionPlan();
        }
    }
    
    private void processAdviceRequestParentActionPlan() {        
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
        //need to check if current user is CO?
        actionPlan.OwnerId = UserInfo.getUserId();
        update actionPlan;
    }
        
    private void processAdviceRequestChildActionPlan() {     
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
        //need to check if current user is SME?
        actionPlan.OwnerId = UserInfo.getUserId();
        update actionPlan;
    }
    
    public class InvalidDataException extends Exception {}
}