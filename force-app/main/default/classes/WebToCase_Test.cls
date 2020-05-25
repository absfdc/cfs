@isTest
private class WebToCase_Test {

    private static String mode;
    private static String category;
    private static String subcategory;
    private static Case caseRecord;
    private static String ipAddress;
    
    private static testMethod void testForCaseCreationWithInvalidIp() {
        mode = 'Road';
        category = 'Road rules';
        subcategory = 'Parking rules';
        setUpTestData();
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getHeaders().put('True-Client-IP', '');
        ApexPages.currentPage().getHeaders().put('X-Salesforce-SIP', ''); 
        ApexPages.currentPage().getParameters().put('source','tfnsw');
        ApexPages.currentPage().getParameters().put('refsite','sit.transport.com');
        ApexPages.currentPage().getParameters().put('about','Road');
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseRecord);
        WebToCase_CX controller = new WebToCase_CX(stdController);
        PageReference pgRef = controller.createCase();
        System.assert(pgRef != null);  
        System.assert(pgRef.getUrl().contains('webtocaseerrorpage'));
        System.Test.stopTest();
    }
    
    private static testMethod void testForSpamCaseCreation() {
        mode = 'Road';
        category = 'Road rules';
        subcategory = 'Parking rules';
        ipAddress = '192.23.165.56';
        setUpTestData();
        createCasesForSpamCheck();
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getParameters().put('source', 'tfnsw intranet');
        ApexPages.currentPage().getParameters().put('about', 'Road');
        ApexPages.currentPage().getHeaders().put('X-Salesforce-SIP', ipAddress);
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseRecord);
        WebToCase_CX controller = new WebToCase_CX(stdController);
        System.assert(WebToCase_CX.sourceRmsIntranet == GlobalConstants.MODE_RMS_INTRANET);
        System.assert(WebToCase_CX.sourceRms == GlobalConstants.MODE_RMS);
        System.assert(WebToCase_CX.sourceSydTrains == GlobalConstants.MODE_SYDNEY_TRAINS);
        System.assert(WebToCase_CX.sourceNswTrains == GlobalConstants.MODE_NSW_TRAINS);
        System.assert(WebToCase_CX.sourceTfnswIntranet == GlobalConstants.MODE_TFNSW_INTRANET);
        System.assert(WebToCase_CX.sourceTfnsw == GlobalConstants.MODE_TFNSW);
        System.assert(WebToCase_CX.modeMaritime == GlobalConstants.MODE_MARITIME);
        System.assert(WebToCase_CX.modeNonModal == GlobalConstants.MODE_NON_MODAL);
        System.assert(WebToCase_CX.feedbackForWebsite == GlobalConstants.FEEDBACK_FOR_WEBSITE);
        System.assert(WebToCase_CX.feedbackForApp == GlobalConstants.FEEDBACK_FOR_APP);
        PageReference pgRef = controller.createCase();
        System.assert(pgRef != null); 
        System.assert(pgRef.getUrl().contains('webtocaseerrorpage'));
        System.Test.stopTest();
    }
    
    private static testMethod void testForCaseWithoutContact() {
        mode = 'Road';
        category = 'Road rules';
        subcategory = 'Parking rules';
        ipAddress = '192.23.165.56';
        setUpTestData();
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getParameters().put('source', 'Maritime');
        ApexPages.currentPage().getParameters().put('about', 'Road');
        ApexPages.currentPage().getHeaders().put('X-Salesforce-SIP', ipAddress);
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseRecord);
        WebToCase_CX controller = new WebToCase_CX(stdController);
        controller.lightRailLines = new List<SelectOption>();
        List<SelectOption> lightRailRoutes = controller.lightRailLines;
        controller.setGmeKey('test');
        String gmeKey = controller.getGmeKey();
        System.assert(gmeKey == 'abc123');
        
        controller.setDatasetId('test');
        String dataSet = controller.getDatasetId();
        System.assert(dataSet == '1234');
        
        controller.setRmsOptions(new List<SelectOption>());
        List<SelectOption> rmsOptions = controller.getRmsOptions();
        System.assert(!rmsOptions.isEmpty());
        
        controller.setOptions(new List<SelectOption>());
        List<SelectOption> options = controller.getOptions();
        System.assert(!options.isEmpty());
        
        controller.setMinutes(new List<SelectOption>());
        List<SelectOption> minutes = controller.getMinutes();
        System.assert(!minutes.isEmpty());
        controller.selectedMinute = '50';
        
        controller.setHours(new List<SelectOption>());
        List<SelectOption> hours = controller.getHours();
        System.assert(!hours.isEmpty());
        controller.selectedHour = '12';
                
        controller.setLine('test');
        String line = controller.getLine();
        System.assert(!String.isBlank(line));
        
        controller.setLocation('test');
        String location = controller.getLocation();
        System.assert(!String.isBlank(location));
        
        controller.setMaritimeDatasetID('12345');
        String datasetId = controller.getMaritimeDatasetID();
        System.assert(!String.isBlank(datasetId));
        
        controller.setLgaSedDatasetID('12345');
        datasetId = controller.getLgaSedDatasetID();
        System.assert(!String.isBlank(datasetId));
        
        controller.errorMessage = '';
        controller.selectedRmsOption = 'Road';
        controller.caseRecord.Description = 'case generated from test class';
        controller.caseRecord.Type = 'Compliment';
        controller.caseRecord.Response_Requested__c = 'No';
        controller.caseRecord.Date_Time_of_Incident__c = System.now();
        
        controller.setAllowedFileAttachments('.pptx');
        System.assert(controller.getAllowedFileAttachments() != null);
        
        PageReference pgRef = controller.createCase();
        System.assert(pgRef != null); 
        System.assert(pgRef.getUrl().contains('webtocasethankyoupage'));
        System.Test.stopTest();
    }
    
    
    private static testMethod void testForLightRail() {
        mode = 'Road';
        category = 'Road rules';
        subcategory = 'Parking rules';
        ipAddress = '192.23.165.56';
        setUpTestData();
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getParameters().put('source', GlobalConstants.RMS_SOURCE_RMS_INTRANET);
        ApexPages.currentPage().getParameters().put('about', 'Light Rail');
        ApexPages.currentPage().getHeaders().put('X-Salesforce-SIP', ipAddress);
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseRecord);
        WebToCase_CX controller = new WebToCase_CX(stdController);
        controller.lightRailLines = new List<SelectOption>();
        List<SelectOption> lightRailRoutes = controller.lightRailLines;
        List<SelectOption> lightRailStops = controller.lightRailStops;        
        String trainLinesForPnr = controller.trainLinesForPnr;
        controller.setLine('test');
        String line = controller.getLine();
        System.assert(!String.isBlank(line));
        
        controller.errorMessage = '';
        controller.caseRecord.Description = 'case generated from test class';
        controller.caseRecord.Type = 'Compliment';
        controller.caseRecord.Response_Requested__c = 'No';
        controller.caseRecord.Date_Time_of_Incident__c = System.now();
        
        PageReference pgRef = controller.createCase();
        System.assert(pgRef != null); 
        System.assert(pgRef.getUrl().contains('webtocasethankyoupage'));
        System.Test.stopTest();
    }
    
    
    private static testMethod void testForCaseWithContact() {
        mode = 'Road';
        category = 'Road rules';
        subcategory = 'Parking rules';
        ipAddress = '192.23.165.56';
        setUpTestData();
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getParameters().put('source', 'Maritime');
        ApexPages.currentPage().getParameters().put('about', 'Road');
        ApexPages.currentPage().getHeaders().put('X-Salesforce-SIP', ipAddress);
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseRecord);
        WebToCase_CX controller = new WebToCase_CX(stdController);
        List<WebToCase_CX.CaseCategorization> locCategorization = WebToCase_CX.retrieveLocTaxonomy('tfnsw',mode);
        System.assert(!locCategorization.isEmpty());
        List<WebToCase_CX.CaseCategorization> issueCategorization = WebToCase_CX.retrieveIssueTaxonomy('tfnsw');
        System.assert(!issueCategorization.isEmpty());
        controller.errorMessage = '';
        controller.caseRecord.Description = 'case generated from test class';
        controller.caseRecord.Type = 'Compliment';
        controller.caseRecord.Response_Requested__c = 'No';
        controller.caseRecord.Date_Time_of_Incident__c = System.now();
        controller.contactPerson.FirstName = 'Test';
        controller.contactPerson.LastName = 'Contact';
        controller.contactPerson.Email = 'test@contact.com';
        controller.contactPerson.Phone = '12345678';
        controller.contactPerson.MailingStreet = 'Castlereagh Street';
        controller.contactPerson.MailingCity = 'Sydney';
        controller.contactPerson.MailingPostalCode = '2000';
        controller.contactPerson.MailingCountry = 'Australia';
        controller.contactPerson.MailingCountryCode = 'AU';
        controller.selectedState = 'NSW';
        
        PageReference pgRef = controller.createCase();
        System.assert(pgRef != null); 
        System.assert(pgRef.getUrl().contains('webtocasethankyoupage'));
        System.Test.stopTest();
    }
    
    private static testMethod void testForException() {
         mode = 'Road';
        category = 'Road rules';
        subcategory = 'Parking rules';
        ipAddress = '192.23.165.56';
        setUpTestData();
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getParameters().put('source', 'Maritime');
        ApexPages.currentPage().getParameters().put('about', 'Road');
        ApexPages.currentPage().getHeaders().put('X-Salesforce-SIP', ipAddress);
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseRecord);
        WebToCase_CX controller = new WebToCase_CX(stdController);
        controller.caseRecord = null;
        PageReference pgRef = controller.createCase();
        System.assert(pgRef.getUrl().contains('webtocaseerrorpage'));
        System.Test.stopTest();
    }
    
    private static void setUpTestData() {
        createTaxonomy();
        createCustomSettingEntries();
        populateCaseDetails();
    }
    
    private static void populateCaseDetails() {
        caseRecord = new Case();
        caseRecord.Description = 'Case generated from test class';
        caseRecord.Type = 'Compliment';
        caseRecord.Response_Requested__c = 'No';
    }
    
    private static void createCasesForSpamCheck() {
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < 10; i++) {
            Case caseDetails = new Case();
            caseDetails.Description = 'Case generated from test class';
            caseDetails.Type = 'Compliment';
            caseDetails.Response_Requested__c = 'No';
            caseDetails.Users_Ip_address__c = ipAddress;
            cases.add(caseDetails);
        }
        insert cases;
    }
    
    private static void createCustomSettingEntries() {
        WebToCaseSpamSettings__c spamSetting = new WebToCaseSpamSettings__c();
        //create spam setting for max 10 allowed cases within 10 mins.
        spamSetting.Within_duration_in_min__c = 10;
        spamSetting.Frequency__c = 10;
        spamSetting.Name = 'WebToCase';
        insert spamSetting;
        
        insert new System_Settings__c(
          Name='Test', Debug__c=true, Error__c=true, Info__c=true, Warning__c=true
        );
        
        insert new AusStates__c(Name='NSW', Sort_order__c = 1);
        
        List<RMSDatasets__c> rmsDataSets = new List<RMSDatasets__c>();
        rmsDataSets.add(new RMSDatasets__c(Name = 'RMS Region', Dataset_Id__c = '1234', Key__c = 'abc123'));
        rmsDataSets.add(new RMSDatasets__c(Name = 'Maritime Datasets', Dataset_Id__c = '123456', Key__c = 'abc1234'));
        rmsDataSets.add(new RMSDatasets__c(Name = 'LGA Datasets', Dataset_Id__c = '12345', Key__c = 'abc1235'));
        insert rmsDataSets;
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.docx');
        insert allowedFiles;
        
        insert new Lightrail_route_location_level_1_values__c(Name = 'Sydney Light Rail Route');
        
        insert new Lightrail_stop_location_level_1_values__c(Name = 'Sydney Light Rail Stop');
        
        insert new TrainLinesForPNR__c(Name = 'nsw trainlink regional coach service');
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
        level2Issue.Customer_Value__c = category;
        level2Issue.Name = category;
        level2Issue.Parent_Id__c = level1Issue.Id;
        level2Taxonomies.add(level2Issue);
        
        insert level2Taxonomies;
        
        List<Taxonomy_Metadata__c> level3Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c taxonomyLoc = new Taxonomy_Metadata__c();
        taxonomyLoc.Agency__c = 'RMS';
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
        taxonomyIssue.Agency__c = 'RMS';
        taxonomyIssue.Customer_Value__c = subcategory;
        taxonomyIssue.Name = subcategory;
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
    
    private static void createLightRailTaxonomy() {
        Taxonomy_Metadata__c roadTaxonomy = new Taxonomy_Metadata__c();
        roadTaxonomy.Type__c = 'Mode';
        roadTaxonomy.Status_Customer_Facing__c = 'Active';
        roadTaxonomy.Status_Staff_Facing__c = 'Active';
        roadTaxonomy.Customer_Value__c = 'Light Rail';
        roadTaxonomy.Name = mode;
        
        insert roadTaxonomy;
        
        List<Taxonomy_Metadata__c> level1Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c level1Loc = new Taxonomy_Metadata__c();
        level1Loc.Type__c = 'Location';
        level1Loc.Status_Customer_Facing__c = 'Active';
        level1Loc.Status_Staff_Facing__c = 'Active';
        level1Loc.Customer_Value__c = 'Sydney Light Rail Route';
        level1Loc.Name = 'Sydney Light Rail Route';
        level1Loc.Parent_Id__c = roadTaxonomy.Id;
        level1Taxonomies.add(level1Loc);
        
        Taxonomy_Metadata__c level1Loc2 = new Taxonomy_Metadata__c();
        level1Loc2.Type__c = 'Location';
        level1Loc2.Status_Customer_Facing__c = 'Active';
        level1Loc2.Status_Staff_Facing__c = 'Active';
        level1Loc2.Customer_Value__c = 'Sydney Light Rail Stop';
        level1Loc2.Name = 'Sydney Light Rail Stop';
        level1Loc2.Parent_Id__c = roadTaxonomy.Id;
        level1Taxonomies.add(level1Loc2);
        
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
        
        Taxonomy_Metadata__c level2Loc2 = new Taxonomy_Metadata__c();
        level2Loc2.Type__c = 'Location';
        level2Loc2.Status_Customer_Facing__c = 'Active';
        level2Loc2.Status_Staff_Facing__c = 'Active';
        level2Loc2.Customer_Value__c = 'L1 Dulwich Hill Line';
        level2Loc2.Name = 'L1 Dulwich Hill Line';
        level2Loc2.Parent_Id__c = level1Loc2.Id;
        level2Taxonomies.add(level2Loc2);
        
        insert level2Taxonomies;
        
        List<Taxonomy_Metadata__c> level3Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c taxonomyLoc = new Taxonomy_Metadata__c();
        taxonomyLoc.Agency__c = 'RMS';
        taxonomyLoc.Customer_Value__c = 'L1 Dulwich Hill Line';
        taxonomyLoc.Name = 'L1 Dulwich Hill Line';
        taxonomyLoc.Issue_Accountability__c = 'Test Location Taxonomy';
        taxonomyLoc.Driver__c = '';
        taxonomyLoc.KPI__c = '';
        taxonomyLoc.Parent_Id__c = level2Loc.Id;
        taxonomyLoc.Status_Customer_Facing__c = 'Active';
        taxonomyLoc.Status_Staff_Facing__c = 'Active';
        taxonomyLoc.Type__c = 'Location'; 
        level3Taxonomies.add(taxonomyLoc);
        
        Taxonomy_Metadata__c taxonomyLoc2 = new Taxonomy_Metadata__c();
        taxonomyLoc2.Agency__c = 'RMS';
        taxonomyLoc2.Customer_Value__c = 'Lilyfield Light Rail';
        taxonomyLoc2.Name = 'Lilyfield Light Rail';
        taxonomyLoc2.Issue_Accountability__c = 'Test Location Taxonomy';
        taxonomyLoc2.Driver__c = '';
        taxonomyLoc2.KPI__c = '';
        taxonomyLoc2.Parent_Id__c = level2Loc2.Id;
        taxonomyLoc2.Status_Customer_Facing__c = 'Active';
        taxonomyLoc2.Status_Staff_Facing__c = 'Active';
        taxonomyLoc2.Type__c = 'Location'; 
       
        level3Taxonomies.add(taxonomyLoc2);
        insert level3Taxonomies;
    }
}