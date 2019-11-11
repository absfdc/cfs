/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Test Class for Action Plan sharing rules.
History
<Date>         <Authors Name>     <Brief Description of Change>
04/05/2015     Manish Damle       Created
-----------------------------------------------------------------------------------*/
@isTest
private class ActionPlanSharingHandler_Test {
 
    @testSetup
    static void setUp() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            User sercoAgent1 = NoteOrAttachmentSharingHandler_Test.createTestUser('md');
            User sercoAgent2 = NoteOrAttachmentSharingHandler_Test.createTestUser('sd');
        }
    }
    
    static testMethod void newActionPlanTest() {
		User sercoAgent1 = [Select Id From User Where Email = 'md@demo.com' limit 1];
        User sercoAgent2 = [Select Id From User Where Email = 'sd@demo.com' limit 1];
        
        system.runAs(sercoAgent2) {
            Case caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            caseRecord.Subject = 'TESTCASE';
            insert caseRecord;
            
         	Action_Plan__c ap = getActionPlanRecord(caseRecord.Id); 
            insert ap;   
        }
        
        Test.startTest(); 
        //action plan created by serco agent 2 should be shared with case owner Serco Agent 1
        list <Action_Plan__Share> shareRecords = [Select Id From Action_Plan__Share Where UserOrGroupId =: sercoAgent2.Id];
        system.assertEquals(1,shareRecords.size());
        Test.stopTest();  
    }
    
    static testMethod void caseOwnerUpdatedTest() {
		User sercoAgent1 = [Select Id From User Where Email = 'md@demo.com' limit 1];
        User sercoAgent2 = [Select Id From User Where Email = 'sd@demo.com' limit 1];        
        Case caseRecord;
        
        system.runAs(sercoAgent2) {
            Test.startTest(); 
            caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord; 
            Test.stopTest();
            
            Action_Plan__c ap = getActionPlanRecord(caseRecord.Id);
            insert ap;

            //Shared with serco agent 2 whenever owner is changed.
            list <Action_Plan__Share> shareRecords = [Select Id From Action_Plan__Share Where UserOrGroupId =: sercoAgent2.Id];
            system.assertEquals(1,shareRecords.size());
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Case c = [Select Id,OwnerId From Case Where Id =: caseRecord.id];
            c.OwnerId = sercoAgent1.Id;
            update c;  
        }
        
        //Criteria based sharing rule can not be tested
        list <Action_Plan__Share> shareRecords = [Select Id From Action_Plan__Share Where UserOrGroupId =: sercoAgent1.Id];
        system.assertEquals(0,shareRecords.size());    
    }
    
    static testMethod void shareChildApWithParentApOwnerUpdatedTest() {
        Case caseRecord;
        Action_Plan__c parentAp;
        User sercoAgent1 = [Select Id From User Where Email = 'md@demo.com' limit 1];
        User sercoAgent2 = [Select Id From User Where Email = 'sd@demo.com' limit 1];       
        
        Id currentUser = UserInfo.getUserId();
        
        system.runAs(sercoAgent1) {
            caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord;  
        }
         
        Test.startTest(); 
            parentAp = getActionPlanRecord(caseRecord.Id);
            parentAp.OwnerId = sercoAgent1.Id;
        	insert parentAp;
            
            Action_Plan__c ap = getActionPlanRecord(caseRecord.Id);
        	ap.OwnerId = sercoAgent1.Id;
            ap.Parent_Action_Plan__c = parentAp.Id;
            ap.OwnerId = currentUser;
        	ap.RecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CHILD_AP_RECORDTYPE_API_NAME].Id;
            insert ap;
        
            list <Action_Plan__Share> shareRecords = [Select Id From Action_Plan__Share Where UserOrGroupId =: sercoAgent1.Id];
            system.assertEquals(2, shareRecords.size());    
            shareRecords = [Select Id From Action_Plan__Share Where UserOrGroupId =: currentUser];
            system.assertEquals(1, shareRecords.size());    
        Test.stopTest();
    }
    
    static testMethod void shareChildApWithParentApOwnerUpdatedTest1() {
        Case caseRecord;
        Action_Plan__c parentAp;
        User sercoAgent1 = [Select Id From User Where Email = 'md@demo.com' limit 1];
        User sercoAgent2 = [Select Id From User Where Email = 'sd@demo.com' limit 1]; 
        
        Id currentUser = UserInfo.getUserId();
        
        system.runAs(sercoAgent1) {
            caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord; 
            
            parentAp = getActionPlanRecord(caseRecord.Id);
            insert parentAp;
        }
         
        Test.startTest();   
        	Action_Plan__c ap = getActionPlanRecord(caseRecord.Id);
            ap.OwnerId = sercoAgent1.Id;
        	ap.Parent_Action_Plan__c = parentAp.Id;
        	ap.RecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CHILD_AP_RECORDTYPE_API_NAME].Id;
            insert ap;
            
            parentAp.OwnerId = currentUser;
            update parentAp;
        
            list <Action_Plan__Share> shareRecords = [Select Id From Action_Plan__Share Where UserOrGroupId =: currentUser];
            system.assertEquals(2, shareRecords.size());    
        Test.stopTest();
    }
    
    public static Action_Plan__c getActionPlanRecord(Id caseId) {
        return new Action_Plan__c(Parent_Case__c = caseId,
                                  Status__c = 'New',
                                  Type__c = 'Referral');
    }
}