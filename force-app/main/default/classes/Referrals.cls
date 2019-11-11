/*---------------------------------------------------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus
Description:   class for sending referrals, to differnet people associated witha case.
                based on the custom settings referral_template_by_response_type__c
                 which relates the templates to be used, the attachments category included 
                 for the kind of recipients.
Test Class:     SendReferralTest
History
<Date>        <Authors Name>     <Brief Description of Change>
07-DEC-2016   Dipankar          Comments and cleanup
20/09/2017    Arxxus            Oct Release: Added dropdown to select email address. Change made to inner class: Recipents
								add logic to prefill the input box on UI with either MO Eamil or Electorate Email
-------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class Referrals {
    
    public Map<Id,Additional_Corro_Recipients__c> acreps{public get;public set;}
    public List<Recipient> recipients{public get;public set;}
    public Id caseId{get;set;}
    public String CaseNumber{get;set;}
    public Id staffContact{get;set;}
    public Id caseContactId{get;set;}
    public Map <String,referral_template_by_response_type__c> templateMap ;
    
    Map <String, Id> templateIdByDevName;
    
    public String responseType;
    public String contactEmailAddress;
    public String emailFromAddress = 'Transport Feedback (no reply)';
    
    @TestVisible Case thisCase;
    @TestVisible Contact customer;
    @TestVisible Contact staff;
    @TestVisible List<Recipient> recipientsSent= new List<Recipient>();
    
    referral_template_by_response_type__c templateSetting;
    
    public static final string MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME = 'MemberOfParliament';
    
    private Id orgWideFromId;
    private String orgWideFromEmail;


    
    public Referrals(ApexPages.StandardSetController controller) {
        try{
            if(ApexPages.currentPage().getParameters().get('id').startsWith(GlobalConstants.CASE_ID_PREFIX)) {
                caseId=ApexPages.currentPage().getParameters().get('id');
                if (null ==thisCase) 
                    thisCase=[select Id, Response_type__c,caseNumber,Staff_Contact__c,ContactId,Contact_Email__c from Case where Id=:caseId];
                
                caseContactId=thisCase.ContactId;
                responseType=thisCase.Response_type__c;
                caseNumber=thisCase.CaseNumber;
                staffContact=thisCase.Staff_Contact__c;
                contactEmailAddress = thisCase.Contact_Email__c;
            }


            Map<Id,Additional_Corro_Recipients__c> acrepsOld =new Map<Id,Additional_Corro_Recipients__c>((List<Additional_Corro_Recipients__c>)controller.getSelected());
            if(acrepsOld.size()<1 ){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No recipients selected for sending referral'));
                return ;
            }
            system.debug('additional corro recipients -'+ acrepsOld.values());
            if(acreps==null) 
                acreps = new Map<Id,Additional_Corro_Recipients__c>([select Id, Contact__r.Record_Type_Dev_Name__c, Contact__r.MOEmail__c, Contact__r.IsEmailBounced, Contact__c, Contact__r.Email, Contact__r.Name, Case__c,Case__r.ContactId,Case__r.CaseNumber, Case__r.Response_type__c 
                                                                    from Additional_Corro_Recipients__c 
                                                                    where Id in:acrepsOld.keySet() ]);
            
            recipients= new List<Recipient>();
            for(Additional_Corro_Recipients__c acrecep:acreps.values())
            {   
                Recipient recipient= new Recipient();
                
                if(recipient.selectedEmailType == NULL)
                    recipient.selectedEmailType = 'MO Email';
               	
                if(acrecep.Contact__r.Record_Type_Dev_Name__c == 'MemberOfParliament' ) {
                    recipient.moEmail = acrecep.Contact__r.MOEmail__c;
                	recipient.elecEmail = acrecep.Contact__r.Email;
                }else{
                    recipient.nonMPEmail = acrecep.Contact__r.Email;
                }
                recipient.corroId = acrecep.Id;
                recipient.recipient=acrecep;
                if(acrecep.Case__c ==null || acrecep.Case__r.Response_type__c==null){
                    system.debug('no response type configured on case');
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'no response type configured on case'));
                    continue;
                }
                if(acrecep.Contact__r.IsEmailBounced ==true ){
                    system.debug('Email bounces from recipient - '+acrecep.Contact__r.Name+', '+acrecep.Contact__r.Email);
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Email bounces from recipients email addrss -'+acrecep.Contact__r.Email));
                    continue;
                }
                if(templateSetting==null){

                    //template is retrieved from custom setting by Response type
                    templateMap= new Map <String,referral_template_by_response_type__c>();
                    Set<String> templateDevNames=new Set<String>();
                    for (referral_template_by_response_type__c templateConf:referral_template_by_response_type__c.getAll().values()){
                        templateMap.put(templateConf.Name,templateConf);
                        if (templateConf.customer__c!=null)templateDevNames.add(templateConf.customer__c);
                        if (templateConf.Staff__c!=null)templateDevNames.add(templateConf.Staff__c);
                        if (templateConf.Additional_contacts__c!=null)templateDevNames.add(templateConf.Additional_contacts__c);

                    }
                    templateIdByDevName= new Map<String, Id> ();
                    for (EmailTemplate et :[select Id, DeveloperName from EmailTemplate where DeveloperName in:templateDevNames]){
                        templateIdByDevName.put(et.DeveloperName,et.Id);
                    }
                    templateSetting=templateMap.get(responseType);
                    if(templateSetting==null || templateIdByDevName==null ){
                        system.debug('No Referral template configured in custom setting for response type - '+responseType);
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No Referral template configured in custom setting for response type - '+responseType));
                        return;
                    }
                }
                if(templateIdByDevName.containsKey(templateSetting.Additional_contacts__c)){
                    Messaging.SingleEmailMessage email = 
                        Messaging.renderStoredEmailTemplate(templateIdByDevName.get(templateSetting.Additional_contacts__c), acrecep.Contact__c, caseId);
                    recipient.htmlBody = email.getHTMLBody();
                    recipient.subject = email.getSubject();
                    recipient.doSend=true;
                    recipient.type=RecipientType.ADDITIONAL_CONTACT;
                    if(templateSetting.Additional_contact_attachment_categories__c!=null){
                        Set<String> categories=new Set<String>(templateSetting.Additional_contact_attachment_categories__c.split(','));
                        recipient.attachments=getReferralAttachments(caseId,categories);
                    }

                    recipients.add(recipient);
                }else{
                    system.debug('No Referral template configured for Additional contacts for response type - '+responseType);
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No Referral template configured for Additional_contacts for response type - '+responseType));
                    return;
                }

            }
            //contact notification email          
            if(caseContactId!=null ){
                Recipient recipient= new Recipient();
                recipient.recipient=new Additional_Corro_Recipients__c(contact__c=caseContactId,Case__c=caseId);
                if(null==customer) 
                    customer= [Select Id , isEmailBounced from Contact where Id=:caseContactId];
                    
                if(customer.isEmailBounced!=true){
                    //template is retrieved from custom setting by Response type
                    if (templateSetting==null || !templateIdByDevName.containsKey(templateSetting.Customer__c)){
                        system.debug('No Customer notification template configured  for Referral');
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No Customer notification template configured for Referral - '+responseType));
                        return;
                    }
                    
                    Messaging.SingleEmailMessage email = 
                        Messaging.renderStoredEmailTemplate(templateIdByDevName.get(templateSetting.Customer__c),caseContactId, caseId);
                    recipient.htmlBody = email.getHTMLBody();
                    recipient.subject = email.getSubject();
                    recipient.type=RecipientType.CUSTOMER;
                    if(templateSetting.Customer_attachment_categories__c!=null){
                        Set<String> categories=new Set<String>(templateSetting.Customer_attachment_categories__c.split(','));
                        recipient.attachments=getReferralAttachments(caseId,categories);
                    }
                    if(contactEmailAddress != null)
                        recipient.contactEmail = contactEmailAddress;

                    recipients.add(recipient);
                }else{
                    system.debug('Email bounces from customer ');
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Email bounces from customer email addrss '));
                    
                }
                
            }
            //Staff notification email          
            if(staffContact!=null){
                Recipient recipient= new Recipient();
                recipient.recipient=new Additional_Corro_Recipients__c(contact__c=staffContact,Case__c=caseId);
                if(null ==staff) 
                    staff= [Select Id , isEmailBounced from Contact where Id=:staffContact];
                if(staff.isEmailBounced!=true){
                    //template is retrieved from custom setting by Response type
                    if(templateSetting==null || !templateIdByDevName.containsKey(templateSetting.staff__c)){
                        system.debug('No Staff notification template configured for Referral');
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,'No Staff notification template configured for response type - '+responseType));
                        return;
                    }
                    
                    Messaging.SingleEmailMessage email = 
                        Messaging.renderStoredEmailTemplate(templateIdByDevName.get(templateSetting.Staff__c),staffContact, caseId);
                    recipient.htmlBody = email.getHTMLBody();
                    recipient.subject = email.getSubject();
                    recipient.type=RecipientType.STAFF;
                    if(templateSetting.Staff_attachment_categories__c!=null){
                        Set<String> categories=new Set<String>(templateSetting.Staff_attachment_categories__c.split(','));
                        recipient.attachments=getReferralAttachments(caseId,categories);
                    }
                    recipients.add(recipient);
                }else{
                    system.debug('Email bounces from staff ');
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Email bounces from staff email addrss '));
                    
                }
                
            }
        }catch(Exception ex){
            system.debug('Exception occured - '+ex.getStackTraceString());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Exception occured - '+ex.getStackTraceString()));
            return;
        }
    }
    Messaging.SingleEmailMessage[] prepareEmails() {
        
        OrgWideEmailAddress[] owea = [select Id, Address, DisplayName from OrgWideEmailAddress where DisplayName =: emailFromAddress];
        
        if(owea.size() > 0) {
         
         orgWideFromId = owea.get(0).Id;
         orgWideFromEmail = owea.get(0).Address;
        }
        
        Messaging.SingleEmailMessage[] emails=new List<Messaging.SingleEmailMessage>() ;
        List<String> bccEmailAddress = new List<String>();
        bccEmailAddress.add(UserInfo.getUserEmail());
        
        for(Recipient recp:recipients){
            
            System.debug('recp mo Email '+recp.moEmail);
            System.debug('recp elec Email '+recp.elecEmail);
            
            if(!recp.doSend) continue;
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses;
            List<Messaging.EmailFileAttachment> efas=getEmailAttachments(recp.attachments);
            if(caseContactId != recp.recipient.Contact__c) {
            
             //toAddresses = recp.recipient.Contact__r.Record_Type_Dev_Name__c == MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recp.recipient.Contact__r.MOEmail__c != '' && recp.recipient.Contact__r.MOEmail__c != NULL?new List<String> {recp.recipient.Contact__r.MOEmail__c}:new List<String> {recp.recipient.Contact__c};
             if(recp.recipient.Contact__r.Record_Type_Dev_Name__c == MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recp.selectedEmailType == 'MO Email')
             toAddresses = new List<String> {recp.moEmail};
             else if(recp.recipient.Contact__r.Record_Type_Dev_Name__c == MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recp.selectedEmailType == 'Electorate Email')
             toAddresses = new List<String> {recp.elecEmail};
             else if(recp.recipient.Contact__r.Record_Type_Dev_Name__c != MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recp.selectedEmailType == 'MO Email')
             toAddresses = new List<String> {recp.nonMPEmail};
             else if(recp.recipient.Contact__r.Record_Type_Dev_Name__c != MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recp.selectedEmailType == 'Electorate Email')
             toAddresses = new List<String> {recp.nonMPSecondaryEmail};
             
             email.setTreatTargetObjectAsRecipient(false);
             
            }
            else if(caseContactId == recp.recipient.Contact__c){
                toAddresses = new List<String> {caseContactId};
            }
            else if (staffContact == recp.recipient.Contact__c){
                toAddresses = new List<String> {staffContact};
            }

            if(recp.contactEmail != null){
               toAddresses = new List<String> {recp.contactEmail};        
               email.setTreatTargetObjectAsRecipient(false);
            }
            if(efas!=null && efas.size()>0) email.setFileAttachments(efas);

            // Sets the paramaters of the email


            email.setSubject( recp.subject );
            email.setToAddresses( toAddresses);
            email.setHtmlBody( recp.htmlBody );
            email.setOptOutPolicy('FILTER');
            email.setOrgWideEmailAddressId(orgWideFromId);
            email.setWhatId(caseId);
            email.setTargetObjectId(recp.recipient.Contact__c);
            email.setBccAddresses(bccEmailAddress);
            emails.add(email);
            recipientsSent.add(recp);
        }
        return emails;
            
    }
    List<Additional_Corro_Recipients__c> getRecipientsForUpdate(Messaging.SendEmailResult [] sers, Messaging.SingleEmailMessage[] emails,List<Recipient> recipientsSent) {
    
        List<Additional_Corro_Recipients__c> recipientsForUpdate= new List<Additional_Corro_Recipients__c>();
        Map<String, EmailMessage> emailMessagesMap = new Map<String, EmailMessage>();
        
        Map<String, List<Attachment>> emailMessagesAttachmentAssociation = new Map<String, List<Attachment>>();
        
        for(Integer ie = 0; ie < sers.size(); ie++) {
            
            Messaging.SendEmailResult ser = sers[ie];
            Messaging.SingleEmailMessage email = emails[ie];

            Recipient recipient = recipientsSent[ie];

            if(ser.isSuccess()) {
                
                if(recipient.recipient.Contact__c == caseContactId) {
                  
                  EmailMessage inboundEmail = new EmailMessage();
                  inboundEmail.FromAddress = orgWideFromEmail;
                  inboundEmail.ToAddress = recipient.contactEmail;
                  inboundEmail.HtmlBody = email.getHTMLBody();
                  inboundEmail.incoming = FALSE;
                  inboundEmail.ParentId = caseId;
                  inboundEmail.Subject = email.getSubject();
                  inboundEmail.MessageDate = System.Now();
                  inboundEmail.Status = '3';
                  inboundEmail.TextBody = email.getPlainTextBody();
                  
                  emailMessagesMap.put(inboundEmail.ToAddress+'-'+caseId, inboundEmail);
                  
                  if(email.getFileAttachments() != NULL) {
                  
                   System.debug('Email Attachment -'+email.getFileAttachments().size());
                  
                   for(Integer i = 0; i < email.getFileAttachments().size(); i++) {
                  
                    List<Attachment> emailMsgAtt;
                    if(emailMessagesAttachmentAssociation.containsKey(inboundEmail.ToAddress+'-'+caseId))
                     emailMsgAtt = emailMessagesAttachmentAssociation.get(inboundEmail.ToAddress+'-'+caseId);
                    else
                     emailMsgAtt = new List<Attachment>();
                   
                    Attachment tempAtt = new Attachment();
                    tempAtt.Name = email.getFileAttachments()[i].getFileName();
                    tempAtt.Body = email.getFileAttachments()[i].getBody();
                    tempAtt.ParentId = inboundEmail.Id;
                    tempAtt.ContentType = email.getFileAttachments()[i].getContentType();
                   
                    emailMsgAtt.add(tempAtt);
                    emailMessagesAttachmentAssociation.put(inboundEmail.ToAddress+'-'+caseId, emailMsgAtt);
                   
                   }
                  }
                  ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Email queued successfully for customer'));
                
                }
                else if(recipient.recipient.Contact__c==staffContact){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Email queued successfully for staff'));

                }
                else{
                    String tempEmailAddress = '';
                    //String tempEmailAddress = recipient.recipient.Contact__r.Record_Type_Dev_Name__c == MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recipient.recipient.Contact__r.MOEmail__c != '' && recipient.recipient.Contact__r.MOEmail__c != NULL?recipient.recipient.Contact__r.MOEmail__c:recipient.recipient.Contact__r.Email;
                    if(recipient.recipient.Contact__r.Record_Type_Dev_Name__c == MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recipient.selectedEmailType == 'MO Email')
                        tempEmailAddress = recipient.moEmail;
                    else if(recipient.recipient.Contact__r.Record_Type_Dev_Name__c == MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recipient.selectedEmailType == 'Electorate Email')
                        tempEmailAddress = recipient.elecEmail;
                    else if(recipient.recipient.Contact__r.Record_Type_Dev_Name__c != MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recipient.selectedEmailType == 'MO Email')
                        tempEmailAddress =recipient.nonMPEmail;
                    else if(recipient.recipient.Contact__r.Record_Type_Dev_Name__c != MEMBER_OF_PARLIAMENT_CONTACT_REC_TYPE_DEV_NAME && recipient.selectedEmailType == 'Electorate Email')
                        tempEmailAddress = recipient.nonMPSecondaryEmail;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Email queued successfully for- '+recipient.recipient.Contact__r.Name+' '+tempEmailAddress));
                    recipient.recipient.Is_Referred__c = true;
                    recipientsForUpdate.add(recipient.recipient);
                    
                    EmailMessage inboundEmail = new EmailMessage();
                    inboundEmail.FromAddress = orgWideFromEmail;
                    inboundEmail.ToAddress = tempEmailAddress;
                    inboundEmail.HtmlBody = email.getHTMLBody();
                    inboundEmail.incoming = FALSE;
                    inboundEmail.ParentId = caseId;
                    inboundEmail.Subject = email.getSubject();
                    inboundEmail.MessageDate = System.Now();
                    inboundEmail.Status = '3';
                    inboundEmail.TextBody = email.getPlainTextBody();
                    
                    emailMessagesMap.put(inboundEmail.ToAddress+'-'+caseId, inboundEmail);
                    
                    if(email.getFileAttachments() != NULL) {
                     
                     System.debug('Email Attachment -'+email.getFileAttachments().size());
                     
                     for(Integer i = 0; i < email.getFileAttachments().size(); i++) {
                  
                      List<Attachment> emailMsgAtt;
                      if(emailMessagesAttachmentAssociation.containsKey(inboundEmail.ToAddress+'-'+caseId))
                       emailMsgAtt = emailMessagesAttachmentAssociation.get(inboundEmail.ToAddress+'-'+caseId);
                      else
                       emailMsgAtt = new List<Attachment>();
                   
                      Attachment tempAtt = new Attachment();
                      tempAtt.Name = email.getFileAttachments()[i].getFileName();
                      tempAtt.Body = email.getFileAttachments()[i].getBody();
                      tempAtt.ParentId = inboundEmail.Id;
                      tempAtt.ContentType = email.getFileAttachments()[i].getContentType();
                   
                      emailMsgAtt.add(tempAtt);
                      emailMessagesAttachmentAssociation.put(inboundEmail.ToAddress+'-'+caseId, emailMsgAtt);
                     
                     }
                    }
                }

                System.debug('Email queued successfully for -'+email.getToAddresses());
                
                
            } 
            else {
                
              System.debug('Failed to send email: ' + ser.errors[0].message);
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,'Failed to send email:'+ser.errors[0].message));
            }


        }
        
        System.debug('Email Map: '+emailMessagesAttachmentAssociation.size());
        
        if(emailMessagesMap.size() > 0) {
         
         insert emailMessagesMap.values();
         
         System.debug('Email Message Insert Map: '+emailMessagesAttachmentAssociation.values());
         System.debug('Email Message Insert Map: '+emailMessagesAttachmentAssociation.keySet());
         
         List<Attachment> emaiMsgAttachments = new List<Attachment>();
         
         for(String tempEMMapKey : emailMessagesAttachmentAssociation.keySet()) {
          
          System.debug('Email Message Insert Map Values: '+emailMessagesAttachmentAssociation.get(tempEMMapKey)); 
          
          for(Attachment tempAtt : emailMessagesAttachmentAssociation.get(tempEMMapKey)) {
           
           tempAtt.ParentId = emailMessagesMap.get(tempEMMapKey).Id;
           emaiMsgAttachments.add(tempAtt);
          }
         }
         
         if(emaiMsgAttachments.size() > 0)
          insert emaiMsgAttachments;
        }
        
        return recipientsForUpdate;
    } 

    public PageReference send() {
        PageReference retUrl =null;

        try{
            Messaging.SingleEmailMessage[] emails= prepareEmails();
            
            
            // Sends the email
            Messaging.reserveSingleEmailCapacity(emails.size());

            Messaging.SendEmailResult [] sers =  Messaging.sendEmail(emails,false);
            List<Additional_Corro_Recipients__c> recipientsForUpdate=getRecipientsForUpdate(sers, emails,recipientsSent);
            
            update recipientsForUpdate;
            AggregateResult[] totalRecipients=[select COUNT(Id) totalRecipients from Additional_Corro_Recipients__c where case__c=:caseId];
            AggregateResult[] referredRecipients=[select COUNT(Id) referredRecipients from Additional_Corro_Recipients__c where case__c=:caseId and Is_Referred__c=true];
            if((Integer)totalRecipients[0].get('totalRecipients')==(Integer)referredRecipients[0].get('referredRecipients')){
                Case thisCase= new Case(id=caseId,Are_All_Recipients_Referrel__c=true);
                update thisCase;
            }
			return retUrl;
            
        }catch(Exception ex){
            system.debug('Exception occured - '+ex);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Exception occured while sending- '+ex.getStackTraceString()));
            
        }finally{
            recipients=null;
        }

       
        return null;
    }
    public PageReference cancel() {
       
        return new PageReference('/'+caseId);
    }
    
    List<NoteOrAttachment__c> getReferralAttachments(Id caseId, Set<String> categories) {
        if(categories!=null){
            return [select Id, Name,Category__c, Attachment_Id__c,ContentType__c, File_Name__c,View__c from NoteOrAttachment__c where Case__c=:caseId and Category__c in:categories];
        }else{
            return null;
        } 
    } 
    List<Messaging.EmailFileAttachment> getEmailAttachments(List< NoteOrAttachment__c> noas) {
        if(noas==null) 
            return null;
        Set <Id> attachmentids= new Set<Id>();
        for(NoteOrAttachment__c noa:noas){
            attachmentids.add(noa.Attachment_Id__c);
        }
        List <Messaging.EmailFileAttachment> efas= new List <Messaging.EmailFileAttachment> ();
        for(Attachment att : [select Id, Body, ContentType, Name,parentId from Attachment where id in: attachmentids]){
            Messaging.EmailFileAttachment efa= new Messaging.EmailFileAttachment();
            efa.setBody(att.Body);
            efa.setContentType(att.ContentType);
            efa.setFileName(att.Name);
            efas.add(efa);
        }
        return efas;
    }

    //Arxxus => method to redirect to case detail page afetr clicking on back button(MO Enhancements OCT Release) starts here
    public  PageReference redirectToRecordDetail(){    
        PageReference pr = new PageReference('/'+caseId);
        pr.setRedirect(true);
        return pr;
    }        
    //Arxxus => method to redirect to case detail page afetr clicking on back button(MO Enhancements OCT Release) ends here
    
    public class Recipient{
        public Additional_Corro_Recipients__c recipient {public get;public set;}
        public String subject{public get;public set;}
        public String htmlBody{public get;public set;}
        public boolean doSend{public get;public set;}
        public List<NoteOrAttachment__c> attachments{public get;public set;}
        public RecipientType type {get;set;} //additinal corro recipients, or staff or customer
        public String typeName{
            public get{return type.name();}
        }
        public String moEmail {get;set;}
        public String elecEmail {get;set;}
        public String nonMPEmail {get;set;}
        public String nonMPSecondaryEmail {get;set;}
        public String contactEmail{get;set;}
        public String selectedEmailType {get;set;}
        public String corroId {get;set;}
        
        public String getContactEmail() {
            if(this.selectedEmailType == 'MO Email') {
                return moEmail;
            }else {
                return elecEmail;
            }
        }
       
    }   
    
    public enum RecipientType{ADDITIONAL_CONTACT,CUSTOMER,STAFF}
   
}