@isTest
public class DFSIAttachmentMetadataTest
{
	public static String jsonString = '[{ "attributes": {   "type": "Attachment",   "url": "/services/data/v40.0/sobjects/Attachment/00PN0000006d6zVMAQ"  },  "Id": "00PN0000006d6zVMAQ",  "Name": "image001.jpg",  "ContentType": "image/jpeg",  "ParentId": "xxx" }, {  "attributes": {   "type": "Attachment",   "url": "/services/data/v40.0/sobjects/Attachment/00PN0000006d6zWMAQ"  },  "Id": "00PN0000006d6zWMAQ",  "Name": "Casino.jpg",  "ContentType": "image/jpeg",  "ParentId": "xxx" }, {  "attributes": {   "type": "Attachment",   "url": "/services/data/v40.0/sobjects/Attachment/00PN0000006d6zXMAQ"  },  "Id": "00PN0000006d6zXMAQ",  "Name": "UAT.txt",  "ContentType": "text/plain",  "ParentId": "yyy" }, {  "attributes": {   "type": "Attachment",   "url": "/services/data/v40.0/sobjects/Attachment/00PN0000006d7VjMAI"  },  "Id": "00PN0000006d7VjMAI",  "Name": "image001.jpg",  "ContentType": "image/jpeg",  "ParentId": "yyy" }, {  "attributes": {   "type": "Attachment",   "url": "/services/data/v40.0/sobjects/Attachment/00PN0000006d7VkMAI"  },  "Id": "00PN0000006d7VkMAI",  "Name": "salesforce_apex_language_reference.pdf",  "ContentType": "application/pdf",  "ParentId": "yyy" }]';

	@isTest
	static void testJSONParsing() {

		List<DFSIAttachmentMetadata> result = DFSIAttachmentMetadata.parse(jsonString);

		System.assertEquals(5, result.size());

	}

	@isTest 
	static void testConversion() {
		DFSIAttachmentMetadata obj = new DFSIAttachmentMetadata();
		obj.Id = 'aaa';
		obj.Name = 'bbb';
		obj.ContentType = 'ccc';
		obj.ParentId = 'ddd';
		obj.Title = 'eee';
		obj.RecordType = 'fff';

		NoteOrAttachment__c result = obj.convert();

		System.assertEquals('aaa',result.DFSIAttachmentId__c);
		System.assertEquals('bbb',result.Name);
		System.assertEquals('ccc',result.ContentType__c);
		System.assertEquals(Schema.SObjectType.NoteOrAttachment__c.getRecordTypeInfosByName().get('Attachment').getRecordTypeId(),result.RecordTypeId);


	}
}