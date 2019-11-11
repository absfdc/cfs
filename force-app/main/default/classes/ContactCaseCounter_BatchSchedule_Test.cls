@isTest
private class ContactCaseCounter_BatchSchedule_Test {

    private static List<Contact> contactRecords;
    private static List<Case> cases;
    
    private static testMethod void testForBatchRun() {
        setUpTestData();
        
        System.Test.startTest();        
        ContactCaseCounter_BatchSchedule scheduler = new ContactCaseCounter_BatchSchedule();
        scheduler.execute(null);
        System.Test.stopTest();
        
        List<Contact> contacts = [SELECT Id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                  FROM Contact];
        System.assert(!contacts.isEmpty());        
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 1);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 1);
    }
    
    private static void setUpTestData() {
        createCustomSettings();
        createContacts(100);
        cases = new List<Case>();
        createCfmCases(100);
        createMinCorrCases(100); 
        insert cases;       
    }
    
    private static void createCfmCases(Integer caseCount) { 
        List<RecordType> rt = [ SELECT Id, Name 
                                FROM RecordType 
                                WHERE sObjectType = 'Case' 
                                    AND Name IN ('Bus', 'Ferry', 'Train', 'Light Rail')];       
        for(Integer i = 0; i < caseCount; i++) {
            Case caseRecord = new Case();
            caseRecord.Description = 'Test case for creating action plan';
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Feedback';
            caseRecord.Taxonomy_Symptom__c = 'Difficult to Use';
            caseRecord.Taxonomy_Location__c = '140';
            caseRecord.Taxonomy_Area__c = 'Willoughby';
            caseRecord.Taxonomy_Location_Type__c = 'Sydney Buses';
            caseRecord.Taxonomy_Transaction__c = 'Agency Website';
            caseRecord.Taxonomy_Moment__c = 'Planning the Trip';
            caseRecord.Modes__c = 'Bus';
            caseRecord.contactId = contactRecords[i].Id;
            if(!rt.isEmpty()) {
                caseRecord.recordTypeId = rt[0].Id;
            }
            cases.add(caseRecord);
        }
    }
    
    private static void createMinCorrCases(Integer caseCount) { 
        String minCorrRecordTypeName = '%' + GlobalConstants.MIN_CORR_RECORDTYPE_NAME  + '%';
        List<RecordType> rt = [ SELECT Id, Name 
                                FROM RecordType 
                                WHERE sObjectType = 'Case' 
                                    AND Name LIKE :minCorrRecordTypeName ];
        for(Integer i = 0; i < caseCount; i++) {
            Case caseRecord = new Case();
            caseRecord.Description = 'Test case for creating action plan';
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Feedback';
            caseRecord.Taxonomy_Symptom__c = 'Difficult to Use';
            caseRecord.Taxonomy_Location__c = '140';
            caseRecord.Taxonomy_Area__c = 'Willoughby';
            caseRecord.Taxonomy_Location_Type__c = 'Sydney Buses';
            caseRecord.Taxonomy_Transaction__c = 'Agency Website';
            caseRecord.Taxonomy_Moment__c = 'Planning the Trip';
            caseRecord.Modes__c = 'Bus';
            caseRecord.contactId = contactRecords[i].Id;
            if(!rt.isEmpty()) {
                caseRecord.recordTypeId = rt[0].Id;
            }
            cases.add(caseRecord);
        }
    }
    
    private static void createContacts(Integer contactCount) {
        contactRecords = new List<Contact>();
        for(Integer i = 0; i < contactCount; i++) {
            Contact contactRecord = new Contact();
            contactRecord.FirstName = 'Test' + i;
            contactRecord.LastName = 'Contact' + i;
            contactRecord.Email = 'test.contact@nsw.gov.au' + i;
            contactRecord.Phone = '123123123' + i;
            
            contactRecords.add(contactRecord);
        }        
        Database.DMLOptions dmlOption = new Database.DMLOptions(); 
        dmlOption.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> result = Database.insert(contactRecords, dmlOption);
    }
    
    private static void createCustomSettings() {
        List<CFMCaseRecordType__c> settings = new List<CFMCaseRecordType__c>();
        settings.add(new CFMCaseRecordType__c(Name = 'Bus'));
        settings.add(new CFMCaseRecordType__c(Name = 'Light Rail'));
        settings.add(new CFMCaseRecordType__c(Name = 'Ferry'));
        settings.add(new CFMCaseRecordType__c(Name = 'Train'));
        settings.add(new CFMCaseRecordType__c(Name = 'Maritime'));
        
        insert settings;  
        
        List<CaseRecordTypesToExcludeFromRtFlip__c> rtToExclude = new List<CaseRecordTypesToExcludeFromRtFlip__c>();
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'General Ministerial Correspondence', Record_Type_Name__c = 'General Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Roads & Freight Ministerial Cor', Record_Type_Name__c = 'Roads & Freight Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Transport Ministerial Correspondence', Record_Type_Name__c = 'Transport Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign', Record_Type_Name__c = 'Campaign'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign Member', Record_Type_Name__c = 'Campaign Member'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Erroneous Cases MinCorr', Record_Type_Name__c = 'Erroneous Cases Ministerial Correspondence'));
        insert rtToExclude;      
    }    
}