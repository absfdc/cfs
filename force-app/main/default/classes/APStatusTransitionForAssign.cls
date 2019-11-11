public without sharing class APStatusTransitionForAssign extends AbstractAPStatusTransition {
    public APStatusTransitionForAssign(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '. Action plan details missing');
        }
    }
    
    public override void performTransition() {
        if(!GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)
                && !GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '. Action plan type is other than ' 
                + GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST + ' and ' + GlobalConstants.AP_TYPE_AGENCY_RESPONSE);
        }
        
        if(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST.equalsIgnoreCase(actionPlan.Type__c)) {
            processAdviceRequestAP();
        } else {
            processAgencyResponseAP();
        }
    }
    
    private void processAgencyResponseAP() {
        if(String.isBlank(actionPlan.Parent_Action_Plan__c)) {
            processAgencyResponseParentActionPlan();
        } else {
            processAgencyResponseChildActionPlan();
        }
    }
    
    private void processAgencyResponseParentActionPlan() {
        if(!GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_NEW_STATUS.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED 
                + '. Current status is other than ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + ' and ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;
        List<Group> groups = [  SELECT Id, Name 
                                FROM Group 
                                Where DeveloperName = :Label.RMS_Corro_officer_queue 
                                    AND Type = 'Queue' LIMIT 1];
        if(groups.isEmpty()) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '. RMS Corro officer queue not available.');
        }
        actionPlan.OwnerId = groups[0].Id;
        update actionPlan;
    }
    
    private void processAgencyResponseChildActionPlan() {
        processAdviceRequestChildActionPlan();
    }
    
    private void processAdviceRequestAP() {
        if(String.isBlank(actionPlan.Agency__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '. Agency/Division not populated on action plan.');
        }
        if(GlobalConstants.ACTION_PLAN_AGENCY_Q_NOT_FOUND.equalsIgnoreCase(actionPlan.AgencyVsQueueMapping__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' 
                + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '. Queue detail for ' + actionPlan.Agency__c + ' is not available');
        }
    
        if(String.isBlank(actionPlan.Parent_Action_Plan__c)) {
            processAdviceRequestParentActionPlan();
        } else {
            processAdviceRequestChildActionPlan();
        }
    }
    
    private void processAdviceRequestParentActionPlan() {
        System.debug('Action plan current status: ' + actionPlan.Status__c);        
        
        if(!GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_NEW_STATUS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED 
                + '. Current status is other than ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + ', ' + GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT + ', ' + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS + ' and ' + GlobalConstants.ACTION_PLAN_NEW_STATUS);
        }
        
        if(!GlobalConstants.ACTION_PLAN_NEW_STATUS.equalsIgnoreCase(actionPlan.Status__c) && String.isBlank(actionPlan.Divisions__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED 
                + '. Division is not populated on action plan');
        }
        
        if(String.isBlank(actionPlan.AssignedSME__c)) {
            populateCOQueue();            
        } else {
            actionPlan.OwnerId = actionPlan.AssignedSME__c;
            actionPlan.TempAssignedSME__c = actionPlan.AssignedSME__c;
            actionPlan.AssignedSME__c = null;
        }        
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;
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
    
    private void processAdviceRequestChildActionPlan() {
        System.debug('Assigned SME on action plan: ' + actionPlan.AssignedSME__c);
        //throw exception if SME is not selected on child action plan
        if(String.isBlank(actionPlan.AssignedSME__c) && actionPlan.Has_Corro_Officer_Permissions__c) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED + '. SME details missing on action plan');
        }
        
        System.debug('Action plan current status: ' + actionPlan.Status__c);
        if(GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(actionPlan.Status__c)) {
            List<Action_Plan__c> parent = [SELECT Id, OwnerId FROM Action_Plan__c WHERE Id = :actionPlan.Parent_Action_Plan__c];
            if(parent.isEmpty() || parent[0].OwnerId != UserInfo.getUserId()) {
                throw new InvalidDataException('Failed to assign action plan. You are not authorised to perform assignment on action plan');
            }
        }
        
        if(!GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.Status__c)
            && !GlobalConstants.ACTION_PLAN_NEW_STATUS.equalsIgnoreCase(actionPlan.Status__c)) {
            throw new InvalidDataException('Failed to update action plan status to ' + GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED 
                + '. Current status is other than ' + GlobalConstants.ACTION_PLAN_NEW_APPROVED + ', ' 
                + GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT + ', ' 
                + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS + ' and ' + GlobalConstants.ACTION_PLAN_NEW_STATUS);
        }
        
        if(!String.isBlank(actionPlan.AssignedSME__c)) {
            actionPlan.OwnerId = actionPlan.AssignedSME__c;
            actionPlan.TempAssignedSME__c = actionPlan.AssignedSME__c;
            actionPlan.AssignedSME__c = null;
        }
        
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;        
        update actionPlan;
    }
    
    public class InvalidDataException extends Exception {}
}