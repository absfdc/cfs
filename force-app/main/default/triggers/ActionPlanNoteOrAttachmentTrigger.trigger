trigger ActionPlanNoteOrAttachmentTrigger on AP_NoteOrAttachment__c (after insert, after delete, after undelete) {
	TriggerFactory.createTriggerDispatcher(AP_NoteOrAttachment__c.sObjectType);
}