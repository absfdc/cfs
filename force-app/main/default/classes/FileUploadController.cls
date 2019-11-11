/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus Technology Partners
Description:   Server side Rest resource controller for Upload Attachment.
               This controller services UploadAttachmentModal.cmp component

History
26/06/2017      Pawan Tiwari         Created.
------------------------------------------------------------*/

public without sharing class FileUploadController {
 
    // this method creates a salesforce attachment based on the file name and file data from lightning controller
    @AuraEnabled
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) { 
        Id attachmentId;
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment tempAttachment = new Attachment();
        tempAttachment.parentId = parentId;
        tempAttachment.Body = EncodingUtil.base64Decode(base64Data);
        tempAttachment.Name = fileName;
        tempAttachment.ContentType = contentType;
        
       Database.SaveResult sr = Database.insert(tempAttachment);

        if(sr.isSuccess()){
          List<NoteOrAttachment__c> customAttachmentList = [SELECT Id FROM NoteOrAttachment__c 
                                                          WHERE Attachment__c = : tempAttachment.Id limit 1];
          if(customAttachmentList.size() > 0){
            Attachment newAttachment = new Attachment(name = tempAttachment.Name, body = tempAttachment.Body, parentId = customAttachmentList[0].Id);
            System.debug('newAttachment :: '+ newAttachment);
            insert newAttachment;

            customAttachmentList[0].Attachment__c = newAttachment.Id;
            update customAttachmentList;
            
            delete tempAttachment;

            attachmentId = newAttachment.Id;
          }
        }
        System.debug('Final Attachment :: '+ attachmentId);
        return attachmentId; 
    }
    
    // this method updates salesforce attachment based on the file name and file data from lightning controller
    @AuraEnabled
    public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId){ 
        Exception ex;
        System.debug('saveTheChunk ParentId :: ' + parentId );
        System.debug('Attachment Id :: ' + fileId);
        List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
        try{
            if (String.isEmpty(fileId)) {
                fileId = saveTheFile(parentId, fileName, base64Data, contentType);
            } else {
                appendToFile(fileId, base64Data);
            }
            
            return Id.valueOf(fileId);

        }catch(Exception e){
        
            ex = e;
            return null;
        }finally{
            System.debug('finally executing.');
            if(ex != NULL) {
                System.debug(ex);
                ApplicationLogMessage message= new ApplicationLogMessage();
                message.source='FileUploadController';
                message.sourceFunction='saveTheChunk';
                message.logMessage=ex.getMessage()+'--'+ex.getLineNumber();
                message.ex=ex;
                message.debugLevel=GlobalConstants.ERROR;
                messages.add(message);
                ApplicationLogUtility.logMessage(messages);
                messages.clear();
                return null;
            }
        }
        
    }
    
    // append the attachment body
    @TestVisible
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        List<Attachment> attachmentList = [SELECT Id, Body,ParentId FROM Attachment WHERE Id = :fileId];
        if(attachmentList.size() > 0){
          String existingBody = EncodingUtil.base64Encode(attachmentList[0].Body);
          attachmentList[0].Body = EncodingUtil.base64Decode(existingBody + base64Data); 
        
          update attachmentList;
        }
        
    }
}