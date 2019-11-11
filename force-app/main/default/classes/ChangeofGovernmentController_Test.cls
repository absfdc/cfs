/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for ChangeofGovernmentController

-----------------------------------------------------------------------------------*/
@isTest
public class ChangeofGovernmentController_Test {
  
  @testSetup 
  static void setUpUser() {
   
   Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
   UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
   
   User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                      LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u1;
   
  }
 
  //Successful change of Ownership 
  @isTest
  static void ownershipChangeTest() {
  
   setupCaseRecTypesToExcludeCS();
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   System.runAs(u1) {

    Case roadCase = getRoadsCaseRecord();
    insert roadCase;
    
    Case transportCase = getTransportCaseRecord();
    insert transportCase;
   }
   
   Test.startTest();
   ChangeofGovernmentController con = new ChangeofGovernmentController();
   con.transferOwnerShip();
   Test.stopTest();
   
   System.assertEquals(TRUE, con.batchScheduled);
   
  }
  
  //Failure in case change of Ownership 
  @isTest
  static void noOwnershipChangeTest() {
  
   setupCaseRecTypesToExcludeCS();
   
   User u1 = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   Case roadCase = getRoadsCaseRecord();
   Case transportCase = getTransportCaseRecord();
      
   System.runAs(u1) {

    insert roadCase;
    
    transportCase.Response_Type__c = 'No response required (NRR)';
    transportCase.NRR_Notes__c = '';
    insert transportCase;
   } 
    
    GovernmentChangeTransferOwnershipProcess con = new GovernmentChangeTransferOwnershipProcess(UserInfo.getUserEmail());
    con.execute(new List<Case>{roadCase, transportCase});
    
    System.debug('Error List: '+con.messages);
    
    System.assertEquals(1, con.messages.size());
    
    con.finish();
   
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