@IsTest
public with sharing class AddressValidationServiceReqBuilderTest{
	
	public static testMethod void testForInvalidParameter(){
		System.Test.startTest();
		try{
			AddressValidationServiceReqBuilder reqBuilder = new AddressValidationServiceReqBuilder();
			reqBuilder.buildRequest(new Account());
			System.assert(false,'Failed to test request builder for invalid parameter');
		} catch(NSWPointServiceException e){
			System.assert(e.getMessage() == 'Invalid parameter to build address validation service request', 
                'Failed to test request builder for invalid parameter');
		}
		System.Test.stopTest();
	}
	
	public static testMethod void testForBlankAddress(){
		AddressDetails addr = new AddressDetails();
		System.Test.startTest();
		try{
			AddressValidationServiceReqBuilder reqBuilder = new AddressValidationServiceReqBuilder();
			reqBuilder.buildRequest(addr);
			System.assert(false,'Failed to test request builder for blank address details');
		} catch(NSWPointServiceException e){
			System.assert(e.getMessage() == 'Address to validate is mandatory parameter for address validation service.', 
                'Failed to test request builder for blank address details');
		}
		System.Test.stopTest();
	}
}