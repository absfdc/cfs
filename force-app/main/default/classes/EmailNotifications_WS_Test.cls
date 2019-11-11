@isTest
private class EmailNotifications_WS_Test {
	static testMethod void sendEmailTest() {
        Case caseRecord;
        Action_Plan__c parentAp,childAP;
        Id childActionPlanRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CHILD_AP_RECORDTYPE_API_NAME limit 1].Id;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord;
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	parentAp = new Action_Plan__c(Parent_Case__c = caseRecord.id,
                                  		  Status__c = 'New',
                                          Type__c = 'Advice Request');
            insert parentAp;
            
            childAP = new Action_Plan__c(Parent_Action_Plan__c = parentAp.id,
                                  		 Status__c = 'New',
                                         Type__c = 'Advice Request',
                                         RecordTypeId = childActionPlanRecordTypeId);
            insert childAP;     
            
            Test.startTest();
            system.assertEquals(true,EmailNotifications_WS.notifyCOOnRejectedDueToIncorrectAssignment(childAP.Id));
       		system.assertEquals(true,EmailNotifications_WS.notifyCOWhenSMESubmitsActionPlanForReview(childAP.Id));
            Test.stopTest();
        }
    }
}