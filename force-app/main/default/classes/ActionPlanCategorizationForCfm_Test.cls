@isTest
private class ActionPlanCategorizationForCfm_Test {

    private static List<Action_Plan__c> actionPlans;
    private static Map<Id,Case> caseDetails;
    private static Id caseRecordTypeId;
    private static final String ISSUE_LEVEL_1 = 'Planning the Trip';
    private static final String ISSUE_LEVEL_2 = 'Website';
    private static final String ISSUE_LEVEL_3 = 'Sydney Buses';
    private static final String LOCATION_LEVEL_1 = 'Kennedys';
    private static final String LOCATION_LEVEL_2 = 'South Nowra';
    private static final String LOCATION_LEVEL_3 = '728';
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            ActionPlanCategorizationForCfm categorizationSelector = new ActionPlanCategorizationForCfm (actionPlans, caseDetails);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            ActionPlanCategorizationForCfm categorizationSelector = new ActionPlanCategorizationForCfm (new List<Action_Plan__c>(), new Map<Id,Case>());
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
        
    }
    
    private static testMethod void testForActionPlanOnMinCorrCases() {
        setUpTestData(5, false);
        System.Test.startTest();
        ActionPlanCategorizationForCfm categorizationSelector = new ActionPlanCategorizationForCfm (actionPlans, caseDetails);
        categorizationSelector.populateCategorizationDetails();     
        System.Test.stopTest();
        for(Action_Plan__c ap : actionPlans) {
            System.assert(ap.Issue_Level_1__c == null);
            System.assert(ap.Issue_Level_2__c == null);
            System.assert(ap.Issue_Level_3__c == null);
            System.assert(ap.Location_Level_1__c == null);
            System.assert(ap.Location_Level_2__c == null);
            System.assert(ap.Location_Level_3__c == null);
        }
    }
    
    private static testMethod void testForActionPlanOnCfmCases() {
        setUpTestData(1, true);
        System.Test.startTest();
        ActionPlanCategorizationForCfm categorizationSelector = new ActionPlanCategorizationForCfm (actionPlans, caseDetails);
        categorizationSelector.populateCategorizationDetails();     
        System.Test.stopTest();
        for(Action_Plan__c ap : actionPlans) {
            System.assert(ap.Issue_Level_1__c == ISSUE_LEVEL_1);
            System.assert(ap.Issue_Level_2__c == ISSUE_LEVEL_2);
            System.assert(ap.Issue_Level_3__c == ISSUE_LEVEL_3);
            System.assert(ap.Location_Level_1__c == LOCATION_LEVEL_1);
            System.assert(ap.Location_Level_2__c == LOCATION_LEVEL_2);
            System.assert(ap.Location_Level_3__c == LOCATION_LEVEL_3);
        }
    }
    
    private static testMethod void testForBulkActionPlanOnCfmCases() {
        setUpTestData(5, true);
        System.Test.startTest();
        ActionPlanCategorizationForCfm categorizationSelector = new ActionPlanCategorizationForCfm (actionPlans, caseDetails);
        categorizationSelector.populateCategorizationDetails();     
        System.Test.stopTest();
        for(Action_Plan__c ap : actionPlans) {
            System.assert(ap.Issue_Level_1__c == ISSUE_LEVEL_1);
            System.assert(ap.Issue_Level_2__c == ISSUE_LEVEL_2);
            System.assert(ap.Issue_Level_3__c == ISSUE_LEVEL_3);
            System.assert(ap.Location_Level_1__c == LOCATION_LEVEL_1);
            System.assert(ap.Location_Level_2__c == LOCATION_LEVEL_2);
            System.assert(ap.Location_Level_3__c == LOCATION_LEVEL_3);
        }
    }
    
    private static void setUpTestData(Integer caseCount, Boolean isCfm) {
        createCustomSettings();
        createCases(caseCount, isCfm);
        createActionPlans(caseCount);
    }
    
    private static void createCases(Integer caseCount, Boolean isCfm) {
        List<Case> cases = new List<Case>();
        List<RecordType> rt;
        if(isCfm) {
            rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND Id NOT IN :CaseTriggerDispatcher.recordTypesMinCorro];
        } else {
            rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND Id IN :CaseTriggerDispatcher.recordTypesMinCorro];           
        }
        if(!rt.isEmpty()) {             
            caseRecordTypeId = rt[0].Id;
        }
        for(Integer index=0; index < caseCount; index++) {
            Case caseRecord = new Case();
            caseRecord.RecordTypeId = caseRecordTypeId;
            caseRecord.Modes__c = 'Bus';
            caseRecord.Taxonomy_Moment__c = ISSUE_LEVEL_1;
            caseRecord.Taxonomy_Transaction__c = ISSUE_LEVEL_2;
            caseRecord.Taxonomy_Symptom__c = ISSUE_LEVEL_3;
            caseRecord.Taxonomy_Location_Type__c = LOCATION_LEVEL_1;
            caseRecord.Taxonomy_Area__c = LOCATION_LEVEL_2;
            caseRecord.Taxonomy_Location__c = LOCATION_LEVEL_3;
            caseRecord.Description = 'Test case for action plan';
            cases.add(caseRecord);
        }
        insert cases;
        caseDetails = new Map<Id,Case>();
        for(Case caseRecord: [  SELECT Id, Taxonomy_Moment__c,Taxonomy_Transaction__c, Taxonomy_Symptom_Id__c, Taxonomy_Location_Id__c, Agency__c,
                                    Taxonomy_Location_Type__c, Taxonomy_Symptom__c, Taxonomy_Location__c, Taxonomy_Area__c, Modes__c, IsMinCorroCase__c
                                FROM Case
                                WHERE Id IN :cases]) {
            caseDetails.put(caseRecord.Id, caseRecord);
        }
    }
    
    private static void createActionPlans(Integer apCount) {
        actionPlans = new List<Action_Plan__c>();
        List<Case> cases = caseDetails.values();
        for(Integer index=0; index < apCount; index++) {
            Action_Plan__c ap = new Action_Plan__c();
            ap.Parent_Case__c = cases[index].Id;
            actionPlans.add(ap);
        }
    }
    
    private static void createCustomSettings() {
        List<CaseRecordTypesToExcludeFromRtFlip__c> rtToExclude = new List<CaseRecordTypesToExcludeFromRtFlip__c>();
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'General Ministerial Correspondence', Record_Type_Name__c = 'General Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Roads & Freight Ministerial Cor', Record_Type_Name__c = 'Roads & Freight Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Transport Ministerial Correspondence', Record_Type_Name__c = 'Transport Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign', Record_Type_Name__c = 'Campaign'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign Member', Record_Type_Name__c = 'Campaign Member'));
        insert rtToExclude;
    }
}