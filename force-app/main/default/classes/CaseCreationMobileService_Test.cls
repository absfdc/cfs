/*------------------------------------------------------------------------
Author:        Deepak Soni
Company:       Arxxus Technology Partners
Description:   A test class created to validate the CaseCreationMobileService Rest service
               
               setupTestData()
               Create a Contact to validate the Duplicate Conatct matching criteria related code

               Tests executed:
               1 - unitTest()
               Test the API post method.

History
<Date>      <Authors Name>     	<Brief Description of Change>
25/02/2016  Deepak Soni     	Implemented Rest API service Test class
----------------------------------------------------------------------------*/

@isTest
private class CaseCreationMobileService_Test {
	@testSetup static void setupTestData() {
		// populate data for Public Site Domain Name custom setting
		List<SObject> publicSiteDomainName = Test.loadData(PublicSiteDomainName__c.SObjectType, 'PublicSiteDomainName');

		Contact con = new Contact();
		con.FirstName = 'Jhon';	
		con.LastName = 'Carter';
		con.Email = 'deepak.soni@arxxus.com';
		con.MobilePhone = '0444 444 444';

		insert con;
		FullMatchDuplicateContactRules__c fullDuplicateContactRules = new FullMatchDuplicateContactRules__c();
        fullDuplicateContactRules.Name = 'contactNormalizedMatch';
        insert fullDuplicateContactRules;
		System.assertEquals(publicSiteDomainName.size() > 0, true);
	}


	@isTest static void unitTest() {
		// Implement test code
		RestRequest req = new RestRequest(); 
	    RestResponse res = new RestResponse();

	    PublicSiteDomainName__c psdn = PublicSiteDomainName__c.getValues('Site URL');
	    String domainName = psdn.Domain_Name__c;

	    // pass the req and resp objects to the method     
	    //req.requestURI = 'https://appdev-tfnsw.cs5.force.com/feedback/services/apexrest/cfm/v1/createCases';  
	    req.requestURI = domainName + 'feedback/services/apexrest/cfm/v1/createCases';
	    req.httpMethod = 'POST';

	    RestContext.request = req;
    	RestContext.response = res;

    	// Negative Testing
	    CaseCreationMobileService.ResponseWrapper result = CaseCreationMobileService.doPost();

	    System.assertEquals(false, result.success);

	    String bases64EncodedImage = 'Test image';

	    CaseCreationMobileService.AttachmentWrapper attWr1 = new CaseCreationMobileService.AttachmentWrapper();
		attWr1.name = 'nice image.jpeg';
		attWr1.body = bases64EncodedImage;
		attWr1.createdDateTime = Datetime.now().getTime();

		List<CaseCreationMobileService.RequestWrapper> requestData = new List<CaseCreationMobileService.RequestWrapper>();

		CaseCreationMobileService.RequestWrapper rw1 = new CaseCreationMobileService.RequestWrapper();
		rw1.mode = 'Bus';
		rw1.category = 'Bus Timings';
		rw1.location = 'test bus location';
		rw1.description = 'Bus was late, Bus time table chart is not updated';
		rw1.toBeContacted = true;
		rw1.firstName = 'Jhon';
		rw1.lastName = 'Carter';
		rw1.email = 'deepak.soni@arxxus.com';
		rw1.mobile = '0444 444 444';
		rw1.mailingStreet = 'park street';
		rw1.mailingCity = 'Sydney';
		rw1.mailingState = 'NSW';
		rw1.mailingPostalCode = '2000';
		rw1.mailingCountry = 'Australia';
		rw1.incidentLatitude = -33.8653722;
		rw1.incidentLongitude = 150.7181694;
		rw1.localId = 'a0034';

		rw1.attachments = new List<CaseCreationMobileService.AttachmentWrapper>{attWr1};
		requestData.add(rw1);

		req.requestBody = Blob.valueOf(JSON.serialize(requestData));
		
		result = CaseCreationMobileService.doPost();
        System.debug('result: '+result);
	    System.assertEquals(true, result.success);
	}
	
}