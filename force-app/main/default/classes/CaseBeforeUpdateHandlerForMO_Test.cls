/*----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for CaseBeforeUpdateHandlerForMO

-----------------------------------------------------------------------------------*/
@isTest
public class CaseBeforeUpdateHandlerForMO_Test {
 
 @testSetup 
 static void setUpUser() {
        
   Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
   Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
   
   UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
   UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
   UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Senior_MAGS_Officer'];
   UserRole r4 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Chief_of_Staff_Road'];
   UserRole r5 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Chief_of_Staff_Transport'];
   UserRole r6 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MAGS_Manager'];
   
   User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u1;
   
   User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u2;
   
   User u3 = new User(Alias = 'standt', Email = 'standarduser3@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r3.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u3;
   
   User u4 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r4.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u4;
   
   User u5 = new User(Alias = 'standt', Email = 'standarduser5@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r5.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u5;
   
   User u6 = new User(Alias = 'standt', Email = 'standarduser6@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r6.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u6;
   
 }
 
 //Roads Case Updation
 @isTest
 static void roadsCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser4@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
   
   System.runAs(u2) {
    
    Case roadCase = getRoadsCaseRecord();
    insert roadCase;
   
    roadCase.Signatory__c = 'Chief of Staff Roads';
    roadCase.Status = 'MAGS Approved';
   
    Test.startTest();
    update roadCase;
    Test.stopTest();
   
    roadCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c FROM Case WHERE Id = :roadCase.Id];
    System.assertEquals('Chief of Staff Roads', roadCase.Signatory__c);
    System.assertEquals(u3.Id, roadCase.Signatory_Person__c);
    System.assertEquals(u1.Id, roadCase.Minister_User__c);
    System.assertEquals(u2.Id, roadCase.Rejection_User__c);
   }
 }
 
 //Transport Case Updation
 @isTest
 static void transportCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser5@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
   
   System.runAs(u2) {
    
    Case transportCase = getTransportCaseRecord();
    insert transportCase;
   
    transportCase.Signatory__c = 'Chief of Staff Transport';
    transportCase.Status = 'MAGS Approved';
   
    Test.startTest();
    update transportCase;
    Test.stopTest();
   
    transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c FROM Case WHERE Id = :transportCase.Id];
    System.assertEquals('Chief of Staff Transport', transportCase.Signatory__c);
    System.assertEquals(u3.Id, transportCase.Signatory_Person__c);
    System.assertEquals(u1.Id, transportCase.Minister_User__c);
    System.assertEquals(u2.Id, transportCase.Rejection_User__c);
    
   }
 }
 
 //MAGS Manager Signatory Case Updation
 @isTest
 static void magsSignatoryCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
   
   System.runAs(u2) {
    
    Case roadCase = getRoadsCaseRecord();
    insert roadCase;
   
    roadCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
    roadCase.Status = 'MAGS Approved';
   
    Test.startTest();
    update roadCase;
    Test.stopTest();
   
    roadCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c, OwnerId FROM Case WHERE Id = :roadCase.Id];
    System.assertEquals('Manager, Ministerial & Government Services - Roads, Maritime and Freight', roadCase.Signatory__c);
    System.assertEquals(u3.Id, roadCase.Signatory_Person__c);
    System.assertEquals(u1.Id, roadCase.Minister_User__c);
    System.assertEquals(u2.Id, roadCase.OwnerId);
    System.assertEquals(u2.Id, roadCase.Rejection_User__c);
    
   }
 }
 
 //Remove Signatory Case Updation
 @isTest
 static void removeSignatoryCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
   
   System.runAs(u2) {
    
    Case roadCase = getRoadsCaseRecord();
    insert roadCase;
   
    roadCase.Signatory__c = '';
   
    Test.startTest();
    update roadCase;
    Test.stopTest();
   
    roadCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c, OwnerId FROM Case WHERE Id = :roadCase.Id];
    System.assertEquals(NULL, roadCase.Signatory__c);
    System.assertEquals(NULL, roadCase.Signatory_Person__c);
    System.assertEquals(u1.Id, roadCase.Minister_User__c);
   }
 }
 
 //Changing case owner on MO approval intermediate rejection
 @isTest
 static void approvalIntermediateRejectionRoadsCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser4@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
    
   Case roadCase = getRoadsCaseRecord();
   
   System.runAs(u2) {
    
    insert roadCase;
    
    System.debug('Insert Case: '+roadCase.Id);
    
    
    roadCase.Signatory__c = 'Chief of Staff Roads';
    roadCase.Status = 'MAGS Approved';
    update roadCase;

    roadCase.Status = GlobalConstants.AWAITING_MO_CONTACT_APPROVAL_MIN_CORRO;
    update roadCase;
       
    Test.startTest();
 
    roadCase.Status = GlobalConstants.MO_AMEND_MIN_CORRO;
    update roadCase;
        
    Test.stopTest();
   } 
    
   roadCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c, OwnerId FROM Case WHERE Id = :roadCase.Id];
   Group RoadMAGSManagerQueue = [Select Id From Group Where DeveloperName = 'Roads_Manager_Queue' and Type = 'Queue' limit 1];
    
   System.assertEquals('Chief of Staff Roads', roadCase.Signatory__c);
   System.assertEquals(u3.Id, roadCase.Signatory_Person__c);
   System.assertEquals(u1.Id, roadCase.Minister_User__c);
   System.assertEquals(RoadMAGSManagerQueue.Id, roadCase.OwnerId);
 }
 
 //Changing case owner on MO approval rejection
 @isTest
 static void approvalSignatoryRejectionRoadsCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
    
   Case roadCase = getRoadsCaseRecord();
   
   System.runAs(u2) {
    
    insert roadCase;
    
    System.debug('Insert Case: '+roadCase.Id);
    
    
    roadCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
    roadCase.Status = 'MAGS Approved';
    update roadCase;

    roadCase.Status = GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO;
    update roadCase;
       
    Test.startTest();
 
    roadCase.Status = GlobalConstants.SIGNATORY_REJECTED_MIN_CORRO;
    update roadCase;
        
    Test.stopTest();
   } 
    
   roadCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c, OwnerId FROM Case WHERE Id = :roadCase.Id];
   Group RoadMAGSManagerQueue = [Select Id From Group Where DeveloperName = 'Roads_Manager_Queue' and Type = 'Queue' limit 1];
    
   System.assertEquals('Manager, Ministerial & Government Services - Roads, Maritime and Freight', roadCase.Signatory__c);
   System.assertEquals(u3.Id, roadCase.Signatory_Person__c);
   System.assertEquals(u1.Id, roadCase.Minister_User__c);
   System.assertEquals(u2.Id, roadCase.OwnerId);
 }
 
 //Changing case owner on MO approval intermediate rejection
 @isTest
 static void approvalIntermediateRejectionTransportCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser5@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
    
   Case transportCase = getTransportCaseRecord();
   
   System.runAs(u2) {
    
    insert transportCase;
    
    transportCase.Signatory__c = 'Chief of Staff Transport';
    transportCase.Status = 'MAGS Approved';
    update transportCase;

    transportCase.Status = GlobalConstants.AWAITING_MO_CONTACT_APPROVAL_MIN_CORRO;
    update transportCase;
       
    Test.startTest();
 
    transportCase.Status = GlobalConstants.MO_AMEND_MIN_CORRO;
    update transportCase;
        
    Test.stopTest();
   } 
    
   transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c, OwnerId FROM Case WHERE Id = :transportCase.Id];
   Group TransportMAGSManagerQueue = [Select Id From Group Where DeveloperName = 'Transport_Manager_Queue' and Type = 'Queue' limit 1];
    
   System.assertEquals('Chief of Staff Transport', transportCase.Signatory__c);
   System.assertEquals(u3.Id, transportCase.Signatory_Person__c);
   System.assertEquals(u1.Id, transportCase.Minister_User__c);
   System.assertEquals(TransportMAGSManagerQueue.Id, transportCase.OwnerId);
 }
 
 //Changing case owner on MO approval rejection
 @isTest
 static void approvalSignatoryRejectionTransportCaseUpdationTest() {
   
   User u1 = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
   
   User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   
   User u3 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
    
   Case transportCase = getTransportCaseRecord();
   
   System.runAs(u2) {
    
    insert transportCase;
    
    transportCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
    transportCase.Status = 'MAGS Approved';
    update transportCase;

    transportCase.Status = GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO;
    update transportCase;
       
    Test.startTest();
 
    transportCase.Status = GlobalConstants.SIGNATORY_REJECTED_MIN_CORRO;
    update transportCase;
        
    Test.stopTest();
   } 
    
   transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c, Rejection_User__c, OwnerId FROM Case WHERE Id = :transportCase.Id];
   Group TransportMAGSManagerQueue = [Select Id From Group Where DeveloperName = 'Transport_Manager_Queue' and Type = 'Queue' limit 1];
    
   System.assertEquals('Manager, Ministerial & Government Services - Roads, Maritime and Freight', transportCase.Signatory__c);
   System.assertEquals(u3.Id, transportCase.Signatory_Person__c);
   System.assertEquals(u1.Id, transportCase.Minister_User__c);
   System.assertEquals(u2.Id, transportCase.OwnerId);
 }
 
 //Chekcing if case is unlocked on case being submitted to MO approval view
 @isTest
 static void approvalSubmissionCaseUnlockUpdationTest() {
  
  User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
  
  setupCaseRecTypesToExcludeCS();
    
  Case transportCase = getTransportCaseRecord();
  
  insert transportCase;
  
  transportCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
  transportCase.Status = 'MAGS Approved';
  update transportCase;
  
  List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
  Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
  tempReq.setComments('Submitting response for approval');
  tempReq.setObjectId(transportCase.Id);
  approvalRequests.add(tempReq);
   
  Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
  
  System.assertEquals(TRUE, processResults[0].isSuccess());
  
  update transportCase;
  
  System.assertEquals(FALSE, Approval.isLocked(transportCase.Id));
  
 }
 
 //Chekcing if case is assigned to correct team queue and team picklist is updated correctly
 @isTest
 static void teamPicklistCaseUpdationTest() {
  
  setupCaseRecTypesToExcludeCS();
  
  Group TeamAQueue = [Select Id From Group Where DeveloperName = 'Team_A' and Type = 'Queue' limit 1];
    
  Case transportCase = getTransportCaseRecord();
  
  insert transportCase;
  transportCase.OwnerId = TeamAQueue.Id;
  update transportCase;
  
  transportCase = [SELECT OwnerId, Responsible_Team__c FROM Case WHERE Id = :transportCase.Id];
  
  System.assertEquals(TeamAQueue.Id, transportCase.OwnerId);
  System.assertEquals('Team A', transportCase.Responsible_Team__c);
 }
 
 //Chekcing if case is assigned to Responsible MAGS Officer upon being marked as Signed & Emailed
 @isTest
 static void ownerUpdationSignedAndEmailCaseUpdationTest() {
  
  User u1 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
  
  setupCaseRecTypesToExcludeCS();
  Case transportCase = getTransportCaseRecord();
  
  insert transportCase;
  
  transportCase.Status = GlobalConstants.MO_SIGNED_AND_EMAILED_MIN_CORRO;
  transportCase.Minister_Communication_Preference__c = GlobalConstants.MINISTER_COMM_PREFERENCE_EMAIL;
  transportCase.Responsible_MAGS_Officer__c = u1.Id;
  
  update transportCase;
  
  transportCase = [SELECT OwnerId FROM Case WHERE Id = :transportCase.Id];
  
  System.assertEquals(u1.Id, transportCase.OwnerId);
 }
 
 //Cheking if incoming PDF generation call is being sent for web form origin cases
 @isTest
 static void incomingPDFGenerationWebCaseUpdationTest() {
  
  User u1 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
  User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
  
  setupCaseRecTypesToExcludeCS();
  
  APXTConga4__Conga_Template__c incomingTestTemplate = new APXTConga4__Conga_Template__c();
  incomingTestTemplate.APXTConga4__Name__c = 'WebCaseIncomingTemplate';
  insert incomingTestTemplate;
  
  Attachment attach = new Attachment();    
  attach.Name = 'Dummy Conga Template';
  Blob bodyBlob = Blob.valueOf('Dummy Conga Template');
  attach.body = bodyBlob;
  attach.parentId = incomingTestTemplate.id;
  insert attach;
      
  Case transportCase = getTransportCaseRecord();
  
  transportCase.Status = GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS;
  transportCase.Origin = GlobalConstants.WEB2CASE_ORIGIN;
  transportCase.OwnerId = u2.Id;
  
  insert transportCase;
  
  System.runAs(u1) {
  
   Test.startTest();
   
   // Set mock callout class
   GenerateIncomingPDF.mock = new GenerateResponsePDFMockHttpResponse();
   transportCase.OwnerId = u1.Id;
   
   Test.stopTest();
   
   update transportCase;
  }
  
  transportCase = [SELECT OwnerId, Incoming_PDF_Generated__c FROM Case WHERE Id = :transportCase.Id];
  
  System.assertEquals(TRUE, transportCase.Incoming_PDF_Generated__c);
 }
 
 //Cheking if incoming PDF generation call is being sent for Ezescan email origin cases
 @isTest
 static void incomingPDFGenerationEmailCaseUpdationTest() {
  
  User u1 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
  User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
  
  setupCaseRecTypesToExcludeCS();
  
  APXTConga4__Conga_Template__c incomingTestTemplate = new APXTConga4__Conga_Template__c();
  incomingTestTemplate.APXTConga4__Name__c = 'WebCaseIncomingTemplate';
  insert incomingTestTemplate;
  
  Case transportCase = getTransportCaseRecord();
  
  transportCase.Status = GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS;
  transportCase.Origin = GlobalConstants.EZESCAN_CASE_ORIGIN;
  transportCase.OwnerId = u2.Id;
  
  insert transportCase;
  
  System.runAs(u1) {
   
   Test.startTest();
   
   // Set mock callout class
   GenerateIncomingPDF.mock = new GenerateResponsePDFMockHttpResponse();
   GenerateIncomingPDF.generate(transportCase.Id, UserInfo.getSessionId());
   
   transportCase.OwnerId = u1.Id;
   
   Test.stopTest();
   
   update transportCase;
  }
  
  transportCase = [SELECT OwnerId, Incoming_PDF_Generated__c FROM Case WHERE Id = :transportCase.Id];
  
  System.assertEquals(TRUE, transportCase.Incoming_PDF_Generated__c);
  
  
 }
 
 //Cheking if incoming PDF generation call is being sent for Ezescan email origin General Ministerial Correspondence cases
 @isTest
 static void incomingPDFGenerationEmailGMCCaseUpdationTest() {
  
  User u1 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
  User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
  
  setupCaseRecTypesToExcludeCS();
  
  APXTConga4__Conga_Template__c incomingTestTemplate = new APXTConga4__Conga_Template__c();
  incomingTestTemplate.APXTConga4__Name__c = 'WebCaseIncomingTemplate';
  insert incomingTestTemplate;
  
  Case gMCCase = getGMCCaseRecord();
  
  Contact tempCon = new Contact();
  tempCon.FirstName = 'Sample';
  tempCon.LastName = 'Last Name';
  tempCon.Email = 'test@testLastname.com';
  
  insert tempCon;
  
  gMCCase.Status = GlobalConstants.DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS;
  gMCCase.Origin = GlobalConstants.EZESCAN_EMAIL_CASE_ORIGIN;
  gMCCase.OwnerId = u2.Id;
  gMCCase.ContactId = tempCon.Id;
  
  insert gMCCase;
  
  System.runAs(u1) {
   
   Test.startTest();
   
   // Set mock callout class
   GenerateIncomingPDF.mock = new GenerateResponsePDFMockHttpResponse();
   GenerateIncomingPDF.generate(gMCCase.Id, UserInfo.getSessionId());
   
   gMCCase.OwnerId = u1.Id;
   
   Test.stopTest();
   
   update gMCCase;
  }
  
  gMCCase = [SELECT OwnerId, Incoming_PDF_Generated__c FROM Case WHERE Id = :gMCCase.Id];
  
  System.assertEquals(TRUE, gMCCase.Incoming_PDF_Generated__c);
  
  
 }
 
 //Cheking if incoming PDF generation call is failed when no conga template found
 /*
 @isTest
 static void incomingPDFGenerationFailureTest() {
  
  User u1 = [Select Id From User Where email = 'standarduser6@nsw.gov.au.com' limit 1];
  User u2 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
  
  setupCaseRecTypesToExcludeCS();
  
  Case transportCase = getTransportCaseRecord();
  
  transportCase.Status = GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS;
  transportCase.Origin = GlobalConstants.EZESCAN_CASE_ORIGIN;
  transportCase.OwnerId = u2.Id;
  
  insert transportCase;
  
  System.runAs(u1) {
   
   Test.startTest();
   Test.setMock(HttpCalloutMock.class, new GenerateResponsePDFMockHttpResponse());
   Test.stopTest();
   
   transportCase.OwnerId = u1.Id;
   
   update transportCase;
  }
  
  System.assertEquals(TRUE, GenerateIncomingPDF.exceptionInvoked);
 }
 */
 
 //Exception handling test
 @isTest
 static void exceptionHandlingTest() {
   
  CaseBeforeUpdateHandlerForMO tempHandler = new CaseBeforeUpdateHandlerForMO();
  tempHandler.mainEntry(NULL);
  tempHandler.inProgressEntry(NULL);
  System.assertEquals(TRUE, tempHandler.exceptionInvoked);
   
 }
  
 /*------------------------------------------------------------------- ----------------
  Author:        
  Description:   This method creates a roads case record sobject
  -----------------------------------------------------------------------------------*/
  public static Case getRoadsCaseRecord() {
   
   RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD limit 1];
   
   return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                        Status = 'New',
                        RecordTypeId = rt.Id,
                        Priority = 'Normal',
                        Modes__c = 'MAGS', 
                        Portfolio__c = 'Roads, Maritime and Freight',
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
                        Status = 'New',
                        RecordTypeId = rt.Id,
                        Priority = 'Normal',
                        Modes__c = 'MAGS', 
                        Portfolio__c = 'Transport and Infrastructure',
                        Signatory__c = 'Minister for Transport and Infrastructure');
  }
  
  /*------------------------------------------------------------------- ----------------
  Author:        
  Description:   This method creates a General Ministerial Correspondence case record sobject
  -----------------------------------------------------------------------------------*/
  public static Case getGMCCaseRecord() {
   
   RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.MIN_CORRO_RECTYPE_API_NAME limit 1];
   
   return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                        Status = 'New',
                        RecordTypeId = rt.Id,
                        Priority = 'Normal',
                        Modes__c = 'MAGS');
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