@isTest
private class DFSISyncCaseAttachmentsTest
{
	
	@testSetup
	static void init() {
		DFSI_Case_Owner_And_RecordType_Ids__c DFSIMapping1 = new DFSI_Case_Owner_And_RecordType_Ids__c(Name = 'RMS',Owner_Id__c ='00G0K000003IDjYUAW', RecordTypeId__c='0120K000000iyelQAA');
		DFSI_Case_Owner_And_RecordType_Ids__c DFSIMapping2 = new DFSI_Case_Owner_And_RecordType_Ids__c(Name = 'Transport',Owner_Id__c ='00G0K000003HSSbUAO', RecordTypeId__c='0120K000000ixikQAA');
		insert new List<DFSI_Case_Owner_And_RecordType_Ids__c>{DFSIMapping1, DFSIMapping2};
	}
	
	
	@isTest
	static void testService() {

		DFSISyncCaseAttachments instance = new DFSISyncCaseAttachments();
		System.assertNotEquals(null, instance.getAttachmentService());

	}

	@isTest
	static void test_populateParentId() {
		Map<String, Attachment> allAttachmentsMap = new Map<String, Attachment>();
		Map<String, NoteOrAttachment__c> allNoteAndAttachmentsMap = new Map<String, NoteOrAttachment__c>();

		Attachment att1 = new Attachment();
		Attachment att2 = new Attachment();
		Attachment att3 = new Attachment();

		allAttachmentsMap.put('xxx', att1);
		allAttachmentsMap.put('yyy', att2);
		allAttachmentsMap.put('zzz', att3);

		NoteOrAttachment__c na1 = new NoteOrAttachment__c(Id = DFSITestDataFactory.getFakeId(NoteOrAttachment__c.sObjectType));
		NoteOrAttachment__c na2 = new NoteOrAttachment__c(Id = DFSITestDataFactory.getFakeId(NoteOrAttachment__c.sObjectType));
		NoteOrAttachment__c na3 = new NoteOrAttachment__c(Id = DFSITestDataFactory.getFakeId(NoteOrAttachment__c.sObjectType));

		//insert new List<NoteOrAttachment__c>{na1, na2, na3};

		allNoteAndAttachmentsMap.put('xxx', na1);
		allNoteAndAttachmentsMap.put('yyy', na2);
		allNoteAndAttachmentsMap.put('zzz', na3);

		DFSISyncCaseAttachments instance = new DFSISyncCaseAttachments();
		instance.populateParentId(allAttachmentsMap, allNoteAndAttachmentsMap);

		System.assertEquals(na1.Id, att1.ParentId);
		System.assertEquals(na2.Id, att2.ParentId);
		System.assertEquals(na3.Id, att3.ParentId);

	}

	@isTest
	static void test_getAllNotesAndAttachments() {
		NoteOrAttachment__c na1 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'aaa', Name = 'NA 1');
		NoteOrAttachment__c na2 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'bbb', Name = 'NA 2');
		NoteOrAttachment__c na3 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'ccc', Name = 'NA 3');
		NoteOrAttachment__c na4 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'ddd', Name = 'NA 4');
		NoteOrAttachment__c na5 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'eee', Name = 'NA 5');
		NoteOrAttachment__c na6 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'fff', Name = 'NA 6');

		List<NoteOrAttachment__c> aList = new List<NoteOrAttachment__c>{na1, na4, na5};
		List<NoteOrAttachment__c> bList = new List<NoteOrAttachment__c>{na2, na6};
		List<NoteOrAttachment__c> cList = new List<NoteOrAttachment__c>{na3};

		// Map of external case Id and List of Attachments
		Map<String, List<NoteOrAttachment__c>> noteAndAttachmentsMap = new Map<String, List<NoteOrAttachment__c>>();
		noteAndAttachmentsMap.put('xxx', aList);
		noteAndAttachmentsMap.put('yyy', bList);
		noteAndAttachmentsMap.put('zzz', cList);

		DFSISyncCaseAttachments instance = new DFSISyncCaseAttachments();
		Map<String, NoteOrAttachment__c> allAttachmentsMap = instance.getAllNotesAndAttachments(noteAndAttachmentsMap);

		System.assertEquals('NA 1', allAttachmentsMap.get('aaa').Name);
		System.assertEquals('NA 2', allAttachmentsMap.get('bbb').Name);
		System.assertEquals('NA 3', allAttachmentsMap.get('ccc').Name);
		System.assertEquals('NA 4', allAttachmentsMap.get('ddd').Name);
		System.assertEquals('NA 5', allAttachmentsMap.get('eee').Name);
		System.assertEquals('NA 6', allAttachmentsMap.get('fff').Name);

	}

	@isTest
	static void test_populateValues() {
		Map<String, Case> caseMap = new Map<String, Case>();
		Map<String, List<NoteOrAttachment__c>> noteAndAttachmentsMap = new Map<String, List<NoteOrAttachment__c>>();
		Map<String, Attachment> allAttachmentsMap = new Map<String, Attachment>();

		Case c1 = new Case(Subject = 'C1', Id = DFSITestDataFactory.getFakeId(Case.sObjectType));
		Case c2 = new Case(Subject = 'C1', Id = DFSITestDataFactory.getFakeId(Case.sObjectType));
		Case c3 = new Case(Subject = 'C1', Id = DFSITestDataFactory.getFakeId(Case.sObjectType));

		caseMap.put('xxx', c1);
		caseMap.put('yyy', c2);
		caseMap.put('zzz', c3);


		NoteOrAttachment__c na1 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'aaa', Name = 'NA 1');
		NoteOrAttachment__c na2 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'bbb', Name = 'NA 2');
		NoteOrAttachment__c na3 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'ccc', Name = 'NA 3');
		NoteOrAttachment__c na4 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'ddd', Name = 'NA 4');
		NoteOrAttachment__c na5 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'eee', Name = 'NA 5');
		NoteOrAttachment__c na6 = new NoteOrAttachment__c(DFSIAttachmentId__c = 'fff', Name = 'NA 6');

		List<NoteOrAttachment__c> aList = new List<NoteOrAttachment__c>{na1, na4, na5};
		List<NoteOrAttachment__c> bList = new List<NoteOrAttachment__c>{na2, na6};
		List<NoteOrAttachment__c> cList = new List<NoteOrAttachment__c>{na3};

		// Map of external case Id and List of Attachments
		noteAndAttachmentsMap.put('xxx', aList);
		noteAndAttachmentsMap.put('yyy', bList);
		noteAndAttachmentsMap.put('zzz', cList);

		Attachment a1 = new Attachment(Name = 'A1', Id = DFSITestDataFactory.getFakeId(Attachment.sObjectType));
		Attachment a2 = new Attachment(Name = 'A2', Id = DFSITestDataFactory.getFakeId(Attachment.sObjectType));
		Attachment a3 = new Attachment(Name = 'A3', Id = DFSITestDataFactory.getFakeId(Attachment.sObjectType));
		Attachment a4 = new Attachment(Name = 'A4', Id = DFSITestDataFactory.getFakeId(Attachment.sObjectType));
		Attachment a5 = new Attachment(Name = 'A5', Id = DFSITestDataFactory.getFakeId(Attachment.sObjectType));
		Attachment a6 = new Attachment(Name = 'A6', Id = DFSITestDataFactory.getFakeId(Attachment.sObjectType));

		allAttachmentsMap.put('aaa', a1);
		allAttachmentsMap.put('bbb', a2);
		allAttachmentsMap.put('ccc', a3);
		allAttachmentsMap.put('ddd', a4);
		allAttachmentsMap.put('eee', a5);
		allAttachmentsMap.put('fff', a6);

		DFSISyncCaseAttachments instance = new DFSISyncCaseAttachments();
		instance.populateValues(caseMap, noteAndAttachmentsMap, allAttachmentsMap);

		System.assertEquals(na1.Case__c, c1.Id);
		System.assertEquals(na4.Case__c, c1.Id);
		System.assertEquals(na5.Case__c, c1.Id);
		System.assertEquals(na2.Case__c, c2.Id);
		System.assertEquals(na6.Case__c, c2.Id);
		System.assertEquals(na3.Case__c, c3.Id);


		System.assertEquals(na1.Attachment__c, a1.Id);
		System.assertEquals(na2.Attachment__c, a2.Id);
		System.assertEquals(na3.Attachment__c, a3.Id);
		System.assertEquals(na4.Attachment__c, a4.Id);
		System.assertEquals(na5.Attachment__c, a5.Id);
		System.assertEquals(na6.Attachment__c, a6.Id);
	}

	@isTest
	static void test_Batch() {
		Case c1 = new Case(DFSICaseID__c = 'xxx', DFSI_Attachment_Synced__c = false);
		Case c2 = new Case(DFSICaseID__c = 'yyy', DFSI_Attachment_Synced__c = false);
		Case c3 = new Case(DFSICaseID__c = 'zzz', DFSI_Attachment_Synced__c = false);

		//insert new List<Case>{c1, c2, c3};
		insert c3;
		Test.startTest();

		DFSISyncCaseAttachments instance = new DFSISyncCaseAttachments();
		instance.attachmentService = new MockCaseAttachmentService();
		instance.startBatch();

		Test.stopTest();

	}

	@isTest
	static void test_Negative() {
		Case c1 = new Case(DFSICaseID__c = 'xxx', DFSI_Attachment_Synced__c = false);
		insert c1;

		GlobalConstants.THROW_EXCEPTIONS = false;

		DFSISyncCaseAttachments instance = new DFSISyncCaseAttachments();
		instance.attachmentService = new MockCaseAttachmentService(true, true);

		Test.startTest();
		instance.startBatch();
		Test.stopTest();

	}

	@isTest
	static void test_Negative2() {
		Case c1 = new Case(DFSICaseID__c = 'xxx', DFSI_Attachment_Synced__c = false);
		Case c2 = new Case(DFSICaseID__c = 'yyy', DFSI_Attachment_Synced__c = false);
		Case c3 = new Case(DFSICaseID__c = 'zzz', DFSI_Attachment_Synced__c = false);
		//insert new List<Case>{c1, c2, c3};
		insert c3;
		GlobalConstants.THROW_EXCEPTIONS = false;

		DFSISyncCaseAttachments instance = new DFSISyncCaseAttachments();
		instance.attachmentService = new MockCaseAttachmentService(false, true);

		Test.startTest();
		instance.startBatch();
		Test.stopTest();

	}
}