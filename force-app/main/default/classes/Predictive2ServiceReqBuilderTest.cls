@IsTest
public with sharing class Predictive2ServiceReqBuilderTest{
	
	public static testMethod void testForInvalidParameter(){
		System.Test.startTest();
		try{
			Predictive2ServiceReqBuilder reqBuilder = new Predictive2ServiceReqBuilder();
			reqBuilder.buildRequest(new Account());
			System.assert(false,'Failed to test request builder for invalid parameter');
		} catch(NSWPointServiceException e){
			System.assert(e.getMessage() == 'Invalid parameter to build predictive2 service request', 
                'Failed to test request builder for invalid parameter');
		}
		System.Test.stopTest();
	}
	
	public static testMethod void testForBlankAddress(){
		AddressDetails addr = new AddressDetails();
		System.Test.startTest();
		try{
			Predictive2ServiceReqBuilder reqBuilder = new Predictive2ServiceReqBuilder();
			reqBuilder.buildRequest(addr);
			System.assert(false,'Failed to test request builder for blank address details');
		} catch(NSWPointServiceException e){
			System.assert(e.getMessage() == 'Address Id is mandatory for predictive2 service.', 
                'Failed to test request builder for blank address details');
		}
		System.Test.stopTest();
	}
}