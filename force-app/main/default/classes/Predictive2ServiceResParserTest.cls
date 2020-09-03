@IsTest
public with sharing class Predictive2ServiceResParserTest{
	
	public static testMethod void testForNullParameter(){
		System.Test.startTest();
		Predictive2ServiceResParser parser = new Predictive2ServiceResParser();
		try{			
			parser.parse(null);
			System.assert(false,'Failed to test response parser for invalid parameter');
		} catch(NSWPointServiceException e){
			System.assert(e.getMessage() == 'Response parser expects instance of NSWPointServiceResponse as input', 
                'Failed to test response parser for invalid parameter');
		}
		String errorMsg = parser.getErrorMessage();
		System.Test.stopTest();
		System.assert(errorMsg == null, 'Failed to test getErrorMessage for invalid response');
	}
}