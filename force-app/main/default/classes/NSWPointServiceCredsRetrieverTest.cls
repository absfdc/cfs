@IsTest
public with sharing class NSWPointServiceCredsRetrieverTest{
	
	public static testMethod void testForInvalidServiceName(){
		String serviceName = 'Test';
		System.Test.startTest();
		String key = NSWPointServiceCredsRetriever.getKey(serviceName);
		String endpoint = NSWPointServiceCredsRetriever.getEndpoint(serviceName);
		System.Test.stopTest();
		System.assert(endpoint == null, 'Failed to test getEndpoint for invalid service name');
		System.assert(key == null, 'Failed to test getKey for invalid service name');
	}
}