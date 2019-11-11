@isTest
private class SignatureAuthorization_Test {
    
    @testSetup
    static void setUpTestData(){

        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MAGS Officer'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
        UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
        
       
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
        
        system.debug('User Inserted :: ' + u1);
        
        User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u2;

    }   

    @isTest 
    static void scheduleDeleteTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        User u2 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        insert transportCase;

        NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
        responseCustomAttachment.Name = 'Response_timestamp';
        responseCustomAttachment.ContentType__c = 'application/pdf';
        responseCustomAttachment.Case__c = transportCase.Id;
        responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
        responseCustomAttachment.Category__c = 'Unsigned Response';
       
        insert responseCustomAttachment;
       
        Attachment attach = new Attachment();    
        attach.Name = 'Dummy Unsigned Response pdf';
        Blob bodyBlob = Blob.valueOf('Dummy Unsigned Response pdf');
        attach.body = bodyBlob;
        attach.parentId = responseCustomAttachment.Id;
        insert attach;
        
        responseCustomAttachment.Attachment__c = attach.Id;
        update responseCustomAttachment;

        Signature_Authorisation__c signatureData = new Signature_Authorisation__c();
        signatureData.Case_Id__c = transportCase.Id;
        signatureData.Document_Id__c = responseCustomAttachment.Id;
        signatureData.User_Id__c = u2.Id;

        insert signatureData;


        Test.startTest();
            
            Id signatureId = signatureData.Id;
            String query = 'Select Id, Case_Id__c, CreatedDate FROM Signature_Authorisation__c WHERE Id =\''+signatureId+'\''; 

            Database.executeBatch(new BatchExecutor(new SignatureAuthorization(), query, null));
        
        Test.stopTest();
    }
    
    /*------------------------------------------------------------------- ----------------
    Author:  Arxxus      
    Description:   This method creates a roads case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getRoadsCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'MAGS Approved',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            MO_User__c = NULL,
                            Response_Type__c = 'Draft response',
                            Signatory__c = 'Minister for Roads, Maritime and Freight');
    }
       
    /*------------------------------------------------------------------- ----------------
    Author:        
    Description:   This method creates a transport case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getTransportCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'MAGS Approved',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            MO_User__c = NULL,
                            Response_Type__c = 'Draft response',
                            Signatory__c = 'Minister for Transport and Infrastructure');
    }

    public static void setupCaseRecTypesToExcludeCS() {
   
        List<CaseRecordTypesToExcludeFromRtFlip__c> rtToExclude = new List<CaseRecordTypesToExcludeFromRtFlip__c>();
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'General Ministerial Correspondence', Record_Type_Name__c = 'General Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Roads & Freight Ministerial Cor', Record_Type_Name__c = 'Roads & Freight Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Transport Ministerial Correspondence', Record_Type_Name__c = 'Transport Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign', Record_Type_Name__c = 'Campaign'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign Member', Record_Type_Name__c = 'Campaign Member'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Erroneous Cases', Record_Type_Name__c = 'Erroneous Cases Ministerial Correspondence'));
        insert rtToExclude;
    }   

}