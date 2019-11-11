public without sharing class ShareCaseOnCategorisationUpdate {
    @Future
    public static void checkForSNSWSharing(List<Id> caseIds) {
        List<Case> cases = [SELECT Id, Responsible_Party__c, Created_By_Email__c, Origin, Taxonomy_Moment__c,
                                Taxonomy_Transaction__c, Taxonomy_Symptom__c, Taxonomy_Location_Type__c, Taxonomy_Area__c, 
                                Taxonomy_Location__c
                            FROM Case 
                            WHERE Id IN :caseIds
                                AND Shared__c = false];
        if(cases.isEmpty()) {
            return;
        }
        AutoShareWebCasesWithSNSW checker = new AutoShareWebCasesWithSNSW(cases);
        checker.shareQualifiedCases();
        List<Case> casesToShare = new List<Case>();
        for(Case caseRecord : cases) {
            if(GlobalConstants.RESPONSIBLE_PARTY_SNSW.equalsIgnoreCase(caseRecord.Responsible_Party__c)) {
                casesToShare.add(caseRecord);
            }
        }
        if(!casesToShare.isEmpty()) {
            update casesToShare;
        }
    }   
}