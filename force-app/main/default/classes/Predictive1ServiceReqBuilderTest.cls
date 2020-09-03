@IsTest
public with sharing class Predictive1ServiceReqBuilderTest{
	
	public static testMethod void testForInvalidParameter(){
		System.Test.startTest();
		try{
			Predictive1ServiceReqBuilder reqBuilder = new Predictive1ServiceReqBuilder();
			reqBuilder.buildRequest(new Account());
			System.assert(false,'Failed to test request builder for invalid parameter');
		} catch(NSWPointServiceException e){
			System.assert(e.getMessage() == 'Invalid parameter to build predictive1 service request', 
                'Failed to test request builder for invalid parameter');
		}
		System.Test.stopTest();
	}
	
	public static testMethod void testForBlankAddress(){
		AddressDetails addr = new AddressDetails();
		System.Test.startTest();
		try{
			Predictive1ServiceReqBuilder reqBuilder = new Predictive1ServiceReqBuilder();
			reqBuilder.buildRequest(addr);
			System.assert(false,'Failed to test request builder for blank address details');
		} catch(NSWPointServiceException e){
			System.assert(e.getMessage() == 'Address to search is mandatory parameter for predictive1 service', 
                'Failed to test request builder for blank address details');
		}
		System.Test.stopTest();
	}
}