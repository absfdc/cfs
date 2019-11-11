global class EmailServicePreprocessorHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        System.debug(LoggingLevel.INFO, 'Email details ' + email);
        String subject = email.subject;
        Integer startIndex = 0;
        Integer endIndex = 0;
        if(subject != null) {
            startIndex = subject.lastIndexOf('._');
            endIndex = subject.lastIndexOf(':ref');
        }
        
        String subRefStr = null;                        
        if((startIndex + 2) < endIndex) {
            subRefStr = subject.substring(startIndex + 2, endIndex);
            subRefStr = subRefStr.subString(0,4) + subRefStr.subString(5);
            System.debug('Reference id from subject: ' + subRefStr);
        }
        
        String body = email.plainTextBody;
        String bodyRefStr = null;
        if(body != null) {
            startIndex = body.lastIndexOf('._');
            endIndex = body.lastIndexOf(':ref');
        }
        
        if((startIndex + 2) < endIndex) {
            bodyRefStr = body.substring(startIndex + 2, endIndex);
            bodyRefStr = bodyRefStr.subString(0,4) + bodyRefStr.subString(5);
            System.debug('Reference id from body: ' + bodyRefStr);
        }
        if(bodyRefStr == null && subRefStr == null) {
            preventCaseCreationToInvalidAddr(email);
        } else {
            forwardToE2CAddress(email);
        }
        
        result.success = true;    
        return result; 
    }  

    private void forwardToE2CAddress(Messaging.InboundEmail msg) {
        //forward to E2C
        Set<String> toAddresses = new Set<String>();
        for(String str : msg.toAddresses) {
            toAddresses.add(str.toLowerCase());
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(msg.ccAddresses != null && !msg.ccAddresses.isEmpty()) {
            mail.setCcAddresses(msg.ccAddresses);
        }
        if(msg.htmlBody != null) {
            mail.setHtmlBody(msg.htmlBody);
        }
        if(msg.inReplyTo != null) {
            mail.setInReplyTo(msg.inReplyTo);
        }
        if(msg.plainTextBody != null) {
            mail.setPlainTextBody(msg.plainTextBody);
        }
        if(msg.subject != null) {
            mail.setSubject(msg.subject);
        }
        if(msg.references != null) {
            mail.setReferences(msg.references[0]);
        }
        
        List<String> toAddressesList = new List<String>();
        Map<String, IncomingEmailToProcessForE2C__c> e2CToprocess = IncomingEmailToProcessForE2C__c.getAll();
        for(String key : e2CToprocess.keySet()) {
            if(toAddresses.contains(e2CToprocess.get(key).Email_Address__c.toLowerCase())) {
                toAddressesList.add(e2CToprocess.get(key).E2C_sf_address__c);
            }
        }
        mail.setToAddresses(toAddressesList);
        
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        
        List<Messaging.InboundEmail.BinaryAttachment> binAttachments = msg.binaryAttachments;
        if(binAttachments == null) {
            binAttachments = new List<Messaging.InboundEmail.BinaryAttachment>();
        }
        List<Messaging.InboundEmail.TextAttachment> textAttachments = msg.textAttachments;
        if(textAttachments == null) {
            textAttachments = new List<Messaging.InboundEmail.TextAttachment>();
        }
        for(Messaging.InboundEmail.TextAttachment txt : textAttachments) {
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName(txt.fileName);
            for(Messaging.InboundEmail.Header header : txt.headers) {
                if(header.name.equalsIgnoreCase('Content-Type')) {
                    attach.setContentType(header.value);
                }
            }
            attach.setBody(Blob.valueOf(txt.body));
            fileAttachments.add(attach);
        }
        for(Messaging.InboundEmail.BinaryAttachment bin : binAttachments) {
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName(bin.fileName);
            for(Messaging.InboundEmail.Header header : bin.headers) {
                if(header.name.equalsIgnoreCase('Content-Type')) {
                    attach.setContentType(header.value);
                }
            }
            attach.setBody(bin.body);
            fileAttachments.add(attach);
        }
        
        if(!fileAttachments.isEmpty()) {
            mail.setFileAttachments(fileAttachments);
        }
        if(!toAddressesList.isEmpty()) {
            System.debug(LoggingLevel.INFO,'Sending email to E2C');
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail});
        }            
    }
    
    private void preventCaseCreationToInvalidAddr(Messaging.InboundEmail msg) {
        Map<String, IncomingEmailsToExcludeFromE2C__c> emailsToExclude = IncomingEmailsToExcludeFromE2C__c.getAll();
        Set<String> toAddresses = new Set<String>();
        for(String str : msg.toAddresses) {
            toAddresses.add(str.toLowerCase());
        }
        Boolean excludeFromE2C = false;
        for(String e2c : emailsToExclude.keySet()) {
            if(toAddresses.contains(emailsToExclude.get(e2c).E2C_Address__c.toLowerCase())) {
                System.debug(LoggingLevel.INFO,'Need to send error response');
                CustomerFailureResponseSenderForE2C.sendResponse(msg, emailsToExclude.get(e2c).Template_Name__c);         
                excludeFromE2C = true;
                break;
            }            
        }
        if(!excludeFromE2C) {
            forwardToE2CAddress(msg);
        }
    }
}