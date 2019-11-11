/**
*  Oct release: removed test medthod for 'Send for printing' 
*/
@isTest
private class ActionPlanStatusTransition_Test{

    private static Action_Plan__c actionPlan;
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try{
            ActionPlanStatusTransition.assign(null);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }

    private static testMethod void testForAssign() {
        setupTestData();
        System.Test.startTest();        
        try {
            String response = ActionPlanStatusTransition.assign(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForComplete() {
        setupTestData();
        System.Test.startTest();
        try {
            String response = ActionPlanStatusTransition.assign(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForInProgress() {
        setupTestData();
        System.Test.startTest();        
        try {
            String response = ActionPlanStatusTransition.inProgress(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForIncorrectAssignment() {
        setupTestData();
        System.Test.startTest();        
        try {
            String response = ActionPlanStatusTransition.rejectedIncorrectAssignment(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForTakeOwnership() {
        setupTestData();
        System.Test.startTest();        
        try {
            String response = ActionPlanStatusTransition.takeOwnership(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForApproved() {
        setupTestData();
        System.Test.startTest();        
        try {
            String response = ActionPlanStatusTransition.submitForReview(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForAmendment() {
        setupTestData();
        System.Test.startTest();
        try {
            String response = ActionPlanStatusTransition.amendment(actionPlan.Id);          
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();     
    }
    
    private static testMethod void testForAwaitingSig() {
        setupTestData();
        System.Test.startTest();        
        try {
            String response = ActionPlanStatusTransition.awaitingSignature(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForRework() {
        setupTestData();
        System.Test.startTest();        
        try {
            String response = ActionPlanStatusTransition.rework(actionPlan.Id);
        } catch(Exception e) {
            System.assert(false);
        }       
        System.Test.stopTest();
    }
    
    private static void setupTestData() {
        actionPlan = new Action_Plan__c();
        actionPlan.Agency__c = GlobalConstants.RMS_AGENCY;
        insert actionPlan;
    }
}