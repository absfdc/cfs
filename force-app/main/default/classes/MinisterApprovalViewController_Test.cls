/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for MinisterApprovalViewController
-----------------------------------------------------------------------------------*/

@isTest
private class MinisterApprovalViewController_Test {
    
    @testSetup
    static void setUpUser(){

        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MAGS Officer'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
        Profile p3 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
        UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
        
       
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
        
        User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p3.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u2;

    }   


    //Transport Case Creation and submit for DLO/PA approval
    private static void transportCaseAndSubmitForApproval(){

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        
        system.runAs(u){

            insert transportCase;   

            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());

        }   
        

    } 

    //Transport Case Creation and submit for MO Signatory approval
    private static void transportCaseAndSubmitForMOSignatoryApproval(){

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;

        system.runAs(u){

            insert transportCase;   

            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResult = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResult[0].isSuccess());

            List < ProcessInstanceWorkitem > workItems = [SELECT Id, ProcessInstanceId, ActorId
                                                          FROM ProcessInstanceWorkitem
                                                          WHERE ProcessInstance.TargetObjectId = : transportCase.Id
                                                          AND ActorId = : u.Id limit 1 ];

            List <Approval.ProcessWorkitemRequest> requests = new List <Approval.ProcessWorkitemRequest>();
            for (ProcessInstanceWorkitem workItem: workItems) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                //Valid values are: Approve, Reject, or Removed. 
                //Only system administrators can specify Removed.
                req.setAction('Approve');
                req.setComments('Approved and sent to signatory for further approval.');
                requests.add(req);
            }

            Approval.ProcessResult[] processResults = Approval.process(requests);
            System.assertEquals(TRUE, processResults[0].isSuccess());

        }

    } 

    // transport case with attachment of Unsigned Response pdf.
    private static NoteOrAttachment__c transportCaseWithUnsignedResponseAttachment(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        NoteOrAttachment__c responseCustomAttachment;

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
       
        system.runAs(u){

            insert transportCase;   

            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());
            
            responseCustomAttachment = new NoteOrAttachment__c();
            responseCustomAttachment.Name = 'Response_timestamp';
            responseCustomAttachment.ContentType__c = 'application/pdf';
            responseCustomAttachment.Case__c = transportCase.Id;
            responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
            responseCustomAttachment.Response_PDF__c = TRUE;
            responseCustomAttachment.Category__c = 'Unsigned Response';
           
            insert responseCustomAttachment;
           
            Attachment attach = new Attachment();    
            attach.Name = 'Dummy pdf';
            Blob bodyBlob = Blob.valueOf('Dummy pdf');
            attach.body = bodyBlob;
            attach.parentId = responseCustomAttachment.Id;
            insert attach;
            
            responseCustomAttachment.Attachment__c = attach.Id;
            update responseCustomAttachment;
            
        }   

        return responseCustomAttachment;
    }


    @isTest
    static void getCaseListQueueTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();

        Test.startTest();
        system.runAs(u){

            List<Case> caseList = MinisterApprovalViewController.getCaseListQueue(0,0,'');
            System.assertEquals(1,caseList.size());

        }   
        Test.stopTest();

    }

    @isTest
    static void getUserRoleToCreateAmendmentTest(){

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();
      
        Test.startTest();
        system.runAs(u){
            Boolean checkValue = false;
            checkValue = MinisterApprovalViewController.getUserRoleToCreateAmendment();
            System.assertEquals(checkValue,TRUE);
        }   
        Test.stopTest();

    }

    @isTest
    static void validateUserForApprovalTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();

        Test.startTest();
        system.runAs(u){
            String approvalUser;
            approvalUser = MinisterApprovalViewController.validateUserForApproval();
            System.assertEquals(approvalUser,'Intermediate');
        }   
        Test.stopTest();


    }

    @isTest
    static void getUserDetailTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();

        Test.startTest();
        system.runAs(u){
            User getUser;
            getUser = MinisterApprovalViewController.getUserDetail();
            System.assertEquals(UserInfo.getUserId(),getUser.Id);
        }   
        Test.stopTest();


    }


    @isTest
    static void getUserOrQueueToSendInstructionsTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();

        Test.startTest();
        system.runAs(u){
            String instructionsSentTo;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            instructionsSentTo = MinisterApprovalViewController.getUserOrQueueToSendInstructions(getCase[0].CaseNumber);
            System.assertEquals(instructionsSentTo,GlobalConstants.TRANSPORT_MO_CONTACT_REJECTED);
        }   
        Test.stopTest();


    }

    // Instructions will be sent by MO Signatory
    @isTest
    static void getUserOrQueueToSendInstructionsByMOSignatoryTest() {

        User u = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        User u1 = [Select Id,Name from User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        transportCaseAndSubmitForMOSignatoryApproval();
        
        Test.startTest();
        system.runAs(u){
            String instructionsSentTo;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            instructionsSentTo = MinisterApprovalViewController.getUserOrQueueToSendInstructions(getCase[0].CaseNumber);
            //System.assertEquals(instructionsSentTo,u1.Name);
        }

        Test.stopTest();


    }


    // Signed PDF preview with MO Signatory
    @isTest
    static void getDocumentPreviewWithSignatureByMOSignatoryTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        User u1 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;

        Test.startTest();
        system.runAs(u){

            insert transportCase;   

            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResult = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResult[0].isSuccess());

            List < ProcessInstanceWorkitem > workItems = [SELECT Id, ProcessInstanceId, ActorId
                                                          FROM ProcessInstanceWorkitem
                                                          WHERE ProcessInstance.TargetObjectId = : transportCase.Id
                                                          AND ActorId = : u.Id limit 1 ];

            List <Approval.ProcessWorkitemRequest> requests = new List <Approval.ProcessWorkitemRequest>();
            for (ProcessInstanceWorkitem workItem: workItems) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                //Valid values are: Approve, Reject, or Removed. 
                //Only system administrators can specify Removed.
                req.setAction('Approve');
                req.setComments('Approved and sent to signatory for further approval.');
                requests.add(req);
            }

            Approval.ProcessResult[] processResults = Approval.process(requests);
            System.assertEquals(TRUE, processResults[0].isSuccess());

            NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
            responseCustomAttachment.Name = 'Response_timestamp';
            responseCustomAttachment.ContentType__c = 'application/msword';
            responseCustomAttachment.Case__c = transportCase.Id;
            responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
            responseCustomAttachment.Response_PDF__c = TRUE;
                       
            insert responseCustomAttachment;
           
            Attachment attach = new Attachment();    
            attach.Name = 'Dummy doc';
            Blob bodyBlob = Blob.valueOf('Dummy doc');
            attach.body = bodyBlob;
            attach.parentId = responseCustomAttachment.Id;
            insert attach;
            
            responseCustomAttachment.Attachment__c = attach.Id;
            update responseCustomAttachment;

        }

        
        system.runAs(u1){
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];       
            Test.setMock(HttpCalloutMock.class, new GenerateResponsePDFMockHttpResponse());
            MinisterApprovalViewController.getDocumentPreviewWithSignature(getCase[0].CaseNumber);
        }

        Test.stopTest();


    }



    @isTest
    static void setCaseParametersTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();
        List<Case> getCase = [Select Id,caseNumber from Case limit 1];

        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.setCaseParameters(0,0,0,'');
            System.assertEquals(getCase[0].CaseNumber,MinisterApprovalViewController.CaseNumber);

        }   
        Test.stopTest();

    }


    @isTest
    static void getCaseInformationTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();

        Test.startTest();
        system.runAs(u){
            List<Case> getCaseList;
            getCaseList = MinisterApprovalViewController.getCaseInformation(0,0,0,'',true,new List<String>{});
            System.assertEquals(1,getCaseList.size());
        }   
        Test.stopTest();


    }

    @isTest
    static void getUpdateCaseWithRejectionCommentTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        
        transportCaseWithUnsignedResponseAttachment();

        Test.startTest();
        system.runAs(u){
            String caseUpdateResult;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            caseUpdateResult = MinisterApprovalViewController.getUpdateCaseWithRejectionComment('Reject',true,getCase[0].CaseNumber);
            System.assertEquals(caseUpdateResult,'Success');
        }   
        Test.stopTest();

    }

    @isTest
    static void caseUpdateWithDesktopEditingTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseWithUnsignedResponseAttachment();

        Test.startTest();
        system.runAs(u){
            String caseUpdateResult;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            caseUpdateResult = MinisterApprovalViewController.caseUpdateWithDesktopEditing(getCase[0].CaseNumber);
            System.assertEquals(caseUpdateResult,'Marked for desktop editing successfully');
        }   
        Test.stopTest();
    }


    @isTest
    static void updateCaseSingnatureURLTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();
        
        Test.startTest();
        system.runAs(u){
            String isSignatureUPdated;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            isSignatureUPdated = MinisterApprovalViewController.updateCaseSingnatureURL(getCase[0].CaseNumber);
            System.assertEquals(isSignatureUPdated,'Updated');
        }   
        Test.stopTest();
    }

    @isTest
    static void getCommunicationPreferencesTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseAndSubmitForApproval();
        List<Case> getCaseList = [Select Id FROM Case Limit 1];
        Test.startTest();
        system.runAs(u){
            Case getCase;
            List<Case> getCases = [Select Id,CaseNumber FROM Case LIMIT 1];
            getCase = MinisterApprovalViewController.getCommunicationPreferences(getCases[0].CaseNumber);  
            System.assertEquals(getCase.Id,getCaseList[0].Id);
        }   
        Test.stopTest();
    }
    
    @isTest
    static void getResponseDocumentBodyTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        transportCaseWithUnsignedResponseAttachment();
        Map<String,String> responseDetailMap;
        Test.startTest();
        system.runAs(u){
            responseDetailMap = MinisterApprovalViewController.getResponseDocumentBody(0,0,0,'',true,new List<String>{});  
            System.assertEquals(2,responseDetailMap.size());
        }   
        Test.stopTest();
    }

    @isTest
    static void getIncomingAttachmentsTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        NoteOrAttachment__c customAttachment = transportCaseWithUnsignedResponseAttachment();
        customAttachment.Name = 'Incoming';
        customAttachment.Category__c = GlobalConstants.INCOMING;
        update customAttachment;

        Test.startTest();
        system.runAs(u){
            Map<Id,AttachmentInfo> incomingAttachmentMap;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            incomingAttachmentMap = MinisterApprovalViewController.getIncomingAttachments(getCase[0].CaseNumber);  
            system.assertEquals(1,incomingAttachmentMap.size());
        }   
        Test.stopTest();
    }

    @isTest
    static void getEnclosuresListTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        Test.startTest();
        system.runAs(u){
            
            NoteOrAttachment__c customAttachment = transportCaseWithUnsignedResponseAttachment();
            customAttachment.Name = 'Enclosure';
            customAttachment.Category__c = GlobalConstants.ENCLOUSER;
            update customAttachment;

            List<Attachment> enclosureAttachmentList;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            enclosureAttachmentList = MinisterApprovalViewController.getEnclosuresList(getCase[0].CaseNumber);  
            system.assertEquals(1,enclosureAttachmentList.size());
        }   
        Test.stopTest();
    }

    @isTest
    static void getAmendmentsListTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        Test.startTest();
        system.runAs(u){
            
            NoteOrAttachment__c customAttachment = transportCaseWithUnsignedResponseAttachment();
            customAttachment.Name = 'Response_amendment';
            customAttachment.Category__c = GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT;
            update customAttachment;            
            
            List<Case> getCaseList = [Select Id,CaseNumber from Case limit 1];
            AttachmentInfo amendmentAttachmentInfo;
            amendmentAttachmentInfo = MinisterApprovalViewController.getAmendmentsList(getCaseList[0].CaseNumber);  
            system.assertEquals(getCaseList[0].CaseNumber,amendmentAttachmentInfo.currentCaseNumber);
        }   
        Test.stopTest();
    }

    @isTest
    static void getConsolidatedAdviceListTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        Test.startTest();
        system.runAs(u){

            NoteOrAttachment__c customAttachment = transportCaseWithUnsignedResponseAttachment();
            customAttachment.Name = 'APN_timestamp';
            customAttachment.Category__c= null;
            update customAttachment;  
            
            Map<Id, AttachmentInfo> adviceAttachmentMap;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            adviceAttachmentMap = MinisterApprovalViewController.getConsolidatedAdviceList(getCase[0].CaseNumber);  
            system.assertEquals(1,adviceAttachmentMap.size());
        }   
        Test.stopTest();
    }

    @isTest
    static void getPrecedentsDetailTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();
    
        List<Case> caseToInsertList = new List<Case>();
        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        
        caseToInsertList.add(transportCase);
        
        Case transportCase1 = getTransportCaseRecord();
        transportCase1.MO_User__c = u.Id;
        
        caseToInsertList.add(transportCase1);

        Test.startTest();
        system.runAs(u){
            
            insert caseToInsertList;
            
            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());
            
            NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
            responseCustomAttachment.Name = 'Response_timestamp';
            responseCustomAttachment.ContentType__c = 'application/pdf';
            responseCustomAttachment.Case__c = transportCase1.Id;
            responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
            responseCustomAttachment.Category__c = GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE;
           
            insert responseCustomAttachment;
           
            Attachment attach = new Attachment();    
            attach.Name = 'Response_timestamp';
            Blob bodyBlob = Blob.valueOf('Signed response pdf');
            attach.body = bodyBlob;
            attach.parentId = responseCustomAttachment.Id;
            insert attach;
            
            responseCustomAttachment.Attachment__c = attach.Id;
            update responseCustomAttachment;
            
            Precedent__c precdentCase = new Precedent__c();
            precdentCase.Related_Case__c = transportCase.Id;
            precdentCase.Precedent_Case__c = transportCase1.Id;
            insert precdentCase;
            
            Map<Id,AttachmentInfo> precedentAttachmentMap;
            List<Case> getCase = [Select Id,CaseNumber FROM Case WHERE Id =:transportCase.Id LIMIT 1];

            precedentAttachmentMap = MinisterApprovalViewController.getPrecedentsDetail(getCase[0].CaseNumber);  
            System.assertEquals(1,precedentAttachmentMap.size());
        }   
        Test.stopTest();
    }
    
    @isTest
    static void getPreviousCorroRelatedToContactTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();
        
        Contact testContact = new Contact();
        testContact.LastName = 'Test';
        testContact.Email = 'test@test.com';
        insert testContact;
    
        List<Case> caseToInsertList = new List<Case>();
        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        transportCase.ContactId = testContact.Id;
        
        caseToInsertList.add(transportCase);
        
        Case transportCase1 = getTransportCaseRecord();
        transportCase1.MO_User__c = u.Id;
        transportCase1.ContactId = testContact.Id;
        
        caseToInsertList.add(transportCase1);

        Test.startTest();
        system.runAs(u){
            
            insert caseToInsertList;
            
            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());
            
            NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
            responseCustomAttachment.Name = 'Response_pdf';
            responseCustomAttachment.ContentType__c = 'application/pdf';
            responseCustomAttachment.Case__c = transportCase1.Id;
            responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
            responseCustomAttachment.Category__c = GlobalConstants.SIGNED_RESPONSE;
           
            insert responseCustomAttachment;
           
            Attachment attach = new Attachment();    
            attach.Name = 'Response_pdf';
            Blob bodyBlob = Blob.valueOf('Signed response pdf');
            attach.body = bodyBlob;
            attach.parentId = responseCustomAttachment.Id;
            insert attach;
            
            responseCustomAttachment.Attachment__c = attach.Id;
            update responseCustomAttachment;
         
            Map<Id,AttachmentInfo> corroAttachmentMap;
            List<Case> getCase = [Select Id,CaseNumber FROM Case WHERE Id =:transportCase.Id LIMIT 1];

            corroAttachmentMap = MinisterApprovalViewController.getPreviousCorroRelatedToContact(getCase[0].CaseNumber);  
        }   
        Test.stopTest();
    }

    @isTest
    static void getThunderHeadDraftURLTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;



        Test.startTest();
        system.runAs(u){
            
            insert transportCase;

            TH1__Draft__c createDraft = new  TH1__Draft__c();
            createDraft.Related_Lookup_Case__c = transportCase.Id;
            createDraft.Status__c = GlobalConstants.MAGS_APPROVED_MIN_CORRO;

            insert createDraft;
            
            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());
            
            List<Case> getCase = [Select Id,CaseNumber FROM Case WHERE Id =:transportCase.Id LIMIT 1];

            MinisterApprovalViewController.getThunderHeadDraftURL(getCase[0].CaseNumber);  
        }   
        Test.stopTest();
    }

    @isTest
    static void caseDetailsTest(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        
        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;

        Test.startTest();
        system.runAs(u){

            insert transportCase;

            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());

            PageReference pageRef = Page.MinisterApprovalView;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('caseId',transportCase.Id);
            pageRef.getParameters().put('caseIndex','0');
            pageRef.getParameters().put('sortColIndex','0');
            pageRef.getParameters().put('sortColOrder','0');

            MinisterApprovalViewController controller = new MinisterApprovalViewController();
            controller.caseDeatils();
            System.assertEquals(UserInfo.getUserId(),MinisterApprovalViewController.loggedInUserId);
        }
        Test.stopTest();
       
    }

    @isTest
    static void approvalQueueHomeTest(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        
        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;

        Test.startTest();
        system.runAs(u){

            insert transportCase;

            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());

            PageReference pageRef = Page.MinisterApprovalView;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('sortColIndex','0');
            pageRef.getParameters().put('sortColOrder','0');

            MinisterApprovalViewController controller = new MinisterApprovalViewController();
            controller.approvalQueueHome();
        }
        Test.stopTest();
    }

    @isTest
    static void approvalQueueHomePageTest(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        
        Test.startTest();
        system.runAs(u){

            PageReference pageRef = Page.MinisterApprovalView;
            Test.setCurrentPage(pageRef);
            MinisterApprovalViewController.approvalQueueHomePage();

        }
        Test.stopTest();
    }

    @isTest
    static void submitApprovalRequestTest(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        
        transportCaseAndSubmitForApproval();

        Test.startTest();
        system.runAs(u){
            String result;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];

            result = MinisterApprovalViewController.submitApprovalRequest('Intermediate','Approve','Email','',getCase[0].CaseNumber);
            System.assertEquals(result,'Approved');
        }
        Test.stopTest();   
    }

    // send approval request by signatory
    @isTest
    static void sendApprovalRequestFromSignatoryTest(){
        
        
        //transportCaseAndSubmitForMOSignatoryApproval();
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        User u1 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;

        Test.startTest();
        system.runAs(u){

            PublicSiteDomainName__c setting = new PublicSiteDomainName__c();
            setting.Name = 'Site URL';
            setting.Domain_Name__c = 'test domain';
            insert setting;

            insert transportCase;   

            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);


            NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
            responseCustomAttachment.Name = 'Response_timestamp';
            responseCustomAttachment.ContentType__c = 'application/msword';
            responseCustomAttachment.Case__c = transportCase.Id;
            responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
            responseCustomAttachment.Response_PDF__c = TRUE;
                       
            insert responseCustomAttachment;
           
            Attachment attach = new Attachment();    
            attach.Name = 'Dummy doc';
            Blob bodyBlob = Blob.valueOf('Dummy doc');
            attach.body = bodyBlob;
            attach.parentId = responseCustomAttachment.Id;
            insert attach;
            
            responseCustomAttachment.Attachment__c = attach.Id;
            update responseCustomAttachment;

            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResult = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResult[0].isSuccess());

            List < ProcessInstanceWorkitem > workItems = [SELECT Id, ProcessInstanceId, ActorId
                                                          FROM ProcessInstanceWorkitem
                                                          WHERE ProcessInstance.TargetObjectId = : transportCase.Id
                                                          AND ActorId = : u.Id limit 1 ];

            List <Approval.ProcessWorkitemRequest> requests = new List <Approval.ProcessWorkitemRequest>();
            for (ProcessInstanceWorkitem workItem: workItems) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                //Valid values are: Approve, Reject, or Removed. 
                //Only system administrators can specify Removed.
                req.setAction('Approve');
                req.setComments('Approved and sent to signatory for further approval.');
                requests.add(req);
            }

            Approval.ProcessResult[] processResults = Approval.process(requests);
            System.assertEquals(TRUE, processResults[0].isSuccess());

            
        }
        
        system.runAs(u1){
            Test.setMock(HttpCalloutMock.class, new GenerateResponsePDFMockHttpResponse());
            String result;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];

            MinisterApprovalViewController.submitApprovalRequest('Signatory','Approve','Email','',getCase[0].CaseNumber);            
            
        }

        Test.stopTest();

    }


    @isTest
    static void sendRejectionRequestFromIntermediateTest(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        
        transportCaseAndSubmitForApproval();

        Test.startTest();
        system.runAs(u){
            String result;
            List<Case> getCase = [Select Id,CaseNumber FROM Case LIMIT 1];
            MinisterApprovalViewController.submitApprovalRequest('Intermediate','Reject','Email','',getCase[0].CaseNumber);
            
        }
        Test.stopTest();   
    }



    @isTest
    static void getCaseListQueueExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getCaseListQueue(NULL,0,'');
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);     
        }
        Test.stopTest();
        
    }

    @isTest
    static void setCaseParametersExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.setCaseParameters(0,0,0,''); 
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();

    }
    
    @isTest
    static void getUserOrQueueToSendInstructionsExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.getUserOrQueueToSendInstructions(NULL); 
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();

    }

    @isTest
    static void submitApprovalRequestExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.submitApprovalRequest('','','','',NULL);    
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();
        
    }

    @isTest
    static void getCaseInformationExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.getCaseInformation(0,0,0,'',false,new List<String>{});
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
        
    }

    @isTest
    static void caseUpdateWithDesktopEditingExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.caseUpdateWithDesktopEditing(NULL);
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
        
    }

    @isTest
    static void getUpdateCaseWithRejectionCommentExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.getUpdateCaseWithRejectionComment('test',true, NULL);
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
    }

    @isTest
    static void updateCaseSingnatureURLExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.updateCaseSingnatureURL(NULL);  
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();
    }

    @isTest
    static void getCommunicationPreferencesExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){

            MinisterApprovalViewController.getCommunicationPreferences(NULL);  
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();
    }

    @isTest
    static void getResponseDocumentBodyExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getResponseDocumentBody(0,0,0,'',false,new List<String>{});  
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();
    }

    @isTest
    static void getEnclosuresListExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getEnclosuresList(NULL);    
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();
    }

    @isTest
    static void getIncomingAttachmentsExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getIncomingAttachments(NULL);
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
    }

    @isTest
    static void getPrecedentsDetailExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getPrecedentsDetail(NULL);
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
    }

    @isTest
    static void getPreviousCorroRelatedToContactExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getPreviousCorroRelatedToContact(NULL); 
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();
    }

    @isTest
    static void getConsolidatedAdviceListExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getConsolidatedAdviceList(NULL);
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
    }

    @isTest
    static void getThunderHeadDraftURLExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        PublicSiteDomainName__c setting = new PublicSiteDomainName__c();
        setting.Name = 'Draft Base Domain';
        setting.Domain_Name__c = 'test domain';
        insert setting;
            
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getThunderHeadDraftURL(NULL);   
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);         
        }
        Test.stopTest();
    }

    @isTest
    static void getAmendmentsListExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getAmendmentsList(NULL);
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
    }

    @isTest
    static void createAuthorisationRecordAndUpdateSignatureURLExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.createAuthorisationRecordAndUpdateSignatureURL(NULL,'', NULL);
            System.assertEquals(TRUE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
    }

    @isTest
    static void getDocumentPreviewWithSignatureExceptionHandling(){
        User u = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        Test.startTest();
        system.runAs(u){
            MinisterApprovalViewController.getDocumentPreviewWithSignature('');
            System.assertEquals(FALSE, MinisterApprovalViewController.exceptionInvoked);             
        }
        Test.stopTest();
    }

    /*------------------------------------------------------------------- ----------------
    Author:  Arxxus      
    Description:   This method creates a roads case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getRoadsCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'MAGS Approved',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            MO_User__c = NULL,
                            Response_Type__c = 'Draft response',
                            Signatory__c = 'Minister for Roads, Maritime and Freight');
    }
       
    /*------------------------------------------------------------------- ----------------
    Author:        
    Description:   This method creates a transport case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getTransportCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'MAGS Approved',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            MO_User__c = NULL,
                            Response_Type__c = 'Draft response',
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
    }
    
}