/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for RecallPendingApprovalsController

-----------------------------------------------------------------------------------*/
@isTest
public class RecallPendingApprovalsController_Test {
  
  @testSetup 
  static void setUpUser() {
   
   Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
   
   UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MAGS_Manager'];
   UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
   UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
        
   User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                      LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u1;
   
   User u2 = new User(Alias = 'standt', Email = 'standarduser4@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                   LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u2;

   User u3 = new User(Alias = 'standt', Email = 'standarduser5@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
               LocaleSidKey='en_US', UserRoleId = r3.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u3;
   
  }
  
  //Successful recall of pending approvals 
  @isTest
  static void recallPendingApprovalsSuccessTest() {
   
   setupCaseRecTypesToExcludeCS();
   
   List<Group> roadsManagerQueue = [Select Id From Group Where DeveloperName = 'Roads_Manager_Queue' and Type = 'Queue' Limit 1];
   List<Group> transportManagerQueue = [Select Id From Group Where DeveloperName = 'Transport_Manager_Queue' and Type = 'Queue' Limit 1];
  
   Set<Id> targetSetIds = new Set<Id>();
   
   Case roadCase = getRoadsCaseRecord();
   roadCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
   roadCase.Status = 'MAGS Approved';
   roadCase.ownerId = roadsManagerQueue[0].Id;
   insert roadCase;
   roadCase.Wet_Signature__c=false;
   update roadCase;
   targetSetIds.add(roadCase.Id);
   
   List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
   Approval.ProcessSubmitRequest tempReqRoad = new Approval.ProcessSubmitRequest();
   tempReqRoad.setComments('Submitting response for approval');
   tempReqRoad.setObjectId(roadCase.Id);
   approvalRequests.add(tempReqRoad);
   
   Case transportCase = getTransportCaseRecord();
   transportCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
   transportCase.Status = 'MAGS Approved';
   transportCase.ownerId = transportManagerQueue[0].Id;
   insert transportCase;
   transportCase.Wet_Signature__c=false;
   update transportCase;
   targetSetIds.add(transportCase.Id);
   
   Approval.ProcessSubmitRequest tempReqTransport = new Approval.ProcessSubmitRequest();
   tempReqTransport.setComments('Submitting response for approval');
   tempReqTransport.setObjectId(transportCase.Id);
   approvalRequests.add(tempReqTransport);
   
   Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
  
   System.assertEquals(TRUE, processResults[0].isSuccess());
   
   Test.startTest();
   RecallPendingApprovalsController con = new RecallPendingApprovalsController();
   con.recallApprovals();
   Test.stopTest();
   
   List<ProcessInstanceWorkItem> workItems = [Select ProcessInstance.Status, ProcessInstance.TargetObjectId, ProcessInstanceId, OriginalActorId,
                                               Id, ActorId
                                               From ProcessInstanceWorkitem 
                                               WHERE ProcessInstance.TargetObjectId IN :targetSetIds
                                               AND ProcessInstance.Status = 'Pending'];
   
   System.assertEquals(0, workItems.size());
   
  }
  
  //Failure in recall of pending approvals 
  @isTest
  static void recallPendingApprovalsFailureTest() {
   
   setupCaseRecTypesToExcludeCS();
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   List<Group> roadsManagerQueue = [Select Id From Group Where DeveloperName = 'Roads_Manager_Queue' and Type = 'Queue' Limit 1];
   List<Group> transportManagerQueue = [Select Id From Group Where DeveloperName = 'Transport_Manager_Queue' and Type = 'Queue' Limit 1];
  
   Set<Id> targetSetIds = new Set<Id>();
   
   Case roadCase = getRoadsCaseRecord();
   roadCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
   roadCase.Status = 'MAGS Approved';
   roadCase.ownerId = roadsManagerQueue[0].Id;
   insert roadCase;
   roadCase.Wet_Signature__c=false;
   update roadCase;
   targetSetIds.add(roadCase.Id);
   
   List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
   Approval.ProcessSubmitRequest tempReqRoad = new Approval.ProcessSubmitRequest();
   tempReqRoad.setComments('Submitting response for approval');
   tempReqRoad.setObjectId(roadCase.Id);
   approvalRequests.add(tempReqRoad);
   
   Case transportCase = getTransportCaseRecord();
   transportCase.Signatory__c = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
   transportCase.Status = 'MAGS Approved';
   transportCase.ownerId = transportManagerQueue[0].Id;
   insert transportCase;
   transportCase.Wet_Signature__c=false;
   update transportCase;
   targetSetIds.add(transportCase.Id);
   
   Approval.ProcessSubmitRequest tempReqTransport = new Approval.ProcessSubmitRequest();
   tempReqTransport.setComments('Submitting response for approval');
   tempReqTransport.setObjectId(transportCase.Id);
   approvalRequests.add(tempReqTransport);
   
   Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
  
   System.assertEquals(TRUE, processResults[0].isSuccess());
   
   System.runAs(u1) {
   
    Test.startTest();
    RecallPendingApprovalsController con = new RecallPendingApprovalsController();
    con.recallApprovals();
    Test.stopTest();
   
    List<ProcessInstanceWorkItem> workItems = [Select ProcessInstance.Status, ProcessInstance.TargetObjectId, ProcessInstanceId, OriginalActorId,
                                               Id, ActorId
                                               From ProcessInstanceWorkitem 
                                               WHERE ProcessInstance.TargetObjectId IN :targetSetIds
                                               AND ProcessInstance.Status = 'Pending'];
   
    System.assertEquals(2, workItems.size());
   }
   
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