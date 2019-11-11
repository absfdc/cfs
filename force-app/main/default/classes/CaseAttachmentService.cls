public interface CaseAttachmentService {

	//return  Map of External Id against Attachment for all attachments of the case
	Map<String, Attachment> getAttachments(Case scope);

	// return Map of External Case Id against Note or attachment for all attachments of the cases list
	Map<String, List<NoteOrAttachment__c>> getAttachmentMetadata(List<Case> cases);
}