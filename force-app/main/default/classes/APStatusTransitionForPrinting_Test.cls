@isTest
private class APStatusTransitionForPrinting_Test {

    private static Action_Plan__c actionPlan;
    
    private static void setUpTestData() {
        actionPlan = new Action_Plan__c();
        actionPlan.Type__c = GlobalConstants.AP_TYPE_AGENCY_RESPONSE;
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
        actionPlan.Agency__c = GlobalConstants.RMS_AGENCY;
        actionPlan.RecordTypeId = retrieveAgencyResponseRT();
        actionPlan.Print_Location_Region__c = 'Sydney Region';
        actionPlan.Printing_Location__c = 'North Sydney (Miller Street)';
        insert actionPlan;
    }
    
    private static Id retrieveAgencyResponseRT() {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Action_Plan__c' AND DeveloperName = 'RMS_Action_Plan'];
        return rts.isEmpty()? null : rts[0].Id;
    }
    
    private static Id retrieveChildActionPlanRT() {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Action_Plan__c' AND DeveloperName = 'MCWS_Child_Action_Plan'];
        return rts.isEmpty()? null : rts[0].Id;
    }
    
    private static testMethod void testForEmptyPrintLocation() {
        setUpTestData();
        actionPlan.Printing_Location__c = null;
        update actionPlan;
        System.Test.startTest();
        try {           
            APStatusTransitionForPrinting printingInstance = new APStatusTransitionForPrinting(actionPlan.Id);
            printingInstance.performTransition();
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForInvalidData() {
        actionPlan = new Action_Plan__c();
        System.Test.startTest();
        try {           
            APStatusTransitionForPrinting printingInstance = new APStatusTransitionForPrinting(actionPlan.Id);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForActionPlanOfAdviceRequest() {
        setUpTestData();
        actionPlan.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        update actionPlan;
        System.Test.startTest();
        try {           
            APStatusTransitionForPrinting printingInstance = new APStatusTransitionForPrinting(actionPlan.Id);
            printingInstance.performTransition();
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForActionPlanOfAgencyResponse() {
        setUpTestData();
        
        System.Test.startTest();
        try {           
            APStatusTransitionForPrinting printingInstance = new APStatusTransitionForPrinting(actionPlan.Id);
            printingInstance.performTransition();           
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        Action_Plan__c ap = [SELECT Id, Status__c  FROM Action_Plan__c WHERE Id = :actionPlan.Id];
        System.assert(GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT == ap.Status__c);
    }
        
    private static testMethod void testForParentActionPlanInvalidData() {
        setUpTestData();
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG;
        update actionPlan;
        System.Test.startTest();
        try {           
            APStatusTransitionForPrinting printingInstance = new APStatusTransitionForPrinting(actionPlan.Id);
            printingInstance.performTransition();   
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForChildActionPlan() {
        setUpTestData();
        Id childActionPlanId = createChildActionPlan();
        System.Test.startTest();
        try {           
            APStatusTransitionForPrinting printingInstance = new APStatusTransitionForPrinting(childActionPlanId);
            printingInstance.performTransition();   
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        Action_Plan__c child = [SELECT Id, Status__c FROM Action_Plan__c WHERE Id = :childActionPlanId];
        System.assert(child.Status__c == GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG);
    }
    
    private static Id createChildActionPlan() {
        Action_Plan__c child = new Action_Plan__c();
        child.Type__c = GlobalConstants.AP_TYPE_AGENCY_RESPONSE;
        child.Status__c = GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG;
        child.Agency__c = GlobalConstants.RMS_AGENCY;
        child.recordTypeId = retrieveChildActionPlanRT();
        child.Parent_Action_Plan__c = actionPlan.Id;
        insert child;
        return child.Id;
    }
}