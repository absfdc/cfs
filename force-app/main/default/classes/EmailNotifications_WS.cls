global without sharing class EmailNotifications_WS {
    
	private static Id noReplyOrgWideEmailAddressId;
    
    static {
        
        noReplyOrgWideEmailAddressId = [Select Id 
                                        From OrgWideEmailAddress 
                                        Where DisplayName =: GlobalConstants.NOREPLY_ORGWIDE_EMAIL limit 1].Id;
    }
    
    webservice static boolean notifyCOOnRejectedDueToIncorrectAssignment(String actionPlanId) { 
        try {
        	if(actionPlanId == null || actionPlanId == '')
                return false;
            
            EmailTemplate et = [Select Id From EmailTemplate Where DeveloperName =: GlobalConstants.REJECTED_AP_NOTIFICATION_EMAIL_TEMPLATE limit 1];
            Action_Plan__c ap = [Select Id, Parent_AP_Owner_Id__c From Action_Plan__c Where Id =: actionPlanId limit 1];
            System.debug('-----@Email Action Plan----' + et + '--' + ap);
            if(ap.Parent_AP_Owner_Id__c == null || ap.Parent_AP_Owner_Id__c == '')
                return false;
                
            sendEmail(et.Id, ap.Id, ID.valueOf(ap.Parent_AP_Owner_Id__c));
            return true;
        }Catch(Exception e) {
            System.debug('-----@Email Not Sent----' + e.getMessage() + e.getLineNumber());
            return false;
        }
    }
    
    webservice static boolean notifyCOWhenSMESubmitsActionPlanForReview(String actionPlanId) { 
        try {
        	if(actionPlanId == null || actionPlanId == '')
                return false;
            
            EmailTemplate et = [Select Id From EmailTemplate Where DeveloperName =: GlobalConstants.AP_SBMITTED_FOR_REVIEW_NOTIFICATION_EMAIL_TEMPLATE limit 1];
            Action_Plan__c ap = [Select Id, Parent_AP_Owner_Id__c From Action_Plan__c Where Id =: actionPlanId limit 1];
            System.debug('-----@Email Action Plan----' + et + '--' + ap);
            if(ap.Parent_AP_Owner_Id__c == null || ap.Parent_AP_Owner_Id__c == '')
                return false;
            
            sendEmail(et.Id, ap.Id, ID.valueOf(ap.Parent_AP_Owner_Id__c));
            return true;
        }Catch(Exception e) {
            //ID.valueOf(ap.Parent_AP_Owner_Id__c)
            System.debug('-----@Email Not Sent----' + e.getMessage() + e.getLineNumber());
            return false;
        }
    }
    
    private static void sendEmail(Id emailTemplateId, Id whatId, Id targetObjectId) {
        System.debug('-----@Email Parameters----' + emailTemplateId + '--' + whatId + '--' + targetObjectId);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(targetObjectId);
        email.setWhatId(whatId);
        email.setOrgWideEmailAddressId(noReplyOrgWideEmailAddressId);
        email.setTemplateId(emailTemplateId);
        email.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        System.debug('-----@Email Sent----');
    }
}