@isTest
private class GeneratePdfPreviewWithSignature_Test {
    
    @testSetup 
    static void setUpUser() {
            
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Senior_MAGS_Officer'];
        UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Road'];
        UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MAGS_Manager'];
        UserRole r4 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
        UserRole r5 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
      
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
       
        User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u2;
       
        User u3 = new User(Alias = 'standt', Email = 'standarduser3@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r3.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u3;

        User u4 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r4.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u4;

        User u5 = new User(Alias = 'standt', Email = 'standarduser5@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', UserRoleId = r5.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u5;
       
    }

    private static void createCustomSetting(){

        MO_Template_by_Response_Type__c moTemplate = new MO_Template_by_Response_Type__c();
        moTemplate.Name = 'MO View Email Attachment';
        moTemplate.Additional_Contact_Attachment_Categories__c = 'Signed Response,Incoming,Enclosures';
        moTemplate.Additional_Contacts_Email_Template__c = 'MOViewAdditionalCorroContactEmailTemplate';
        moTemplate.Contact_Attachment_Categories__c = 'Signed Response,Enclosures';
        moTemplate.Customer_Email_Template__c = 'MOViewCustomerContactEmailTemplate';
        moTemplate.Staff_Attachment_Categories__c = 'Signed Response,Enclosures';
        moTemplate.Staff_Email_Template__c =  'MOViewStaffContactEmailTemplate';
        insert moTemplate;

    }

    @isTest
    static void generateTest(){
        
        setupCaseRecTypesToExcludeCS();
        createCustomSetting();
   
        User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        User u2 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        Case roadCase = getRoadsCaseRecord();
        
        roadCase.Status = 'MAGS Approved';
        roadCase.MO_User__c = u2.Id;
        roadCase.OwnerId = u2.Id;
        roadCase.Signatory__c = 'Minister for Roads, Maritime and Freight';
        insert roadCase;

        roadCase = [SELECT Status, OwnerId, RecordTypeId, Response_Type__c, Signatory__c, Signatory_Person__c, Submitted_For_MO_Approval__c, MO_User__c, RecordType.Name FROM Case WHERE Id = :roadCase.Id];
        
        System.debug('Got roadCase: '+roadCase);
       
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
        tempReq.setComments('Submitting response for approval');
        tempReq.setObjectId(roadCase.Id);
        tempReq.setSubmitterId(u2.Id);
        approvalRequests.add(tempReq);
       
        Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
        
        System.assertEquals(TRUE, processResults[0].isSuccess());
        
        // Unlock the cases
        Set<Id> tempCaseId = new Set<Id>();
        tempCaseId.add(Id.valueOf(roadCase.Id));
                    
        Approval.UnlockResult[] lrList = Approval.unlock(new List<Id>(tempCaseId), false);
        
        System.debug('Unlock Result Got: '+lrList[0].getErrors());
        System.assertEquals(TRUE, lrList[0].isSuccess());
        
        roadCase = [SELECT Status, OwnerId, RecordTypeId, Response_Type__c, Signatory__c, Signatory_Person__c, Submitted_For_MO_Approval__c, MO_User__c, RecordType.Name FROM Case WHERE Id = :roadCase.Id];
        
        System.debug('Got roadCase details : '+roadCase);
        
        List<Application_Log__c> messages = [SELECT Message__c, Reference_Id__c, Reference_Info__c, Source__c,
                                                  Source_Function__c, Stack_Trace__c
                                                  FROM Application_Log__c];
                                                  
        for(Application_Log__c tempLog : messages)
          System.debug('Exception Got: '+tempLog);
        
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ActorId 
                                                    FROM ProcessInstanceWorkitem 
                                                    WHERE ProcessInstance.TargetObjectId =: roadCase.Id
                                                    limit 1];
        
        System.debug('Got workItem: '+workItems[0]);
        
        System.runAs(u2) {
        
         workItems = [SELECT Id, ProcessInstanceId ,ActorId 
                      FROM ProcessInstanceWorkitem 
                      WHERE ProcessInstance.TargetObjectId =: roadCase.Id
                      limit 1];
        
        System.debug('Got workItem: '+workItems[0]);
        System.debug('Running User Id: '+u2.Id);   
        System.debug('Logged in user: '+UserInfo.getUserId());                                                     
                                                                
        NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
        responseCustomAttachment.Name = 'response_timestamp';
        responseCustomAttachment.ContentType__c = 'application/msword';
        responseCustomAttachment.Case__c = roadCase.Id;
        responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
       
        insert responseCustomAttachment;
       
        Attachment attach = new Attachment();    
        attach.Name = 'Dummy Response WordML Doc.';
        Blob bodyBlob = Blob.valueOf('Dummy Response WordML Doc.');
        attach.body = bodyBlob;
        attach.parentId = responseCustomAttachment.Id;
        insert attach;
        
        // Set mock callout class
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GenerateResponsePDFMockHttpResponse());

        GeneratePdfPreviewWithSignature.generate(roadCase.Id,attach.Id,'response_timestamp',UserInfo.getSessionId(),true);
        Test.stopTest();
       }
    }
    
    
    // generate pdf with signature where signatory communication preference is 'Email'
    @isTest
    static void generateSignedPDFWithEmailTest(){

        setupCaseRecTypesToExcludeCS();
        createCustomSetting();

        Digital_Process_Send_Email__c digitalProcessCustomSetting = new Digital_Process_Send_Email__c();
        digitalProcessCustomSetting.On__c = false;
        digitalProcessCustomSetting.Name = GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL;
        insert digitalProcessCustomSetting;
   
        String folderName = [select id from folder where name = 'Andrew Constance Signature Folder' limit 1].Id;

        Document document = new Document();
        document.Body = Blob.valueOf('Some Text');
        document.ContentType = 'image/png';
        document.DeveloperName = 'my_document';
        document.Name = 'My Document';
        document.FolderId = folderName;
        insert document;

        User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        User u2 = [Select Id From User Where email = 'standarduser5@nsw.gov.au.com' limit 1];
        
        u2.Signature_Location__c = 'test@test.com/documentId='+document.Id;
        update u2;

     
        Case getCase = createRoadCaseAndSubmiForApproval();
        Attachment getAttachment = createAttachment(getCase.Id);
        
        getCase.Signature_Authorisation_Failure__c = FALSE;
        update getCase;

        Signature_Authorisation__c signatureData = new Signature_Authorisation__c();
        signatureData.Case_Id__c = getCase.Id;
        signatureData.Document_Id__c = getAttachment.Id;
        signatureData.User_Id__c = u2.Id;

        insert signatureData;
        
        System.runAs(u2) {
            
            Test.startTest();
            GeneratePdfPreviewWithSignature.mock = new GenerateResponsePDFMockHttpResponse();
            GeneratePdfPreviewWithSignature.generateSignedPDF(getCase.Id,getAttachment.Id,'response_timestamp',UserInfo.getSessionId(),false,'Email',u2.Id);
            Test.stopTest();
        }

    }

    // generate pdf with signature where signatory communication preference is 'Email'
    @isTest
    static void sendEmailAfterApprovalTest(){

        setupCaseRecTypesToExcludeCS();
        createCustomSetting();
   
        User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        User u2 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        Case getCase = createRoadCaseAndSubmiForApproval();
        Attachment getAttachment = createAttachment(getCase.Id);
        
        getCase.Signature_Authorisation_Failure__c = FALSE;
        update getCase;
        
        System.runAs(u2) {
            
            Test.startTest();
            
            GeneratePdfPreviewWithSignature.sendEmailAfterApproval(getCase.Id);
            Test.stopTest();
        }

    }

    // generate pdf with signature where signatory communication preference is 'Email'
    @isTest
    static void testNULLResponse(){

        
        setupCaseRecTypesToExcludeCS();
        createCustomSetting();
   
        User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        User u2 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        Case getCase = createRoadCaseAndSubmiForApproval();
        Attachment getAttachment = createAttachment(getCase.Id);

        System.runAs(u2) {
            
            Test.startTest();
            GeneratePdfPreviewWithSignature.mock = new GenerateResponsePDFMockNullHttpResponse();
            GeneratePdfPreviewWithSignature.generate(getCase.Id,getAttachment.Id,'response_timestamp',UserInfo.getSessionId(),false);
            Test.stopTest();
        }

    }
    
    
    // generate pdf with signature where signatory communication preference is 'Letter'
    @isTest
    static void generateSignedPDFWithLetterTest(){

        setupCaseRecTypesToExcludeCS();
        createCustomSetting();

        Digital_Process_Send_Email__c digitalProcessCustomSetting = new Digital_Process_Send_Email__c();
        digitalProcessCustomSetting.On__c = false;
        digitalProcessCustomSetting.Name = GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL;
        insert digitalProcessCustomSetting;
           
        User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        User u2 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        Case getCase = createRoadCaseAndSubmiForApproval();
        Attachment getAttachment = createAttachment(getCase.Id);

        System.runAs(u2) {
            Test.startTest();
            GeneratePdfPreviewWithSignature.mock = new GenerateResponsePDFMockHttpResponse();
            GeneratePdfPreviewWithSignature.generateSignedPDF(getCase.Id,getAttachment.Id,'response_timestamp',UserInfo.getSessionId(),false,'Letter',u2.Id);
            Test.stopTest();
        }

    }
    
    
    //Exception handling test
    @isTest
    static void exceptionHandlingTest() {

        GeneratePdfPreviewWithSignature.generate(NULL, NULL,'response_timestamp', UserInfo.getSessionId(),false);
        System.assertEquals(TRUE, GeneratePdfPreviewWithSignature.exceptionInvoked);
       
        GeneratePdfPreviewWithSignature.exceptionInvoked = FALSE;
        Test.startTest();
        GeneratePdfPreviewWithSignature.generateSignedPDF(NULL, NULL,'response_timestamp', UserInfo.getSessionId(),true,'Email',UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals(TRUE, GeneratePdfPreviewWithSignature.exceptionInvoked);
    }
    
    private static Case createRoadCaseAndSubmiForApproval(){

        setupCaseRecTypesToExcludeCS();
   
        User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        User u2 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        Contact customer = new Contact(Salutation='Mr',LastName='Customer', Firstname='Contact',Email='customer@contact.com');
        Contact staff = new Contact(Salutation='Mr',LastName='Staff', Firstname='Contact',Email='staff@contact.com');
        Contact additionalContact = new Contact(Salutation='Mr',LastName='Additional', Firstname='Contact',Email='additional@contact.com');

        insert new List<Contact>{customer,staff,additionalContact};

        Case roadCase = getRoadsCaseRecord();
        roadCase.Status = 'MAGS Approved';
        roadCase.MO_User__c = u2.Id;
        roadCase.OwnerId = u2.Id;
        roadCase.Signatory__c = 'Minister for Roads, Maritime and Freight';
        roadCase.contactId =customer.Id;
        roadCase.staff_contact__c =staff.Id;
        insert roadCase;

        Additional_Corro_Recipients__c additionalRecipient = new Additional_Corro_Recipients__c(case__c=roadCase.Id,contact__c=additionalContact.Id);
        insert additionalRecipient;
       
        //Test.startTest();
        //submitting case to MO approval - will route to MO_User__c i.e DLO/PA for approval
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
        tempReq.setComments('Submitting response for approval');
        tempReq.setObjectId(roadCase.Id);
        tempReq.setSubmitterId(u2.Id);
        approvalRequests.add(tempReq);
       
        Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
        
        System.assertEquals(TRUE, processResults[0].isSuccess());
        
        // Unlock the cases
        Set<Id> tempCaseId = new Set<Id>();
        tempCaseId.add(Id.valueOf(roadCase.Id));
                    
        Approval.UnlockResult[] lrList = Approval.unlock(new List<Id>(tempCaseId), false);
        
        System.debug('Unlock Result Got: '+lrList[0].getErrors());
        System.assertEquals(TRUE, lrList[0].isSuccess());
        //Test.stopTest();
       
        System.runAs(u2) {
        
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId ,ActorId 
                                                                FROM ProcessInstanceWorkitem 
                                                                WHERE ProcessInstance.TargetObjectId =: roadCase.Id
                                                                limit 1];
        
        System.debug('Got workItem: '+workItems[0]);
        System.debug('Running User Id: '+u2.Id);   
        System.debug('Logged in user: '+UserInfo.getUserId());                                                     
    
       }

       return roadCase;

    }

    private static Attachment createAttachment(Id caseId){

        NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
        responseCustomAttachment.Name = 'response_timestamp';
        responseCustomAttachment.ContentType__c = 'application/msword';
        responseCustomAttachment.Case__c = caseId;
        responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;

        NoteOrAttachment__c signedAttachment = new NoteOrAttachment__c();
        signedAttachment.Name = 'response_timestamp';
        signedAttachment.ContentType__c = 'application/pdf';
        signedAttachment.Case__c = caseId;
        signedAttachment.IsMinCorroCaseNote__c = TRUE;
        signedAttachment.Category__c = GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE;

        NoteOrAttachment__c enclosureCustomAttachment = new NoteOrAttachment__c();
        enclosureCustomAttachment.Name = 'Enclosure';
        enclosureCustomAttachment.ContentType__c = 'application/pdf';
        enclosureCustomAttachment.Case__c = caseId;
        enclosureCustomAttachment.IsMinCorroCaseNote__c = TRUE;
        enclosureCustomAttachment.Category__c = GlobalConstants.ENCLOUSER;
       
        insert new List<NoteOrAttachment__c>{responseCustomAttachment,enclosureCustomAttachment,signedAttachment};
            
        Attachment attach = new Attachment();    
        attach.Name = 'Dummy Response WordML Doc.';
        Blob bodyBlob = Blob.valueOf('Dummy Response WordML Doc.');
        attach.body = bodyBlob;
        attach.parentId = responseCustomAttachment.Id;

        Attachment signedAttach = new Attachment();    
        signedAttach.Name = 'Dummy Response WordML Doc.';
        Blob bodyBlobData = Blob.valueOf('Dummy Response pdf');
        signedAttach.body = bodyBlob;
        signedAttach.parentId = signedAttachment.Id;
        
        Attachment enclosureAttach = new Attachment();    
        enclosureAttach.Name = 'Dummy Response pdf';
        Blob enclosureBodyBlob = Blob.valueOf('Dummy pdf');
        enclosureAttach.body = enclosureBodyBlob;
        enclosureAttach.parentId = enclosureCustomAttachment.Id;

        insert new List<Attachment>{attach,enclosureAttach,signedAttach};     

        signedAttachment.Attachment__c = signedAttach.Id;
        enclosureCustomAttachment.Attachment__c = enclosureAttach.Id;
        
        update new List<NoteOrAttachment__c>{enclosureCustomAttachment,signedAttachment};

        return attach;

    }

    /*-----------------------------------------------------------------------------------
    Author:        
    Description:   This method creates a roads case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getRoadsCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'New',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            Portfolio__c = 'Roads, Maritime and Freight',
                            Signatory__c = 'Minister for Roads, Maritime and Freight');
    }
       
    /*-----------------------------------------------------------------------------------
    Author:        
    Description:   This method creates a transport case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getTransportCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'New',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            Portfolio__c = 'Transport and Infrastructure',
                            Signatory__c = 'Minister for Transport and Infrastructure');
    } 
      
    public static void setupCaseRecTypesToExcludeCS() {
       
        List<CaseRecordTypesToExcludeFromRtFlip__c> rtToExclude = new List<CaseRecordTypesToExcludeFromRtFlip__c>();
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'General Ministerial Correspondence', Record_Type_Name__c = 'General Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Roads & Freight Ministerial Cor', Record_Type_Name__c = 'Roads & Freight Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Transport Ministerial Correspondence', Record_Type_Name__c = 'Transport Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign', Record_Type_Name__c = 'Campaign'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign Member', Record_Type_Name__c = 'Campaign Member'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Erroneous Cases', Record_Type_Name__c = 'Erroneous Cases Ministerial Correspondence'));
        insert rtToExclude;
        
        List<Digital_Process_Send_Email__c> digitalEmailCS = new List<Digital_Process_Send_Email__c>();
        digitalEmailCS.add(new Digital_Process_Send_Email__c(Name = 'Send Email Process', On__c = TRUE));
        insert digitalEmailCS;
    }
    
}