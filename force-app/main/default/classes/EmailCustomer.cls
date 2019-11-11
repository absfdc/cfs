/*------------------------------------------------------------
Author:        Arxxus
Description:   class for sending email for wet signature functionality
Test Class:     EmailCustomer_Test
History
<Date>          <Authors Name>     <Brief Description of Change>
12-DEC-2016     Arxxus          Comments and cleanup
12-SEP-2017     Ian F           Added check for empty email list before sending
16-JUL-2017     Abhi I          SFCOE-3186 - Commented workaround to log the duplicate activity
------------------------------------------------------------*/
global with sharing class EmailCustomer {

    public static Map <String,MO_Template_by_Response_Type__c> templateMap = new Map <String,MO_Template_by_Response_Type__c>();
    public static String emailFromAddress = 'Transport Feedback (no reply)';
    public static String fromAddress {get; set;}
    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   send email to Customer, Staff Contact and Additional Recipients
    Inputs:        case id
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    12-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    webService static String prepareAndSendEmail(Id caseId) {
        
        List<ApplicationLogMessage> logMessages = new List<ApplicationLogMessage>();
        try {
            
            
            system.debug('sendEmailAfterApproval called :: ' + caseId);

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            List<String> bccEmailAddress = new List<String>();
            bccEmailAddress.add(UserInfo.getUserEmail());
          
            EmailMessage inboundEmail;

            templateMap = MO_Template_by_Response_Type__c.getAll();

            List<Case> getCaseContact = [Select Id, Contact_Email__c, Contact.Id, Response_Type__c, Staff_Contact__c, Staff_Contact__r.Email 
                                          FROM Case 
                                          WHERE Id = : caseId ];

            Id orgWideAddressId;

            List<OrgWideEmailAddress> getOrgWideAddressList = [Select Id, Address 
                                                                FROM OrgWideEmailAddress 
                                                                WHERE DisplayName =: emailFromAddress
                                                                LIMIT 1 ];

            if (getOrgWideAddressList.size() > 0){
                orgWideAddressId = getOrgWideAddressList[0].Id;
                fromAddress = getOrgWideAddressList[0].Address;
            }

            String ccemailAddress = '';

            // check custom setting for MO Approval email template
            if(templateMap.containsKey(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE)){

                // Do not send automatic email to additional corro recepients when response type is 'Referred to other portfolio' and 'Partial Referral' 
                if( getCaseContact.size() > 0 
                    && ( getCaseContact[0].Response_Type__c != GlobalConstants.CASE_RESPONSE_TYPE_PARTIAL_REFERRAL
                        && getCaseContact[0].Response_Type__c != GlobalConstants.CASE_RESPONSE_TYPE_ADMIN_REFERRAL ) ) {


                    List<Additional_Corro_Recipients__c> corroEmailList = new List <Additional_Corro_Recipients__c> ();
                    
                    // get all additional corro recepients
                    for(Additional_Corro_Recipients__c getAdditionalCorro: [Select Id, Contact__c, Contact__r.Name, Contact__r.Email, Case__c
                                                                              FROM Additional_Corro_Recipients__c
                                                                              WHERE Case__c = : caseId ]) {
                        corroEmailList.add(getAdditionalCorro);
                    }

                    Set<String> getAttachmentId = new Set <String> ();

                    if(corroEmailList.size() > 0) {

                        // check custom setting for MO Approval email template
                        //if(templateMap.containsKey(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE)){

                        if(templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Additional_Contacts_Email_Template__c != null){

                            List<EmailTemplate> additionalCorroTemplateId = [Select id from EmailTemplate 
                                                                                where DeveloperName =: templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Additional_Contacts_Email_Template__c limit 1 ];
                                // create an email attachment
                            if(additionalCorroTemplateId.size() > 0){

                                if(templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Additional_Contact_Attachment_Categories__c !=null){
                            
                                    Set<String> categories=new Set<String>(templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Additional_Contact_Attachment_Categories__c.split(','));
                            
                                    // get all categories for additional corro mentioned in custom settings
                                    if(categories.contains(GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE)){

                                        // get latest signed response
                                        for(NoteOrAttachment__c customAttachment: [Select Id, Name, Case__c, Attachment_Id__c, Category__c
                                                                        FROM NoteOrAttachment__c
                                                                        WHERE Case__c = : caseId
                                                                        AND Attachment_Id__c != NULL
                                                                        AND Category__c =: GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE
                                                                        ORDER BY CreatedDate DESC LIMIT 1 ]) {
                                            getAttachmentId.add(customAttachment.Attachment_Id__c);
                                        }

                                    }

                                    // if there is signed response then get all Incoming and Enclosure documents
                                    if(getAttachmentId.size() > 0){

                                        categories.remove(GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE);

                                        for(NoteOrAttachment__c customAttachment: [Select Id, Name, Case__c, Attachment_Id__c, Category__c
                                                                                    FROM NoteOrAttachment__c
                                                                                    WHERE Case__c = : caseId
                                                                                    AND Attachment_Id__c != NULL
                                                                                    AND Category__c IN :categories ]) {
                                            getAttachmentId.add(customAttachment.Attachment_Id__c);
                                        }
                                    }

                                }

                                // Create the email attachment
                                List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();

                                // get all SF attachments required
                                for(Attachment getAttachment: [SELECT Id, Name, ContentType, Body FROM Attachment WHERE Id IN: getAttachmentId]) {

                                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                                    efa.setBody(getAttachment.Body);
                                    efa.setContentType(getAttachment.ContentType);
                                    efa.setInline(false);
                                    efa.setFileName(getAttachment.Name);
                                    efaList.add(efa);
                                }
                                    
                                system.debug('sfalist :: ' + efaList);

                                for(Additional_Corro_Recipients__c tempGetAdditionalCorro: corroEmailList) {

                                    if(tempGetAdditionalCorro.Contact__c != NULL) {
                                        
                                        Messaging.SingleEmailMessage sendCorroEmail = new Messaging.SingleEmailMessage();
                                        
                                        sendCorroEmail.setTemplateID(additionalCorroTemplateId[0].Id);

                                        sendCorroEmail.setWhatId(caseId);
                                        sendCorroEmail.setOrgWideEmailAddressId(orgWideAddressId);

                                        sendCorroEmail.setTargetObjectId(tempGetAdditionalCorro.Contact__c);
                                        sendCorroEmail.setToAddresses(new List < String > {
                                            tempGetAdditionalCorro.Contact__r.Email
                                        });

                                        if(bccEmailAddress.size() > 0) {
                                            sendCorroEmail.setBccAddresses(bccEmailAddress);
                                        }

                                        if(efaList.size() > 0)
                                            sendCorroEmail.setFileAttachments(efaList);

                                        emails.add(sendCorroEmail);
                                        System.debug('get sendCorroEmail :: ' + sendCorroEmail);
                                    }
                                }
                            }
                        }
                    }   
                }

                if(getCaseContact.size() > 0 && getCaseContact[0].Contact_Email__c != NULL 
                    && templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Contact_Attachment_Categories__c != null
                    && templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Customer_Email_Template__c != null  ) {

                    Messaging.SingleEmailMessage sendEmail = new Messaging.SingleEmailMessage();
                    List<EmailTemplate> templateId = [Select id from EmailTemplate 
                                                        where DeveloperName =: templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Customer_Email_Template__c
                                                        limit 1];

                    if (templateId.size() == 0)
                        return '';

                    Set<String> categories=new Set<String>(templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Contact_Attachment_Categories__c.split(','));
                    Set<String> getAttachmentId = new Set <String> ();                
                    // get all categories for additional corro mentioned in custom settings
                    if(categories.contains(GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE)){

                        // get latest signed response
                        for(NoteOrAttachment__c customAttachment: [Select Id, Name, Case__c, Attachment_Id__c, Category__c
                                                        FROM NoteOrAttachment__c
                                                        WHERE Case__c = : caseId
                                                        AND Attachment_Id__c != NULL
                                                        AND Category__c =: GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE
                                                        ORDER BY CreatedDate DESC LIMIT 1 ]) {
                            getAttachmentId.add(customAttachment.Attachment_Id__c);
                        }

                    }

                    // if there is signed response then get all Incoming and Enclosure documents
                    if(getAttachmentId.size() > 0){

                        categories.remove(GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE);

                        for(NoteOrAttachment__c customAttachment: [Select Id, Name, Case__c, Attachment_Id__c, Category__c
                                                                    FROM NoteOrAttachment__c
                                                                    WHERE Case__c = : caseId
                                                                    AND Attachment_Id__c != NULL
                                                                    AND Category__c IN :categories ]) {
                            getAttachmentId.add(customAttachment.Attachment_Id__c);
                        }
                    }
                    
                    // Create the email attachment
                    List<Messaging.Emailfileattachment> efaContactList = new List<Messaging.Emailfileattachment>();
                    
                    // get all SF attachments required
                    for(Attachment getAttachment: [SELECT Id, Name, ContentType, Body FROM Attachment WHERE Id IN: getAttachmentId]) {

                        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                        efa.setBody(getAttachment.Body);
                        efa.setContentType(getAttachment.ContentType);
                        efa.setInline(false);
                        efa.setFileName(getAttachment.Name);
                        efaContactList.add(efa);
                    }

                    sendEmail.setTemplateID(templateId[0].Id);

                    sendEmail.setWhatId(caseId);
                    sendEmail.setOrgWideEmailAddressId(orgWideAddressId);

                    if(getCaseContact.size() > 0) {
                        sendEmail.setTargetObjectId(getCaseContact[0].Contact.Id);
                        sendEmail.setToAddresses(new List<String> {
                            getCaseContact[0].Contact_Email__c
                        });
                    }

                    if(bccEmailAddress.size() > 0) {
                        sendEmail.setBccAddresses(bccEmailAddress);
                    }

                    if(efaContactList.size() > 0)
                        sendEmail.setFileAttachments(efaContactList);

                    sendEmail.setTreatTargetObjectAsRecipient(false);
                    emails.add(sendEmail);
                    System.debug('get Email :: ' + sendEmail);

                    //SFCOE-3186 - Start
                    // Duplicate activity being logged 
                    /*
                    Messaging.SingleEmailMessage email =
                        Messaging.renderStoredEmailTemplate(templateId[0].Id, getCaseContact[0].Contact.Id, caseId);

                    inboundEmail = new EmailMessage(FromAddress = fromAddress,
                                                    ToAddress = getCaseContact[0].Contact_Email__c,
                                                    HtmlBody = email.getHTMLBody(),
                                                    Incoming = false,
                                                    ParentId = caseId,
                                                    Subject = email.getSubject(),
                                                    MessageDate = system.now(),
                                                    Status = '3',
                                                    TextBody = email.getPlainTextBody()
                    );
                    */
                    //SFCOE-3186 - End
                }

                if (getCaseContact.size() > 0 && getCaseContact[0].Staff_Contact__c != NULL 
                    && getCaseContact[0].Staff_Contact__r.Email != NULL
                    && templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Staff_Attachment_Categories__c != null
                    && templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Staff_Email_Template__c != null ) {
                    
                    Messaging.SingleEmailMessage sendStaffContactEmail = new Messaging.SingleEmailMessage();
                    List <EmailTemplate> staffTemplateId = [Select id from EmailTemplate 
                                                            where DeveloperName =: templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Staff_Email_Template__c
                                                            limit 1];

                    if (staffTemplateId.size() == 0)
                        return '';

                    Set<String> categories=new Set<String>(templateMap.get(GlobalConstants.MO_APPROVAL_EMAIL_TEMPLATE_TYPE).Staff_Attachment_Categories__c.split(','));
                    Set<String> getAttachmentId = new Set <String> ();

                    // get all categories for additional corro mentioned in custom settings
                    if(categories.contains(GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE)){

                        // get latest signed response
                        for(NoteOrAttachment__c customAttachment: [Select Id, Name, Case__c, Attachment_Id__c, Category__c
                                                        FROM NoteOrAttachment__c
                                                        WHERE Case__c = : caseId
                                                        AND Attachment_Id__c != NULL
                                                        AND Category__c =: GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE
                                                        ORDER BY CreatedDate DESC LIMIT 1 ]) {
                            getAttachmentId.add(customAttachment.Attachment_Id__c);
                        }

                    }

                    // if there is signed response then get all Incoming and Enclosure documents
                    if(getAttachmentId.size() > 0){

                        categories.remove(GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE);

                        for(NoteOrAttachment__c customAttachment: [Select Id, Name, Case__c, Attachment_Id__c, Category__c
                                                                    FROM NoteOrAttachment__c
                                                                    WHERE Case__c = : caseId
                                                                    AND Attachment_Id__c != NULL
                                                                    AND Category__c IN :categories ]) {
                            getAttachmentId.add(customAttachment.Attachment_Id__c);
                        }
                    }
                    
                    // Create the email attachment
                    List<Messaging.Emailfileattachment> efaStaffList = new List<Messaging.Emailfileattachment>();
                    
                    // get all SF attachments required
                    for(Attachment getAttachment: [SELECT Id, Name, ContentType, Body FROM Attachment WHERE Id IN: getAttachmentId]) {

                        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                        efa.setBody(getAttachment.Body);
                        efa.setContentType(getAttachment.ContentType);
                        efa.setInline(false);
                        efa.setFileName(getAttachment.Name);
                        efaStaffList.add(efa);
                    }    

                    sendStaffContactEmail.setTemplateID(staffTemplateId[0].Id);

                    sendStaffContactEmail.setWhatId(caseId);
                    sendStaffContactEmail.setOrgWideEmailAddressId(orgWideAddressId);

                    sendStaffContactEmail.setTargetObjectId(getCaseContact[0].Staff_Contact__c);
                    sendStaffContactEmail.setToAddresses(new List < String > {
                        getCaseContact[0].Staff_Contact__r.Email
                    });

                    if(bccEmailAddress.size() > 0) {
                        sendStaffContactEmail.setBccAddresses(bccEmailAddress);
                    }

                    sendStaffContactEmail.setSaveAsActivity(false);

                    if(efaStaffList.size() > 0)
                        sendStaffContactEmail.setFileAttachments(efaStaffList);

                    emails.add(sendStaffContactEmail);
                    System.debug('get sendStaffContactEmail :: ' + sendStaffContactEmail);

                }
            }    

            System.debug('get Emails :: ' + emails);
            
            //check for empty list - Ian F 12/09/2017
            if (emails.size()>0){
                Messaging.SendEmailResult[] r = Messaging.sendEmail(emails);

                if(r[0].isSuccess()) {

                    Case updateCase = new Case();
                    updateCase.Id = caseId;
                    updateCase.Status = GlobalConstants.MO_SIGNED_AND_EMAILED_MIN_CORRO;
                    update updateCase;

                    //SFCOE-2414 - 09-04-2018 - If there is nothing to insert, do not attempt to do it - Start
                    if(inboundEmail!=null){
                    insert inboundEmail;

                    System.debug('get attachments :: ' + emails[0].getFileAttachments());

                    if(emails[0].getFileAttachments() != null) {
                        Attachment[] attachments = new Attachment[] {};
                        Attachment attachment = null;
                        for(Integer i = 0; i < emails[0].getFileAttachments().size(); i++) {
                            attachment = new Attachment();
                            attachment.Name = emails[0].getFileAttachments()[i].getFileName();
                            attachment.Body = emails[0].getFileAttachments()[i].getBody();
                            attachment.ParentId = inboundEmail.Id;
                            attachment.ContentType = emails[0].getFileAttachments()[i].getContentType();
                            attachments.add(attachment);
                        }
                        insert attachments;
                    }
                }
                    //SFCOE-2414 - 09-04-2018 - End
                    
                    return 'Success';
                }
                System.debug('Emails Error:' + r);
            }       

        } catch (Exception e) {

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'EmailCustomer';
            message.sourceFunction = 'prepareAndSendEmail';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            logMessages.add(message);
            ApplicationLogUtility.logMessage(logMessages);
            logMessages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            Throw(e);
        }

        return '';
    }
}