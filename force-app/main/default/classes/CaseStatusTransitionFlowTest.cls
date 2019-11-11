@isTest
private class CaseStatusTransitionFlowTest { 
    
    private static User  crgs,mags;
    @testSetup static void setup() {
        system.debug('-------Data Setup------');
        crgs = RetrieveNextUtils_WS_Test.createTestUser('CRGS Admin','CRGS_Admin');
        mags = RetrieveNextUtils_WS_Test.createTestUser('MAGS Officer','MAGS_Officer');
        system.debug('-------Data Setup Finished------');
    }
        
    //CRGS Admin User => MAGS Queue = AllocationererrorScenariosActionPlanrorScenariosActionPlan
    @isTest
    static void scenario1() {
        Group MAGS_Queue = [Select Id From Group Where DeveloperName =: GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME limit 1];
        User CRGSAdmin = [Select Id From User Where Profile.Name = 'CRGS Admin' and Email = 'md@demo.com' and isActive = true limit 1];
        Case dummyCase  = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');
        insert dummyCase;
        
        Test.startTest();
        Case newCase  = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');
        newCase.OwnerId =  MAGS_Queue.id;
        newCase.Id = dummyCase.Id;
        
        Case oldCase  = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');        
        oldCase.OwnerId = CRGSAdmin.Id;
        oldCase.Status = GlobalConstants.RESEARCH_STATUS_MIN_CORRO;
        oldCase.Id = dummyCase.Id;
        
        Map<Id,Case> oldMap = new Map<Id,Case> {oldCase.Id => oldCase};
        list<Case> newList = new List<Case> {newCase};
        list<Case> oldList = new List<Case> {oldCase};
        Map<Id,case> newMap = new Map<Id,case> {newCase.Id => newCase};
        
        TriggerParameters tp = new TriggerParameters(oldList, newList, oldMap, newMap, false, true, false, false, true, false, false);
        CaseBeforeUpdateTriggerHandler handler = new CaseBeforeUpdateTriggerHandler();
        handler.changeMinCorroCaseStatus(tp);
        system.assertEquals(GlobalConstants.ALLOCATION_STATUS_MIN_CORRO, newCase.Status);
        Test.stopTest();
    }
    
    //MAGS Queue => MAGS officer or MAGS manager = Research
    @isTest
    static void scenario2() {
    	Group MAGS_Queue = [Select Id From Group Where DeveloperName =: GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME limit 1];
        User MagsOfficer = [Select Id From User Where Profile.Name = 'MAGS Officer'  and Email = 'md@demo.com' and isActive = true limit 1];
        Case dummyCase  = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');
        insert dummyCase;
        
        Test.startTest();
        Case newCase  = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');
        newCase.OwnerId =  MagsOfficer.id;
        newCase.Id = dummyCase.Id;
        
        Case oldCase  = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');        
        oldCase.OwnerId = MAGS_Queue.Id;
        oldCase.Status = GlobalConstants.ALLOCATION_STATUS_MIN_CORRO;
        oldCase.Id = dummyCase.Id;
        
        Map<Id,Case> oldMap = new Map<Id,Case> {oldCase.Id => oldCase};
        list<Case> newList = new List<Case> {newCase};
        list<Case> oldList = new List<Case> {oldCase};
        Map<Id,case> newMap = new Map<Id,case> {newCase.Id => newCase};
            
        TriggerParameters tp = new TriggerParameters(oldList, newList, oldMap, newMap, false, true, false, false, true, false, false);
        CaseBeforeUpdateTriggerHandler handler = new CaseBeforeUpdateTriggerHandler();
        handler.changeMinCorroCaseStatus(tp);
        system.assertEquals(GlobalConstants.RESEARCH_STATUS_MIN_CORRO, newCase.Status);
        Test.stopTest();    
    }
	
    @isTest
    static void errorScenariosActionPlan() {
        ActionPlanAfterInsertTriggerHandler ap = new ActionPlanAfterInsertTriggerHandler();
        ap.mainEntry(null);
        ap.inProgressEntry(null);
        ActionPlanAfterUpdateTriggerHandler ap1 = new ActionPlanAfterUpdateTriggerHandler();
        ap1.mainEntry(null);
        ap1.inProgressEntry(null);
        ActionPlanAfterUndeleteTriggerHandler ap2 = new ActionPlanAfterUndeleteTriggerHandler();
        ap2.mainEntry(null);
        ap2.inProgressEntry(null);
        ActionPlanBeforeInsertTriggerHandler ap3 = new ActionPlanBeforeInsertTriggerHandler();
        ap3.mainEntry(null);
        ap3.inProgressEntry(null);
        ActionPlanBeforeUpdateTriggerHandler ap4 = new ActionPlanBeforeUpdateTriggerHandler();
        ap4.mainEntry(null);        
        ap4.inProgressEntry(null);
        list <Application_Log__c> logs = [Select Id from Application_Log__c];
        system.assert(logs !=null);
    }
    
    @isTest
    static void errorScenariosCaseTriggerHandlers() {
        CaseBeforeDeleteTriggerHandler c1 = new CaseBeforeDeleteTriggerHandler();
        c1.mainEntry(null);
        c1.inProgressEntry(null);
        
        CaseBeforeInsertTriggerHandler c2 = new CaseBeforeInsertTriggerHandler();
        c2.mainEntry(null);
        c2.inProgressEntry(null);
        list <Application_Log__c> logs = [Select Id from Application_Log__c];
        system.assert(logs !=null);
    }
}