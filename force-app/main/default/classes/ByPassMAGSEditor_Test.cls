@isTest
private class ByPassMAGSEditor_Test {
    
    @testSetup
    static void setUpUser(){
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MAGS Officer'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
        UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Senior_MAGS_Officer'];
        UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MAGS_Editor'];
        UserRole r4 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MAGS_Officer'];
        
       
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
        
        User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u2;

        User u3 = new User(Alias = 'standt', Email = 'standarduser3@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r3.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u3;

        User u4 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r4.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u4;
    }


    @isTest
    static void makeApprovalTest(){

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        User u1 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];

        User u3 = [Select Id From User Where email = 'standarduser4@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        transportCase.Status = 'Draft in Progress';
        insert transportCase;
        
        

        TH1__Draft__c createDraft = new  TH1__Draft__c();
        createDraft.Related_Lookup_Case__c = transportCase.Id;
        createDraft.Status__c = 'Draft Response in Progress';
        insert createDraft;
        
        Attachment dft_attach = new Attachment();    
        dft_attach.Name = 'Dummy_XML';
        Blob dft_bodyBlob = Blob.valueOf('Dummy_XML');
        dft_attach.body = dft_bodyBlob;
        dft_attach.parentId = createDraft.Id;
        insert dft_attach;
        
        createDraft.TH1__Draft_XML_Attachment_Id__c = dft_attach.Id;
        update createDraft;

        System.runAs(u3){
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting draft for approval');
            tempReq.setObjectId(createDraft.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.debug('Draft approval :: ' + processResults );
            System.assertEquals(TRUE, processResults[0].isSuccess());    
        }
        
	  //  transportCase.Signatory__c = 'Executive Director, Customer Relations & Government Services';
      //  update transportCase;
        Attachment attach = new Attachment();    
        attach.Name = 'Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA';
        Blob bodyBlob = Blob.valueOf('Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA_{{IMAGE:CASE_SIGNATURE_IMAGE_URL:W=300:H=100}}__');
        attach.body = bodyBlob;
        attach.parentId = transportCase.Id;
        insert attach;
                                     
        System.runAs(u1){
            ByPassMAGSEditor.makeApproval(transportCase.Id);
        }
        transportCase = [Select Id,Status from Case Where Id = : transportCase.Id Limit 1];
        System.assertEquals('MAGS Approved', transportCase.Status);  
    }
    
    @isTest
    static void makeSCDraftExceptionTest(){

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        User u1 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];

        User u3 = [Select Id From User Where email = 'standarduser4@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        transportCase.Status = 'Draft in Progress';
        insert transportCase;

        TH1__Draft__c createDraft = new  TH1__Draft__c();
        createDraft.Related_Lookup_Case__c = transportCase.Id;
        createDraft.Status__c = 'Draft Response in Progress';
        insert createDraft;

        System.runAs(u3){
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting draft for approval');
            tempReq.setObjectId(createDraft.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.debug('Draft approval :: ' + processResults );
            System.assertEquals(TRUE, processResults[0].isSuccess());    
        }
        
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ActorId, ProcessInstance.TargetObjectId
                                                   FROM ProcessInstanceWorkitem
                                                   WHERE ProcessInstance.TargetObjectId = :transportCase.Id];
        List<ProcessInstanceWorkitem> updateItems = new List<ProcessInstanceWorkitem>();
        for (ProcessInstanceWorkitem itm : workItems){
        	itm.ActorId = u1.Id;
        	updateItems.add(itm);
        } 
        update updateItems;
        Map<Id,Case> caseMap = new Map<Id,Case>{transportCase.Id=>transportCase};
        System.runAs(u1){
            DraftAfterUpdateTriggerHandler.processWorkItemCases(caseMap);
        }
 
        Test.startTest();
        transportCase.subject = 'Throw Test Exception';
        update transportCase;
        
        DraftAfterUpdateTriggerHandler.generateSmartCorroPdf(new List<Id>{createDraft.Id}); 
        Test.stopTest();
        
        new DraftAfterUpdateTriggerHandler().inProgressEntry(null);
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
    
    private static void createAttachment(String caseId, String attachmentCategory,String name){

        NoteOrAttachment__c responseCustomAttachment;

        responseCustomAttachment = new NoteOrAttachment__c();
        responseCustomAttachment.Name = name;
        responseCustomAttachment.ContentType__c = 'application/pdf';
        responseCustomAttachment.Case__c = caseId;
        responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
        responseCustomAttachment.Category__c = attachmentCategory;
       
        insert responseCustomAttachment;
       
        Attachment attach = new Attachment();    
        attach.Name = name;
        Blob bodyBlob = Blob.valueOf(name);
        attach.body = bodyBlob;
        attach.parentId = responseCustomAttachment.Id;
        insert attach;
        
        responseCustomAttachment.Attachment__c = attach.Id;
        update responseCustomAttachment;
    }

}