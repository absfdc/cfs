@isTest
private class AutoShareWebCasesWithSNSW_Test {
    
    private static List<Case> cases;
    private static final String QUALIFIED_CRITERIA_VALUE = 'Tolling';
    
    private static void setUpTestData(String criteriaVal, Integer caseCount) {
        setUpQualificationCriteria();
        cases = new List<Case>();
        for(Integer index = 0; index < caseCount; index++) {
            Case caseRecord = new Case();
            caseRecord.Origin = 'Web';
            caseRecord.Taxonomy_Transaction__c = criteriaVal;
            
            cases.add(caseRecord);
        }
    }
    
    private static void setUpQualificationCriteria() {
        Case_sharing_criteria_for_SNSW__c criteria = new Case_sharing_criteria_for_SNSW__c();
        criteria.Name = 'Criteria 1';
        criteria.Field__c = 'Taxonomy_Transaction__c';
        criteria.Value__c = QUALIFIED_CRITERIA_VALUE;
        
        insert criteria;
    }
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            AutoShareWebCasesWithSNSW autoShare = new AutoShareWebCasesWithSNSW(cases);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForQualfiedCases() {
        setUpTestData(QUALIFIED_CRITERIA_VALUE, 1);
        System.Test.startTest();
        AutoShareWebCasesWithSNSW autoShare = new AutoShareWebCasesWithSNSW(cases);
        autoShare.shareQualifiedCases();
        System.assert(cases[0].Responsible_Party__c == GlobalConstants.RESPONSIBLE_PARTY_SNSW);
        System.Test.stopTest();
    }
    
    private static testMethod void testForNotQualifiedCases() {
        setUpTestData('dummy', 1);
        System.Test.startTest();
        AutoShareWebCasesWithSNSW autoShare = new AutoShareWebCasesWithSNSW(cases);
        autoShare.shareQualifiedCases();
        System.assert(cases[0].Responsible_Party__c != GlobalConstants.RESPONSIBLE_PARTY_SNSW);
        System.Test.stopTest();
    }
}