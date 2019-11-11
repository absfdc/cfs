@isTest
global class DFSIFeedbackAssistTest {

	@testSetup
	static void init() {
		DFSI_Case_Owner_And_RecordType_Ids__c DFSIMapping1 = new DFSI_Case_Owner_And_RecordType_Ids__c(Name = 'RMS',Owner_Id__c ='00G0K000003IDjYUAW', RecordTypeId__c='0120K000000iyelQAA');
		DFSI_Case_Owner_And_RecordType_Ids__c DFSIMapping2 = new DFSI_Case_Owner_And_RecordType_Ids__c(Name = 'Transport',Owner_Id__c ='00G0K000003HSSbUAO', RecordTypeId__c='0120K000000ixikQAA');
		insert new List<DFSI_Case_Owner_And_RecordType_Ids__c>{DFSIMapping1, DFSIMapping2};
		
		DFSIEndpoint__c csCred = new DFSIEndpoint__c(Name = 'DFSI', DFSINamedCred__c = 'xxx');
		DFSIEndpoint__c cs = new DFSIEndpoint__c(Name = 'GET_ATTACHMENTS_DATA', DFSIMethodURL__c = 'yyy');
		DFSIEndpoint__c cs2 = new DFSIEndpoint__c(Name = 'getCases', DFSIMethodURL__c = 'zzz');
		insert new List<DFSIEndpoint__c>{csCred, cs, cs2};
		
		DFSIScheduledJobRun__c jobSetting = new DFSIScheduledJobRun__c(Name='DFSI', LastJobEndTime__c = Datetime.now());
		insert jobSetting;

	}

	@isTest
	static void testMetadata() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Case c1 = new Case(DFSICaseID__c = 'xxx', DFSI_Attachment_Synced__c = false);
		Case c2 = new Case(DFSICaseID__c = 'yyy', DFSI_Attachment_Synced__c = false);
		Case c3 = new Case(DFSICaseID__c = 'zzz', DFSI_Attachment_Synced__c = false);
		List<Case> scope = new List<Case>{c1, c2, c3};

		Test.setMock(HttpCalloutMock.class, new MockAttachmentMetaDataService());

		Test.startTest();

		Map<String, List<NoteOrAttachment__c>>  noteAttachmentMap = service.getAttachmentMetadata(scope);

		System.assertEquals(2, noteAttachmentMap.get('xxx').size());
		System.assertEquals(3, noteAttachmentMap.get('yyy').size());
		System.assertEquals(null, noteAttachmentMap.get('zzz'));
		Test.stopTest();

	}

	@isTest
	static void testNgative() {

		Case c1 = new Case(DFSICaseID__c = 'xxx', DFSI_Attachment_Synced__c = false, Id= DFSITestDataFactory.getFakeId(Case.sObjectType));
		Case c2 = new Case(DFSICaseID__c = 'yyy', DFSI_Attachment_Synced__c = false);
		Case c3 = new Case(DFSICaseID__c = 'zzz', DFSI_Attachment_Synced__c = false);
		List<Case> scope = new List<Case>{c1, c2, c3};

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockAttachmentMetaDataServiceError(400));

		Test.startTest();
		try {
			Map<String, List<NoteOrAttachment__c>>  noteAttachmentMap = service.getAttachmentMetadata(scope);
		} catch(DFSIException e) {
			System.assertEquals('Error::{xxx,yyy,zzz}::Test Message', e.getMessage());
		}

		try {
			Map<String, Attachment>  noteAttachmentMap = service.getAttachments(c1);
		} catch(DFSIException e) {
			System.assertEquals('Error::{'+ c1.Id + '}::Test Message', e.getMessage());
		}

		Test.setMock(HttpCalloutMock.class, new MockAttachmentMetaDataServiceError(501));

		try {
			Map<String, List<NoteOrAttachment__c>>  noteAttachmentMap = service.getAttachmentMetadata(scope);
		} catch(DFSIException e) {
			System.assertEquals('Error::{xxx,yyy,zzz}::501 Test Status', e.getMessage());
		}

		try {
			Map<String, Attachment>  noteAttachmentMap = service.getAttachments(c1);
		} catch(DFSIException e) {
			System.assertEquals('Error::{'+ c1.Id + '}::501 Test Status', e.getMessage());
		}

		Test.stopTest();
	}

	@isTest
	static void testNegative2() {


		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Case c1 = new Case(DFSICaseID__c = 'xxx', DFSI_Attachment_Synced__c = false);
		Case c2 = new Case(DFSICaseID__c = 'yyy', DFSI_Attachment_Synced__c = false);
		Case c3 = new Case(DFSICaseID__c = 'zzz', DFSI_Attachment_Synced__c = false);
		List<Case> scope = new List<Case>{c1, c2, c3};

		Test.setMock(HttpCalloutMock.class, new MockEmptyService());

		Test.startTest();

		Map<String, List<NoteOrAttachment__c>>  noteAttachmentMap = service.getAttachmentMetadata(scope);

		System.assertEquals(null, noteAttachmentMap);


		Map<String, Attachment>  attachmentMap = service.getAttachments(c1);

		System.assertEquals(null, attachmentMap);

		Test.setMock(HttpCalloutMock.class, new MockErrorService());

		DFSIFeedbackAssist.getDFSICases(Datetime.now());

		Test.setMock(HttpCalloutMock.class, new MockExceptionService());

		DFSIFeedbackAssist.getDFSICases(Datetime.now());

		Test.stopTest();
	}


	@isTest
	static void testAttachments() {


		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Case c1 = new Case(DFSICaseID__c = 'xxx', DFSI_Attachment_Synced__c = false);
		
		Test.setMock(HttpCalloutMock.class, new MockAttachmentService());

		Test.startTest();

		Map<String, Attachment>  attachmentMap = service.getAttachments(c1);

		System.assertEquals('Test Name', attachmentMap.get('xxx').Name);
		System.assertEquals('Test Name 2', attachmentMap.get('yyy').Name);
		Test.stopTest();

	}

	@isTest
	static void testCases() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseService());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesNoSuppliedName() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceNoSuppliedName());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesLongLastName() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceLongLastName());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesParseException() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceParse());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(0, cases.size());

	}

	@isTest
	static void testCasesNullAttachments1() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceNullAttachments1());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesNullAttachmentsRMS() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceNullAttachmentsRMS());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesLongFirstName() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceLongFirstName());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesLongName() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceLongName());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesMiddleName() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceMiddleName());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	@isTest
	static void testCasesNameNotProvided() {

		DFSIFeedbackAssist service = new DFSIFeedbackAssist();

		Test.setMock(HttpCalloutMock.class, new MockCaseServiceNameNotProvided());
		
		Test.startTest();
		DFSIFeedbackAssist.getDFSICases(Datetime.now());
		Test.stopTest();

		List<Case> cases = [Select Id from Case];

		System.assertEquals(1, cases.size());

	}

	global class MockAttachmentMetaDataService implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIAttachmentMetadataTest.jsonString);
	        res.setStatusCode(200);
	        return res;
	    }
	}
	
	global class MockServiceForFAWidget implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(FAParseJSONTest.createJSONString());
	        res.setStatusCode(201);
	        return res;
	    }
	}

	global class MockServiceForFAWidgetWithIncorrectReferenceId implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(FAParseJSONTest.createJSONStringWithIncorrectId());
	        res.setStatusCode(201);
	        return res;
	    }
	}

	global class MockServiceForFAWidgetWithIncorrectReferenceIdAndStatusCode implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(FAParseJSONTest.createJSONStringWithIncorrectId());
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockServiceForFAWidgetWithIncorrectJSON implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(FAParseJSONTest.createIncorrectJSONString());
	        res.setStatusCode(201);
	        return res;
	    }
	}

	global class MockEmptyService implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody('');
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockAttachmentMetaDataServiceError implements HttpCalloutMock {

		Integer statusCode; 

		public MockAttachmentMetaDataServiceError(Integer statusCode) {
			this.statusCode = statusCode;
		}

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody('Test Message');
	        res.setStatusCode(statusCode);
	        res.setStatus('Test Status');
	        return res;
	    }
	}

	global class MockAttachmentService implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIAttachmentTest.jsonStr);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseService implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonString);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceNoSuppliedName implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonStringNoName);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceLongLastName implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonStringLongLastName);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceMiddleName implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonStringMiddleName);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceLongName implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonStringLongName);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceNameNotProvided implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonStringNameNotProvided);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceParse implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonParseException);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceNullAttachments1 implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonNullAttachments1);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceNullAttachmentsRMS implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonNullAttachmentsRMS);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockCaseServiceLongFirstName implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(DFSIGetCaseResponseTest.jsonLongFirstName);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockErrorService implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody('{asds}');
	        res.setStatusCode(200);
	        return res;
	    }
	}

	global class MockExceptionService implements HttpCalloutMock {

		global HTTPResponse respond(HTTPRequest req) {
	        throw new DFSIException();
	    }
	}



}