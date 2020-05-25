@isTest
private class WebToCaseConcessionTest {
    
    private static Case caseRecord;
    
    private static testMethod void testForInitialisationOfAttachments() {
        setUpTestData();
        ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        System.Test.startTest();
        PageReference pageRef = Page.WebToCaseFormConcession;
        pageRef.getParameters().put('source', 'tfnsw');
        pageRef.getParameters().put('about', 'non-modal');
        pageRef.getHeaders().put('True-Client-IP','123.123.123.123');
        Test.setCurrentPage(pageRef);
        WebToCaseConcession_CX classInstance = new WebToCaseConcession_CX(controller);
        List<Attachment> attachments = classInstance.attachments ;
        System.Test.stopTest();
        System.assert(attachments != null);
        System.assert(!attachments.isEmpty());
    }
    
    private static testMethod void testForAllowedFileExtensions() {
        setUpTestData();
        ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        System.Test.startTest();
        PageReference pageRef = Page.WebToCaseFormConcession;
        pageRef.getParameters().put('source', 'tfnsw');
        pageRef.getParameters().put('about', 'non-modal');
        pageRef.getHeaders().put('True-Client-IP','123.123.123.123');
        Test.setCurrentPage(pageRef);
        WebToCaseConcession_CX classInstance = new WebToCaseConcession_CX(controller);
        String fileExtns = classInstance.getAllowedFileAttachments() ;
        classInstance.setAllowedFileAttachments('.docx');
        System.Test.stopTest();
        System.assert(fileExtns != null);       
    }
    
    private static testMethod void testForException() {
        setUpTestData();
        ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        System.Test.startTest();
        PageReference pageRef = Page.WebToCaseFormConcession;
        pageRef.getParameters().put('source', 'tfnsw');
        pageRef.getParameters().put('about', 'non-modal');
        pageRef.getHeaders().put('True-Client-IP','123.123.123.123');
        Test.setCurrentPage(pageRef);
        WebToCaseConcession_CX classInstance = new WebToCaseConcession_CX(controller);
        classInstance.caseRecord = null;
        PageReference pgRef = classInstance.createCase();
        System.Test.stopTest();
        System.assert(pgRef != null);       
    }
    
    private static testMethod void testForControllerInitialisation(){
        setUpTestData();
        ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        System.Test.startTest();
        PageReference pageRef = Page.WebToCaseFormConcession;
        pageRef.getParameters().put('source', 'tfnsw');
        pageRef.getParameters().put('about', 'non-modal');
        pageRef.getHeaders().put('X-Salesforce-SIP', '123.124.124.124');
        Test.setCurrentPage(pageRef);
        WebToCaseConcession_CX classInstance = new WebToCaseConcession_CX(controller);
        String errorMessage = classInstance.errorMessage;
        String sourceTfnsw = WebToCaseConcession_CX.sourceTfnsw;
        System.Test.stopTest();
        System.assert(classInstance.caseRecord != null);
        System.assert(classInstance.contactPerson != null);
        System.assert(classInstance.attachments != null);
        System.assert(sourceTfnsw == GlobalConstants.MODE_TFNSW);
    }
    
    private static testMethod void testForConcessionTaxonomy(){
        setUpTestData();
        ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        System.Test.startTest();
        PageReference pageRef = Page.WebToCaseFormConcession;
        pageRef.getParameters().put('source', 'tfnsw');
        pageRef.getParameters().put('about', 'non-modal');
        Test.setCurrentPage(pageRef);
        List<WebToCase_CX.CaseCategorization> taxonomy = WebToCaseConcession_CX.retrieveConcessionTaxonomy();
        System.Test.stopTest();
        System.assert(taxonomy != null );
        System.assert(taxonomy.size() == 1);        
    }
    
    private static testMethod void testForCaseCreation(){
        setUpTestData();
        ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        System.Test.startTest();
        PageReference pageRef = Page.WebToCaseFormConcession;
        pageRef.getParameters().put('source', 'tfnsw');
        pageRef.getParameters().put('about', 'non-modal');
        Test.setCurrentPage(pageRef);
        WebToCaseConcession_CX classInstance = new WebToCaseConcession_CX(controller);
        classInstance.caseRecord.Users_Ip_address__c = '124.123.124.124';
        classInstance.caseRecord.Type_of_Application__c = 'New Application';
        classInstance.caseRecord.Type = 'Enquiry';
        classInstance.contactPerson.LastName = 'User';
        classInstance.contactPerson.FirstName = 'Test';
        classInstance.contactPerson.MailingStreet = '477 Pitt Street';
        classInstance.contactPerson.MailingState = 'NSW';
        classInstance.contactPerson.MailingCity = 'Sydney';
        classInstance.contactPerson.MailingPostalCode = '2000';
        classInstance.contactPerson.MailingCountryCode = 'AU';
        classInstance.contactPerson.MailingCountry = 'Australia';
        
        PageReference pgRef = classInstance.createCase();
        System.Test.stopTest();
        System.assert(pgRef != null);
        System.assert(classInstance.caseRecord.Id != null);
        
    }
    
    
    private static testMethod void testForError(){
        setUpTestData();
        ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        System.Test.startTest();
        PageReference pageRef = Page.WebToCaseFormConcession;
        pageRef.getParameters().put('source', 'tfnsw');
        pageRef.getParameters().put('about', 'non-modal');
        Test.setCurrentPage(pageRef);
        WebToCaseConcession_CX classInstance = new WebToCaseConcession_CX(controller);
        classInstance.caseRecord.Users_Ip_address__c = null;
        
        PageReference pgRef = classInstance.createCase();
        System.Test.stopTest();
        System.assert(pgRef != null);
        System.assert(classInstance.caseRecord.Id == null);     
    }
    
    private static void setUpTestData() {
        createCase();
        createTaxonomy();
    }
    
    private static void createCase() {
        caseRecord = new Case();
        caseRecord.Modes__c = 'Non-modal';
        caseRecord.Taxonomy_Accountability__c = '';
        caseRecord.Taxonomy_Location__c = 'Sydney';
        caseRecord.Agency__c = '';
        caseRecord.Origin = 'Web';
        caseRecord.Priority = 'Normal';
        caseRecord.Type = 'Enquiry';
        caseRecord.Description = 'Test case for web to case creation'; 
    }
    
    private static void createTaxonomy() {      
        Taxonomy_Metadata__c nonModeTaxonomy = new Taxonomy_Metadata__c();
        nonModeTaxonomy.Type__c = 'Mode';
        nonModeTaxonomy.Status_Customer_Facing__c = 'Active';
        nonModeTaxonomy.Status_Staff_Facing__c = 'Active';
        nonModeTaxonomy.Customer_Value__c = 'Non-modal';
        nonModeTaxonomy.Name = 'Non-modal';
        
        insert nonModeTaxonomy;
        
        List<Taxonomy_Metadata__c> level1Taxonomies = new List<Taxonomy_Metadata__c>();
        
        Taxonomy_Metadata__c level1Issue = new Taxonomy_Metadata__c();
        level1Issue.Type__c = 'Issue';
        level1Issue.Status_Customer_Facing__c = 'Active';
        level1Issue.Status_Staff_Facing__c = 'Active';
        level1Issue.Customer_Value__c = 'Concessions and schemes';
        level1Issue.Name = 'Concessions and schemes';
        level1Issue.Parent_Id__c = nonModeTaxonomy.Id;
        level1Taxonomies.add(level1Issue);
        
        insert level1Taxonomies;
        
        List<Taxonomy_Metadata__c> level2Taxonomies = new List<Taxonomy_Metadata__c>();
        
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
        taxonomyIssue.Display_on_Concession_Form__c = true;
        taxonomyIssue.Type__c = 'Issue';        
        level3Taxonomies.add(taxonomyIssue);
        insert level3Taxonomies;
    }
}