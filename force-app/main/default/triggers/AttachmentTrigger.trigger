trigger AttachmentTrigger on Attachment (after insert, after delete, after undelete,before insert) {

  TriggerFactory.createTriggerDispatcher(Attachment.sObjectType);
}