@isTest
private class CaseCFSApiRetrieveCaseRestService_Test {

    static testMethod void basicTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c (Viewable_Case_Fields__c='Status', Name='Test');
        insert setting;
        
        Case c = new Case(Subject='Test Case1', GUID__c='1234_ABCD', Description='Test description' );
        insert c;
        
        Case c2 = new Case(Subject='Test Case2', GUID__c='1234_XYZ', Description='Test description' );
        insert c2;
               
        //Valid GUIDs        
        String JSONString = '{ "Cases" :['+
                            '{  "CaseGUID" : "1234_ABCD",'+
                            '    "CaseFields" : "Status"},'+
                            '{  "CaseGUID" : "1234_XYZ",'+
                            '   "CaseFields" : "Status"} ]}';

           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/retrievecase';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRetrieveCaseRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
    }
    
     static testMethod void invalidFieldTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        Case c = new Case(Subject='Test Case1', GUID__c='1234_ABCD', Description='Test description' );
        insert c;
     
        String JSONString = '{ "Cases" :['+
                            '{  "CaseGUID" : "1234_ABCD",'+
                            '    "CaseFields" : "Status", "Description"} ]}';

           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/retrievecase';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRetrieveCaseRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
    
    static testMethod void hundredCasesTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c (Viewable_Case_Fields__c='Status', Name='Test');
        insert setting;
        
        Case c = new Case(Subject='Test Case1', GUID__c='1234_ABCD', Description='Test description' );
        insert c;
     
        String JSONString = '{ "Cases" :[';
        
        //Only testing 99 as the test code runs synchronously and will break at 100 cases as there is a SOQL
        // to retrieve the custom Setting (getAll cannot be used as it is not a List type Custom Setting)
        //When called via REST up to 200 SOQL calls are allowed so this is not an issue.
        for (Integer x =0; x<99; x++){
            JSONString  += '{  "CaseGUID" : "1234_ABCD", "CaseFields" : "Status"},';
        } 
        //remove last comma
        JSONString = JSONString.removeEnd(',');                   
        JSONString += ']}';

        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/retrievecase';
        req.httpMethod = 'POST';

        RestContext.request = req;
        Test.startTest();
        CaseCFSApiRetrieveCaseRestService.doPost();
        Test.stopTest();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
    }
    
    static testMethod void hundredandOneCasesTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c (Viewable_Case_Fields__c='Status', Name='Test');
        insert setting;
        
        Case c = new Case(Subject='Test Case1', GUID__c='1234_ABCD', Description='Test description' );
        insert c;
     
        String JSONString = '{ "Cases" :[';

        for (Integer x =0; x<101; x++){
            JSONString  += '{  "CaseGUID" : "1234_ABCD", "CaseFields" : "Status"},';
        } 
        //remove last comma
        JSONString = JSONString.removeEnd(',');                   
        JSONString += ']}';

        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/retrievecase';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRetrieveCaseRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
    
    static testMethod void invalidJSONTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c (Viewable_Case_Fields__c='Status', Name='Test');
        insert setting;
        
        Case c = new Case(Subject='Test Case1', GUID__c='1234_ABCD', Description='Test description' );
        insert c;
        
        Case c2 = new Case(Subject='Test Case2', GUID__c='1234_XYZ', Description='Test description' );
        insert c2;
               
        //Valid GUIDs        
        String JSONString = '{ "Cases" :['+
                            '{  "CaseGUID" : "1234_ABCD",'+
                            '    "CaseFields" : "Status"}'+
                            '{  "CaseGUID" : "1234_XYZ",'+
                            '   "CaseFields" : "Status"} ]}';

           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/retrievecase';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRetrieveCaseRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
}