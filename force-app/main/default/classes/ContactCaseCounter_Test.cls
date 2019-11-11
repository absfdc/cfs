@isTest
private class ContactCaseCounter_Test {

    private static Contact contactRecord;
    private static List<Case> cases;
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            ContactCaseCounter caseCounter = new ContactCaseCounter(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>());
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForSingleCfmCaseInsert() {
        setUpTestData(true, false, 1);
        cases[0].contactId = contactRecord.Id;
        insert cases;
        
        System.Test.startTest();
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 1);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 0);
    }
    
    private static testMethod void testForCaseInsertWithoutContact() {
        setUpTestData(true, false, 1);
        insert cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 0);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 0);
    }
    
    private static testMethod void testForCaseDelete() {
        setUpTestData(true, true, 1);
        for(Case caseRecord: cases) {
            caseRecord.contactId = contactRecord.Id;
        }        
        insert cases;
        delete cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 0 );
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 0 );
    }
    
    private static testMethod void testForCaseInsertWithParentCase() {
        setUpTestData(true, true, 1);
        Case parentCase = createParentCase();
        for(Case caseRecord: cases) {
            caseRecord.contactId = contactRecord.Id;
            caseRecord.parentId = parentCase.Id;
        }
        insert cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 0);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 0);
    }
    
    private static testMethod void testForCaseUpdateWithParentCase() {
        setUpTestData(true, true, 1);
        insert cases;
        Case parentCase = createParentCase();
        for(Case caseRecord: cases) {
            caseRecord.contactId = contactRecord.Id;
            caseRecord.parentId = parentCase.Id;
        }
        update cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 0);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 0);
    }
    
    private static testMethod void testForSingleMinCorrCaseInsert() {
        setUpTestData(false, true, 1);
        cases[0].contactId = contactRecord.Id;
        insert cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 0);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 1);
    }
    
    private static testMethod void testForMultipleCasesInsert() {
        setUpTestData(true, true, 1);
        for(Case caseRecord: cases) {
            caseRecord.contactId = contactRecord.Id;
        }
        insert cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 1);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 1);
    }
    
    private static testMethod void testForCaseUndelete() {
        setUpTestData(true, true, 1);
        for(Case caseRecord: cases) {
            caseRecord.contactId = contactRecord.Id;
        }        
        insert cases;        
        delete cases;
        undelete cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 1);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 1);
    }
    private static testMethod void testForCaseUpdate() {
        setUpTestData(true, true, 1);                
        insert cases;        
        for(Case caseRecord: cases) {
            caseRecord.contactId = contactRecord.Id;
        }
        update cases;
        
        System.Test.startTest();        
        ContactCaseCounter caseCounter = new ContactCaseCounter(new List<Id>{contactRecord.Id});
        caseCounter.countCases();
        System.Test.stopTest();
        
        List<Contact> contacts = [  SELECT id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c 
                                    FROM Contact 
                                    WHERE id = :contactRecord.Id];
        System.debug('Contact details: ' + contacts);
        System.assert(!contacts.isEmpty());
        System.assert(contacts[0].No_CFM_cases_12_mth_rolling__c == 1);
        System.assert(contacts[0].No_MinCorro_cases_12_mth_rolling__c == 1);
    }
       
    private static Case createParentCase() {
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
        insert caseRecord;
        
        return caseRecord;
    }    
    private static void setUpTestData(Boolean createCfm, Boolean createMinCorr, Integer caseCount) {
        createCustomSettings();
        cases = new List<Case>();
        if(createCfm) {
            createCfmCases(caseCount);
        }
        if(createMinCorr) {
            createMinCorrCases(caseCount);
        }
        createContact();
    }
    
    private static void createCfmCases(Integer caseCount) { 
        List<RecordType> rt = [ SELECT Id, Name 
                                FROM RecordType 
                                WHERE sObjectType = 'Case' 
                                    AND Name IN ('Bus')];       
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
            if(!rt.isEmpty()) {
                caseRecord.recordTypeId = rt[0].Id;
            }
            cases.add(caseRecord);
        }
    }
    
    private static void createMinCorrCases(Integer caseCount) { 
        String minCorrRecordTypeName = '%' + GlobalConstants.MIN_CORR_RECORDTYPE_NAME  + '%';
        List<RecordType> rt = [SELECT Id, Name 
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
            if(!rt.isEmpty()) {
                caseRecord.recordTypeId = rt[0].Id;
                System.debug('MinCorr Record type set as: ' + rt[0].Id + ' ' + rt[0].Name);
            }
            cases.add(caseRecord);
        }
    }
    
    private static void createContact() {
        contactRecord = new Contact();
        contactRecord.FirstName = 'Test';
        contactRecord.LastName = 'Contact';
        contactRecord.Email = 'test.contact@nsw.gov.au';
        contactRecord.Phone = '123123123';
        
        insert contactRecord;
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
    
    
    private static User createSercoUser() {
        Profile profileRecord = [Select Name, Id From Profile WHERE Name = 'Serco Agent'];
        
        User userRecord = new User();
        userRecord.userName = 'stduser@nsw.gov.au';
        userRecord.LastName = 'User';
        userRecord.FirstName = 'Test';
        userRecord.email = 'stduser@nsw.gov.au';
        userRecord.ProfileId = profileRecord.Id;
        userRecord.TimeZoneSidKey = 'GMT';
        userRecord.LocaleSidKey = 'en_US';
        userRecord.EmailEncodingKey = 'ISO-8859-1';
        userRecord.LanguageLocaleKey = 'en_US';
        userRecord.UserPermissionsMobileUser = false;
        userRecord.Alias = 'stdu';
        
        insert userRecord;
        return userRecord;
    } 
}