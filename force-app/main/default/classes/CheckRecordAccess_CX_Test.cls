/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for CheckRecordAccess_CX

-----------------------------------------------------------------------------------*/
@isTest
public class CheckRecordAccess_CX_Test {
 
 @testSetup 
 static void setUpCase() {
  
  Case tempCase = new Case();
  insert tempCase;
 }
 
 @isTest
 static void checkRecordAccessTestInvalid() {
  
  checkRecordAccess_CX con = new checkRecordAccess_CX();
  PageReference pageRef = con.autoRun();
  System.assertEquals(NULL, pageRef);
  
 }
 
 @isTest
 static void checkRecordAccessTestValid() {
  
  Case tempCase = [SELECT CaseNumber, Id, OwnerId, Owner.Name FROM Case LIMIT 1];
  
  Test.setCurrentPageReference(new PageReference('Page.checkRecordAccess'));
  System.currentPageReference().getParameters().put('id', tempCase.Id);
  System.currentPageReference().getParameters().put('assignedTo', tempCase.Owner.Name);
  System.currentPageReference().getParameters().put('tabLabel', 'Case');
    
  checkRecordAccess_CX con = new checkRecordAccess_CX();
  PageReference pageRef = con.autoRun();
  System.assertEquals(NULL, pageRef);
  System.assertEquals(TRUE, con.hasReadAccess);
  
 }
}