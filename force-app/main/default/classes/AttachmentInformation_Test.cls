@isTest
private class AttachmentInformation_Test {
    
    
    @testSetup
    static void setUpCase(){
        setupCaseRecTypesToExcludeCS();

        Contact newContact = new Contact();
        newContact.LastName = 'Test';
        newContact.Email = 'test@test.com';
        newContact.Phone = '1234234';
        insert newContact;

        Case transportCase1 = getTransportCaseRecord();
        
        transportCase1.OBO__c = newContact.Id;

        Case transportCase2 = getTransportCaseRecord();
       
        transportCase2.OBO__c = newContact.Id;
        insert new List<Case>{transportCase1, transportCase2};

        PreviousCorro_Document_Count__c setting = new PreviousCorro_Document_Count__c();
        setting.Name = 'Previous Corro';
        setting.Count__c = 3;
        insert setting;

    }
        
    @isTest static void getIncomingAttachmentTest() {

        Test.startTest();
        List<Case> getCase = [Select Id FROM Case LIMIT 1];
        
        if(getCase.size() > 0){
            createAttachment(getCase[0].Id, GlobalConstants.INCOMING,'Incoming PDF');
            Map<Id,AttachmentInfo> attachmentMap;
            attachmentMap = AttachmentInformation.getIncomingAttachment(getCase[0].Id,GlobalConstants.INCOMING);
            System.assertEquals(1,attachmentMap.size());
        }
        Test.stopTest();
    }

    @isTest static void getAdviceAttachmentTest() {

        Test.startTest();
        List<Case> getCase = [Select Id FROM Case LIMIT 1];
        if(getCase.size() > 0){
            createAttachment(getCase[0].Id, GlobalConstants.ATTACHMENT_CATEGORY_ADVICE,'APN123');
            createAttachment(getCase[0].Id, '','Advice');

            Map<Id,AttachmentInfo> attachmentMap;
            attachmentMap = AttachmentInformation.getAdviceAttachment(getCase[0].Id);
            System.assertEquals(1,attachmentMap.size());
            attachmentMap = AttachmentInformation.getAdviceAttachment(getCase[0].Id);
            System.assertEquals(1,attachmentMap.size());
        }
        Test.stopTest();
    }

    @isTest static void getPrecedentAttachmentTest() {

        Test.startTest();
        List<Case> getCase = [Select Id FROM Case LIMIT 2];
        if(getCase.size() > 0){
    
            createAttachment(getCase[0].Id, GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE,'Signed Response');
            
            Precedent__c precdentCase = new Precedent__c();
            precdentCase.Related_Case__c = getCase[1].Id;
            precdentCase.Precedent_Case__c = getCase[0].Id;
            insert precdentCase;

            Map<Id,AttachmentInfo> attachmentMap;
            attachmentMap = AttachmentInformation.getPrecedentAttachment(getCase[1].Id);
            System.assertEquals(1,attachmentMap.size());
        }
        Test.stopTest();
    }

    @isTest static void getPreviousCorroAttachmentTest() {
        Test.startTest();
        List<Case> getCase = [Select Id FROM Case ORDER BY CreatedDate DESC LIMIT 2];
        if(getCase.size() > 0){
    
            createAttachment(getCase[0].Id, GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE,'Signed Response');
            createAttachment(getCase[1].Id, GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE,'Signed Response');
            
            Map<Id,AttachmentInfo> attachmentMap;
            attachmentMap = AttachmentInformation.getPreviousCorroAttachment(getCase[0].Id);
            System.assertEquals(1,attachmentMap.size());
        }
        Test.stopTest();
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
    
}