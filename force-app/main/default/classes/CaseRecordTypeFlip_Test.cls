@isTest
private class CaseRecordTypeFlip_Test {

    private static List<Case> cases;
    private static String mode;
    private static Id recordTypeId;
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForBusRecordTypeFlip() {
        mode = 'Bus';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForRoadRecordTypeFlip() {
        mode = 'Road';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForFerryRecordTypeFlip() {
        mode = 'Ferry';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForLightRailRecordTypeFlip() {
        mode = 'Light Rail';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForMaritimeRecordTypeFlip() {
        mode = 'Maritime';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForMultiIssueRecordTypeFlip() {
        mode = 'Multi Issue';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForNonModalRecordTypeFlip() {
        mode = 'Non-modal';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :GlobalConstants.NON_MODAL_RECORD_TYPE_NAME];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForTrainRecordTypeFlip() {
        mode = 'Train';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }   
    
    private static testMethod void testForWalkingAndCyclingRecordTypeFlip() {
        mode = 'Walking & Cycling';
        setUpTestData(1);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static testMethod void testForBulkCases() {
        mode = 'Bus';
        setUpTestData(200);
        System.Test.startTest();
        CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip(cases);
        rtFlip.flipRecordTypes();
        System.Test.stopTest();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = :mode];
        System.assert(!rt.isEmpty());
        System.assert(cases[0].recordTypeId == rt[0].Id);
    }
    
    private static void setUpTestData(Integer caseCount) {
        createCustomSettings();
        retrieveRecordTypes();
        createCases(caseCount);
    }
    
    private static void createCases(Integer caseCount) {
        cases = new List<Case>();
        for(Integer i=0; i < caseCount; i++) {
            Case caseRecord = new Case();
            caseRecord.Modes__c = mode;
            caseRecord.Taxonomy_Accountability__c = '';
            caseRecord.Taxonomy_Location__c = 'Sydney';
            caseRecord.Agency__c = '';
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Compliment';
            caseRecord.Description = 'Test case for web to case creation';
            caseRecord.RecordTypeId = recordTypeId;
            
            cases.add(caseRecord);
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
    
    private static void retrieveRecordTypes() {
        Map<String, CaseRecordTypesToExcludeFromRtFlip__c> rtToExclude = CaseRecordTypesToExcludeFromRtFlip__c.getAll();
        Set<String> rtNamesToExclude = new Set<String>();
        for(CaseRecordTypesToExcludeFromRtFlip__c rtName: rtToExclude.values()) {
            rtNamesToExclude.add(rtName.Record_Type_Name__c);
        }
        if(mode == 'NonModal') {
            rtNamesToExclude.add('Non Mode');
        } else {
            rtNamesToExclude.add(mode);
        }
        List<RecordType> rt = [ SELECT Id, Name FROM RecordType WHERE sObjectType = 'Case' AND Name NOT IN :rtNamesToExclude];
        if(!rt.isEmpty()) {
            recordTypeId = rt[0].Id;
        }
    }
}