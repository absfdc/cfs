/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   This class exposes @future callout method to generate PDF document using Conga
History 
<Date>         <Authors Name>     <Brief Description of Change>
21/09/2016     Arxxus             Created
-------------------------------------------------------------------------------------*/
global without sharing class GenerateIncomingPDF {
 
 public static HttpCalloutMock mock = null;
 public static boolean exceptionInvoked = FALSE;
  
 @future(callout=true)
 global static void generate(String caseId, String userSessionId) {   
  
  List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
   
  APXTConga4__Conga_Template__c incomingTemplate = [SELECT Id, Name 
                                                           FROM APXTConga4__Conga_Template__c
                                                           WHERE APXTConga4__Name__c = 'WebCaseIncomingTemplate'
                                                           ORDER BY CreatedDate DESC LIMIT 1];
                                                           
   if(incomingTemplate != NULL) {
    
    String serverUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/services/Soap/u/29.0/'+UserInfo.getOrganizationId();
        
    System.debug('Got server url: '+serverUrl);
    System.debug('Got session Id: '+userSessionId);
   

      
      String endpointURL = 'https://composer.congamerge.com/composer8/index.html'+
                                 '?sessionId='+userSessionId+
                                 '&serverUrl='+EncodingUtil.urlEncode(serverUrl, 'UTF-8')+
                                 '&id='+caseId+
                                 '&TemplateId='+incomingTemplate.Id+
                                 '&DefaultPDF=1'+
                                 '&APIMode=1'+
                                 '&AttachmentParentID='+caseId+
                                 '&AC0=0'+
                                 '&SC0=0'+
                                 '&SC1=Attachments'+
                                 '&OFN=Incoming';
                          
      HttpRequest req = new HttpRequest();
      req.setEndpoint(endpointURL);
      req.setMethod('GET');
      req.setTimeout(120000);
      req.setHeader('Authorization', 'OAuth ' + userSessionId);
      req.setHeader('Content-Type','application/json');
      
      Http http = new Http();
      
      HttpResponse res;
            
      //HttpResponse res = http.send(req);
      
      if(Test.isRunningTest() && (mock != null))
       res = mock.respond(req);
      else
       res = http.send(req);
      
      System.debug('Conga URL: '+endpointURL);
      System.debug('Got Conga Response Status: '+res.getStatus());
      System.debug('Got Conga Response Body: '+res.getBody());
            
      //checking if reponse from conga is positive, if yes it returns created attachment's id
      if(res.getBody() != NULL && res.getBody().startsWith('00P')) {
      
       //finding out auto-generated related custom NoteOrAttachment__c record
       List<NoteOrAttachment__c> relatedNoteOrAttachmentRecord = [SELECT Name, Category__c, Attachment_Id__c, Attachment__c
                                                                  FROM NoteOrAttachment__c
                                                                  WHERE Attachment_Id__c = :res.getBody()
                                                                  ORDER BY CreatedDate DESC
                                                                  LIMIT 1];
       
       System.debug('Attachment: '+relatedNoteOrAttachmentRecord);
                                                                 
       if(relatedNoteOrAttachmentRecord.size() > 0) {
        
        relatedNoteOrAttachmentRecord[0].Category__c = GlobalConstants.INCOMING;
        relatedNoteOrAttachmentRecord[0].IsMinCorroCaseNote__c = TRUE;
        //update relatedNoteOrAttachmentRecord[0];
        
        Attachment actualCongaAttachment = [SELECT Id, Name, ParentId, Body, BodyLength, ContentType FROM Attachment WHERE Id = :res.getBody()];
               
        Attachment actualCongaAttachmentCopy = new Attachment();
        actualCongaAttachmentCopy.Name = actualCongaAttachment.Name;
        actualCongaAttachmentCopy.Body = actualCongaAttachment.Body;
        actualCongaAttachmentCopy.ContentType = actualCongaAttachment.ContentType;
        actualCongaAttachmentCopy.ParentId = relatedNoteOrAttachmentRecord[0].Id;
               
        insert actualCongaAttachmentCopy;
        
        relatedNoteOrAttachmentRecord[0].Attachment__c = actualCongaAttachmentCopy.Id;
               
        update relatedNoteOrAttachmentRecord[0];
        
        delete actualCongaAttachment;
       }
      }
     }
 }
}