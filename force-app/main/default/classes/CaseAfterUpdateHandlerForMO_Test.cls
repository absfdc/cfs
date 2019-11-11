/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for CaseAfterUpdateHandlerForMO
-----------------------------------------------------------------------------------*/

@isTest
private class CaseAfterUpdateHandlerForMO_Test {
  
  @testSetup
  static void setUpUser(){

       Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MAGS Officer'];
       Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
       Profile p3 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
     
       UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
       UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Senior_MAGS_Officer'];
       UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
       UserRole r4 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
       
       User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', Signature_Location__c = 'www.google.com',UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
       insert u1;
       
       User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US',Signature_Location__c = 'www.google.com', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
       insert u2;

       User u3 = new User(Alias = 'standt', Email = 'standarduser3@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', Signature_Location__c = 'www.google.com',UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
       insert u3;
       
       User u4 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                         LocaleSidKey='en_US', Signature_Location__c = 'www.google.com',UserRoleId = r3.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
       insert u4;
       
       User u5 = new User(Alias = 'standt', Email = 'standarduser5@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                         LocaleSidKey='en_US', Signature_Location__c = 'www.google.com',UserRoleId = r4.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
       insert u5;
  }  


  @isTest 
  static void transportCaseCreationTest() {
    
        // Implement test code
        User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        User u3 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();
    
        List<Case> caseToInsertList = new List<Case>();
        Case transportCase = getTransportCaseRecord();
        transportCase.MO_User__c = u.Id;
        
        caseToInsertList.add(transportCase);
        
        Case transportCase1 = getTransportCaseRecord();
        transportCase1.MO_User__c = u.Id;
        
        caseToInsertList.add(transportCase1);

        Test.startTest();
        
        System.runAs(u){
          
          insert caseToInsertList;

          transportCase.MO_User__c = u3.Id;

          Precedent__c precdentCase = new Precedent__c();
          precdentCase.Related_Case__c = transportCase.Id;
          precdentCase.Precedent_Case__c = transportCase1.Id;
          insert precdentCase;

          update transportCase;

        }


        Test.stopTest();

  }
  
  @isTest 
  static void signatoryPPTest() {
    
    User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
    User u2 = [Select Id From User Where email = 'standarduser5@nsw.gov.au.com' limit 1];
    
    setupCaseRecTypesToExcludeCS();
    
    Case transportCase = getTransportCaseRecord();
    
    transportCase.MO_User__c = u1.Id;
    
    insert transportCase;
    
    List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
    Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
    tempReq.setComments('Submitting response for approval');
    tempReq.setObjectId(transportCase.Id);
    approvalRequests.add(tempReq);
   
    Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
  
    System.assertEquals(TRUE, processResults[0].isSuccess());
    
    ProcessInstanceWorkitem workItem = [SELECT Id, ProcessInstanceId, ActorId
                                         FROM ProcessInstanceWorkitem
                                         WHERE ProcessInstance.TargetObjectId = :transportCase.Id];
    
    System.assertEquals(u1.Id, workItem.ActorId);
    
    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
    req.setWorkitemId(workItem.Id);
    req.setAction('Approve');
    
    processResults = Approval.process(new List<Approval.ProcessWorkitemRequest>{req});
    
    System.assertEquals(TRUE, processResults[0].isSuccess());
    
    transportCase = [SELECT Status FROM Case WHERE Id = :transportCase.Id];
    
    System.assertEquals(GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO, transportCase.Status);
    
    transportCase.Signatory_Person_OBO__c = u2.Id;
    
    update transportCase;
    
    workItem = [SELECT Id, ProcessInstanceId, ActorId
                                         FROM ProcessInstanceWorkitem
                                         WHERE ProcessInstance.TargetObjectId = :transportCase.Id];
                                         
    System.assertEquals(u2.Id, workItem.ActorId);
  }
  
  //Exception handling test
  @isTest
  static void exceptionHandlingTest() {

  CaseAfterUpdateHandlerForMO tempHandler = new CaseAfterUpdateHandlerForMO();
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