@isTest
private class CaseCFSApiRestService_Test {

    static testMethod void basicTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "In Person",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"ClosureTargetDate__c" : "2017-11-04T11:15:12Z",'+
            '"Date_Time_of_Incident_gmt__c" : "2019-06-04T14:00:00Z",'+
            '"MultiAgency__c" : "true",'+
            '"Draft_Rejection_Count__c" : "12",'+
            '"Case_Resolution_Date__c" : "2017-10-17"'+
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"Email": "testEmail@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        CaseCFSApiRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
        system.debug('CaseCFSApiRestService_Test basicTest res : '+res);
    }
    
    static testMethod void duplicateTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        Contact c = new Contact (FirstName='testFirstName', LastName='testLastName', Email='testLastName@testing.com');
        insert c;
        
        String ContactString = '{"Case":{'+
               '"Subject": "TestAPI Date Case" },'+
               '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"Email": "testLastName@testing.com"'+
            '}'+
           '}';
           
        req.requestBody = Blob.valueOf(ContactString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        CaseCFSApiRestService.doPost();
        
        FullMatchDuplicateContactRules__c fullDuplicateContactRules = new FullMatchDuplicateContactRules__c();
        fullDuplicateContactRules.Name = 'contactNormalizedMatch';
        insert fullDuplicateContactRules;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Case",'+
            '"Origin": "In Person",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"ClosureTargetDate__c" : "2017-11-04T11:15:12Z",'+
            '"MultiAgency__c" : "true",'+
            '"Draft_Rejection_Count__c" : "12",'+
            '"Case_Resolution_Date__c" : "2017-10-17"'+
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"Email": "testLastName@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        CaseCFSApiRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
          
    }
    
    static testMethod void errorCaseTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"Email": "testLastName@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        CaseCFSApiRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
          
    }
    
    static testMethod void noCaseTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"Email": "testLastName@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        CaseCFSApiRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
          
    }
    
    static testMethod void errorContactTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"ClosureTargetDate__c" : "2017-11-04T11:15:12Z",'+
            '"MultiAgency__c" : "true",'+
            '"Case_Resolution_Date__c" : "2017-10-17"'+
            '},'+
        '"Contact":{},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"Test.txt",'+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        CaseCFSApiRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
          
    }
    
    static testMethod void errorAttachmentTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"ClosureTargetDate__c" : "2017-11-04T11:15:12Z",'+
            '"MultiAgency__c" : "true",'+
            '"Case_Resolution_Date__c" : "2017-10-17"'+
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName"'+
               '"Email": "testEmail@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        CaseCFSApiRestService.doPost();
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400); 
    }
    
    static testMethod void longAttachmentNameTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"ClosureTargetDate__c" : "2017-11-04T11:15:12Z",'+
            '"MultiAgency__c" : "true",'+
            '"Case_Resolution_Date__c" : "2017-10-17"'+
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"Email": "testEmail@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"very_long_file_name_more_than_80_characters_very_long_file_name_more_than_80_characters.txt", '+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        System.debug('longAttachmentNameTest JSONString : '+JSONString);   
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200); 
    }
    
    static testMethod void taxonomyTest() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        //Set up Taxonomy
        Taxonomy_Metadata__c mode = new Taxonomy_Metadata__c(Type__c='Mode', Status_Customer_Facing__c='Active', 
        Status_Staff_Facing__c='Active', Name='Road', Agency__c='RMS', Customer_Value__c ='Road');
        insert mode;
        
        Taxonomy_Metadata__c issuelevel1 = new Taxonomy_Metadata__c(Type__c='Issue', Status_Customer_Facing__c='Active', 
        Status_Staff_Facing__c='Active', Name='Roads', Agency__c='RMS', Customer_Value__c ='Roads', Parent_Id__c = mode.Id);
        insert issuelevel1;

        Taxonomy_Metadata__c issuelevel2 = new Taxonomy_Metadata__c( Type__c='Issue', Parent_Id__c = issuelevel1.Id,Status_Customer_Facing__c='Active', Status_Staff_Facing__c='Active',  Name='Traffic Management & Safety',  Agency__c='RMS', Customer_Value__c ='Traffic Management & Safety');
        insert issuelevel2;

        Taxonomy_Metadata__c issuelevel3 = new Taxonomy_Metadata__c( Type__c='Issue', Parent_Id__c = issuelevel2.Id, Status_Customer_Facing__c='Active', Status_Staff_Facing__c='Active',  Name='Safety barriers',  Agency__c='RMS', Customer_Value__c ='Safety barriers');
        insert issuelevel3;
        
        Taxonomy_Metadata__c loclevel1 = new Taxonomy_Metadata__c(Type__c='Location', Status_Customer_Facing__c='Active', 
        Status_Staff_Facing__c='Active', Name='Roads', Agency__c='RMS', Customer_Value__c ='Roads', Parent_Id__c = mode.Id);
        insert loclevel1;

        Taxonomy_Metadata__c loclevel2 = new Taxonomy_Metadata__c( Type__c='Location', Parent_Id__c = loclevel1.Id,Status_Customer_Facing__c='Active', Status_Staff_Facing__c='Active',  Name='Region',  Agency__c='RMS', Customer_Value__c ='Region');
        insert loclevel2;

        Taxonomy_Metadata__c loclevel3 = new Taxonomy_Metadata__c( Type__c='Location', Parent_Id__c = loclevel2.Id, Status_Customer_Facing__c='Active', Status_Staff_Facing__c='Active',  Name='Hunter',  Agency__c='RMS', Customer_Value__c ='Hunter');
        insert loclevel3;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"MultiAgency__c" : "true",'+
            '"Taxonomy_Symptom_Id__c" : "'+issuelevel3.Id+'",'+
            '"Taxonomy_Location_Id__c" : "'+loclevel3.Id+'"'+
           '}}';
         
        System.debug('taxonomyTest JSONString : '+JSONString);
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;
        
        Test.startTest();
        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200); 
        
        Case createdCase = [select Id from Case where subject = 'TestAPI Date Case'
                            and Taxonomy_Location_Type__c = 'Roads'
                            and Taxonomy_Area__c = 'Region'
                            and Taxonomy_Location__c = 'Hunter'
                            and Taxonomy_Moment__c = 'Roads'
                            and Taxonomy_Transaction__c = 'Traffic Management & Safety'
                            and Taxonomy_Symptom__c = 'Safety barriers' limit 1];
                            
        System.Assert(createdCase!=null);     
        Test.stopTest();               
    }
    
    static testMethod void invalidObjectsTest() {
    	RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Cas1e":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"ClosureTargetDate__c" : "2017-11-04T11:15:12Z",'+
            '"MultiAgency__c" : "true",'+
            '"Case_Resolution_Date__c" : "2017-10-17"'+
            '},'+
        '"Con1tact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName"'+
               '"Email": "testEmail@testing.com"'+
            '},'+
        '"Attach1ment":{"ContentType":"text/plain", '+
                   '"Name":"test.txt", '+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400); 
    }
    
    static testMethod void invalidFieldsTest() {
    	RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Sub1ject": "TestAPI Date Case",'+
            '"Or2igin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint",'+
            '"Status": "New",'+
            '"ClosureTargetDate__c" : "2017-11-04T11:15:12Z",'+
            '"MultiAgency__c" : "true",'+
            '"Case_Resolution_Date__c" : "2017-10-17"'+
            '},'+
        '"Contact":{'+
               '"First2Name": "testFirstName",'+
               '"Last2Name": "testLastName"'+
               '"Email": "testEmail@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"test.txt", '+
                  '"Bo2dy":"VGVzdCBkYXRh"}'+
           '}';
           
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400); 
    }
    
    static testMethod void invalidAttachmentType() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint"' +
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"Email": "testEmail@testing.com"'+
            '},'+
        '"Attachment":{"ContentType":"application/rtf", '+
                   '"Name":"Test.rtf", '+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
             
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400); 
    }
    
    static testMethod void incompleteMailingAddress() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint"' +
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"MailingStreet": "477 Pitt St"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"test.txt", '+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
              
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400); 
    }
    
    static testMethod void validMailingAddress() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint"' +
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"MailingStreet": "477 Pitt St",'+
               '"MailingCity": "Sydney",'+
               '"MailingState": "NSW",'+
               '"MailingStateCode": "NSW",'+ 
               '"MailingPostalCode": "2001",'+
               '"MailingCountry": "Australia",'+
               '"MailingCountryCode": "AU"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"test.txt", '+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
             
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200); 
    }
    
    static testMethod void invalidMailingStateCode() {
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        AllowableFileExtensions__c filetype = new AllowableFileExtensions__c(Name='.txt');
        insert filetype;
        
        CFS_API_Settings__c setting = new CFS_API_Settings__c(Name='Test', Required_Case_Fields__c='Origin, Type, Response_Requested__c');
        insert setting;
        
        String JSONString = '{"Case":{'+
            '"Subject": "TestAPI Date Case",'+
            '"Origin": "Phone",'+
            '"Origin_Details__c": "In Person",'+
            '"Priority": "Normal",'+
            '"Response_Requested__c": "No",'+
            '"Type": "Complaint"' +
            '},'+
        '"Contact":{'+
               '"FirstName": "testFirstName",'+
               '"LastName": "testLastName",'+
               '"MailingStreet": "477 Pitt St",'+
               '"MailingCity": "Sydney",'+
               '"MailingState": "Victoria",'+
               '"MailingStateCode": "NSW",'+ 
               '"MailingPostalCode": "2001",'+
               '"MailingCountry": "Australia",'+
               '"MailingCountryCode": "AU"'+
            '},'+
        '"Attachment":{"ContentType":"text/plain", '+
                   '"Name":"test.txt", '+
                  '"Body":"VGVzdCBkYXRh"}'+
           '}';
             
        req.requestBody = Blob.valueOf(JSONString);   
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/case';
        req.httpMethod = 'POST';

        RestContext.request = req;

        CaseCFSApiRestService.doPost();   
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400); 
    }
}