@isTest
private class FileUploadController_Test {

	@testSetup
	static void setUpCase(){
		
		Case privateOperatorCase1 = getPrivateOperatorCaseRecord();
		insert privateOperatorCase1;
	}

	@isTest
	static void testFileUploadControllerMethods(){

		Test.startTest();
		String fileName = 'Test File Name';
		String base64Data = 'Test base64Data'; 
		String contentType = 'Test contentType';
		List<Case> getCase = [Select Id FROM Case LIMIT 1];
		String fileId = FileUploadController.saveTheFile(getCase[0].Id,fileName,base64Data,contentType);
		String fileId1 = FileUploadController.saveTheChunk(getCase[0].Id,fileName,base64Data,contentType,fileId);
		String fileId2 = FileUploadController.saveTheChunk(null,fileName,base64Data,contentType,null);
		FileUploadController.appendToFile(fileId,base64Data);

	}

	/*------------------------------------------------------------------- ----------------
    Author:        
    Description:   This method creates a transport case record sobject
    -----------------------------------------------------------------------------------*/
    private static Case getPrivateOperatorCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.PRIVATE_OPERATOR_RECORD_TYPE limit 1];
       
        return new Case(Subject = 'Test Subject',
                            Description = 'There is long description here',                       
                            Status = 'New',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal');
    }
	
}