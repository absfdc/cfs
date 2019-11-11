@isTest
private class WebToCaseCreator_Test {
    
    private static Case caseRecord;
    private static String mode;
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }       
        System.Test.stopTest();
    }
    
    private static testMethod void testForRmsCaseWithSubCategorySelected() {
        mode = 'Road';
        setUpTestData();
        caseRecord.Taxonomy_Transaction__c = 'Road rules';
        caseRecord.Taxonomy_Symptom__c = 'Parking rules';
        System.Test.startTest();
        WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
        caseRecord = caseCreator.insertCase();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, Taxonomy_Transaction__c, Taxonomy_Symptom__c, Agency__c FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        System.assert(cases[0].Taxonomy_Transaction__c == 'Road rules');
        System.assert(cases[0].Taxonomy_Symptom__c == 'Parking rules');
        System.assert(cases[0].Agency__c == 'SNSW');
    }
    
    private static testMethod void testForRmsCaseWithSubCategoryNotSelected() {
        mode = 'Road';
        setUpTestData();
        caseRecord.Taxonomy_Transaction__c = 'Road rules';
        System.Test.startTest();
        WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
        caseRecord = caseCreator.insertCase();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, Taxonomy_Transaction__c, Taxonomy_Symptom__c, Agency__c FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        System.assert(cases[0].Taxonomy_Transaction__c == 'Road rules');
        System.assert(String.isBlank(cases[0].Taxonomy_Symptom__c));
        System.assert(String.isBlank(cases[0].Agency__c));
    }
    
    private static testMethod void testForRmsCaseWithoutCategory() {
        mode = 'Road';
        setUpTestData();
        caseRecord.Taxonomy_Transaction__c = '';
        System.Test.startTest();
        WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
        caseRecord = caseCreator.insertCase();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, Taxonomy_Transaction__c, Taxonomy_Symptom__c, Agency__c FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        System.assert(String.isBlank(cases[0].Taxonomy_Transaction__c));
        System.assert(String.isBlank(cases[0].Taxonomy_Symptom__c));
        System.assert(String.isBlank(cases[0].Agency__c));
    }
    
    private static testMethod void testForBusCaseWithoutCategory() {
        mode = 'Bus';
        setUpTestData();
        caseRecord.Taxonomy_Transaction__c = '';
        System.Test.startTest();
        WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
        caseRecord = caseCreator.insertCase();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, Taxonomy_Transaction__c, Taxonomy_Symptom__c, Agency__c FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        System.assert(String.isBlank(cases[0].Taxonomy_Transaction__c));
        System.assert(String.isBlank(cases[0].Taxonomy_Symptom__c));
        System.assert(String.isBlank(cases[0].Agency__c));
    }

    private static testMethod void testForSNSWCaseCreatedBySNSWTeam() {
        mode = 'Road';
        setUpTestData();
        caseRecord.Taxonomy_Transaction__c = 'Road rules';
        caseRecord.Taxonomy_Symptom__c = 'Parking rules';
        caseRecord.Created_By_Email__c = 'test' + GlobalConstants.SNSW_EMAIL_DOMAIN;
        System.Test.startTest();
        WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
        caseRecord = caseCreator.insertCase();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, Taxonomy_Transaction__c, Taxonomy_Symptom__c, Agency__c FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        System.assert(cases[0].Taxonomy_Transaction__c == 'Road rules');
        System.assert(cases[0].Taxonomy_Symptom__c == 'Parking rules');
        System.assert(cases[0].Agency__c == 'RMS');
    }
    
    private static void setUpTestData() {
        createCase();
        createTaxonomy();
    }
    
    private static void createCase() {
        caseRecord = new Case();
        caseRecord.Modes__c = mode;
        caseRecord.Taxonomy_Accountability__c = '';
        caseRecord.Taxonomy_Location__c = 'Sydney';
        caseRecord.Agency__c = '';
        caseRecord.Origin = 'Web';
        caseRecord.Priority = 'Normal';
        caseRecord.Type = 'Compliment';
        caseRecord.Description = 'Test case for web to case creation'; 
    }
    
    private static void createTaxonomy() {      
        Taxonomy_Metadata__c roadTaxonomy = new Taxonomy_Metadata__c();
        roadTaxonomy.Type__c = 'Mode';
        roadTaxonomy.Status_Customer_Facing__c = 'Active';
        roadTaxonomy.Status_Staff_Facing__c = 'Active';
        roadTaxonomy.Customer_Value__c = mode;
        roadTaxonomy.Name = mode;
        
        insert roadTaxonomy;
        
        List<Taxonomy_Metadata__c> level1Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c level1Loc = new Taxonomy_Metadata__c();
        level1Loc.Type__c = 'Location';
        level1Loc.Status_Customer_Facing__c = 'Active';
        level1Loc.Status_Staff_Facing__c = 'Active';
        level1Loc.Customer_Value__c = 'Region';
        level1Loc.Name = 'Region';
        level1Loc.Parent_Id__c = roadTaxonomy.Id;
        level1Taxonomies.add(level1Loc);
        
        Taxonomy_Metadata__c level1Issue = new Taxonomy_Metadata__c();
        level1Issue.Type__c = 'Issue';
        level1Issue.Status_Customer_Facing__c = 'Active';
        level1Issue.Status_Staff_Facing__c = 'Active';
        level1Issue.Customer_Value__c = 'Road';
        level1Issue.Name = 'Road';
        level1Issue.Parent_Id__c = roadTaxonomy.Id;
        level1Taxonomies.add(level1Issue);
        
        insert level1Taxonomies;
        
        List<Taxonomy_Metadata__c> level2Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c level2Loc = new Taxonomy_Metadata__c();
        level2Loc.Type__c = 'Location';
        level2Loc.Status_Customer_Facing__c = 'Active';
        level2Loc.Status_Staff_Facing__c = 'Active';
        level2Loc.Customer_Value__c = 'Sydney';
        level2Loc.Name = 'Sydney';
        level2Loc.Parent_Id__c = level1Loc.Id;
        level2Taxonomies.add(level2Loc);
        
        Taxonomy_Metadata__c level2Issue = new Taxonomy_Metadata__c();
        level2Issue.Type__c = 'Issue';
        level2Issue.Status_Customer_Facing__c = 'Active';
        level2Issue.Status_Staff_Facing__c = 'Active';
        level2Issue.Customer_Value__c = 'Road rules';
        level2Issue.Name = 'Road rules';
        level2Issue.Parent_Id__c = level1Issue.Id;
        level2Taxonomies.add(level2Issue);
        
        insert level2Taxonomies;
        
        List<Taxonomy_Metadata__c> level3Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c taxonomyLoc = new Taxonomy_Metadata__c();
        taxonomyLoc.Agency__c = '';
        taxonomyLoc.Customer_Value__c = 'Sydney';
        taxonomyLoc.Name = 'Sydney';
        taxonomyLoc.Issue_Accountability__c = 'Test Location Taxonomy';
        taxonomyLoc.Driver__c = '';
        taxonomyLoc.KPI__c = '';
        taxonomyLoc.Parent_Id__c = level2Loc.Id;
        taxonomyLoc.Status_Customer_Facing__c = 'Active';
        taxonomyLoc.Status_Staff_Facing__c = 'Active';
        taxonomyLoc.Type__c = 'Location'; 

        Taxonomy_Metadata__c taxonomyIssue = new Taxonomy_Metadata__c();
        taxonomyIssue.Agency__c = 'SNSW';
        taxonomyIssue.Customer_Value__c = 'Parking rules';
        taxonomyIssue.Name = 'Parking rules';
        taxonomyIssue.Issue_Accountability__c = 'Test Location Taxonomy';
        taxonomyIssue.Driver__c = '';
        taxonomyIssue.KPI__c = '';
        taxonomyIssue.Parent_Id__c = level2Issue.Id;
        taxonomyIssue.Status_Customer_Facing__c = 'Active';
        taxonomyIssue.Status_Staff_Facing__c = 'Active';
        taxonomyIssue.Type__c = 'Issue';        
        level3Taxonomies.add(taxonomyIssue);
        level3Taxonomies.add(taxonomyLoc);
        insert level3Taxonomies;
    }
}