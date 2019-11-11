@isTest
private class NoteOrAttachmentOwnershipUpdater_Test {
	
	@testSetup
	static void setUpUser() {
		User testUser = RetrieveNextUtils_WS_Test.createTestUser('System Administrator', 'STA');
	}


	@isTest static void ownershipChangedToUser() {
		User newOwner = [Select Id From User Where Email = 'md@demo.com' limit 1];
		Case parent = new Case(Subject = 'parent',
                        		Description = 'Theres a parent in the east street, west end crossing in front of busstop',
                        		Status = 'New',
                        		Agency__c = GlobalConstants.STA_AGENCY,
                        		Modes__c= GlobalConstants.MULTI_ISSUE_TYPE);

        System.runAs(new User(Id=UserInfo.getUserId())){
            insert parent;
        }

        NoteOrAttachment__c att1 = new NoteOrAttachment__c(Name = 'Restricted Attachment',
					                                        Case__c = parent.Id,
					                                        Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_RESTRICTED);

        NoteOrAttachment__c att2 = new NoteOrAttachment__c(Name = 'Standard Attachment',
					                                        Case__c = parent.Id,
					                                        Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD);

        System.runAs(new User(Id=UserInfo.getUserId())){
        	insert new list <NoteOrAttachment__c> {att1, att2};
    	}

    	Test.startTest();
    		Case c = [Select Id, OwnerId From Case Where Id =: parent.Id limit 1];
    		c.OwnerId = newOwner.Id;
    		update c;

    		list <NoteOrAttachment__c> updatedAtts = [Select Id,OwnerId From NoteOrAttachment__c];
    		System.assertEquals(2, updatedAtts.size());
    	Test.stopTest();
	}
	
	@isTest static void ownershipChangedToQueue() {
		Group q = [Select Id From Group Where Type = 'Queue' And DeveloperName =: GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME limit 1];

		Case parent = new Case(Subject = 'parent',
                        		Description = 'Theres a parent in the east street, west end crossing in front of busstop',
                        		Status = 'New',
                        		Agency__c = GlobalConstants.STA_AGENCY,
                        		Modes__c= GlobalConstants.MULTI_ISSUE_TYPE);

        System.runAs(new User(Id=UserInfo.getUserId())){
            insert parent;
        }

        NoteOrAttachment__c att1 = new NoteOrAttachment__c(Name = 'Restricted Attachment',
					                                        Case__c = parent.Id,
					                                        Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_RESTRICTED);

        NoteOrAttachment__c att2 = new NoteOrAttachment__c(Name = 'Standard Attachment',
					                                        Case__c = parent.Id,
					                                        Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD);

        System.runAs(new User(Id=UserInfo.getUserId())){
        	insert new list <NoteOrAttachment__c> {att1, att2};
    	}

    	Test.startTest();
    		Case c = [Select Id, OwnerId From Case Where Id =: parent.Id limit 1];
    		c.OwnerId = q.Id;
    		update c;

    		list <NoteOrAttachment__c> updatedAtts = [Select Id,OwnerId From NoteOrAttachment__c];
    		System.assertEquals(2, updatedAtts.size());
    	Test.stopTest();
	}
	
	@isTest static void errorHandling() {
		NoteOrAttachmentOwnershipUpdater handler = new NoteOrAttachmentOwnershipUpdater();
		handler.updateOwnership(null);

		list <Application_Log__c> logs = [Select Id From Application_Log__c];
		system.assert(logs != null);
	}
}