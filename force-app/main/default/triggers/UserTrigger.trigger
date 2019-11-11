trigger UserTrigger on User (after update, before update, after insert) { 
    if(Trigger.isAfter && Trigger.isUpdate){
        Boolean isOn;
        Map<String,TriggerSwitch__c> checkTriggerSwitch = TriggerSwitch__c.getAll();
        if(checkTriggerSwitch.size() > 0){

            isOn = checkTriggerSwitch.get('User').On__c;
        }
        
        if(isOn == true){
            UserAfterUpdateTriggerHandler.setUserPassword(Trigger.new);
        }
    }
    

//JIRA# SFCOE-1837 Add User License Audit information - 26-05 Start
    
        if(Trigger.isBefore && Trigger.isUpdate){
        
        for (Id aUserId : Trigger.newMap.keySet()) {
            User oldUser = (User) Trigger.oldMap.get(aUserId);
            User newUser = (User) Trigger.newMap.get(aUserId);
            
            if (oldUser.IsActive != newUser.IsActive){
                AddUserAudit.createUserAuditRecord(newUser.Id, UserInfo.getUserId(), datetime.now(), (newUser.IsActive)?'User Activated':'User Deactivated', newUser.User_License__c, newUser.Agency__c);
            }
        }
    }
    
    
    
    if(Trigger.isAfter && Trigger.isInsert){
        
        for (Id aUserId : Trigger.newMap.keySet()) {
            User newUser = (User) Trigger.newMap.get(aUserId);

            AddUserAudit.createUserAuditRecord(newUser.Id, UserInfo.getUserId(), datetime.now(), 'New User Created', newUser.User_License__c, newUser.Agency__c);
        }
    }    
//JIRA# SFCOE-1837 Add User License Audit information - 26-05 End    
}