/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for CaseBeforeInsertHandlerForMO

-----------------------------------------------------------------------------------*/
@isTest
public class CaseBeforeInsertHandlerForMO_Test {
  
  @testSetup 
  static void setUpUser() {
        
   Profile p = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
   
   UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
   UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
   
   User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u1;
   
   User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
   insert u2;
  }
  
  //Roads Case Creation
  @isTest
  static void roadsCaseCreationTest() {
   
   User u = [Select Id From User Where email = 'standarduser1@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
   
   Case roadCase = getRoadsCaseRecord();
   
   System.assertEquals(roadCase.Signatory_Person__c, NULL);
   
   Test.startTest();
   insert roadCase;
   Test.stopTest();
   
   roadCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c FROM Case WHERE Id = :roadCase.Id];
   System.assertEquals(roadCase.Signatory__c, 'Minister for Roads, Maritime and Freight');
   System.assertEquals(roadCase.Signatory_Person__c, u.Id);
   System.assertEquals(roadCase.Minister_User__c, u.Id);
  }
  
  //Transport Case Creation
  @isTest
  static void transportCaseCreationTest() {
   
   User u = [Select Id From User Where email = 'standarduser2@nsw.gov.au.com' limit 1];
   
   setupCaseRecTypesToExcludeCS();
        
   Case transportCase = getTransportCaseRecord();
   
   System.assertEquals(transportCase.Signatory_Person__c, NULL);
   
   Test.startTest();
   insert transportCase;
   Test.stopTest();
   
   transportCase = [SELECT Signatory__c, Signatory_Person__c, Minister_User__c FROM Case WHERE Id = :transportCase.Id];
   System.assertEquals(transportCase.Signatory__c, 'Minister for Transport and Infrastructure');
   System.assertEquals(transportCase.Signatory_Person__c, u.Id);
   System.assertEquals(transportCase.Minister_User__c, u.Id);
  }
  
  //Exception handling test
  @isTest
  static void exceptionHandlingTest() {
   
   CaseBeforeInsertHandlerForMO tempHandler = new CaseBeforeInsertHandlerForMO();
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