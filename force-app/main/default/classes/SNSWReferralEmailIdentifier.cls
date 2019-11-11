/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    utility class for retrieving email address to send SNSW referral email based on issue category
Inputs:         "caseRecords" - list of cases for which SNSW referral email needs to be identified
Test Class:     SNSWReferralEmailIdentifier_Test
History:
------------------------------------------------------------*/
public with sharing class SNSWReferralEmailIdentifier {

    private List<Case> cases;
    private static final String DEFAULT_REFERRAL = 'Default';
    
    public SNSWReferralEmailIdentifier(List<Case> caseRecords) {
        if(caseRecords == null || caseRecords.isEmpty()) {
            throw new InvalidParameterException('Cannot identify email address for SNSW referral. Case details missing');
        }
        this.cases= caseRecords;
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Salesforce.com
    Description:    Function populates SNSW referral email address on case based on issue category.
    Inputs:         
    Returns:        
    History:
    ------------------------------------------------------------*/
    public void populateSNSWReferral() {
        Map<String,SNSW_referral_email_address__c> snswReferralAddress = SNSW_referral_email_address__c.getAll();
        if(snswReferralAddress.isEmpty()) {
            return;
        }
        
        for(Case caseRecord: cases) {
            if(!String.isBlank(caseRecord.Agency__c) 
                    && caseRecord.Agency__c == GlobalConstants.SNSW_AGENCY 
                    && !String.isBlank(caseRecord.Taxonomy_Transaction__c)) {
                if(snswReferralAddress.containsKey(caseRecord.Taxonomy_Transaction__c)) {
                   caseRecord.SNSW_Referral_Email__c = snswReferralAddress.get(caseRecord.Taxonomy_Transaction__c).To_address__c;
                } else if(snswReferralAddress.containsKey(DEFAULT_REFERRAL)){
                    caseRecord.SNSW_Referral_Email__c = snswReferralAddress.get(DEFAULT_REFERRAL).To_address__c;
                }
            }    
        }        
    }
    
    public class InvalidParameterException extends Exception {}
}