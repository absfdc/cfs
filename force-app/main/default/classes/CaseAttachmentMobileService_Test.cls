/*------------------------------------------------------------------------
Author:        Deepak Soni
Company:       Arxxus Technology Partners
Description:   A test class created to validate the CaseAttachmentMobileService Rest service
               
               Tests executed:
               1 - unitTest()
               Test the API post method.

History
<Date>      <Authors Name>     	<Brief Description of Change>
25/02/2016  Deepak Soni     	Implemented Rest API service Test class
----------------------------------------------------------------------------*/

@isTest
private class CaseAttachmentMobileService_Test {

	@testSetup static void setupTestData() {
		// populate data for Public Site Domain Name custom setting
		List<SObject> publicSiteDomainName = Test.loadData(PublicSiteDomainName__c.SObjectType, 'PublicSiteDomainName');
		System.assertEquals(publicSiteDomainName.size() > 0, true);
	}
	
	@isTest static void unitTest() {
		// Implement test code
		RestRequest req = new RestRequest(); 
	    RestResponse res = new RestResponse();

	    PublicSiteDomainName__c psdn = PublicSiteDomainName__c.getValues('Site URL');
	    String domainName = psdn.Domain_Name__c;

	    // pass the req and resp objects to the method     
	    //req.requestURI = 'https://appdev-tfnsw.cs5.force.com/feedback/services/apexrest/cfm/v1/addAttachment';  
	    req.requestURI = domainName + 'feedback/services/apexrest/cfm/v1/addAttachment';
	    req.httpMethod = 'POST';

	    RestContext.request = req;
    	RestContext.response = res;

    	// Negative Testing
    	// Covers NO guid found
	    CaseAttachmentMobileService.ResponseWrapper result = CaseAttachmentMobileService.doPost();

	    System.assertEquals(false, result.success);


    	// Covers No File Name found
	    String guid = '32bf965c-7b64-96d1-eb70-e5c6ef4a14cb';

	    req.addParameter('guid', guid);

	    result = CaseAttachmentMobileService.doPost();

	    System.assertEquals(false, result.success);


	    // Covers exception block
	    req.addParameter('filename', 'Test Image.jpeg');

	    req.addHeader('Content-Type', 'application/json; charset=UTF-8');

	    req.requestBody = Blob.valueOf(JSON.serialize('Test image'));

	    result = CaseAttachmentMobileService.doPost();

	    System.assertEquals(false, result.success);

	    // Positive Testing
	    String multiIssueRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE).getRecordTypeId();

	    Case newCase = new Case();
	    newCase.RecordTypeId = multiIssueRecordTypeId;
	    newCase.GUID__c = guid;
	    insert newCase;

	    req.addParameter('createdDateTime', String.valueOf(Datetime.now().getTime()));

	    result = CaseAttachmentMobileService.doPost();

	    System.assertEquals(true, result.success);
	    System.assertEquals(guid, result.guid);
	}
	
}