@isTest
private class ActionPlanStatusUpdater_Test {
    
    @testSetup static void setupData() {
        Group g1 = new Group(Name='CRGS Admins', type='Queue');
        insert g1;
        
        System.runAs(new User(Id=UserInfo.getUserId())){
            QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
            insert q1;
        }

        Id validRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RECORD_TYPE_MINCORRGENERAL).getRecordTypeId();

        Case newCase = new Case();
        newCase.recordtypeId = validRecordType;
        newCase.ownerId = g1.Id; 
        insert newcase;

        system.assertEquals(newCase.ownerId,g1.Id);
        system.assertEquals(newCase.recordtypeId,validRecordType);

        Action_plan__c ap = new Action_plan__c(Parent_case__c = newCase.Id);
        insert ap;
    }

    //Sunny day scenario
    @isTest static void closeRelatedActionPlanTest() {
        // Implement test code
        List<Case> caseList = [select Id,Response_Type__c,recordtypeId from Case];
        Test.startTest();
        for(Case c : caseList){
            c.Response_Type__c = GlobalConstants.CASE_NRR_RESPONSE_TYPE;
        }
        
        update caseList;

        Action_plan__c ap = [select Id,Status__c from Action_plan__c limit 1];
        System.assert(ap!=NULL);
        System.debug('Action Plan Status ....'+ap.Status__c);
        System.assert(ap.Status__c == GlobalConstants.ACTION_PLAN_CLOSED_STATUS);
        Test.stopTest();
    }
    
    //No Record found
    @isTest static void noRecordForUpdateTest() {
        // Implement test code
        List<Case> oldCases = [select Id,recordtypeId,Response_Type__c from case];
        Map<Id,Case> oldMap = new Map<Id,Case>([select Id,recordtypeId,Response_Type__c from case]);
        
        List<Case> newCases = new List<Case>(oldCases);
        Map<Id,case> newMap = new Map<Id,case>(oldMap);

        TriggerParameters tp = new TriggerParameters(oldCases, newCases, oldMap, newMap, false, true, false, false, true, false, false);

        ActionPlanStatusUpdater apsu = new ActionPlanStatusUpdater();
        System.assert(!apsu.closeRelatedActionPlan(tp));
    }

    @isTest static void directCloseRelatedActionPlanTest() {
        // Implement test code
        List<Case> oldCases = new List<Case>();
        Map<Id,Case> oldMap = new Map<Id,case>();

        Test.startTest();
        List<Case> newCases = [select Id,recordtypeId,Response_Type__c from case];
        Map<Id,case> newMap = new Map<Id,Case>([select Id,recordtypeId,Response_Type__c from case]);
        for(case c : newCases){
            Case oldCase = new case();
            oldCase.id = c.Id;
            oldCase.recordtypeId = c.recordtypeId; 
            oldCase.Response_Type__c = '';
            c.Response_Type__c=  GlobalConstants.CASE_NRR_RESPONSE_TYPE;
            c.NRR_Notes__c = 'Sample Notes';
            oldCases.add(oldCase);
            oldMap.put(oldCase.Id,oldCase);
        }

        System.runAs(new User(Id=UserInfo.getUserId())){
            update newCases;
        }
        
        newMap = new Map<Id,Case>([select Id,recordtypeId,Response_Type__c from case]);
        
        System.debug('oldCases.get(0).Response_Type__c ....'+oldCases.get(0).Response_Type__c );
        System.debug('newCases.get(0).Response_Type__c ....'+newCases.get(0).Response_Type__c );

        TriggerParameters tp = new TriggerParameters(oldCases, newCases, oldMap, newMap, false, true, false, false, true, false, false);

        ActionPlanStatusUpdater apsu = new ActionPlanStatusUpdater();
        System.assert(apsu.closeRelatedActionPlan(tp));
        Test.stopTest();
    }

     //Log Exception
    @isTest static void logExceptionTest() {
        ActionPlanStatusUpdater apsu = new ActionPlanStatusUpdater();
        apsu.closeRelatedActionPlan(NULL);
        
        list <Application_Log__c> logs = [Select Id From Application_Log__c];
        system.assert(logs != null);
    }
}