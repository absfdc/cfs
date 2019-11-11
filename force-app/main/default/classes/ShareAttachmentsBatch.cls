global  without sharing class ShareAttachmentsBatch implements Database.Batchable<sObject>{

    global final String query = 'SELECT Id, Case__c FROM NoteOrAttachment__c WHERE Is_Shared_S2S__c = true AND Shared__c = false';

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<NoteOrAttachment__c> scope){
        Set<Id> sharedCases = new Set<Id>();
        for(NoteOrAttachment__c customAttachment : scope){
            sharedCases.add(customAttachment.Case__c);
            customAttachment.Shared__c = true;
        }
        Map<Id, Id> attachmentsToShare = new Map<Id, Id>();
        for(Attachment attach : [SELECT Id, ParentId FROM Attachment WHERE ParentId IN :sharedCases AND IsPrivate = false]) {
            attachmentsToShare.put(attach.Id, attach.ParentId);
        }
        S2SConnectionHelper.shareRecord(attachmentsToShare, GlobalConstants.S2S_CONNECTION_NAME);
        update scope;
    }

    global void finish(Database.BatchableContext BC){
        List<NoteOrAttachment__c> attachments = (List<NoteOrAttachment__c>) Database.query(query);
        if(!attachments.isEmpty()) {
            ShareAttachmentsBatch shareAttBatch = new ShareAttachmentsBatch();
            Database.executeBatch(shareAttBatch);
        }
    }
}