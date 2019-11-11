/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for PrecedentBeforeDeleteTriggerHandler
-----------------------------------------------------------------------------------*/

@isTest
private class PrecedentBeforeDeleteTriggerHandler_Test {
    
    @testSetup
    static void setUpUser(){

        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MAGS Officer'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
        Profile p3 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
        UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Senior_MAGS_Officer'];
        UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
        UserRole r4 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
        
       
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
        
        system.debug('User Inserted :: ' + u1);
        
        User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u2;

        User u3 = new User(Alias = 'standt', Email = 'standarduser3@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u3;
        
        User u4 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                   LocaleSidKey='en_US', UserRoleId = r3.Id, ProfileId = p3.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u4;

        User u5 = new User(Alias = 'standt', Email = 'standarduser5@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
               LocaleSidKey='en_US', UserRoleId = r4.Id, ProfileId = p3.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u5;

    }   
    
    //Transport Case Creation
    @isTest
    static void transportCaseCreationTest() {

        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        User u3 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();
        
        List<Case> caseToInsertList = new List<Case>();
        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        
        caseToInsertList.add(transportCase);
        
        Case transportCase1 = getTransportCaseRecord();
        transportCase1.MO_User__c = u3.Id;
        
        caseToInsertList.add(transportCase1);

        Test.startTest();
        system.runAs(u){
            
            insert caseToInsertList;
            
            transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c,CaseNumber,MO_User__c FROM Case WHERE Id = :transportCase.Id];
            System.assertEquals(transportCase.MO_User__c, u.Id);
        
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
            tempReq.setComments('Submitting response for approval');
            tempReq.setObjectId(transportCase.Id);
            approvalRequests.add(tempReq);

            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            System.assertEquals(TRUE, processResults[0].isSuccess());
            
            
            Precedent__c precdentCase = new Precedent__c();
            precdentCase.Related_Case__c = transportCase.Id;
            precdentCase.Precedent_Case__c = transportCase1.Id;
            insert precdentCase;



            delete precdentCase;
            
            
        }   
        Test.stopTest();
    }
    
    //Exception handling test
    @isTest
    static void exceptionHandlingTest() {

    PrecedentBeforeDeleteTriggerHandler tempHandler = new PrecedentBeforeDeleteTriggerHandler();
    tempHandler.mainEntry(NULL);
    tempHandler.inProgressEntry(NULL);
    System.assertEquals(TRUE, tempHandler.exceptionInvoked);

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