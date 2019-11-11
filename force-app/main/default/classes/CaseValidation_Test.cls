/**********************************************************************************************
Created By:     Ian Fitzgerald
Created date:   11/May/2017
Description:  Test class for "validation" method in CaseBeforeUpdateTriggerHandler

Changes:

************************************************************************************************/
@isTest
private class CaseValidation_Test { 
    
    private static User nswTrainsUser;
    Private static Contact SME_1, SME_2;
    static void setup() {
        Account smeParentAccount = new Account(Name='NSW Trains');
        insert smeParentAccount;
        Account smeAccount = new Account (Name='SME Account', ParentId = smeParentAccount.Id);
        insert smeAccount;
        RecordType staffRT = [select Id from RecordType where SobjectType ='Contact'  and DeveloperName = 'Staff' limit 1];
        SME_1 = new Contact(LastName='SME1', AccountId = smeAccount.Id, RecordTypeId=staffRT.Id);
        insert SME_1;
        SME_2 = new Contact(LastName='SME2', AccountId = smeAccount.Id, RecordTypeId=staffRT.Id);
        insert SME_2;
        //Use system.runAs to get around Mixed DML Error
        System.runAs(new User(Id = Userinfo.getUserId())) {
            nswTrainsUser = createTestUser('NSW Trains Case Manager','NSW_Trains');
        }
    }
        
    @isTest
    static void smeAssignPositiveTest() {
        setup();
        Case smeCase = createCase();
        smeCase.ownerId=nswTrainsUser.Id;
        insert smeCase;
        
        System.runAs(nswTrainsUser ) {
            smeCase.assigned_SME__c = SME_1.Id;
            update smeCase;
        }
     }
     
     @isTest
    static void smeAssignNegativeTest() {
        setup();
        Case smeCase = createCase();
        smeCase.ownerId=nswTrainsUser.Id;
        insert smeCase;
        
        smeCase.assigned_SME__c = SME_1.Id;
        try{
           update smeCase;
        }
        catch(System.DmlException dmlException){
            String errorMsg = dmlException.getMessage();
            System.Assert(errorMsg.contains('You are not allowed to assign other departments SME to Case'));
        }   
     }
     
     @isTest
    static void smeAssignPositiveBulkTest() {
        setup();
        List<Case> bulkTestList = new List<Case>();
        for (Integer i = 0; i<100; i++){
             Case smeCase = createCase();
             smeCase.ownerId=nswTrainsUser.Id;
             bulkTestList.add(smeCase);
        }
        insert bulkTestList;
        System.runAs(nswTrainsUser ) {
            for (Case c : bulkTestList){
                c.assigned_SME__c = SME_1.Id;
            }    
            Test.StartTest();
            update bulkTestList;
            Test.StopTest();
        }
     }
        
        
    private static Case createCase() {
        Case caseRecord = new Case();
        caseRecord.Taxonomy_Location__c = 'Sydney';
        caseRecord.Agency__c = '';
        caseRecord.Origin = 'Web';
        caseRecord.Priority = 'Normal';
        caseRecord.Type = 'Complaint';
        caseRecord.Description = 'Test case'; 
        system.debug('createCase  return');
        return caseRecord;
    }   
    
    private static User createTestUser(String profileName, String RoleName) {
        User user = new User();
        user.Username = 'smetest'+ System.currentTimeMillis() + '@demo.com';
        user.LastName = 'SMETest';
        user.Email = 'SMETest@demo.com';
        user.alias = 'SMETestl';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.UserPermissionsKnowledgeUser = true;
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [Select Id From Profile Where Name =: profileName].Id;
        user.UserRoleId = [Select Id From UserRole Where DeveloperName =: RoleName].Id;
        user.LanguageLocaleKey = 'en_US';
        user.isActive = true;
        insert user;
        return user;
    }
    
}