@isTest
public class DFSIAttachmentTest {

	public static String jsonStr =     '[{ '
						+ '    "Name": "Test Name",'
						+ '    "Body": "Test Body",'
						+ '    "Id": "xxx" '
						+ '},'
						+ '{ '
						+ '    "Name": "Test Name 2",'
						+ '    "Body": "Test Body 2",'
						+ '    "Id": "yyy" '
						+ '}]';
    
	@isTest
	static void testJsonPArsing() {
	List<DFSIAttachment> result = DFSIAttachment.parse(jsonStr);

	System.assertEquals(2, result.size());
	System.assertEquals('xxx', result.get(0).Id);
	System.assertEquals('Test Name 2', result.get(1).Name);
	}

	@isTest
	static void testConversion() {
		DFSIAttachment obj = new DFSIAttachment();
		obj.Name = 'aaa';
		obj.Body = Blob.valueOf('bbb');
		obj.Id = 'ccc';

		Attachment result = obj.convert();

		System.assertEquals('aaa', result.Name);
		System.assertEquals('bbb', result.body.toString());
	}
}