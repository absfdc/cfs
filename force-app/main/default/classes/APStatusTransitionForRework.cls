public without sharing class APStatusTransitionForRework extends AbstractAPStatusTransition {
    public APStatusTransitionForRework(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to send action plan for ' + GlobalConstants.ACTION_PLAN_REWORK + '. Action plan details missing');
        }
    }
    
    public override void performTransition() {
        if(!GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to send action plan for ' 
                + GlobalConstants.ACTION_PLAN_REWORK + '. Action plan type is other than ' 
                + GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST + '.');
        }
        
        processAdviceRequestAP();
    }
            
    private void processAdviceRequestAP() {
        if(String.isBlank(actionPlan.Agency__c)) {
            throw new InvalidDataException('Failed to send action plan for ' 
                + GlobalConstants.ACTION_PLAN_REWORK + '. Agency/Division not populated on action plan.');
        }
        if(GlobalConstants.ACTION_PLAN_AGENCY_Q_NOT_FOUND.equalsIgnoreCase(actionPlan.AgencyVsQueueMapping__c)) {
            throw new InvalidDataException('Failed to send action plan for ' 
                + GlobalConstants.ACTION_PLAN_REWORK + '. Queue detail for ' + actionPlan.Agency__c + ' is not available');
        }
    
        if(String.isBlank(actionPlan.Parent_Action_Plan__c)) {
            processAdviceRequestParentActionPlan();
        } else {
            throw new InvalidDataException('Failed to send action plan for ' 
                + GlobalConstants.ACTION_PLAN_REWORK + '. Rework button cannot be used with child action plan.');
        }
    }
    
    private void processAdviceRequestParentActionPlan() {
        System.debug('Action plan current status: ' + actionPlan.Status__c);        
        
        if(!GlobalConstants.ACTION_PLAN_CLOSED_STATUS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to send action plan for ' + GlobalConstants.ACTION_PLAN_REWORK 
                + '. Current status is other than ' + GlobalConstants.ACTION_PLAN_CLOSED_STATUS + '.');
        }
                
        if(String.isBlank(actionPlan.AssignedSME__c)) {
            populateCOQueue();            
        } else {
            actionPlan.OwnerId = actionPlan.AssignedSME__c;
            actionPlan.AssignedSME__c = null;
        }        
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;
        actionPlan.IsRework__c = true;
        actionPlan.SkipValidations__c = false;
        update actionPlan;
    }
        
    private void populateCOQueue() {
        List<Group> groups = [  SELECT Id, Name 
                                FROM Group 
                                Where DeveloperName = :actionPlan.AgencyVsQueueMapping__c 
                                    AND Type = 'Queue' LIMIT 1];
        if(groups.isEmpty()) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '. Queue not available for ' + actionPlan.Agency__c + '.');
        }
        actionPlan.OwnerId = groups[0].Id;
    }
    
    public class InvalidDataException extends Exception {}
}