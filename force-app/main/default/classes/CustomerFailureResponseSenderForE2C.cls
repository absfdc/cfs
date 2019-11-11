public without sharing class CustomerFailureResponseSenderForE2C {
    
    public static void sendResponse(Messaging.InboundEmail email, String templateName) {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE Name = :String.escapeSingleQuotes(templateName) AND IsActive = true];
        List<OrgWideEmailAddress> orgWideAddr = [Select Id From OrgWideEmailAddress Where DisplayName =:GlobalConstants.NOREPLY_ORGWIDE_EMAIL limit 1];
        if(!templates.isEmpty()) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTemplateId(templates[0].Id);
            msg.setTargetObjectId(UserInfo.getUserId());
            msg.setSaveAsActivity(false);
            SavePoint sp = Database.setSavePoint();
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {msg});
            Database.rollback(sp);
            System.debug(LoggingLevel.INFO, 'Email body for customer response: ' + msg.plainTextBody);
            
            Messaging.SingleEmailMessage customerResponse = new Messaging.SingleEmailMessage();
            customerResponse.setPlainTextBody(msg.plainTextBody);
            customerResponse.setHtmlBody(msg.htmlBody);
            customerResponse.setToAddresses(new List<String> {email.fromAddress});
            customerResponse.setSubject(msg.getSubject());
            
            if(!orgWideAddr.isEmpty()) {
                customerResponse.setOrgWideEmailAddressId(orgWideAddr[0].Id);
            }
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {customerResponse});
        }
    }
}