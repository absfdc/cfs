@isTest
private class BulkUploadStagingRecords_Test {

    private static String testFileContent;
    private static List<sObject> stagingList;
    private static String soqlQuery;
    @testSetup
    static void setUpTestData(){

        RecordType rt = [Select Id From RecordType Where DeveloperName = 'Staff' limit 1];
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'TfNSW' limit 1];
        RecordType accountRT = [Select Id From RecordType Where DeveloperName = 'organization' limit 1];
        Profile portalProfile = [Select Id from Profile where name = 'TfNSW Operator Portal User'];
        Account portalAccount = new Account(name = 'portalAccount',RecordTypeId=accountRT.Id);//create a portal account first
        insert portalAccount;
        Contact portalContact = new contact(LastName = 'portalContact', AccountId = portalAccount.Id,RecordTypeId = rt.Id); //create a portal contact
        insert portalContact;
        User u1 = new User( email='test@test.com',
                profileid = portalProfile.Id, 
                UserName='portalUserCFS@portalCFSTestUser.com', 
                Alias = 'a',
                TimeZoneSidKey='Australia/Sydney',
                EmailEncodingKey='ISO-8859-1',
                LocaleSidKey='en_US', 
                LanguageLocaleKey='en_US',
                ContactId = portalContact.Id,
                FirstName = 'Test FirstName',
                LastName = 'LastName');

        insert u1;
        System.debug('u1::' + u1);

        BU_Staging_Job_Detail__c stagingJobStartNumber = new BU_Staging_Job_Detail__c();
        stagingJobStartNumber.Name = 'Job Id';
        stagingJobStartNumber.Job_Id__c = '10000';
        insert stagingJobStartNumber;
       
        FullMatchDuplicateContactRules__c fullMatchConfidenceRules = new FullMatchDuplicateContactRules__c();
        fullMatchConfidenceRules.Name = 'contactNormalizedMatch';
        insert fullMatchConfidenceRules;

        System.runAs(u1){
            getStagingRecords();
        }

    }

    private static void getStagingRecords(){

        Contact newContact = new Contact(FirstName = 'Eric',LastName = 'John', Email = 'eric@test.com');
        insert newContact;

        List<sObject> stagingRecList = Test.loadData(BU_Staging__c.sObjectType, 'BulkUploadTestFile');
        System.debug('stagingRecList :: ' + stagingRecList ); 
        System.debug('Staging Record list size :: '+ stagingRecList.size() );

        MappingRecord.getMappingMetadataList();
        String soqlQuery = 'select Case__c, Processing_Status__c, Contact__c, Location_Level_3__c, '+MappingRecord.stagingApiName+' FROM BU_Staging__c';
        System.debug('soqlQuery *:: ' + soqlQuery);
        List<BU_Staging__c> stagingRecordList = Database.Query(soqlQuery);
        List<BU_Staging__c> stagingRecToBeInserted = new List<BU_Staging__c>();

        Taxonomy_Metadata__c taxonomyModeRec = new Taxonomy_Metadata__c(
                                                Name = 'Test Mode',
                                                Type__c = 'Mode',
                                                Status_Staff_Facing__c = 'Active');
        insert taxonomyModeRec;

        Taxonomy_Metadata__c taxonomyLoc1 = new Taxonomy_Metadata__c(
                                                Name = 'Test Location1',
                                                Type__c = 'Location',
                                                Status_Staff_Facing__c = 'Active',
                                                Parent_Id__c = taxonomyModeRec.Id );
        insert taxonomyLoc1;

        Taxonomy_Metadata__c taxonomyLoc2 = new Taxonomy_Metadata__c(
                                                Name = 'Test Location2',
                                                Type__c = 'Location',
                                                Status_Staff_Facing__c = 'Active',
                                                Parent_Id__c = taxonomyLoc1.Id);
        insert taxonomyLoc2;

        Taxonomy_Metadata__c taxonomyLoc3 = new Taxonomy_Metadata__c(
                                                Name = 'Test Location3',
                                                Type__c = 'Location',
                                                Status_Staff_Facing__c = 'Active',
                                                Parent_Id__c = taxonomyLoc2.Id);
        insert taxonomyLoc3;

        for(BU_Staging__c stagingRec : stagingRecordList ){
            BU_Staging__c stagingRecClone = stagingRec.clone(false,true);
            stagingRecClone.Location_Level_3_Id__c =  taxonomyLoc3.Id; 
            stagingRecClone.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
            stagingRecClone.Failure_Reason__c = '';
            stagingRecToBeInserted.add(stagingRecClone);
        }
        
        insert stagingRecToBeInserted;
        /*System.debug(' stagingRecToBeInserted :: ' + stagingRecToBeInserted);
        System.debug(' stagingRecToBeInserted size:: ' + stagingRecToBeInserted.size());
        */
    }

    private static void getStagingRecordsWithContactId(){
        MappingRecord.getMappingMetadataList();
        String soqlQuery = 'select Case__c, Processing_Status__c, Contact__c, Location_Level_3__c, '+MappingRecord.stagingApiName+' FROM BU_Staging__c';
        //System.debug('soqlQuery *:: ' + soqlQuery);
        List<BU_Staging__c> stagingRecordList = Database.Query(soqlQuery);
        List<BU_Staging__c> stagingRecToBeInserted = new List<BU_Staging__c>();

        for(BU_Staging__c stagingRec : stagingRecordList ){
            if(stagingRec.Contact_Id__c != null && stagingRec.Contact_Id__c != ''){
                BU_Staging__c stagingRecClone = stagingRec.clone(false,true);
                stagingRecClone.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                stagingRecClone.Contact_First_Name__c = 'Test';
                stagingRecClone.Failure_Reason__c = '';
                stagingRecToBeInserted.add(stagingRecClone);
            }
        }
        
        insert stagingRecToBeInserted;

        delete stagingRecordList;
        System.debug(' getStagingRecordsWithContactId stagingRecToBeInserted :: ' + stagingRecToBeInserted);
        System.debug(' getStagingRecordsWithContactId stagingRecToBeInserted size :: ' + stagingRecToBeInserted.size());
        
    }

    private static void getStagingRecordsWithCaseId(){
        MappingRecord.getMappingMetadataList();
        String soqlQuery = 'select Case__c, Processing_Status__c, Contact__c, Location_Level_3__c, '+MappingRecord.stagingApiName+' FROM BU_Staging__c';
        List<BU_Staging__c> stagingRecordList = Database.Query(soqlQuery);
        List<BU_Staging__c> stagingRecToBeInserted = new List<BU_Staging__c>();

        for(BU_Staging__c stagingRec : stagingRecordList ){
            if(stagingRec.Contact_Id__c != null && stagingRec.Contact_Id__c != ''){
                BU_Staging__c stagingRecClone = stagingRec.clone(false,true);
                stagingRecClone.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                stagingRecClone.Description__c = 'Change case description';
                stagingRecClone.Failure_Reason__c = '';
                stagingRecToBeInserted.add(stagingRecClone);
            }
        }
        
        insert stagingRecToBeInserted;
        delete stagingRecordList;
        System.debug(' getStagingRecordsWithCaseId stagingRecToBeInserted :: ' + stagingRecToBeInserted);
        System.debug(' getStagingRecordsWithCaseId stagingRecToBeInserted size :: ' + stagingRecToBeInserted.size());
        
    }

    @isTest static void testAddRecordsCSVExceptionHandling(){
        Test.startTest();
        User u = [Select Id from User Where email = 'test@test.com' LIMIT 1];
        System.runAs(u){
            String subjectDetail = 'This is the case subject which is required to fail the insert operation to generate the exception with nunber of charaters more than 255.'
                                +' This subject data will produce an error and will invoke the maximum length error for the case subject field. Maximum length.';
            String csvRow1 = 'Contact First Name,Contact Second Name,Contact Email,Subject';
            String csvRow2 = 'Test,UserUpload User,upload@test.com,Test Subject';
            String csvRow3 = 'Test,UserUpload User,upload@test1.com,'+subjectDetail;
            testFileContent = csvRow1+'\r\n'+csvRow2+'\r\n'+ csvRow3;
            Integer successUploads = BulkUploadStagingRecords.addRecordsCSV(testFileContent);
            System.assertEquals(successUploads,0);
          
        }
        Test.stopTest();
    }

    @isTest static void testAddRecordsCSVSuccessRecords(){
        Test.startTest();
        User u = [Select Id from User Where email = 'test@test.com' LIMIT 1];
        System.runAs(u){
            String csvRow1 = 'Contact First Name,Contact Second Name,Contact Email,Subject';
            String csvRow2 = 'Test,UserUpload User,upload@test.com,Test Subject';
            String csvRow3 = 'Test,UserUpload User,upload@test1.com,Test Subject 2';
            testFileContent = csvRow1+'\r\n'+csvRow2+'\r\n'+ csvRow3;
            Integer successUploads = BulkUploadStagingRecords.addRecordsCSV(testFileContent);
            System.assertEquals(successUploads,2);
        }
        Test.stopTest();
    }

    @isTest static void testAddRecordsCSVWithContactId() {
        Test.startTest();
        User u = [Select Id from User Where email = 'test@test.com' LIMIT 1];
        System.runAs(u){
            System.debug('testAddRecordsCSVWithContactId called');
            getStagingRecordsWithContactId();
        }
        Test.stopTest();
    }

    @isTest static void testAddRecordsCSVWithCaseId() {
        Test.startTest();
        User u = [Select Id from User Where email = 'test@test.com' LIMIT 1];
        System.runAs(u){
            getStagingRecordsWithContactId();
            getStagingRecordsWithCaseId();
        }
        Test.stopTest();
    }

    @isTest static void testGetCSVColumnHeaders(){

        Test.startTest();
        User u = [Select Id from User Where email = 'test@test.com' LIMIT 1];
        System.runAs(u){
            BulkUploadStagingRecords.getCSVColumnHeaders();
        }
        Test.stopTest();
    }

    @isTest static void testGetUploadRecordCount(){

        Test.startTest();
        User u = [Select Id from User Where email = 'test@test.com' LIMIT 1];
        System.runAs(u){
            BulkUploadStagingRecords.getUploadRecordCount();
        }
        Test.stopTest();
    } 


}