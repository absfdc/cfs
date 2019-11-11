/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   Test class for BatchExecutor

-----------------------------------------------------------------------------------*/
@isTest
public class BatchExecutor_Test {
 
 //Successful batch execution call 
 @isTest
 static void successCallingBatch() {
  
  String query = 'SELECT Id, CaseNumber, Portfolio__c, OwnerId, Owned_By_MO_Staff__c'+
                 ' FROM Case';

  String id = Database.executeBatch(new BatchExecutor(new GovernmentChangeTransferOwnershipProcess(UserInfo.getUserEmail()), query, null), 10);
  
  System.assertNotEquals(NULL, id);
 }
  
}