trigger NoteOrAttachmentTrigger on NoteOrAttachment__c (after insert,after update, after delete, after undelete , before Update,before insert) {
    TriggerFactory.createTriggerDispatcher(NoteOrAttachment__c.sObjectType);
}