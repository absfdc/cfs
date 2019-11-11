public without sharing class DuplicateAttachmentPurger {

    @Future
    public static void deleteDuplicateAttachments(Set<Id> attachmentsToDelete) {
        List<Attachment> attachments = new List<Attachment>();
        for(Id attachId : attachmentsToDelete) {
            Attachment attach = new Attachment(Id = attachId);
            attachments.add(attach);
        }
        delete attachments;
    }
    
    public static void shareAttachments(Map<Id, Id> attachmentsToShare) {
        S2SConnectionHelper.shareRecord(attachmentsToShare, GlobalConstants.S2S_CONNECTION_NAME);
    }
}