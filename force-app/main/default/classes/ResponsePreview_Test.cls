@isTest
private class ResponsePreview_Test {
    
    @testSetup 
    static void setUpUser() {
            
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Road'];
        
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
              
    }
    
    @isTest static void showResponsePreviewPDFTest() {
        CreateEntitlement();
        Test.startTest();
        Case transportCase = getTransportCaseRecord();
        transportCase.Signature_Image_URL__c = 'test@test.com';
        insert transportCase;
        createAttachment(transportCase.Id,'','Dummy Doc');
        GeneratePdfPreviewWithSignature.mock = new GenerateResponsePDFMockHttpResponse();
        Map<String,String> responsedataMap = new Map<String,String>();
        responsedataMap = ResponsePreview.showResponsePreviewPDF(transportCase.Id);
        Test.stopTest();
    }


    private static void createAttachment(String caseId, String attachmentCategory,String name){
       
        NoteOrAttachment__c responseCustomAttachment;

        responseCustomAttachment = new NoteOrAttachment__c();
        responseCustomAttachment.Name = name;
        responseCustomAttachment.ContentType__c = 'application/msword';
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
    
    /*------------------------------------------------------------------- ----------------
    Author:        
    Description:   This method creates a transport case record sobject
    -----------------------------------------------------------------------------------*/
    private static Case getTransportCaseRecord() {
    
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
    
    
    private static void CreateEntitlement() {
     
     Account testAccount = new Account(name='Test Company Name');
     insert testAccount;
       
     Entitlement testEntitlement = new Entitlement();
     testEntitlement.Name = testAccount.name;
     testEntitlement.StartDate = System.Today();
     testEntitlement.AccountId = testAccount.Id;
     
     insert testEntitlement;
      
     // Verify that the entitlment was created in the database.
     Entitlement NewEntitlement = [SELECT AccountId FROM Entitlement WHERE Name = :testAccount.Name];
     System.assertEquals(testAccount.ID, NewEntitlement.AccountId);
    }

}