@isTest
private class GenerateSignature_Test {
    
    @testSetup
    static void setUpUser(){
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MAGS Officer'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
        UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
        
       
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
        
        User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u2;
    }
    
    
    @isTest
    static void validateForSignatureWithoutSignatureURLTest() {

        Digital_Process_Send_Email__c digitalProcessCustomSetting = new Digital_Process_Send_Email__c();
        digitalProcessCustomSetting.On__c = false;
        digitalProcessCustomSetting.Name = GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL;
        insert digitalProcessCustomSetting;

        User u = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];

        String userId = '';
        String caseId = '';
        String documentId = '';

        String folderName = [select id from folder where name = 'Andrew Constance Signature Folder' limit 1].Id;

        System.runAs(u){

            Document document = new Document();
            document.Body = Blob.valueOf('Some Text');
            document.ContentType = 'image/png';
            document.DeveloperName = 'my_document';
            document.Name = 'My Document';
            document.FolderId = folderName;
            insert document;

            documentId = document.Id;

            userId = u.Id;

            Case tempCase = new Case();
            insert tempCase;
            caseId = tempCase.Id;
            
            Signature_Authorisation__c signatureData = new Signature_Authorisation__c();
            signatureData.Case_Id__c = caseId;
            signatureData.Document_Id__c = documentId;
            signatureData.User_Id__c = u.Id;

            insert signatureData;
        }
            
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        // pass the req and resp objects to the method     
        req.requestURI = '/services/apexrest/mincor/v1/GenerateSignature';  
        
        System.debug('Document Id :: ' + documentId);

        req.addParameter('userId', userId);
        req.addParameter('caseId', caseId);
        req.addParameter('documentId', documentId);
        
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        
        System.runAs(u){
            
          GenerateSignature.validateForSignature();
          List<Case> caseList = [Select Id, Signature_Authorisation_Failure__c from Case where Id =: caseId Limit 1];
          if(caseList.size() > 0){
            System.assertEquals(caseList[0].Signature_Authorisation_Failure__c,true);
          }   
        }   
        Test.stopTest();

    }
    
    @isTest
    static void validateForSignatureWithSignatureURLTest() {

        Digital_Process_Send_Email__c digitalProcessCustomSetting = new Digital_Process_Send_Email__c();
        digitalProcessCustomSetting.On__c = false;
        digitalProcessCustomSetting.Name = GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL;
        insert digitalProcessCustomSetting;

        User u = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];

        String userId = '';
        String caseId = '';
        String documentId = '';

        String folderName = [select id from folder where name = 'Andrew Constance Signature Folder' limit 1].Id;

        System.runAs(u){

            Document document = new Document();
            document.Body = Blob.valueOf('Some Text');
            document.ContentType = 'image/png';
            document.DeveloperName = 'my_document';
            document.Name = 'My Document';
            document.FolderId = folderName;
            insert document;

            documentId = document.Id;

            u.Signature_Location__c = 'test@test.com/documentId='+document.Id;
            update u;

            userId = u.Id;

            Case tempCase = new Case();
            insert tempCase;
            caseId = tempCase.Id;
            
            Signature_Authorisation__c signatureData = new Signature_Authorisation__c();
            signatureData.Case_Id__c = caseId;
            signatureData.Document_Id__c = documentId;
            signatureData.User_Id__c = u.Id;

            insert signatureData;
        }
            
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        // pass the req and resp objects to the method     
        req.requestURI = '/services/apexrest/mincor/v1/GenerateSignature';  
        
        System.debug('Document Id :: ' + documentId);

        req.addParameter('userId', userId);
        req.addParameter('caseId', caseId);
        req.addParameter('documentId', documentId);
        
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        
        System.runAs(u){
            
          GenerateSignature.validateForSignature();
          List<Case> caseList = [Select Id, Signature_Authorisation_Failure__c from Case where Id =: caseId Limit 1];
          if(caseList.size() > 0){
            System.assertEquals(caseList[0].Signature_Authorisation_Failure__c,true);
          }   
        }   
        Test.stopTest();

    }

    @isTest
    static void validateForSignatureExceptionHandling(){
        
        User u = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
        
        System.runAs(u){
            GenerateSignature.validateForSignature();
        }

    }
    
}