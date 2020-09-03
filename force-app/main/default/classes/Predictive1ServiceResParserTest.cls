@IsTest
public with sharing class Predictive1ServiceResParserTest{
	
	public static testMethod void testForNullParameter(){
		System.Test.startTest();
		Predictive1ServiceResParser parser = new Predictive1ServiceResParser();
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