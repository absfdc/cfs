@isTest
private class CaseCFSApiAttachmentRestService_Test {

     static testMethod void basicTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
        
        Case c = new Case(Subject='Text Case', GUID__c='1234_ABCD');
        insert c;
        
        c = [select CaseNumber, GUID__c from Case where Id = :c.Id limit 1];
        
        //Valid GUID        
        String JSONString = '{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                   '"CaseGUID":  "'+c.GUID__c +'",'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
        
        // Invalid GUID
        JSONString = '{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                   '"CaseGUID": "12345",'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        res = RestContext.response;
        System.Assert(res.statusCode==400);
        
        //No GUID
        JSONString = '{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        res = RestContext.response;
        System.Assert(res.statusCode==400); 
    }
    
    static testMethod void longNameTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
        
        Case c = new Case(Subject='Text Case', GUID__c='1234_ABCD');
        insert c;
        
        String JSONString = '{"ContentType":"text/plain", '+
                   '"Name":"very_long_file_name_more_than_80_characters_very_long_file_name_more_than_80_characters.txt",'+
                   '"CaseGUID": "1234_ABCD",'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);  
    }
    
    //Test long filename with no extension
    static testMethod void longNameTest2() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
        
        Case c = new Case(Subject='Text Case', GUID__c='1234_ABCD');
        insert c;
        
        String JSONString = '{"ContentType":"text/plain", '+
                   '"Name":"very_long_file_name_more_than_80_characters_very_long_file_name_more_than_80_characters",'+
                   '"CaseGUID": "1234_ABCD",'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
    
    static testMethod void noPayloadTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
           
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
    
    //Test error, no name sent
    static testMethod void noNameTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
        
        Case c = new Case(Subject='Text Case', GUID__c='1234_ABCD');
        insert c;
        
        String JSONString = '{"ContentType":"text/plain", '+
                   '"CaseGUID": "1234_ABCD",'+
                   '"Name":"",'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
    
    //Test error, no body sent
    static testMethod void noBodyTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
        
        Case c = new Case(Subject='Text Case', GUID__c='1234_ABCD');
        insert c;
        
        String JSONString = '{"ContentType":"text/plain", '+
                   '"CaseGUID": "1234_ABCD",'+
                  '"Name":"Test.txt"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
    
    //Test error, no content type sent
    static testMethod void noContentType() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
        
        Case c = new Case(Subject='Text Case', GUID__c='1234_ABCD');
        insert c;
        
        String JSONString = '{"ContentType":" ", '+
                   '"CaseGUID": "1234_ABCD",'+
                  '"Name":"Test.txt",'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
    
    //Invalid JSON
    static testMethod void invalidJSON() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name='.txt');
        insert allowedFiles;
        
        Case c = new Case(Subject='Text Case', GUID__c='1234_ABCD');
        insert c;
        
        //Invalid JSON, missing comma after Name entry
        String JSONString = '{"ContentType":" ", '+
                   '"CaseGUID": "1234_ABCD",'+
                  '"Name":"Test.txt"'+
                  '"Body":"VGVzdCBkYXRh"'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/attachment';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiAttachmentRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
    }
}