public without sharing class APStatusTransitionForPrinting extends AbstractAPStatusTransition {
    public APStatusTransitionForPrinting(Id actionPlanId) {
        try {
            validateActionPlan(actionPlanId);
        } catch(Exception e) {
            throw new InvalidDataException('Failed to send action plan for printing. Action plan details missing');
        }        
    }
    
    public override void performTransition() {
        if(!GlobalConstants.AP_TYPE_AGENCY_RESPONSE.equalsIgnoreCase(actionPlan.Type__c)) {
            throw new InvalidDataException('Failed to send action plan for printing. Action plan type is other than ' 
                + GlobalConstants.AP_TYPE_AGENCY_RESPONSE );
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
        if(!GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(actionPlan.status__c)
                && !GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(actionPlan.status__c)) {
            throw new InvalidDataException('Failed to send action plan for printing. Current status of action plan is other than ' 
                + GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS + ' and ' + GlobalConstants.ACTION_PLAN_NEW_APPROVED);
        }
        
        if(String.isBlank(actionPlan.Printing_Location__c)) {
            throw new InvalidDataException('Failed to send action plan for printing. Printing location details missing on action plan.');
        }
        List<Group> groups = [  SELECT Id, Name 
                                FROM Group 
                                Where DeveloperName = :Label.For_Printing_Queue 
                                    AND Type = 'Queue' LIMIT 1];
        
        if(groups.isEmpty()) {
            throw new InvalidDataException('Failed to send action plan for printing. Printing queue details is not available.');
        }
        actionPlan.OwnerId = groups[0].Id;
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT;
        
        update actionPlan;
    }
        
    private void processAgencyResponseChildActionPlan() { 
        
    }
    
    public class InvalidDataException extends Exception {}
}