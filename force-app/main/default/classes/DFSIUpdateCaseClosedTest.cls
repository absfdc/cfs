@isTest
global class DFSIUpdateCaseClosedTest {

	@testSetup
	static void init() {
		DFSIEndpoint__c csCred = new DFSIEndpoint__c(Name = 'DFSI', DFSINamedCred__c = 'xxx');
		DFSIEndpoint__c cs = new DFSIEndpoint__c(Name = 'GET_ATTACHMENTS_DATA', DFSIMethodURL__c = 'yyy');
		DFSIEndpoint__c cs2 = new DFSIEndpoint__c(Name = 'getCases', DFSIMethodURL__c = 'zzz');
		//DFSIEndpoint__c cs3 = new DFSIEndpoint__c(Name = 'CreateCase', DFSIMethodURL__c = 'xyz');
		
		insert new List<DFSIEndpoint__c>{csCred, cs, cs2};
		
		DFSIScheduledJobRun__c jobSetting = new DFSIScheduledJobRun__c(Name='DFSI', LastJobEndTime__c = Datetime.now());
		insert jobSetting;
		

	}

	static void createCustomSettingForCallout()
	{
		DFSIEndpoint__c cs3 = new DFSIEndpoint__c(Name = 'CreateCase', DFSIMethodURL__c = 'xyz');
		insert cs3;

		DFSI_Case_Owner_And_RecordType_Ids__c DFSIMapping1 = new DFSI_Case_Owner_And_RecordType_Ids__c(Name = 'RMS',Owner_Id__c ='00G0K000003IDjYUAW', RecordTypeId__c='0120K000000iyelQAA');
		DFSI_Case_Owner_And_RecordType_Ids__c DFSIMapping2 = new DFSI_Case_Owner_And_RecordType_Ids__c(Name = 'Transport',Owner_Id__c ='00G0K000003HSSbUAO', RecordTypeId__c='0120K000000ixikQAA');
		insert new List<DFSI_Case_Owner_And_RecordType_Ids__c>{DFSIMapping1, DFSIMapping2};
		
	}
	@isTest
	static void test_CloseCase() {
		
		createCustomSettingForCallout();
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockEmptyService());

		Test.startTest();

		Case c1 = new Case(DFSICaseID__c = 'xxx');
		insert c1;
		
		c1.Status = 'Closed';
		c1.Reason = 'Justified';
		update c1;
		Test.stopTest();
	}
	
	@isTest
	static void test_Negative() {
		createCustomSettingForCallout();
		Case c1 = new Case(DFSICaseID__c = 'xxx');
		insert c1;

		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockExceptionService());

		Test.startTest();

		c1.Status = 'Closed';
		c1.Reason = 'Justified';

		update c1;

		Test.stopTest();

	}
	
	@isTest
	static void test_complaintYes() {
		createCustomSettingForCallout();
		Case c1 = new Case(DFSICaseID__c = 'xxx');
		insert c1;

		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockEmptyService());

		Test.startTest();
		
		c1.type = 'Complaint';
		c1.Status = 'Closed';
		c1.Response_Requested__c = 'Yes˝';

		update c1;

		Test.stopTest();
	}
	
	@isTest
	static void test_complaintNo() {
		createCustomSettingForCallout();
		Case c1 = new Case(DFSICaseID__c = 'xxx');
		insert c1;

		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockEmptyService());

		Test.startTest();
		
		c1.type = 'Complaint';
		c1.Status = 'Closed';
		c1.Response_Requested__c = 'No';

		update c1;

		Test.stopTest();
	}

	@isTest
	static void testInsertCaseFromFAWidgetEnquiry() {
		createCustomSettingForCallout();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		c1.Type = 'Enquiry';
		insert c1;
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidget());
		Test.startTest();
		Test.stopTest();
	}

	@isTest
	static void testInsertCaseFromFAWidgetEnquiryRMSException() {
		
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		c1.Type = 'Enquiry';
		insert c1;
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidget());
		Test.startTest();
		Test.stopTest();
	}


	@isTest
	static void testInsertCaseFromFAWidgetEnquiryException() {
		createCustomSettingForCallout();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		c1.Type = 'Enquiry';
		insert c1;
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidget());
		Test.startTest();
		Test.stopTest();
	}

	@isTest
	static void testInsertCaseFromFAWidgetAgencyRMS() {
		createCustomSettingForCallout();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		c1.Origin_Details__c = 'tfnsw';
		c1.Agency__c = 'RMS';
		insert c1;
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidget());
		Test.startTest();
		Test.stopTest();
	}

	@isTest
	static void testInsertCaseFromFAWidgetOwnerAgencyRMS() {
		createCustomSettingForCallout();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		c1.Origin_Details__c = 'tfnsw';
		c1.OwnerAgency__c = 'RMS';
		c1.Description = 'This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test This is test ';
		insert c1;
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidget());
		Test.startTest();
		Test.stopTest();
	}

	@isTest
	static void testInsertCaseFromFAWidgetOriginDetailsRMSWebsite() {
		createCustomSettingForCallout();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		c1.Origin_Details__c = 'RMS Website';
		c1.OwnerAgency__c = 'RMS';
		c1.Description = 'This is test';
		insert c1;
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidget());
		Test.startTest();
		Test.stopTest();
	}
	
	@isTest
	static void testInsertCaseFromFAWidgetOwnerAgencyNonRMS() {
		createCustomSettingForCallout();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		c1.Origin_Details__c = 'tfnsw';
		c1.OwnerAgency__c = 'xyz';
		insert c1;
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidget());
		Test.startTest();
		Test.stopTest();

	}


	@isTest
	static void testInsertCaseFromFAWidgetWithIncorrectRefId() {
		createCustomSettingForCallout();
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidgetWithIncorrectReferenceId());
		Test.startTest();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		insert c1;
		Test.stopTest();
	}
	
	@isTest
	static void testInsertCaseFromFAWidgetWithIncorrectRefIdAndStatusCode() {
		createCustomSettingForCallout();
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidgetWithIncorrectReferenceIdAndStatusCode());
		Test.startTest();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		insert c1;
		Test.stopTest();

	}
	@isTest
	static void testInsertCaseFromFAWidgetWithIncorrectJSONResponse() {
		createCustomSettingForCallout();
		Test.setMock(HttpCalloutMock.class, new DFSIFeedbackAssistTest.MockServiceForFAWidgetWithIncorrectJSON());
		Test.startTest();
		Case c1 = new Case();
		c1.isFeedbackAssist__c = true;
		insert c1;
		Test.stopTest();

	}
	
	@isTest
	static void testFASendCasesToDFSIAfterInsertException() {
		FASendCasesToDFSIAfterInsert obj = new FASendCasesToDFSIAfterInsert();
		obj.SendCasesToDFSI(null);
	}
	

}