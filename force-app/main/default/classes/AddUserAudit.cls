public class AddUserAudit {
    
    @future    
     public static void createUserAuditRecord(Id auditedUserId, Id last_Modified_By_User, Datetime last_Modified_Date, String activation_Status, String userLicense, String agency){

		list<User_Audit__c> userAudits = new list<User_Audit__c>();
        //Add user Audit 
         User_Audit__c userAudit = new User_Audit__c();
         userAudit.Activation_Status__c = activation_Status;
         userAudit.Last_Modified_By_User__c = last_Modified_By_User;
         userAudit.Last_Modified_Date__c = last_Modified_Date;
         userAudit.Audited_User_Id__c = auditedUserId;
         userAudit.User_License__c = userLicense;
         userAudit.Agency__c = agency;
         userAudits.add(userAudit);
         
       if(!userAudits.isEmpty() && !Test.isRunningTest())
            insert userAudits;
    }
}