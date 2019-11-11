/*------------------------------------------------------------------------
Author:        Deepak Soni
Company:       Arxxus Technology Partners
Description:   A test class created to validate the CaseStatusMobileService Rest service
               
               setupTestData()
               Setup the custom setting data from static resource file

               Tests executed:
               1 - unitTest()
               Test the API post method.

History
<Date>      <Authors Name>      <Brief Description of Change>
25/02/2016  Deepak Soni         Implemented Rest API service Test class
----------------------------------------------------------------------------*/

@isTest
private class CaseStatusMobileService_Test {
    @testSetup static void setupTestData() {

        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
               
        User u1 = new User(Alias = 'standt', Email = 'admin@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;

        // populate data for Case Status Mapping For Mobile App custom setting
        List<SObject> caseAllStatusMapping = Test.loadData(CaseStatusForMobileApp__c.SObjectType, 'CaseStatusMappingForMobileApp');

        // populate data for Case Status Update Frequency For Mobile App custom setting
        List<SObject> caseStatusUpdateFrequencies = Test.loadData(CaseStatusUpdateFrequencey__c.SObjectType, 'CaseStatusUpdateFrequencyForMobile');

        // populate data for Public Site Domain Name custom setting
        List<SObject> publicSiteDomainName = Test.loadData(PublicSiteDomainName__c.SObjectType, 'PublicSiteDomainName');
        
        System.assertEquals(caseAllStatusMapping.size() > 0, true);
        System.assertEquals(caseStatusUpdateFrequencies.size() > 0, true);
        System.assertEquals(publicSiteDomainName.size() > 0, true);
    }

    @isTest static void unitTest() {
        
        User u = [Select Id From User Where email = 'admin@nsw.gov.au.com' limit 1];

        // Implement test code
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        PublicSiteDomainName__c psdn = PublicSiteDomainName__c.getValues('Site URL');
        String domainName = psdn.Domain_Name__c;

        System.runAs(u){
            // pass the req and resp objects to the method     
            //req.requestURI = 'https://appdev-tfnsw.cs5.force.com/feedback/services/apexrest/cfm/v1/createCases';  
            req.requestURI = domainName + 'feedback/services/apexrest/cfm/v1/createCases';
            req.httpMethod = 'POST';

            RestContext.request = req;
            RestContext.response = res;

            // Negative Testing
            CaseStatusMobileService.ResponseWrapper result = CaseStatusMobileService.doPost();

            System.assertEquals(false, result.success);


            // Positive Testing
            String multiIssueRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE).getRecordTypeId();
            String guid = '32bf965c-7b64-96d1-eb70-e5c6ef4a14cb';

            Case newCase = new Case();
            newCase.RecordTypeId = multiIssueRecordTypeId;
            newCase.GUID__c = guid;
            newCase.Status = GlobalConstants.DEFAULT_WEBTOCASE_STATUS_TRIAGE;
            insert newCase;

            req.requestBody = Blob.valueOf(JSON.serialize(new List<String>{guid}));

            result = CaseStatusMobileService.doPost();

            System.assertEquals(true, result.success);
            System.assertEquals(false, result.response.isEmpty());
            System.assertEquals('Received', result.response.get(guid));

            newCase.Partner_Case_Status__c = 'Open';
            newCase.Responsible_Party__c = GlobalConstants.RESPONSIBLE_PARTY_SNSW;
            update newCase;

            result = CaseStatusMobileService.doPost();

            System.assertEquals(true, result.success);
            System.assertEquals(false, result.response.isEmpty());
            System.assertEquals('SNSWReceived', result.response.get(guid));
        }    
    }
    
}