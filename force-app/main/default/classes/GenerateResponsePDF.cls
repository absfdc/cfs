/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   This class exposes @future callout method to generate PDF document using Conga
History 
<Date>         <Authors Name>     <Brief Description of Change>
21/09/2016     Arxxus             Created
-------------------------------------------------------------------------------------*/
global class GenerateResponsePDF {
    
    public static HttpCalloutMock mock = null;
    public static boolean exceptionInvoked = FALSE;
    
    global static void generate(String caseId, String customAttachmentId, String attachmentId, String attachmentName, String userSessionId) {
        
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        
        try{
            
            System.debug('Gor user session id: ' + userSessionId);
            
            Attachment responseAttachment = [SELECT Id, Name, ParentId, Body, BodyLength, ContentType FROM Attachment WHERE Id =: attachmentId];
            
            System.debug('Attachment Body: ' + responseAttachment.Body);
            System.debug('Attachment Size: ' + responseAttachment.BodyLength);
            
            responseAttachment.Name = attachmentName;
            
            attachmentName = attachmentName.replace(' ', '-');
            attachmentName = attachmentName.replace(':', '-');
            attachmentName = attachmentName.replace('.doc', '');
            
            String tempAttName = responseAttachment.Name;
            tempAttName = tempAttName.replace(' ', '-');
            tempAttName = tempAttName.replace(':', '-');
            
            NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
            responseCustomAttachment.Id = customAttachmentId;
            responseCustomAttachment.Name = tempAttName;
            responseCustomAttachment.Conga_Response_PDF_Generated__c = TRUE;
            
            update responseCustomAttachment;
            
            Attachment responseAttachmentCopy = new Attachment();
            
            responseAttachmentCopy.Name = tempAttName;
            responseAttachmentCopy.Body = responseAttachment.Body;
            responseAttachmentCopy.ContentType = responseAttachment.ContentType;
            responseAttachmentCopy.ParentId = customAttachmentId;
            
            insert responseAttachmentCopy;
            
            responseCustomAttachment = new NoteOrAttachment__c();
            responseCustomAttachment.Id = customAttachmentId;
            responseCustomAttachment.Name = tempAttName;
            responseCustomAttachment.Attachment__c = responseAttachmentCopy.Id;
            responseCustomAttachment.Conga_Response_PDF_Generated__c = TRUE;
            
            update responseCustomAttachment;
            
            delete responseAttachment;
            
            GenerateResponsePDF.generatePDF(caseId, customAttachmentId, responseAttachmentCopy.Id, tempAttName, userSessionId);
            
        } catch(Exception e) {
            
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'GenerateResponsePDF';
            message.sourceFunction = 'generate';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        
    }
    
    @future(callout = true)
    global static void generatePDF(String caseId, String customAttachmentId, String attachmentId, String attachmentName, String userSessionId) {
        
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage> ();
        
        try{
            
            attachmentName = attachmentName.replace(' ', '-');
            attachmentName = attachmentName.replace(':', '-');
            
            String tempAttName = attachmentName;
            
            attachmentName = attachmentName.replace('.doc', '');
            
            if(!attachmentName.contains('response_'))
                attachmentName = 'Response-' + attachmentName;
            
            String serverUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/29.0/' + UserInfo.getOrganizationId();
            
            System.debug('Gor server url: ' + serverUrl);
            
            String endpointURL = 'https://composer.congamerge.com/composer8/index.html' +
                '?sessionId=' + userSessionId +
                '&serverUrl=' + EncodingUtil.urlEncode(serverUrl, 'UTF-8') +
                '&id=' + customAttachmentId +
                '&TemplateId=' + attachmentId +
                '&DefaultPDF=1' +
                '&APIMode=1' +
                '&AttachmentParentID=' + caseId +
                '&AC0=0' +
                '&SC0=0' +
                '&SC1=Attachments' +
                '&OFN=' + attachmentName;
            
            System.debug('endpointURL: ' + endpointURL);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpointURL);
            req.setMethod('GET');
            req.setTimeout(120000);
            req.setHeader('Authorization', 'OAuth ' + userSessionId);
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            
            HttpResponse res;
            
            if (Test.isRunningTest() && (mock != null))
                res = mock.respond(req);
            else
                res = http.send(req);
            
            System.debug('Got Conga Response Status: ' + res.getStatus());
            System.debug('Got Conga Response Body: ' + res.getBody());
            
            //checking if reponse from conga is positive, if yes it returns created attachment's id
            if(res.getBody() != NULL && res.getBody().startsWith('00P')) {
                
                //finding out auto-generated related custom NoteOrAttachment__c record
                List<NoteOrAttachment__c> relatedNoteOrAttachmentRecord = [SELECT Name, Category__c, Attachment_Id__c, Attachment__c
                                                                           FROM NoteOrAttachment__c
                                                                           WHERE Attachment_Id__c =: res.getBody()
                                                                           ORDER BY CreatedDate DESC
                                                                           LIMIT 1 ];
                if(relatedNoteOrAttachmentRecord.size() > 0) {
                    
                    relatedNoteOrAttachmentRecord[0].Category__c = GlobalConstants.UNSIGNED_RESPONSE;
                    relatedNoteOrAttachmentRecord[0].Response_PDF__c = TRUE;
                    
                    NoteOrAttachment__c templateAttachment = new NoteOrAttachment__c();
                    templateAttachment.Id = customAttachmentId;
                    templateAttachment.Name = tempAttName;
                    templateAttachment.Conga_Response_PDF_Generated__c = TRUE;
                    
                    update templateAttachment;
                    
                    Attachment actualCongaAttachment = [SELECT Id, Name, ParentId, Body, BodyLength, ContentType FROM Attachment WHERE Id =: res.getBody()];
                    
                    Attachment actualCongaAttachmentCopy = new Attachment();
                    actualCongaAttachmentCopy.Name = actualCongaAttachment.Name;
                    actualCongaAttachmentCopy.Body = actualCongaAttachment.Body;
                    actualCongaAttachmentCopy.ContentType = actualCongaAttachment.ContentType;
                    actualCongaAttachmentCopy.ParentId = relatedNoteOrAttachmentRecord[0].Id;
                    
                    insert actualCongaAttachmentCopy;
                    
                    relatedNoteOrAttachmentRecord[0].Attachment__c = actualCongaAttachmentCopy.Id;
                    
                    
                    //25-07-2017 ORG Health Check Initiative - Start
                    //update relatedNoteOrAttachmentRecord[0];
                    //delete actualCongaAttachment;
                    
                    relatedNoteOrAttachmentRecord[0].Attachment__c = actualCongaAttachmentCopy.Id;
                    System.debug('generatePDF : relatedNoteOrAttachmentRecord[0].Attachment__c : '+relatedNoteOrAttachmentRecord[0].Attachment__c);
                    
                    Database.SaveResult sr = Database.update(relatedNoteOrAttachmentRecord[0], false);
                    
                   // for (Database.SaveResult sr : srList) {
                        if (!sr.isSuccess()) {
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('Error in generatePDF updating relatedNoteOrAttachmentRecord[0]');                   
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Fields: ' + err.getFields());
                            }
                        }
                    //}
                    
                    //25-07-2017 ORG Health Check Initiative - End

                    
                    Case targetTempCase = [SELECT Id, Response_Type__c, Status, Signatory__c, MO_User__c, doNotUseApprovalProcess__c 
                                           FROM Case WHERE Id =: caseId];
                    
                    //Admin referall cases are not part of MO approval process
                    if(targetTempCase.Response_Type__c != GlobalConstants.CASE_RESPONSE_TYPE_ADMIN_REFERRAL) {
                        
                        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ActorId
                                                                   FROM ProcessInstanceWorkitem
                                                                   WHERE ProcessInstance.TargetObjectId =: caseId
                                                                   AND ActorId =: UserInfo.getUserId() limit 1 ];
                        
                        User loggedInUser = [SELECT Id, Role_Dev_Name__c FROM User WHERE Id =: UserInfo.getUserId() limit 1];
                        
                        //case is in MO Contact approval and needs auto-approval as they have generated new revised doc. using thunderhead
                        //also checking that logged in user who has revised the draft is DLO/PA user only
                        //may come in this flow from Mark for Desktop Editing button
                        if(workItems.size() > 0 &&
                           targetTempCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE &&
                           targetTempCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE &&
                           targetTempCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE &&
                           targetTempCase.MO_User__c != NULL &&
                           GlobalConstants.MO_DLO_AND_PA_ROLE_NAMES.contains(loggedInUser.Role_Dev_Name__c)) {
                               
                               List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                               for (ProcessInstanceWorkitem workItem: workItems) {
                                   
                                   Approval.ProcessWorkitemRequest appReq = new Approval.ProcessWorkitemRequest();
                                   appReq.setWorkitemId(workItem.Id);
                                   appReq.setAction('Approve');
                                   
                                   requests.add(appReq);
                               }
                               
                               Approval.ProcessResult[] processResults = Approval.process(requests);
                               system.debug('Approval ProcessResult :: ' + processResults);
                               
                               if (!processResults[0].isSuccess()) {
                                   
                                   ApplicationLogMessage message = new ApplicationLogMessage();
                                   message.source = 'GenerateResponsePDF';
                                   message.sourceFunction = 'generatePDF';
                                   message.referenceId = caseId;
                                   message.logMessage = 'Mo Contact Auto Approval failed: ' + processResults[0].getErrors()[0];
                                   message.debugLevel = GlobalConstants.ERROR;
                                   messages.add(message);
                                   ApplicationLogUtility.logMessage(messages);
                               }
                               
                               // Unlock the cases
                               Set<Id> tempCaseId = new Set<Id>();
                               tempCaseId.add(Id.valueOf(caseId));
                               
                               Approval.UnlockResult[] lrList = Approval.unlock(new List<Id>(tempCaseId), false);
                               
                               // Iterate through each returned result
                               for (Approval.UnlockResult lr: lrList) {
                                   
                                   if (!lr.isSuccess()) {
                                       
                                       // Operation failed, so get all errors                
                                       for (Database.Error err: lr.getErrors()) {
                                           
                                           ApplicationLogMessage message = new ApplicationLogMessage();
                                           message.source = 'GenerateResponsePDF';
                                           message.sourceFunction = 'generatePDF';
                                           message.referenceId = caseId;
                                           message.logMessage = 'Approval auto-unlock failed: ' + err.getMessage();
                                           message.debugLevel = GlobalConstants.ERROR;
                                           messages.add(message);
                                           ApplicationLogUtility.logMessage(messages);
                                       }
                                   }
                               }
                           } else {
                               
                               if ( targetTempCase.doNotUseApprovalProcess__c==false){
                                   List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
                                   Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
                                   tempReq.setComments('Submitting response for approval');
                                   tempReq.setObjectId(caseId);
                               
                                   if((targetTempCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE &&
                                       targetTempCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE &&
                                       targetTempCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) &&
                                       targetTempCase.MO_User__c != NULL) {
                                      
                                          tempReq.setSubmitterId(targetTempCase.MO_User__c);
                                   }
                               
                                   approvalRequests.add(tempReq);
                               
                                   if(approvalRequests.size() > 0) {
                                   
                                       Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
                                   
                                       for(Approval.ProcessResult tempProcessResult: processResults) {
                                       
                                           if(!tempProcessResult.isSuccess()) {
                                           
                                               ApplicationLogMessage message = new ApplicationLogMessage();
                                               message.source = 'GenerateResponsePDF';
                                               message.sourceFunction = 'generatePDF';
                                               message.referenceId = caseId;
                                               message.logMessage = 'Approval auto-submission failed: ' + tempProcessResult.getErrors()[0];
                                               message.debugLevel = GlobalConstants.ERROR;
                                               messages.add(message);
                                               ApplicationLogUtility.logMessage(messages);
                                           }
                                       }
                                   
                                       // Unlock the cases
                                       Set<Id> tempCaseId = new Set<Id> ();
                                       tempCaseId.add(Id.valueOf(caseId));
                                   
                                       Approval.UnlockResult[] lrList = Approval.unlock(new List<Id>(tempCaseId), false);
                                   
                                       // Iterate through each returned result
                                       for(Approval.UnlockResult lr: lrList) {                                     
                                           if (!lr.isSuccess()) {                                           
                                               // Operation failed, so get all errors                
                                               for (Database.Error err: lr.getErrors()) {
                                                   ApplicationLogMessage message = new ApplicationLogMessage();
                                                   message.source = 'GenerateResponsePDF';
                                                   message.sourceFunction = 'generatePDF';
                                                   message.referenceId = caseId;
                                                   message.logMessage = 'Approval auto-unlock failed: ' + err.getMessage();
                                                   message.debugLevel = GlobalConstants.ERROR;
                                                   messages.add(message);
                                               }
                                           }
                                       }
                                   }//end if targetTempCase.doNotUseApprovalProcess__c==false
                                   
                                   List<Case> targetCase = [SELECT OwnerId, Signatory__c, Signatory_Person__c, MO_User__c FROM Case WHERE Id =: caseId];
                                   
                                   if(targetCase.size() > 0) {
                                       
                                       if((targetCase[0].Signatory__c == GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE ||
                                           targetCase[0].Signatory__c == GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE ||
                                           targetCase[0].Signatory__c == GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) &&
                                           targetCase[0].Signatory_Person__c != NULL &&
                                           targetCase[0].OwnerId != targetCase[0].Signatory_Person__c) {
                                              
                                              targetCase[0].OwnerId = targetCase[0].Signatory_Person__c;
                                              update targetCase[0];
                                       } else if (targetCase[0].Signatory__c != '' && targetCase[0].Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE &&
                                                     targetCase[0].Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE &&
                                                     targetCase[0].Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE &&
                                                     targetCase[0].MO_User__c != NULL && targetCase[0].OwnerId != targetCase[0].MO_User__c) {
                                                         
                                                         targetCase[0].OwnerId = targetCase[0].MO_User__c;
                                                         update targetCase[0];
                                       }
                                   }
                               }
                           }
                    }
                }
            }
            
            if(messages.size() > 0) {
                
                ApplicationLogUtility.logMessage(messages);
                messages.clear();
            }
            
        } catch (Exception e) {
            
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'Private_NoteAfterUpdateTriggerHandler';
            message.sourceFunction = 'generatePDF';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        
    }
    
}