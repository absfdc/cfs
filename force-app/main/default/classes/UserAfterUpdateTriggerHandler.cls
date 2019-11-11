public with sharing class UserAfterUpdateTriggerHandler {
    public static void setUserPassword(List<User> userlist){
        for(User newUser : userlist){       
            system.debug('new user :: ' + newUser );
            if(newUser.Temporary_Password__c != null){
                System.setPassword(newUser.Id, newUser.Temporary_Password__c);
            }
        }
    }
}