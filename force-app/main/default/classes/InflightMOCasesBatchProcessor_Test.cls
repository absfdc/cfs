/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for InflightMOCasesBatchProcessor

-----------------------------------------------------------------------------------*/
@isTest
public class InflightMOCasesBatchProcessor_Test {
 
 @testSetup 
 static void setUpCase() {
  
  Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
  Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
  
  UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Road'];
  UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
  UserRole r3 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
  UserRole r4 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Road'];  
  
  User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', FirstName = 'Road', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
  insert u1;
   
  User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', FirstName = 'Transport', LastName='Testing', LanguageLocaleKey='en_US',
                     LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
  insert u2;
  
  User u3 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', FirstName = 'Transport', LastName='DLO', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', UserRoleId = r3.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
  insert u3;
  
  User u4 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', FirstName = 'Road', LastName='DLO', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', UserRoleId = r4.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
  insert u4;
  
 }
 
 @isTest 
 static void inflightMOCasesBatchProcessorTest() {
  
  Account acc = new Account(Name = 'MO Contacts');
  insert acc;
       
  Contact c1 = new Contact(FirstName = 'Road', LastName = 'Testing');
  insert c1;
  
  Contact c2 = new Contact(FirstName = 'Transport', LastName = 'Testing');
  insert c2;
  
  Contact c3 = new Contact(FirstName = 'Transport', LastName = 'DLO', AccountId = acc.Id);
  insert c3;
  
  Contact c4 = new Contact(FirstName = 'Road', LastName = 'DLO', AccountId = acc.Id);
  insert c4;
  
  Contact c5 = new Contact(FirstName = 'John', LastName = 'Mango', AccountId = acc.Id);
  insert c5;
   
  Case tempCase1 = new Case();
  tempCase1.Portfolio__c = GlobalConstants.MIN_CORR_PORTFOLIO_ROADS;
  tempCase1.Minister__c = c1.Id;
  tempCase1.MO_Contact__c = c4.Id;
  tempCase1.Signatory__c = 'Chief of Staff';
  insert tempCase1;
  
  Case tempCase2 = new Case();
  tempCase2.Portfolio__c = GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT;
  tempCase2.Minister__c = c2.Id;
  tempCase2.MO_Contact__c = c3.Id;
  tempCase2.Signatory__c = 'Chief of Staff';
  insert tempCase2;
  
  Case tempCase3 = new Case();
  tempCase3.Portfolio__c = GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT;
  tempCase3.Minister__c = c2.Id;
  tempCase3.MO_Contact__c = c5.Id;
  tempCase3.Signatory__c = 'Chief of Staff';
  insert tempCase3;
  
  Test.startTest();
  List<Case> tempCases = [SELECT Id, CaseNumber, Minister__c, Minister__r.FirstName, Minister__r.LastName,
                          Minister_User__c, MO_Contact__c, MO_Contact__r.FirstName, MO_Contact__r.LastName,
                          MO_User__c, MO_Contact__r.Account.Name, Signatory__c, Portfolio__c FROM Case];
  
  InflightMOCasesBatchProcessor con = new InflightMOCasesBatchProcessor(UserInfo.getUserEmail());
  con.execute(tempCases);
  con.finish();
  
  ApplicationLogMessage message = new ApplicationLogMessage();
  message.source = 'InflightMOCasesBatchProcessor';
  message.sourceFunction = 'exceute';
  message.logMessage = 'Case Updation Failed: ';
  message.ex = NULL;
  message.debugLevel = 'Error';
  
  con.messages.add(message);
  con.finish();
  
  Test.stopTest();
  System.assertEquals(3, con.totalMinisterCaseCount);
 }
}