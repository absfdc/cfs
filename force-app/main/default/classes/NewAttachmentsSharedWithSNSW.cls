public without sharing class NewAttachmentsSharedWithSNSW {

    private Map<Id, NoteOrAttachment__c> attachments;
    private static Boolean allAttachmentsShared = false;
    public NewAttachmentsSharedWithSNSW(Map<Id, NoteOrAttachment__c> attachments) {
        if(attachments == null || attachments.isEmpty()) {
            throw new InvalidDataException('Failed to share case attachments. Custom attachment details missing');
        }
        this.attachments = attachments;
    }
    
    public void shareAttachments() {
        if(allAttachmentsShared) {
            return;
        }
        List<Attachment> attachmentsToShare = new List<Attachment>();
        Map<Id, Id> attachmentVsCase = new Map<Id,Id>();
        Set<Id> sharedCustomAttachments = new Set<Id>();
        for(NoteOrAttachment__c customAttachment : [SELECT Id, Case__c, Attachment__c 
                                                    FROM NoteOrAttachment__c 
                                                    WHERE Id IN :attachments.keySet()
                                                        AND Case__r.Shared__c = true]) {
            if(attachments.get(customAttachment.Id).Attachment__c != null && !attachments.get(customAttachment.Id).Is_Shared_S2S__c) {
                attachmentVsCase.put((Id) attachments.get(customAttachment.Id).Attachment__c, customAttachment.Case__c);                
            }            
        }
                
        for(Attachment existingAttachment :[SELECT ParentId, Name, IsPrivate, IsPartnerShared,  Id, Description, ContentType,  Body 
                                            FROM Attachment 
                                            WHERE Id IN :attachmentVsCase.keySet()
                                                AND IsPrivate = false
                                                AND IsPartnerShared = false]) {
            
            Attachment newAttachment = new Attachment();
            newAttachment.ParentId = attachmentVsCase.get(existingAttachment.Id);
            newAttachment.Name = existingAttachment.Name;
            newAttachment.IsPrivate = existingAttachment.IsPrivate;
            newAttachment.Description = existingAttachment.Description;
            newAttachment.ContentType = existingAttachment.ContentType;
            newAttachment.Body = existingAttachment.Body;
            
            attachmentsToShare.add(newAttachment);
            sharedCustomAttachments.add(existingAttachment.ParentId);
        }
        
        if(!attachmentsToShare.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'Number of attachments to be shared: ' + attachmentsToShare.size());
            S2SAttachmentShareStatusRetriever.shareAttachment = true;
            insert attachmentsToShare;
            allAttachmentsShared = true;
            for(NoteOrAttachment__c attach : attachments.values()) {
                if(sharedCustomAttachments.contains(attach.Id)) {
                    attach.Is_Shared_S2S__c = true;
                }
            }
        }
    }
    
    public class InvalidDataException extends Exception {}
}