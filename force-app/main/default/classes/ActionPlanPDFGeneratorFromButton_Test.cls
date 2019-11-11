@isTest
private class ActionPlanPDFGeneratorFromButton_Test {
    
    @testSetup 
    static void setUpPermissionSetAssignment() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email = 'standarduser@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u;
        PermissionSet pset = [Select Id From PermissionSet Where Name =: GlobalConstants.PERMISSION_SET_CORRO_OFFICER limit 1];
        insert new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=pset.id);
    }
    
    @isTest static void generatePDFTest() {
        User u = [Select Id From User Where email = 'standarduser@nsw.gov.au.com' limit 1];
        Case caseRecord;
        Action_Plan__c ap;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord; 
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            RecordType rt = [Select Id From RecordType WHere DeveloperName =: GlobalConstants.ACTION_PLAN_MCWS_AP_RECORD_TYPE_NAME];
            ap = new Action_Plan__c(Status__c = 'Action Plan in Review', Parent_Case__c = caseRecord.Id, RecordTypeId = rt.Id);
            insert ap;
        }
        
        System.runAs(u) {
            Test.startTest();
            ap.Approval_Date__c = Date.today();
            ap.Approver_Name__c = 'Abc';
            ap.Approver_Role__c = 'CM';
            ap.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
            ActionPlanAfterUpdateTriggerHandler.firstTimers = null;
            update ap;
            list <NoteOrAttachment__c> newPdfs = [Select Id, ContentType__c From NoteOrAttachment__c Where Case__c =: caseRecord.Id]; 
            system.assertEquals(1, newPdfs.size());
            system.assertEquals('application/pdf', newPdfs[0].ContentType__c);
            String result = ActionPlanPDFGeneratorFromButton.genratePDF(ap.Id);
            system.assertEquals('File generated successfully!\nYou can find the generated pdf in Case Notes & Attachments.',result);
            result = ActionPlanPDFGeneratorFromButton.genratePDF(null);
            system.assertNotEquals('File generated successfully!\nYou can find the generated pdf in Case Notes & Attachments.',result);
            Test.stopTest();
        }
    }
}