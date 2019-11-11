/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for GenerateResponsePDF

-----------------------------------------------------------------------------------*/
@isTest
public class GenerateResponsePDF_Test {
  
  
  @testSetup 
  static void setUpUser() {
        
   Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
   Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
   
   UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Senior_MAGS_Officer'];
   UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Road'];
   UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MAGS_Manager'];
   UserRole r4 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
   UserRole r5 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
  
   User u1 = new User(Alias = 'standt', Email = 'standarduser3@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u1;
   
   User u2 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u2;
   
   User u3 = new User(Alias = 'standt', Email = 'standarduser5@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r3.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u3;
   
   User u4 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                   LocaleSidKey='en_US', UserRoleId = r4.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u4;
 
   User u5 = new User(Alias = 'standt', Email = 'standarduser5@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
               LocaleSidKey='en_US', UserRoleId = r5.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u5;
   
  }
  
  //Validate response PDF generation when case is not in MO approval and signatory is MO
  @isTest
  static void validateResponsePDFGenerationNoApprovalMOSignatoryTest() {
   
   setupCaseRecTypesToExcludeCS();
   
   User u1 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   User u2 = [Select Id From User Where email = 'standarduser4@nsw.gov.au.com' limit 1];
   
   System.runAs(u1) {
    
    Case roadCase = getRoadsCaseRecord();
    roadCase.MO_User__c = u2.Id;
    roadCase.Status = 'MAGS Approved';
    insert roadCase;
    
    
    NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
    responseCustomAttachment.Name = 'response_timestamp';
    responseCustomAttachment.ContentType__c = 'application/msword';
    responseCustomAttachment.Case__c = roadCase.Id;
    responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
   
    insert responseCustomAttachment;
   
    Attachment attach = new Attachment();    
    attach.Name = 'Dummy Response WordML Doc.';
    Blob bodyBlob = Blob.valueOf('Dummy Response WordML Doc.');
    attach.body = bodyBlob;
    attach.parentId = responseCustomAttachment.Id;
    insert attach;
    
    Test.startTest();
    // Set mock callout class
    Test.setMock(HttpCalloutMock.class, new GenerateResponsePDFMockHttpResponse());
    Test.stopTest();
    
    responseCustomAttachment = [SELECT Id, Name, Attachment_Id__c FROM NoteOrAttachment__c WHERE Id =:responseCustomAttachment.Id];
    
    responseCustomAttachment.Attachment__c = attach.Id;
    update responseCustomAttachment;
    
    responseCustomAttachment = [SELECT Id, Name, Attachment_Id__c FROM NoteOrAttachment__c WHERE Id =:responseCustomAttachment.Id];
    
    System.assertNotEquals(NULL, responseCustomAttachment.Attachment_Id__c); 
    
    //GenerateResponsePDF.generate(roadCase.Id, responseCustomAttachment.Id, attach.Id, 'response_timestamp', UserInfo.getSessionId());
    
    responseCustomAttachment = [SELECT Conga_Response_PDF_Generated__c , Name FROM NoteOrAttachment__c  WHERE Id =:responseCustomAttachment.Id];
   
    System.assertEquals(TRUE, responseCustomAttachment.Conga_Response_PDF_Generated__c);
   }
   
  }
  
  //Validate response PDF generation when case is not in MO approval and signatory is non MO
  @isTest
  static void validateResponsePDFGenerationNoApprovalNonMOSignatoryTest() {
   
   setupCaseRecTypesToExcludeCS();
   
   User u1 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   User u2 = [Select Id From User Where email = 'standarduser4@nsw.gov.au.com' limit 1];
   
   System.runAs(u1) {
    
    Case roadCase = getRoadsCaseRecord();
    roadCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
    roadCase.MO_User__c = u2.Id;
    roadCase.Status = 'MAGS Approved';
    insert roadCase;
    
    roadCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
    update roadCase;
    
    NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
    responseCustomAttachment.Name = 'response_timestamp';
    responseCustomAttachment.ContentType__c = 'application/msword';
    responseCustomAttachment.Case__c = roadCase.Id;
    responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
   
    insert responseCustomAttachment;
   
    Attachment attach = new Attachment();    
    attach.Name = 'Dummy Response WordML Doc.';
    Blob bodyBlob = Blob.valueOf('Dummy Response WordML Doc.');
    attach.body = bodyBlob;
    attach.parentId = responseCustomAttachment.Id;
    insert attach;
    
    Test.startTest();
    // Set mock callout class
    Test.setMock(HttpCalloutMock.class, new GenerateResponsePDFMockHttpResponse());
    Test.stopTest();
    
    
    responseCustomAttachment = [SELECT Id, Name, Attachment_Id__c FROM NoteOrAttachment__c WHERE Id =:responseCustomAttachment.Id];
    
    responseCustomAttachment.Attachment__c = attach.Id;
    update responseCustomAttachment;
    
    responseCustomAttachment = [SELECT Id, Name, Attachment_Id__c FROM NoteOrAttachment__c WHERE Id =:responseCustomAttachment.Id];
    
    System.assertNotEquals(NULL, responseCustomAttachment.Attachment_Id__c); 
    
    //GenerateResponsePDF.generate(roadCase.Id, responseCustomAttachment.Id, attach.Id, 'response_timestamp', UserInfo.getSessionId());
    
    responseCustomAttachment = [SELECT Conga_Response_PDF_Generated__c , Name FROM NoteOrAttachment__c  WHERE Id =:responseCustomAttachment.Id];
   
    System.assertEquals(TRUE, responseCustomAttachment.Conga_Response_PDF_Generated__c);
   }
   
  }
  
  //Validate response PDF generation when case is in MO approval and signatory is MO
  @isTest
  static void validateResponsePDFGenerationApprovalMOSignatoryTest() {
   
   setupCaseRecTypesToExcludeCS();
   
   User u1 = [Select Id From User Where email = 'standarduser3@nsw.gov.au.com' limit 1];
   User u2 = [Select Id From User Where email = 'standarduser4@nsw.gov.au.com' limit 1];
    
   Case roadCase = getRoadsCaseRecord();
   roadCase.Status = 'MAGS Approved';
   roadCase.MO_User__c = u2.Id;
   roadCase.OwnerId = u2.Id;
   roadCase.Signatory__c = 'Minister for Roads, Maritime and Freight';
   insert roadCase;
   
   Test.startTest();
   
   //submitting case to MO approval - will route to MO_User__c i.e DLO/PA for approval
   List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
   Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
   tempReq.setComments('Submitting response for approval');
   tempReq.setObjectId(roadCase.Id);
   tempReq.setSubmitterId(u1.Id);
   approvalRequests.add(tempReq);
   
   Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
    
   System.assertEquals(TRUE, processResults[0].isSuccess());
    
   // Unlock the cases
   Set<Id> tempCaseId = new Set<Id>();
   tempCaseId.add(Id.valueOf(roadCase.Id));
                
   Approval.UnlockResult[] lrList = Approval.unlock(new List<Id>(tempCaseId), false);
    
   System.debug('Unlock Result Got: '+lrList[0].getErrors());
   System.assertEquals(TRUE, lrList[0].isSuccess());
   
   roadCase = [SELECT Status, OwnerId, RecordTypeId, RecordType.Name FROM Case WHERE Id = :roadCase.Id];
        
   System.debug('Got roadCase: '+roadCase);
        
   List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId ,ActorId 
                                                                FROM ProcessInstanceWorkitem 
                                                                WHERE ProcessInstance.TargetObjectId =: roadCase.Id
                                                                limit 1];
        
   System.debug('Got workItem: '+workItems[0]);
        
   System.runAs(u2) {
    
    workItems = [SELECT Id, ProcessInstanceId ,ActorId 
                 FROM ProcessInstanceWorkitem 
                 WHERE ProcessInstance.TargetObjectId =: roadCase.Id
                 limit 1];
    
    System.debug('Got workItem: '+workItems[0]);
    System.debug('Running User Id: '+u2.Id);   
    System.debug('Logged in user: '+UserInfo.getUserId());                                                     
                                                            
    NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
    responseCustomAttachment.Name = 'response_timestamp';
    responseCustomAttachment.ContentType__c = 'application/msword';
    responseCustomAttachment.Case__c = roadCase.Id;
    responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
   
    insert responseCustomAttachment;
   
    Attachment attach = new Attachment();    
    attach.Name = 'Dummy Response WordML Doc.';
    Blob bodyBlob = Blob.valueOf('Dummy Response WordML Doc.');
    attach.body = bodyBlob;
    attach.parentId = responseCustomAttachment.Id;
    insert attach;
    
    // Set mock callout class
    GenerateResponsePDF.mock = new GenerateResponsePDFMockHttpResponse();
    
    responseCustomAttachment = [SELECT Id, Name, Attachment_Id__c FROM NoteOrAttachment__c WHERE Id =:responseCustomAttachment.Id];
    
    responseCustomAttachment.Attachment__c = attach.Id;
    update responseCustomAttachment;
    
    responseCustomAttachment = [SELECT Id, Name, Attachment_Id__c FROM NoteOrAttachment__c WHERE Id =:responseCustomAttachment.Id];
    
    System.assertNotEquals(NULL, responseCustomAttachment.Attachment_Id__c); 
    
    responseCustomAttachment = [SELECT Conga_Response_PDF_Generated__c , Name FROM NoteOrAttachment__c  WHERE Id =:responseCustomAttachment.Id];
   
    System.assertEquals(TRUE, responseCustomAttachment.Conga_Response_PDF_Generated__c);
    
   }
   Test.stopTest();
   
  }
  
  //Exception handling test
  @isTest
  static void exceptionHandlingTest() {
   
   GenerateResponsePDF.generate(NULL, NULL, NULL, 'response_timestamp', UserInfo.getSessionId());
   System.assertEquals(TRUE, GenerateResponsePDF.exceptionInvoked);
   
   GenerateResponsePDF.exceptionInvoked = FALSE;
   Test.startTest();
   GenerateResponsePDF.generatePDF(NULL, NULL, NULL, 'response_timestamp', UserInfo.getSessionId());
   Test.stopTest();
   System.assertEquals(TRUE, GenerateResponsePDF.exceptionInvoked);
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