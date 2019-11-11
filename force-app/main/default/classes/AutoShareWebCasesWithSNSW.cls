public without sharing class AutoShareWebCasesWithSNSW {

    private List<Case> cases;
    private Map<String, Case_sharing_criteria_for_SNSW__c> sharingCriterions;
    public AutoShareWebCasesWithSNSW(List<Case> cases) {
        if(cases == null || cases.isEmpty()) {
            throw new InvalidDataException('Failed to share case with SNSW. Case details missing');
        }
        this.cases = cases;
        sharingCriterions = Case_sharing_criteria_for_SNSW__c.getAll();
    }
    
    public void shareQualifiedCases() {
        for(Case caseRecord : cases) {
            if(isQualifiedForSharing(caseRecord)) {
                caseRecord.Responsible_Party__c = GlobalConstants.RESPONSIBLE_PARTY_SNSW;
            }
        }
    }
    
    private Boolean isQualifiedForSharing(Case caseRecord) {        
        for(Case_sharing_criteria_for_SNSW__c criteria : sharingCriterions.values()) {
            String currValue = String.valueOf(caseRecord.get(criteria.Field__c));
            System.debug(LoggingLevel.INFO, 'Current Value: ' + currValue);
            System.debug(LoggingLevel.INFO, 'Criteria Value: ' + criteria.Value__c);
            
            if(GlobalConstants.WEB2CASE_ORIGIN.equalsIgnoreCase(caseRecord.Origin) && currValue != null && criteria.Value__c.equalsIgnoreCase(currValue)
                    && (String.isBlank(caseRecord.Created_By_Email__c) || !caseRecord.Created_By_Email__c.contains(GlobalConstants.SNSW_EMAIL_DOMAIN) )) {
                return true;
            }
        }
        return false;
    }
    
    public class InvalidDataException extends Exception {}
}