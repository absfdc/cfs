public without sharing class CaseAttachmentsSharedWithSNSW {

    private List<Case> sharedCases;
    private static Boolean allAttachmentsShared = false;
    public CaseAttachmentsSharedWithSNSW(List<Case> sharedCases) {
        if(sharedCases == null || sharedCases.isEmpty()) {
            throw new InvalidDataException('Failed to share case attachments. Case details missing');
        }
        this.sharedCases = sharedCases;
    }
    
    public void shareAttachments() {
        if(allAttachmentsShared) {
            return;
        }
        List<Attachment> attachmentsToShare = new List<Attachment>();
        Set<Id> existingAttachmentIds = new Set<Id>();
        Map<Id, Id> customAttachmentVsCase = new Map<Id,Id>();
        Set<Id> sharedCustomAttachments = new Set<Id>();
        Map<Id, NoteOrAttachment__c> customAttachmentMap = 
                    new Map<Id, NoteOrAttachment__c>([  SELECT Id, Case__c, Attachment__c, Is_Shared_S2S__c, Privacy__c 
                                                        FROM NoteOrAttachment__c 
                                                        WHERE Case__c IN :sharedCases
                                                            AND Is_Shared_S2S__c = false]);
        for(NoteOrAttachment__c customAttachment : customAttachmentMap.values()) {
            if(customAttachment.Attachment__c != null && customAttachment.Privacy__c != GlobalConstants.NOTEORATTACHMENT_PRIVACY_RESTRICTED) {
                existingAttachmentIds.add(customAttachment.Attachment__c);
                customAttachmentVsCase.put(customAttachment.Id, customAttachment.Case__c);
            }            
        }
        
        for(Attachment existingAttachment :[SELECT ParentId, Name, IsPrivate, Id, Description, ContentType,  Body 
                                            FROM Attachment 
                                            WHERE Id IN :existingAttachmentIds
                                                AND IsPrivate = false
                                                AND IsPartnerShared = false]) {
            Attachment newAttachment = new Attachment();
            newAttachment.ParentId = customAttachmentVsCase.get(existingAttachment.ParentId);
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
            List<NoteOrAttachment__c> customAttachmentToUpdate = new List<NoteOrAttachment__c>();
            for(NoteOrAttachment__c attach : customAttachmentMap.values()) {
                if(sharedCustomAttachments.contains(attach.Id)) {
                    attach.Is_Shared_S2S__c = true;
                    customAttachmentToUpdate.add(attach);
                }
            }
            update customAttachmentToUpdate;
        }
    }
    
    public class InvalidDataException extends Exception {}
}