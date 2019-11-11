@isTest
public class MockCaseAttachmentService implements CaseAttachmentService {

	Boolean throwException;
	Boolean throwExceptionMeta;

	public MockCaseAttachmentService() {
		this(false, false);
	}

	public MockCaseAttachmentService(Boolean throwExceptionMeta, Boolean throwException) {
		this.throwException = throwException;
		this.throwExceptionMeta = throwExceptionMeta;
	}

	//return  Map of External Id against Attachment for all attachments of the case
	public Map<String, Attachment> getAttachments(Case scope){
		if(throwException)
			throw new DFSIException('Test Exception');

		Map<String, Attachment> allAttachmentsMap = new Map<String, Attachment>();

		Attachment a1 = new Attachment(Name = 'A1', Body=Blob.valueOf('This is Test'));
		Attachment a2 = new Attachment(Name = 'A2', Body=Blob.valueOf('This is Test'));
		Attachment a3 = new Attachment(Name = 'A3', Body=Blob.valueOf('This is Test'));
		Attachment a4 = new Attachment(Name = 'A4', Body=Blob.valueOf('This is Test'));
		Attachment a5 = new Attachment(Name = 'A5', Body=Blob.valueOf('This is Test'));
		Attachment a6 = new Attachment(Name = 'A6', Body=Blob.valueOf('This is Test'));

		if(scope.DFSICaseID__c == 'xxx') {
			allAttachmentsMap.put('aaa', a1);
			allAttachmentsMap.put('ddd', a4);
			allAttachmentsMap.put('eee', a5);
		} else if(scope.DFSICaseID__c == 'yyy') {
			allAttachmentsMap.put('bbb', a2);
			allAttachmentsMap.put('fff', a6);
		} else if(scope.DFSICaseID__c == 'zzz') {
			allAttachmentsMap.put('ccc', a3);
		} else {
			System.assertEquals(1, 2 , 'Valid DFSI Case Id not recieved');
		}

		return allAttachmentsMap;
	}

	// return Map of External Case Id against Note or attachment for all attachments of the cases list
	public Map<String, List<NoteOrAttachment__c>> getAttachmentMetadata(List<Case> cases){

		if(throwExceptionMeta)
			throw new DFSIException('Test Exception');

		System.assertEquals(1, cases.size(), 'The called must send exactly 3 cases');

		Map<String, List<NoteOrAttachment__c>> noteAndAttachmentsMap = new Map<String, List<NoteOrAttachment__c>>();
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
		noteAndAttachmentsMap.put(cases.get(0).DFSICaseID__c, aList);
		//noteAndAttachmentsMap.put(cases.get(1).DFSICaseID__c, bList);
		//noteAndAttachmentsMap.put(cases.get(2).DFSICaseID__c, cList);

		return noteAndAttachmentsMap;
	}
	
}