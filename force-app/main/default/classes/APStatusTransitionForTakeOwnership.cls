public without sharing class APStatusTransitionForTakeOwnership extends AbstractAPStatusTransition {
    public APStatusTransitionForTakeOwnership(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to take ownership of action plan. Action plan details missing');
        }        
    }
    
    public override void performTransition() {
        if(!GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)
                && !GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to take ownership of action plan. Action plan type is other than ' 
                + GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST + ' and ' + GlobalConstants.AP_TYPE_AGENCY_RESPONSE);
        }
        
        if(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)) {
            processAdviceRequestAP();
        } else {
            processAgencyResponseAP();
        }        
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
        if(!GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to take ownership of action plan. Current status is other than ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '.');
        }
        if(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)) {
            actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;
        }
        
        actionPlan.OwnerId = UserInfo.getUserId();
        update actionPlan;
    }
    
    private void processAgencyResponseChildActionPlan() {
        processAdviceRequestChildActionPlan();
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
        if(!GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to take ownership of action plan. Current status is other than ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '.');
        }
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;
        //need to check if current user is GIS admin?
        actionPlan.OwnerId = UserInfo.getUserId();
        update actionPlan;
    }
        
    private void processAdviceRequestChildActionPlan() { 
        if(!GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to take ownership of action plan. Current status is other than ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS + '.');
        }
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;
        //need to check if current user is CO/SME?
        actionPlan.OwnerId = UserInfo.getUserId();
        update actionPlan;
    }
    
    public class InvalidDataException extends Exception {}
}