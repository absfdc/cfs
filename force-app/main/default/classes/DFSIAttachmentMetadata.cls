public class DFSIAttachmentMetadata {
	
	public DFSIAttribute attributes;
	public String Id;
	public String Name;
	public String ContentType;
	public String ParentId;
	public String Title;
	public String RecordType;

	public static List<DFSIAttachmentMetadata> parse(String jsonStr) {
		if(jsonStr == null || jsonStr == '')
			return null;
		return (List<DFSIAttachmentMetadata>) JSON.deserialize(jsonStr, List<DFSIAttachmentMetadata>.class);
	}

	public NoteOrAttachment__c convert() {
		NoteOrAttachment__c result = new NoteOrAttachment__c();
		result.Name = this.Name;
		result.ContentType__c = this.ContentType;
		result.DFSIAttachmentId__c = this.Id;
		result.RecordTypeId = Schema.SObjectType.NoteOrAttachment__c.getRecordTypeInfosByName().get('Attachment').getRecordTypeId();
		return result;
	}
}