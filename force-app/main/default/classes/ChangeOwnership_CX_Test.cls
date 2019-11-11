/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for ChangeOwnership_CX

-----------------------------------------------------------------------------------*/
@isTest
public class ChangeOwnership_CX_Test {
 
 @testSetup 
 static void setUpCase() {
  
  Case tempCase = new Case();
  insert tempCase;
 }
 
 @isTest
 static void checkChangeOwnershipTestValid() {
  
  Case tempCase = [SELECT CaseNumber, Id, OwnerId, Owner.Name FROM Case LIMIT 1];
  
  Test.setCurrentPageReference(new PageReference('Page.ChangeOwnership'));
  System.currentPageReference().getParameters().put('id', tempCase.Id);
  System.currentPageReference().getParameters().put('recordName', tempCase.CaseNumber);
  System.currentPageReference().getParameters().put('recordLabel', 'Case');
  
  ChangeOwnership_CX con = new ChangeOwnership_CX();
  con.updationRecord.put('ownerId', tempCase.OwnerId);
  PageReference pageRef = con.save();
  System.assertNotEquals(NULL, pageRef);
  
  Group RoadMAGSManagerQueue = [Select Id From Group Where DeveloperName = 'Roads_Manager_Queue' and Type = 'Queue' limit 1];
  con.updationRecord.put('ownerId', RoadMAGSManagerQueue.Id);
  pageRef = con.save();
  System.assertNotEquals(NULL, pageRef);
 }
}