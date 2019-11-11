@isTest
private class UserAfterUpdateTriggerHandler_Test {
    

    @testSetup
    static void createCustomSetting(){
        TriggerSwitch__c newTriggerSwitch = new TriggerSwitch__c();
        newTriggerSwitch.Name = 'User';
        newTriggerSwitch.On__c = true;
        insert newTriggerSwitch;
    }

    @isTest static void testSetUserPassword() {

        
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Signatory'];
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
        
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Minister', LanguageLocaleKey='en_US',Temporary_Password__c ='zruknre@123',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='minister' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
        
        update u1;
    }
    
}