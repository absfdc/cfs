@isTest
private class TimeSpentInStatusCalculator_Test {

    private static List<Action_Plan__c> actionPlans;
    private static Map<Id, Action_Plan__c> oldActionPlanMap;

    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(null, null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForInvalidAPMap() {
        setupTestData(2);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForNewStatus() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_NEW_STATUS;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_New__c != null);
    }
    
    private static testMethod void testForRejectedIncorrectAssignment() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_Incorrect_Assignment__c  != null);
    }
    
    private static testMethod void testForAwaitingSignature() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_Awaiting_Signature__c  != null);
    }
    
    private static testMethod void testForReadyForPrinting() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_Ready_for_Printing__c  != null);
    }
    
    private static testMethod void testForInProgress() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_Action_Plan_in_Progress__c  != null);
    }
    
    private static testMethod void testForReadyForAssigned() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_Action_Plan_Assigned__c  != null);
    }
    
    private static testMethod void testForReadyForApproved() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_NEW_APPROVED;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_Action_Plan_in_Review__c  != null);
    }
    
    private static testMethod void testForWaitingApproval() {
        setupTestData(1);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_WAITING_APPROVAL;
        oldActionPlanMap.put(actionPlans[0].Id, actionPlans[0]);
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        System.assert(actionPlans[0].Time_spent_in_Awaiting_Approval__c  != null);
    }   
    
    private static testMethod void testForBulkOperation() {
        setupTestData(200);
        oldActionPlanMap = new Map<Id,Action_Plan__c>();
        actionPlans[0].Status__c = GlobalConstants.ACTION_PLAN_NEW_STATUS;
        for(Action_Plan__c ap : actionPlans) {
            ap.Status__c = GlobalConstants.ACTION_PLAN_NEW_STATUS;
            oldActionPlanMap.put(ap.Id, ap);
        }
        System.Test.startTest();
        try{
            TimeSpentInStatusCalculator calculator = new TimeSpentInStatusCalculator(actionPlans, oldActionPlanMap);
            calculator.stampTimeSpent();            
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        for(Action_Plan__c ap : actionPlans) {
            System.assert(ap.Time_spent_in_New__c != null);
        }
    }
    
    private static void setupTestData(Integer apCount) {
        actionPlans = new List<Action_Plan__c>();
        List<BusinessHours> businessHrs = [SELECT b.Name, b.Id FROM BusinessHours b WHERE b.IsActive = true];
        
        for(Integer index = 0; index < apCount; index++) {
            Action_Plan__c apRecord = new Action_Plan__c();
            if(!businessHrs.isEmpty()) {
                apRecord.BusinessHours__c = businessHrs[0].Id;
            }            
            apRecord.Agency__c = GlobalConstants.RMS_AGENCY;
            actionPlans.add(apRecord);
        }
        
        insert actionPlans;
        
        actionPlans = [ SELECT Id, Status__c, BusinessHours__c, CreatedDate, Date_stamp_on_Incorrect_Assignment__c, Date_stamp_on_Awaiting_Signature__c, 
                            Date_stamp_on_Ready_for_Printing__c, Date_stamp_on_Action_Plan_in_Progress__c, Date_stamp_on_Action_Plan_Assigned__c, 
                            Date_stamp_on_Action_Plan_in_Review__c, Date_stamp_on_Awaiting_Approval__c
                        FROM Action_Plan__c
                        WHERE Id IN :actionPlans];
        for(Action_Plan__c ap : actionPlans) {
            ap.Date_stamp_on_Incorrect_Assignment__c = System.now();
            ap.Date_stamp_on_Awaiting_Signature__c = System.now();
            ap.Date_stamp_on_Ready_for_Printing__c = System.now();
            ap.Date_stamp_on_Action_Plan_in_Progress__c = System.now();
            ap.Date_stamp_on_Action_Plan_Assigned__c = System.now();
            ap.Date_stamp_on_Action_Plan_in_Review__c = System.now();
            ap.Date_stamp_on_Awaiting_Approval__c = System.today();         
        }
    }

}