public without sharing class APStatusTransitionForCompleted extends AbstractAPStatusTransition{
    public APStatusTransitionForCompleted(String actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to complete action plan. Action plan details missing');
        }       
    }    
    
    public override void performTransition() {
        if(!GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)
                && !GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to complete action plan. Action plan type is other than ' 
            + GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST + ' and ' + GlobalConstants.AP_TYPE_AGENCY_RESPONSE);
        }
        
        if(!actionPlan.Has_Liaison_Officer_Permissions__c) {
            throw new InvalidDataException('Failed to complete action plan. Action Plan can only be completed by Agency/Division Liaison Officer or RMS Corro Officer.');
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
        if(!GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS .equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to complete action plan. Current status of action plan is other than ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS  + ' and ' + GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG);
        }
        List<Action_Plan__c> apsToUpdate = new List<Action_Plan__c>();
        if(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)) {
            List<Action_Plan__c> childActionPlans = [SELECT Id, Status__c FROM Action_Plan__c WHERE Parent_Action_Plan__c = :actionPlan.Id];
            for(Action_Plan__c ap : [SELECT Id, Status__c FROM Action_Plan__c WHERE Parent_Action_Plan__c = :actionPlan.Id]) {
                ap.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
                apsToUpdate.add(ap);
            }
        }
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
        apsToUpdate.add(actionPlan);
        update apsToUpdate;
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
        if(!GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to complete action plan. Current status of action plan is other than ' + GlobalConstants.ACTION_PLAN_NEW_APPROVED + ' and ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }
                
        if(!areChildActionPlansComplete()) {
            throw new InvalidDataException('Failed to complete action plan. Atleast one child action plan is not complete.');
        }
        
        if(!isApproverDetailsAvailable()) {
            throw new InvalidDataException('Failed to complete action plan. Please enter the final approver name, role and approval date.');
        }
        
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
        actionPlan.OwnerId = UserInfo.getUserId();
        update actionPlan;
    }
    
    private Boolean isApproverDetailsAvailable() {
        Boolean flag = true;
        if(String.isBlank(actionPlan.Approver_Name__c) 
                || actionPlan.Approval_Date__c == null 
                || String.isBlank(actionPlan.Approver_Role__c)) {
            flag = false;
        }
        return flag;
    }
    
    private Boolean areChildActionPlansComplete() {
        List<Action_Plan__c> childActionPlans = [   SELECT Id 
                                                    FROM Action_Plan__c 
                                                    WHERE Status__c != :GlobalConstants.ACTION_PLAN_CLOSED_STATUS
                                                        AND Parent_Action_Plan__c = :actionPlan.Id];
        return childActionPlans.isEmpty();      
    }
            
    private void processAdviceRequestChildActionPlan() { 
        if(!GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(actionPlan.Status__c)
                && !GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to complete action plan. Current status of action plan is other than ' + GlobalConstants.ACTION_PLAN_NEW_APPROVED + ' and ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }
                
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
        
        List<Action_Plan__c> parent = [SELECT Id, OwnerId FROM Action_Plan__c WHERE Id = :actionPlan.Parent_Action_Plan__c];
        if(!parent.isEmpty()) {
            actionPlan.OwnerId = parent[0].OwnerId;
        }
        
        update actionPlan;
    }
    
    public class InvalidDataException extends Exception {}
}