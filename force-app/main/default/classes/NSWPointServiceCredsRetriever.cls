/**
 * @Author: Sauce Consulting
 * @Description: Helper class to retrieve endpoint and credential details of service
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------------------------
   18-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class NSWPointServiceCredsRetriever {
	private static final Map<String, NSW_Point_Service_Credentials__mdt> CREDS;
	
	static {
		CREDS = new Map<String, NSW_Point_Service_Credentials__mdt>();
		for(NSW_Point_Service_Credentials__mdt setting: [SELECT Id, DeveloperName, Endpoint__c, Service_Key__c 
														FROM NSW_Point_Service_Credentials__mdt LIMIT 10]){
			CREDS.put(setting.DeveloperName, setting);
		}
	}
	
	public static String getEndpoint(String serviceName){
		if(CREDS.containsKey(serviceName)){
			return CREDS.get(serviceName).Endpoint__c;
		}
		return null;
	}
	
	public static String getKey(String serviceName){
		if(CREDS.containsKey(serviceName)){
			return CREDS.get(serviceName).Service_Key__c;
		}
		return null;
	}
}