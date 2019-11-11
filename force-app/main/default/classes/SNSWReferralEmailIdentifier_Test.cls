@isTest
private class SNSWReferralEmailIdentifier_Test {

    private static List<Case> cases;
    private final static String DEFAULT_REFERRAL_EMAIL = 'defaultuser@transport.nsw.gov.au';
    private final static String TOLLING_REFERRAL_EMAIL = 'testuser@transport.nsw.gov.au';
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            SNSWReferralEmailIdentifier referralIdentifier = new SNSWReferralEmailIdentifier (cases);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            SNSWReferralEmailIdentifier referralIdentifier = new SNSWReferralEmailIdentifier (new List<Case>());
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForDefaultReferralAddress() {
        setUpTestData(1);
        for(Case caseRecord: cases) {
            caseRecord.Taxonomy_Transaction__c = 'Licensing';
        }
        System.Test.startTest();
        SNSWReferralEmailIdentifier referralIdentifier = new SNSWReferralEmailIdentifier (cases);
        referralIdentifier.populateSNSWReferral();
        System.Test.stopTest();
        for(Case caseRecord: cases) {
            System.assert(caseRecord.SNSW_Referral_Email__c == DEFAULT_REFERRAL_EMAIL);
        }
    }
    
    private static testMethod void testForIssueSpecificReferralAddress() {
        setUpTestData(1);       
        System.Test.startTest();
        SNSWReferralEmailIdentifier referralIdentifier = new SNSWReferralEmailIdentifier (cases);
        referralIdentifier.populateSNSWReferral();
        System.Test.stopTest();
        for(Case caseRecord: cases) {
            System.assert(caseRecord.SNSW_Referral_Email__c == TOLLING_REFERRAL_EMAIL);
        }
    }
    
    private static testMethod void testForNonSNSWCases() {
        setUpTestData(1);
        for(Case caseRecord: cases) {
            caseRecord.Agency__c = 'RMS';
        }
        System.Test.startTest();
        SNSWReferralEmailIdentifier referralIdentifier = new SNSWReferralEmailIdentifier (cases);
        referralIdentifier.populateSNSWReferral();
        System.Test.stopTest();
        for(Case caseRecord: cases) {
            System.assert(String.isBlank(caseRecord.SNSW_Referral_Email__c));
        }
    }
    
    private static testMethod void testForZeroCustomSettingEntries() {
        createCase(200);
        System.Test.startTest();
        SNSWReferralEmailIdentifier referralIdentifier = new SNSWReferralEmailIdentifier (cases);
        referralIdentifier.populateSNSWReferral();
        System.Test.stopTest();
        for(Case caseRecord: cases) {
            System.assert(String.isBlank(caseRecord.SNSW_Referral_Email__c));
        }
    }
    
    private static testMethod void bulkTest() {
        setUpTestData(200);     
        System.Test.startTest();
        SNSWReferralEmailIdentifier referralIdentifier = new SNSWReferralEmailIdentifier (cases);
        referralIdentifier.populateSNSWReferral();
        System.Test.stopTest();
        for(Case caseRecord: cases) {
            System.assert(caseRecord.SNSW_Referral_Email__c == TOLLING_REFERRAL_EMAIL);
        }
    }
    
    private static void setUpTestData(Integer caseCount) {
        createCase(caseCount);
        createCustomSettingEntry();
    }
    
    private static void createCustomSettingEntry() {
        List<SNSW_referral_email_address__c> referralEmails = new List<SNSW_referral_email_address__c>();
        SNSW_referral_email_address__c defaultReferralAddress = new SNSW_referral_email_address__c(Name='Default', To_address__c = DEFAULT_REFERRAL_EMAIL);
        SNSW_referral_email_address__c issueSpecificReferralAddress = new SNSW_referral_email_address__c(Name='Tolling', To_address__c = TOLLING_REFERRAL_EMAIL);
        referralEmails.add(issueSpecificReferralAddress);
        referralEmails.add(defaultReferralAddress);
        insert referralEmails;
    }
    
    private static void createCase(Integer caseCount) {
        cases = new List<Case>();
        for(Integer index = 0; index < caseCount; index++ ) {
            Case caseRecord = new Case();
            caseRecord.Modes__c = 'Road';
            caseRecord.Taxonomy_Accountability__c = 'SNSW';
            caseRecord.Taxonomy_Location__c = 'Sydney';
            caseRecord.Agency__c = 'SNSW';
            caseRecord.Taxonomy_Transaction__c = 'Tolling';
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Compliment';
            caseRecord.Description = 'Test case for web to case creation'; 
            
            cases.add(caseRecord);
        }
    }
}