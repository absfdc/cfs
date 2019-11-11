/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus Technology Partners
Description:   Test for the Rest API to log Min cor cases coming from road and transport web forms
Test Class:    CaseMinCorRestServiceTest

History
03/11/2016      Dipankar Barman         Implemented Rest API service

15/06/2017      Ian Fitzgerald          Added test method testLargeFileName()

------------------------------------------------------------*/
@isTest
private class CaseMinCorRestServiceTest {
    
    @testSetup static void setupTestData() {
        
        // populate data for Public Site Domain Name custom setting
        List<SObject> publicSiteDomainName = Test.loadData(PublicSiteDomainName__c.SObjectType, 'PublicSiteDomainName');
        
        FullMatchDuplicateContactRules__c fullMatchRule = new FullMatchDuplicateContactRules__c();
        fullMatchRule.Name = 'contactNormalizedMatch';
        insert fullMatchRule;
        
        Contact con = new Contact();
        con.FirstName = 'Dipankar'; 
        con.LastName = 'Barman';
        con.Email = 'dipankar@arxxus.com';
        con.Phone = '0444 444 444';

        insert con;

        System.assertEquals(publicSiteDomainName.size() > 0, true);
    }


    @isTest static void testLargeFileName() {
        
        // Implement test code
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        PublicSiteDomainName__c psdn = PublicSiteDomainName__c.getValues('Site URL');
        String domainName = psdn.Domain_Name__c;

        // pass the req and resp objects to the method     
        //req.requestURI = 'https://appdev-tfnsw.cs5.force.com/feedback/services/apexrest/cfm/v1/createCases';  
        req.requestURI = domainName + 'feedback/services/apexrest/mincor/v1/createCase';
        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response = res;

        // Negative Testing
        CaseMinCorRestService.CaseResultWrapper result = CaseMinCorRestService.doPost();

        System.assertEquals(false, result.success);

        String bases64EncodedImage = 'Test image';

        CaseMinCorRestService.AttachmentWrapper attWr1 = new CaseMinCorRestService.AttachmentWrapper();
        attWr1.name = 'greaterthan80characternameLoremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliqua.jpeg';
        attWr1.createdDateTime = Datetime.now().getTime();


        CaseMinCorRestService.RequestWrapper rw1 = new CaseMinCorRestService.RequestWrapper();
        rw1.subject = 'Bus should be made better';
        rw1.category = 'Bus';
        rw1.description = 'Bus was late, Bus time table chart is not updated';
        rw1.toBeContacted = true;
        rw1.firstName = 'Dipankar';
        rw1.lastName = 'Barman';
        rw1.email = 'dipankar@arxxus.com';
        rw1.phone = '0444 444 444';
        rw1.mailingStreet = '1, Brucee Street';
        rw1.mailingCity = 'Sydney';
        rw1.mailingState = 'NSW';
        rw1.mailingPostalCode = '2000';
        rw1.mailingCountry = 'Australia';
        rw1.incidentLatitude = -33.8653722;
        rw1.incidentLongitude = 150.7181694;
        rw1.localId = 'a0034';
        rw1.origin='Web';
        rw1.originDetail='Roads & Freight Ministerial Correspondence';
        rw1.toBeContacted=true;
        rw1.filenames = new List<CaseMinCorRestService.AttachmentWrapper>{attWr1};

        
        req.requestBody = Blob.valueOf(JSON.serialize(rw1));

        result = CaseMinCorRestService.doPost();

        System.assertEquals(true, result.success);
        
        rw1.originDetail = '';
        
        req.requestBody = Blob.valueOf(JSON.serialize(rw1));

        result = CaseMinCorRestService.doPost();

        System.assertEquals(true, result.success);
    }
    
    @isTest static void unitTest() {
        
        // Implement test code
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        PublicSiteDomainName__c psdn = PublicSiteDomainName__c.getValues('Site URL');
        String domainName = psdn.Domain_Name__c;

        // pass the req and resp objects to the method     
        //req.requestURI = 'https://appdev-tfnsw.cs5.force.com/feedback/services/apexrest/cfm/v1/createCases';  
        req.requestURI = domainName + 'feedback/services/apexrest/mincor/v1/createCase';
        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response = res;

        // Negative Testing
        CaseMinCorRestService.CaseResultWrapper result = CaseMinCorRestService.doPost();

        System.assertEquals(false, result.success);

        String bases64EncodedImage = 'Test image';

        CaseMinCorRestService.AttachmentWrapper attWr1 = new CaseMinCorRestService.AttachmentWrapper();
        attWr1.name = 'nice image.jpeg';
        attWr1.createdDateTime = Datetime.now().getTime();


        CaseMinCorRestService.RequestWrapper rw1 = new CaseMinCorRestService.RequestWrapper();
        rw1.subject = 'Bus should be made better';
        rw1.category = 'Bus';
        rw1.description = 'Bus was late, Bus time table chart is not updated';
        rw1.toBeContacted = true;
        rw1.firstName = 'Dipankar';
        rw1.lastName = 'Barman';
        rw1.email = 'dipankar@arxxus.com';
        rw1.phone = '0444 444 444';
        rw1.mailingStreet = '1, Brucee Street';
        rw1.mailingCity = 'Sydney';
        rw1.mailingState = 'NSW';
        rw1.mailingPostalCode = '2000';
        rw1.mailingCountry = 'Australia';
        rw1.incidentLatitude = -33.8653722;
        rw1.incidentLongitude = 150.7181694;
        rw1.localId = 'a0034';
        rw1.origin='Web';
        rw1.originDetail='Roads & Freight Ministerial Correspondence';
        rw1.toBeContacted=true;
        rw1.filenames = new List<CaseMinCorRestService.AttachmentWrapper>{attWr1};

        
        req.requestBody = Blob.valueOf(JSON.serialize(rw1));

        result = CaseMinCorRestService.doPost();

        System.assertEquals(true, result.success);
        
        rw1.originDetail = '';
        
        req.requestBody = Blob.valueOf(JSON.serialize(rw1));

        result = CaseMinCorRestService.doPost();

        System.assertEquals(true, result.success);
    }
    
}