public class ShowOriginalDescriptionController {
	
   	@AuraEnabled
    public static String getOrigianlDescription(String caseId) {
        System.debug('caseId: '+caseId);
        Case caseRecord = [SELECT Id, Original_Description__c FROM Case WHERE Id =: caseId];
		return caseRecord.Original_Description__c;
        
    }
    
}