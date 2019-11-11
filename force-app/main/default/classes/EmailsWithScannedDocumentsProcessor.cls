/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   An Abstract class which will be used to process the Inbound Emails (Email Service).
               This class will be used by
               Amendments, Campaign Members and Signed Responses
History 
<Date>         <Authors Name>     <Brief Description of Change>
14/07/2015     Manish Damle       Created
19/01/2017     Arxxus             Optimised BAU team's code for generating incoming email as an attachment
-------------------------------------------------------------------------------------*/
public abstract class EmailsWithScannedDocumentsProcessor {

    public boolean isTrimmed = false;
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   An abstract method that will be overridden by child classes
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    public abstract Messaging.InboundEmailResult process(Messaging.InboundEmail email, 
                                                         Messaging.InboundEnvelope envelope, 
                                                         EmailSubjectPatternConfiguration__c patternConfiguration);

    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will check whether preconfigured pattern exists in the 
                   Subject or not. If exists then extract the Case Ref. Number From the 
                   Subject else returns null.
    Inputs:        Message Subject, Pattern preFix, postFix
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected String extractCaseRefNumberFromSubject(String emailSubject, String preFix, String suffix) {
        String refNo = null;
        
        if(emailSubject == null || emailSubject == '')
            return refNo;
        //Trim extra spaces
        emailSubject = emailSubject.normalizeSpace();
        if(emailSubject.containsIgnoreCase(preFix)) {
            //Get the position of the 1st occurance of the prefix in the subject
            Integer index = emailSubject.indexOf(preFix); 
            //Replace the prefix with blank so that remaining string can checked for postFix
            emailSubject = emailSubject.replace(preFix, '');
            //Extract the trailing substring 
            String str = emailSubject.subString(index, emailSubject.length());
            if(str.containsIgnoreCase(suffix)) {
                //If postfix present then extract the case ref. number
                refNo = emailSubject.subString(index, emailSubject.indexOf(suffix));
                refNo = refNo == '' ? 'NOTFOUND' : refNo.normalizeSpace(); //trim the spaces if any
            }
        }
            
        return refNo;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create new case record as pattern does not found in the 
                   email subject.
                   Origin -> copied from custom settings
                   Priority -> copied from custom settings
                   Other Details will be copied from the email
                   
    Inputs:        Inbound Email                   
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected Case createNewCase(Messaging.InboundEmail email, EmailSubjectPatternConfiguration__c configuration) {
        AssignmentRule AR = new AssignmentRule();
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        Id recordTypeId = [Select Id From RecordType Where DeveloperName =: configuration.New_Case_Record_Type_Name__c limit 1].Id;
        
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        

        //SFCOE-126
        Map<String, Integer> fieldsSizeMap = new Map<String, Integer>();
        fieldsSizeMap = getFieldsSizeMap('Case');
        String trimmedDescription = null;
        if (email.plainTextBody != null) trimmedDescription = email.plainTextBody;
        else if (email.htmlBody != null) trimmedDescription = email.htmlBody;
        trimmedDescription = checkMaxValueAndTrim(fieldsSizeMap, 'description', trimmedDescription);

        Case newCase = new Case(Origin = configuration.New_Case_Origin__c, 
                                Priority = configuration.New_Case_Priority__c,
                                Status = configuration.New_Case_Status__c,
                                RecordTypeId = recordTypeId,
                                Subject = checkMaxValueAndTrim(fieldsSizeMap, 'subject', email.Subject),
                                Description = trimmedDescription,
                                Origin_Details__c = configuration.New_Case_Origin_Details__c);
        newCase.setOptions(dmlOpts);
        insert newCase;
        
        Case newCaseRecord = [Select Id, OwnerId, Status, Amendment_Triaged__c, CaseNumber, Origin, Priority, RecordTypeId 
                              From Case 
                              Where Id =: newCase.Id limit 1];
        return newCaseRecord;                               
    }
    
    
public Map<String, Integer> getFieldsSizeMap(String sObjType){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sObjType).getDescribe().fields.getMap();
        Map<String, Integer> fieldsSizeMap = new Map<String, Integer>();
        system.debug('Building Fieldmap...');
    
        try{
            for(String fieldName : fieldMap.keyset()){
                fieldsSizeMap.put(fieldName,fieldMap.get(fieldName).getDescribe().getLength());
                system.debug('FieldName: ' + fieldName + 'size: ' + fieldMap.get(fieldName).getDescribe().getLength());
            }
        }catch(Exception e){
            system.debug('getFieldsSizeMap::Exception - ' + e.getMessage() + e.getLineNumber() + e.getStackTraceString());
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            Throw(e);
         }

        return fieldsSizeMap;
}
    
    public String checkMaxValueAndTrim(Map<String, Integer> fieldsSizeMap, String fieldName, String value){
        Integer fieldLength;
        Integer valueLength = 0;
        
        try{
        system.debug('FieldsSizeMap size: ' + fieldsSizeMap.size());
        fieldLength = fieldsSizeMap.get(fieldName);
        
        if(value != NULL)
         valueLength = value.length();
         
        system.debug('FieldName:: ' + fieldName + ' - fieldLength:: ' + fieldLength + ' - valueLength:: ' + valueLength);
            
            if(!('htmlbody'.equalsIgnoreCase(fieldName)) && !('name'.equalsIgnoreCase(fieldName))){
                if(valueLength > fieldLength)value = value.substring(0, fieldLength - 1);
                system.debug('Trimmed Value: ' + value);
                isTrimmed = true;
            }
            else if('htmlbody'.equalsIgnoreCase(fieldName)){
                if(valueLength > fieldLength)value = value.substring(0, fieldLength - 15) + '</body></html>';
                system.debug('Trimmed HTML Description Value: ' + value);
                isTrimmed = true;
            }
            else if(('name'.equalsIgnoreCase(fieldName))){
                system.debug('Processing Trimming for File Name: ' + value);
                if(valueLength > fieldLength){
                    String extension = value.substring(value.lastIndexOf('.'), value.length());
                    String fileNameWOExtension = value.substring(0, value.lastIndexOf('.'));  //value.length()-5
                    value = fileNameWOExtension.substring(0, fieldLength - extension.length() - 1) + extension;
                    system.debug('FileName Without Extension: ' + fileNameWOExtension + ' - Extension: ' + extension);
                    system.debug('Trimmed Name Value: ' + value);
                    isTrimmed = true;
                }
            }
            
        }catch(Exception e){
            system.debug('checkMaxValueAndTrim::Exception - ' + e.getMessage() + e.getLineNumber() + e.getStackTraceString());
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
            return value;
        }
        
        return value;
    }    

/*  
public void createIncomingEmailHTMLAsAttachment(String htmlBody, Id caseId, String subject){
       
        string htmlContent = htmlBody;
        system.debug('HTML for incoming email: ' + htmlContent);
       
        try{
        Attachment attachmenthtml = new Attachment();
        attachmenthtml.parentId = caseId;
        attachmenthtml.name = 'Full Incoming Email Message: ' + subject + '.html';
        system.debug('HTML after processing incoming email: ' + htmlContent);
        attachmenthtml.body = blob.valueOf(htmlContent);
        insert attachmenthtml;
        System.debug('attachmenthtml id: ' + attachmenthtml.id + 'Attached to Case ID: ' + caseId);
     
        }catch(Exception e) {
            system.debug('createIncomingEmailHTMLAsAttachment:: Exception Occured: Could not convert incoming email to html---' + e.getMessage() 
            + '--LINE--' + e.getLineNumber() + '---Cause---' + e.getCause() + e.getStackTraceString());
        }
}    
*/  
    
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create new case record with following details
                   Record Type -> Erroneous Cases Ministerial Correspondence
                   Priority    -> Normal
                   Origin      -> Email
                    
    Inputs:        Inbound Email                   
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected Case createNewErroneousCase(Messaging.InboundEmail email, EmailSubjectPatternConfiguration__c configuration) {    
        //Fetch Erroneous Cases Ministerial Correspondence record type id
        Id recordTypeId = [Select Id From RecordType Where DeveloperName =: configuration.Erroneous_Case_Record_Type_Name__c limit 1].Id;
        //Fetch Erroneous Cases queue id. This will be set as a case owner
        Group erroneousCasesQueue = [Select Id From Group Where Type = 'Queue' And DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO limit 1];
        
        
        //SFCOE-126
        Map<String, Integer> fieldsSizeMap = new Map<String, Integer>();
        fieldsSizeMap = getFieldsSizeMap('Case');
        //Subject = email.Subject
        //Description = email.plainTextBody,
        
        Case newCase = new Case(Origin = configuration.New_Case_Origin__c, 
                                Priority = configuration.New_Case_Priority__c,
                                RecordTypeId = recordTypeId,
                                Subject = checkMaxValueAndTrim(fieldsSizeMap, 'subject', email.Subject),
                                Description = checkMaxValueAndTrim(fieldsSizeMap, 'description', email.plainTextBody),
                                OwnerId = erroneousCasesQueue.Id);
        insert newCase;
        
        Case newCaseRecord = [Select Id, OwnerId, Status, Amendment_Triaged__c, CaseNumber, Origin, Priority, RecordTypeId 
                              From Case 
                              Where Id =: newCase.Id limit 1];
        return newCaseRecord;
    }
    
        /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create new case record with following details
                   Record Type -> Erroneous Cases Ministerial Correspondence
                   Priority    -> Normal
                   Origin      -> Email
                   Amendment   -> true
                    
    Inputs:        Inbound Email                   
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    20/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected Case createNewErroneousCaseForAmendments(Messaging.InboundEmail email, EmailSubjectPatternConfiguration__c configuration) {    
        //Fetch Erroneous Cases Ministerial Correspondence record type id
        Id recordTypeId = [Select Id From RecordType Where DeveloperName =: configuration.Erroneous_Case_Record_Type_Name__c limit 1].Id;
        //Fetch Erroneous Cases queue id. This will be set as a case owner
        Group erroneousCasesQueue = [Select Id From Group Where Type = 'Queue' And DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO limit 1];
        
        
        //SFCOE-126
        Map<String, Integer> fieldsSizeMap = new Map<String, Integer>();
        fieldsSizeMap = getFieldsSizeMap('Case');
        //Subject = email.Subject,
        //Description = email.plainTextBody,
        
        Case newCase = new Case(Origin = configuration.New_Case_Origin__c, 
                                Priority = configuration.New_Case_Priority__c,
                                RecordTypeId = recordTypeId,
                                Subject = checkMaxValueAndTrim(fieldsSizeMap, 'subject', email.Subject),
                                Amendment__c = true,
                                Description = checkMaxValueAndTrim(fieldsSizeMap, 'description', email.plainTextBody),                                
                                OwnerId = erroneousCasesQueue.Id);
        insert newCase;
        
        Case newCaseRecord = [Select Id, OwnerId, Status, Amendment_Triaged__c, CaseNumber, Origin, Priority, RecordTypeId 
                              From Case 
                              Where Id =: newCase.Id limit 1];
        return newCaseRecord;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create new Email Message Object under case.
    Inputs:        Inbound Email, Parent Id    
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected EmailMessage createNewEmailMessage(Messaging.InboundEmail email, String caseId) {
        
        
        Map<String, Integer> fieldsSizeMap = new Map<String, Integer>();
        fieldsSizeMap = getFieldsSizeMap('EmailMessage');
        String trimmedHtmlBody = checkMaxValueAndTrim(fieldsSizeMap, 'htmlbody', email.htmlBody);
               
        
        //Subject   = email.Subject,
        //TextBody = email.plainTextBody),
        //HtmlBody  = email.htmlBody
        
                
        //if(isTrimmed) createIncomingEmailHTMLAsAttachment(email.htmlBody, caseId, email.Subject);
        
        EmailMessage inboundEmail = new EmailMessage(FromAddress = email.FromAddress,
                                                     ToAddress = (email.ToAddresses != null && email.ToAddresses.size() > 0) ? email.ToAddresses[0] : null,
                                                     CcAddress = (email.ccAddresses != null && email.ccAddresses.size() > 0) ? email.ccAddresses[0] : null,
                                                     FromName  = email.FromName,
                                                     HtmlBody  = trimmedHtmlBody,
                                                     Incoming  = true,
                                                     ParentId  = caseId,
                                                     Subject = checkMaxValueAndTrim(fieldsSizeMap, 'subject', email.Subject),
                                                     MessageDate = system.now(),
                                                     Status   = '0',
                                                     TextBody = checkMaxValueAndTrim(fieldsSizeMap, 'textbody', email.plainTextBody)
                                                    );
        insert inboundEmail;
        return inboundEmail;
        
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will save the custom attachmets on the email to case record.
    Inputs:        Inbound Email , Case Id                 
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected void reparentDocuments(Messaging.InboundEmail email, Case parentCase, String attachmentCategory) {
        
        System.debug('----Attachment Reparenting----');
        
        Id attachmentRecordTypeId = [Select Id From RecordType Where SObjectType = 'NoteOrAttachment__c' And DeveloperName =: GlobalCOnstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT].Id;
        Map<String, Attachment> attachments = new Map<String, Attachment>();
        Map<String, NoteOrAttachment__c> customAttachments = new Map<String, NoteOrAttachment__c>();
        
        
        //SFCOE-126
        Map<String, Integer> fieldsSizeMapAttachment = new Map<String, Integer>();
        fieldsSizeMapAttachment = getFieldsSizeMap('Attachment');
        Map<String, Integer> fieldsSizeMapNoteOrAttachment = new Map<String, Integer>();
        fieldsSizeMapNoteOrAttachment = getFieldsSizeMap('NoteOrAttachment__c');
        
        
        Map<String, Integer> fieldsSizeMap = new Map<String, Integer>();
        fieldsSizeMap = getFieldsSizeMap('EmailMessage');
        String trimmedHtmlBody = checkMaxValueAndTrim(fieldsSizeMap, 'htmlbody', email.htmlBody);
        
        if(isTrimmed && email.htmlbody != NULL) {
         
         //String trimmedAttName = 'Full Incoming Email Message: ' + email.subject + '.html';
         
         String trimmedAttName = 'Full Incoming Email Message: ' + email.subject;
         
         if(trimmedAttName.length() > 75)
          trimmedAttName = trimmedAttName.substring(0, 75);
         
         trimmedAttName += '.html';
         
         
         attachments.put(trimmedAttName, new Attachment(Name = trimmedAttName,
                                                        Body = Blob.valueOf(email.htmlbody),
                                                        ContentType = ''));
                                                        
         customAttachments.put(trimmedAttName, new NoteOrAttachment__c(Name = trimmedAttName,
                                                                       Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD,
                                                                       Case__c = parentCase.Id,
                                                                       OwnerId = parentCase.OwnerId,
                                                                       Category__c = '',
                                                                       RecordTypeId = attachmentRecordTypeId));
        }
        
        if(email.textAttachments != null) {
            
            for(Messaging.Inboundemail.TextAttachment textAtt : email.textAttachments) {
                String contentType = '';
                if(textAtt.headers != null) 
                    for(Messaging.InboundEmail.Header header : textAtt.headers) {
                        if(header.Name == 'Content-Type') {
                            contentType = header.value.split(';')[0];
                            system.debug('No ContentType Found: ' + contentType + 'textAtt.fileName: ' + textAtt.fileName);
                            break;
                        }
                    }

                system.debug('ContentType Found: ' + contentType + 'textAtt.fileName: ' + textAtt.fileName);
                
                contentType = findContentTypeFromFileName(textAtt.fileName);
                                                                
                
                //Name = textAtt.fileName
                String textAttfileName = checkMaxValueAndTrim(fieldsSizeMapNoteOrAttachment, 'name', textAtt.fileName);
                system.debug('Text Attachment Trimmed File Name: ' + textAttfileName);                
                
                attachments.put(textAttfileName, new Attachment(Name = textAttfileName,
                                                                 Body = Blob.valueOf(textAtt.body),
                                                                 ContentType = contentType));
                
                customAttachments.put(textAttfileName, new NoteOrAttachment__c(Name = textAttfileName,
                                                                                Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD,
                                                                                Case__c = parentCase.Id,
                                                                                OwnerId = parentCase.OwnerId,
                                                                                Category__c = attachmentCategory,
                                                                                RecordTypeId = attachmentRecordTypeId));
            }
        }
        
        if(email.binaryAttachments != null) {
            for (Messaging.Inboundemail.BinaryAttachment binaryAtt : email.binaryAttachments) {
                String contentType = '';
                if(binaryAtt.headers != null)
                    for(Messaging.InboundEmail.Header header : binaryAtt.headers) {
                        if(header.Name == 'Content-Type') {
                            contentType = header.value.split(';')[0];
                            system.debug('No ContentType Found: ' + contentType + 'binaryAttfileName: ' + binaryAtt.fileName);
                            break;  
                        }
                    }
                
                system.debug('ContentType Found: ' + contentType + 'binaryAttfileName: ' + binaryAtt.fileName);
                
                contentType = findContentTypeFromFileName(binaryAtt.fileName);
                
                
                //binaryAtt.fileName
                String binaryAttfileName = checkMaxValueAndTrim(fieldsSizeMapNoteOrAttachment, 'name', binaryAtt.fileName);
                system.debug('Binary Attachment Trimmed File Name: ' + binaryAttfileName);
                
                attachments.put(binaryAttfileName, new Attachment(Name = binaryAttfileName,
                                                                   Body = binaryAtt.body,
                                                                   ContentType = contentType));
                
                customAttachments.put(binaryAttfileName, new NoteOrAttachment__c(Name = binaryAttfileName,
                                                                                  Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD,
                                                                                  Case__c = parentCase.Id,
                                                                                  OwnerId = parentCase.OwnerId,
                                                                                  Category__c = attachmentCategory,
                                                                                  RecordTypeId = attachmentRecordTypeId));
            }
        }
        
        system.debug('----Attachments#----' + customAttachments.size());
        
        if(customAttachments.size() > 0) {
           
            insert customAttachments.values();
           
            for(String fileName : customAttachments.keySet()) {
           
                if(attachments.containsKey(fileName) 
                    && customAttachments.get(fileName) != null 
                    && customAttachments.get(fileName).Id != null) {
           
                    attachments.get(fileName).ParentId = customAttachments.get(fileName).Id;
                }
            }
            
            insert attachments.values();
            
            for(Attachment att: attachments.values()) {
                if(customAttachments.containsKey(att.Name) 
                   && customAttachments.get(att.Name) != null 
                   && customAttachments.get(att.Name).Id != null) {
                    customAttachments.get(att.Name).Attachment__c = att.Id;
                    customAttachments.get(att.Name).ContentType__c = att.ContentType;
                }
            }
            
            update customAttachments.values();
        }//end if
    }
    
 //Calculate Content Type from File Name
    
    public String findContentTypeFromFileName(String x){
    String content_type = null;

    if(x.toLowerCase().endsWith('.pdf')) content_type = 'application/pdf';
    else if(x.toLowerCase().endsWith('.jpg')) content_type = 'image/jpg';
    else if(x.toLowerCase().endsWith('.png')) content_type = 'image/png';   
    else if(x.toLowerCase().endsWith('.jpeg')) content_type = 'image/jpeg';
    else if(x.toLowerCase().endsWith('.doc')) content_type = 'application/msword';   
    else if(x.toLowerCase().endsWith('.gif')) content_type = 'image/gif';   
    else if(x.toLowerCase().endsWith('.ppt')) content_type = 'application/vnd.ms-powerpoint';   
    else if(x.toLowerCase().endsWith('.xlsx')) content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';   
    else if(x.toLowerCase().endsWith('.xlx')) content_type = 'application/vnd.ms-excel';   
    else if(x.toLowerCase().endsWith('.pptx')) content_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';      
    else if(x.toLowerCase().endsWith('.docx')) content_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';   

    System.debug('Calculated Content Type: ' + content_type);
    return content_type;
}
    
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will fetch the case details
    Inputs:        Case Number             
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected Case fetchCaseDetails(String caseNumber) {
        list <Case> caseRecords = [Select Id, CaseNumber, Amendment_Count__c, Amendment_Triaged__c, OwnerId, Status, IsMinCorroCase__c
                                           From Case 
                                           Where CaseNumber =: caseNumber limit 1];
        if(caseRecords.size() == 1) {
            return caseRecords[0];
        }
        
        return null;
    } 

    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create a standard attachment record on the case.
    Inputs:        Case Number             
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    protected Id createCaseAttachmentFromEmailAttachments(Messaging.InboundEmail email, Case parentCase) {
        if(email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
            String contentType = '';
            Messaging.Inboundemail.BinaryAttachment binaryAtt = email.binaryAttachments[0];
            if(binaryAtt.headers != null) 
                for(Messaging.InboundEmail.Header header : binaryAtt.headers) {
                    if(header.Name == 'Content-Type') {
                        contentType = header.value.split(';')[0];
                        break;  
                    }
                }

            contentType = findContentTypeFromFileName(binaryAtt.fileName);
            
            //SFCOE-126
            Map<String, Integer> fieldsSizeMapAttachment = new Map<String, Integer>();
            fieldsSizeMapAttachment = getFieldsSizeMap('Attachment');
            
            
            // SFCOE-2546 - Document not received Case 609278 - 19-07-2018 - Start
            String parentOwnerId = parentCase.OwnerId;
            if(parentOwnerId.startsWith('00G')){
                parentOwnerId = UserInfo.getUserId();
            }
            
            Attachment caseAttachment = new Attachment(Name = checkMaxValueAndTrim(fieldsSizeMapAttachment, 'name', binaryAtt.fileName),
                                            Body = binaryAtt.body,
                                            ParentId = parentCase.Id,
                                            OwnerId = parentOwnerId,
                                            ContentType = contentType);
            insert caseAttachment;
            system.debug('ID of newly created attachment: ' + caseAttachment);
            
            try{
                NoteOrAttachment__c customNoteOrAttach = [Select Id, OwnerId From NoteOrAttachment__c Where Attachment__c = :caseAttachment.Id];
                if(customNoteOrAttach.OwnerId != parentCase.OwnerId){
	                customNoteOrAttach.OwnerId = parentCase.OwnerId;
                	update customNoteOrAttach;
                }
            }catch(Exception expp){ 
                System.debug(expp.getMessage() + expp.getLineNumber() + expp.getStackTraceString());
            }
            
            // SFCOE-2546 - Document not received Case 609278 - 19-07-2018 - End
            
            return caseAttachment.Id;
        }

        return null;
    }
}