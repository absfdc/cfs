@isTest
private class DraftApprovalProcess_CX_Test {
     
    @testSetup static void setup() {
        RecordType GMCorrespondence = [Select Id From RecordType Where DeveloperName =: GlobalConstants.MIN_CORRO_RECTYPE_API_NAME limit 1];
        Case parent =new Case(Subject = 'parent',
                              Description = 'Theres a parent in the east street, west end crossing in front of busstop',
                              Status = 'New',
                              Agency__c = 'Agency1',
                              Modes__c= 'MAGS',
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
            parent.Portfolio__c = GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT;
            update parent;
            
            draft.Related_Lookup_Case__c = draft.TH1__Primary_Object_Record_Id__c = parent.Id;
            insert draft;
        }
    }
    
    static testMethod void submittedForApprovaTest() {
        User magsUser = RetrieveNextUtils_WS_Test.createTestUser('MAGS Officer', 'MAGS_Officer');
        TH1__Draft__c draft;
        system.runAs(new User(Id = Userinfo.getUserId())) {
            draft = [Select Id, OwnerId, Submited_For_Approval__c From TH1__Draft__c limit 1];
            draft.OwnerId = magsUser.Id; 
            update draft;
        }
        
        System.runAs(magsUser) {
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(draft.id);
            Approval.ProcessResult result = Approval.process(req1);
            System.debug('-----------Result---------' + result);
        }
        
        Test.startTest();
        TH1__Draft__c draft1 = [Select Id,Status__c, OwnerId, Submited_For_Approval__c From TH1__Draft__c Where Id =: draft.Id limit 1];
        system.assertEquals('Senior Review', draft1.Status__c);
        PageReference pRef = Page.DraftApprovalRequest;
        ApexPages.StandardController std_controller = new ApexPages.StandardController(draft1);
        DraftApprovalProcess_CX controller =  new DraftApprovalProcess_CX(std_controller);
        controller.init();
        Case caseRecord  = [Select Id, Status From Case limit 1];
        system.assertEquals('Senior Review', caseRecord.Status);
        Test.stopTest();
     }

     static testMethod void initTest() {
        TH1__Draft__c draft = [Select Id, OwnerId, Submited_For_Approval__c From TH1__Draft__c limit 1];
        PageReference pRef = Page.DraftApprovalRequest;
        ApexPages.StandardController std_controller = new ApexPages.StandardController(draft);
        draft.Id = null;
         boolean error = false;
         try {
             DraftApprovalProcess_CX controller =  new DraftApprovalProcess_CX(std_controller);
             controller.init();
             controller.approve();
         }catch(Exception e) {
            error = true;
         }
        System.assert(error);
     }
}