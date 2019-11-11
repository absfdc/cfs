@isTest
private class DraftTriggerDispatcher_Test {
    
    @testSetup static void setup() {
        RecordType GMCorrespondence = [Select Id From RecordType Where DeveloperName =: GlobalConstants.MIN_CORRO_RECTYPE_API_NAME limit 1];
    	Case parent =new Case(Subject = 'parent',
                              Description = 'Theres a parent in the east street, west end crossing in front of busstop',
                              Status = 'New',
                              Agency__c = 'Agency1',
                              Modes__c= 'Multi-Issue',
                              RecordTypeId =  GMCorrespondence.Id);  
        
        TH1__Draft__c draft = new TH1__Draft__c();
        draft.TH1__Allow_Storage_Name_Change__c=true;
        draft.TH1__Draft_name__c = 'Draft - Acknowledgement';
        draft.TH1__Draft_XML_Attachment_Id__c='00PO0000003HFsMMAW';
        draft.TH1__Email_attachments_saved__c=true;
        draft.TH1__Approval_Required__c=true;
        draft.TH1__Revise_Rights__c=false;
        draft.TH1__Status__c= 'Draft';
        draft.Status__c= 'Draft Response in Progress';
        draft.TH1__Storage_Info_Saved__c =true;
        draft.TH1__Storage_Name__c = 'Acknowledgement';
        draft.Submited_For_Approval__c = false;
        
        system.runAs(new User(Id = Userinfo.getUserId())) {
            insert parent;
            draft.Related_Lookup_Case__c = draft.TH1__Primary_Object_Record_Id__c = parent.Id;
            insert draft;
        }
    }
    
    static testMethod void submittedForApprovalTest() {
        Case caseRecord = [Select Id From Case limit 1];
        TH1__Draft__c draft = [Select Id, OwnerId, Submited_For_Approval__c From TH1__Draft__c limit 1];
        User magsUser = RetrieveNextUtils_WS_Test.createTestUser('MAGS Officer', 'MAGS_Officer');
        system.runAs(new User(Id = Userinfo.getUserId())) {
        	draft.OwnerId = magsUser.Id;
            update draft;
        }
        
        system.runAs(magsUser) {
            draft.Submited_For_Approval__c = true;
            update draft;
            Test.startTest();
            TH1__Draft__c draft1 = [Select Id, OwnerId, Status__c, Submited_For_Approval__c From TH1__Draft__c Where Id =: draft.Id];
            system.assertEquals('Senior Review', draft1.Status__c);
            Test.stopTest();
        }
    }
    
    static testMethod void backupXMLTest() {
        Case caseRecord = [Select Id From Case limit 1];
        TH1__Draft__c draft = [Select Id, OwnerId, Submited_For_Approval__c From TH1__Draft__c limit 1];
        
        Attachment attach = new Attachment();    
        attach.Name = 'Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA';
        Blob bodyBlob = Blob.valueOf('Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA_{{IMAGE:CASE_SIGNATURE_IMAGE_URL:W=300:H=100}}__');
        attach.body = bodyBlob;
        attach.parentId = caseRecord.Id;
        insert attach;
        Attachment attach2 = new Attachment();    
        attach2.Name = 'Draft_XML';
        bodyBlob = Blob.valueOf('Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA_{{IMAGE:CASE_SIGNATURE_IMAGE_URL:W=300:H=100}}__');
        attach2.body = bodyBlob;
        attach2.parentId = caseRecord.Id;
        insert attach2;
        
        draft.TH1__Draft_XML_Attachment_Id__c = attach2.Id;
        update draft;
        
        new DraftAfterUpdateTriggerHandler().backupDraftXML(new List<TH1__Draft__c>{draft}, new List<Id>{caseRecord.Id}, new List<Id>{attach.Id} );
    }
    
    static testMethod void errorTest() {
        DraftAfterUpdateTriggerHandler h1 = new DraftAfterUpdateTriggerHandler();
        DraftBeforeUpdateTriggerHandler h2 = new DraftBeforeUpdateTriggerHandler();
        h1.mainEntry(null);
        h2.mainEntry(null);
        list <Application_Log__c> logs = [Select Id from Application_Log__c];
        system.assert(logs !=null);
    }
}