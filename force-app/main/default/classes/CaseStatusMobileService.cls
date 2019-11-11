/*------------------------------------------------------------
Author:        Deepak Soni
Company:       Arxxus Technology Partners
Description:   Rest API for Mobile app to read status of all cases by given guids.
			   This API also returns Status Update Frequency data that App uses as govern limits for status update requests.
Inputs:        Json object of guids as request body
			   
Test Class:    CaseStatusMobileService_Test

History
<Date>      	<Authors Name>		<Brief Description of Change>
19/02/2016      Deepak Soni     	Implemented Rest API service
------------------------------------------------------------*/
@RestResource(urlMapping='/cfm/v1/getAllStatuses/*')
global class CaseStatusMobileService {
	public static final String RESPONSIBLE_PARTY_DEFAULT = 'NA';

	@HttpPost
	global static ResponseWrapper doPost() {
		ResponseWrapper statusResponse = new ResponseWrapper();

		try {
	    	String guidsInJson = RestContext.request.requestBody.tostring();

	        List<String> guids = (List<String>) JSON.deserialize(guidsInJson, List<String>.class);

	        List<Case> cases = new List<Case>();
	        if(!guids.isEmpty()) {
	        	Integer queryRecordsLimit = Limits.getLimitQueryRows();
				cases = [SELECT Status, Partner_Case_Status__c, Responsible_Party__c, GUID__c FROM Case WHERE GUID__c IN :guids limit :queryRecordsLimit];
	        }

	        Map<String, String> defaultCaseStatusMap = new Map<String, String>();
	        Map<String, String> snswCaseStatusMap = new Map<String, String>();
	        for(CaseStatusForMobileApp__c caseStatus :CaseStatusForMobileApp__c.getall().values()) {
	        	if(caseStatus.Responsible_Party__c == GlobalConstants.RESPONSIBLE_PARTY_SNSW) {
	        		snswCaseStatusMap.put(caseStatus.Name.toLowerCase(), caseStatus.Case_Status_on_Mobile_App__c);
	        	} else if(caseStatus.Responsible_Party__c == RESPONSIBLE_PARTY_DEFAULT) {
	        		defaultCaseStatusMap.put(caseStatus.Name.toLowerCase(), caseStatus.Case_Status_on_Mobile_App__c);
	        	}
	        }

	        Map<String, String> caseStatusByGuid = new Map<String, String>();
	        for(Case cas :cases) {
	        	String casStatus = cas.Status.toLowerCase();
	        	String partnerCaseStatus = '';

	        	if(cas.Responsible_Party__c == GlobalConstants.RESPONSIBLE_PARTY_SNSW && String.isNotEmpty(cas.Partner_Case_Status__c)) {
	        		partnerCaseStatus = cas.Partner_Case_Status__c.toLowerCase();
	        	}

	        	if(cas.Responsible_Party__c == GlobalConstants.RESPONSIBLE_PARTY_SNSW && cas.Status.equals(GlobalConstants.CASE_SOFTCLOSED_STATUS) && snswCaseStatusMap.containsKey(partnerCaseStatus)) {
	        		caseStatusByGuid.put(cas.GUID__c, snswCaseStatusMap.get(partnerCaseStatus));
        		} else if(defaultCaseStatusMap.containsKey(casStatus)) {
	        		caseStatusByGuid.put(cas.GUID__c, defaultCaseStatusMap.get(casStatus));
	        	}
	        }

	        Map<String, Integer> caseStatusUpdateFrequencyMap = new Map<String, Integer>();
	        for(CaseStatusUpdateFrequencey__c caseStatusUpdateFreq :CaseStatusUpdateFrequencey__c.getall().values()) {
	        	caseStatusUpdateFrequencyMap.put(caseStatusUpdateFreq.Name, Integer.valueOf(caseStatusUpdateFreq.Query_Once_Within__c));
	        }

	        statusResponse.success = true;
	        statusResponse.response = caseStatusByGuid;
	        statusResponse.guidance = caseStatusUpdateFrequencyMap;
		} catch(Exception ex) {
			statusResponse.errorMessage = ex.getMessage();
		}
        
        return statusResponse;
	}

	global class ResponseWrapper {
		public Boolean success {get; set;}
    	public String errorMessage {get; set;}
		public Map<String, String> response {get; set;}
		public Map<String, Integer> guidance {get; set;}

    	public ResponseWrapper() {
    		success = false;
    		response = new Map<String, String>();
    		guidance = new Map<String, Integer>();
    	}
	}
}