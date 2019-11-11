/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    Helper class for identifying number of cfm and min corr cases associated with a contact.
Inputs:         "contactIds" - list of contact ids for which cfm and min corr case count needs to be calculated
Test Class:     ContactCaseCounter_Test
History:
Date            Name          Description
13/01/2017      Arxxus        Updated - Commented unused queries
------------------------------------------------------------*/
public without sharing class ContactCaseCounter {

    private static final String MIN_CORR_RECORDTYPE_NAME = 'Ministerial Correspondence';
    private List<Id> contactIds;
    private Map<Id, Integer> cfmCaseCount;
    private Map<Id, Integer> minCorrCaseCount;
    public ContactCaseCounter(List<Id> contactIds) {
        if(contactIds == null || contactIds.isEmpty()) {
            throw new InvalidParameterException('Failed to count number of cases on contact. Contact details missing');
        }
        this.contactIds = contactIds;
        this.minCorrCaseCount = new Map<Id, Integer>();
        this.cfmCaseCount = new Map<Id, Integer>();
        for(Id contactId : contactIds) {
            cfmCaseCount.put(contactId, 0);
            minCorrCaseCount.put(contactId, 0);
        }
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Method responsible for counting number of cfm and min corr cases associated with a contact.
    Inputs:         
    Returns:        
    History:
    ------------------------------------------------------------*/
    public void countCases() {        
        List<Contact> contacts = [SELECT Id, No_CFM_cases_12_mth_rolling__c, No_MinCorro_cases_12_mth_rolling__c,
                                        (SELECT Id, RecordTypeId, IsMinCorroCase__c 
                                         FROM Cases 
                                         WHERE CreatedDate > :System.today().addYears(-1)
                                             AND ParentId = NULL) 
                                  FROM Contact
                                  WHERE Id IN :contactIds];
        System.debug(LoggingLevel.ERROR, 'related cases');
        countMinCorrCases(contacts);
        countCfmCases(contacts);
        
        for(Contact conRec : contacts) {
            conRec.No_CFM_cases_12_mth_rolling__c = cfmCaseCount.get(conRec.Id);
            conRec.No_MinCorro_cases_12_mth_rolling__c = minCorrCaseCount.get(conRec.Id);
        }
        
        if(!contacts.isEmpty()) {
            System.debug('Contacts to update ' + contacts);
            Database.DMLOptions dmlOption = new Database.DMLOptions(); 
            dmlOption.DuplicateRuleHeader.AllowSave = true;
            List<Database.SaveResult> results = Database.update(contacts, dmlOption);            
        }
    }
    
    private void countMinCorrCases(List<Contact> contacts) {
        
        String minCorrRecordTypeName = '%' + MIN_CORR_RECORDTYPE_NAME  + '%';
        
        //commenting as no use - seems to be garbage code left to be cleaned up
        /*
        List<RecordType> rt = [ SELECT Id, Name 
                                FROM RecordType 
                                WHERE sObjectType = 'Case' 
                                    AND Name LIKE :minCorrRecordTypeName ];
        Set<Id> recordTypeIds = new Set<Id>();
        for(RecordType recType : rt) {
            recordTypeIds.add(recType.Id);   
        }
        */
        
        for(Contact conRec : contacts) {
            List<Case> cases = conRec.Cases;
            System.debug('Related cases: ' + cases);
            for(Case caseRecord : cases) {
                if(caseRecord.IsMinCorroCase__c) {
                    minCorrCaseCount.put(conRec.Id, minCorrCaseCount.get(conRec.Id) + 1);
                }
            }
        }
    }
    
    private void countCfmCases(List<Contact> contacts) {
        
        //commenting as no use - seems to be garbage code left to be cleaned up
        /*
        Map<String, CFMCaseRecordType__c> cfmRecordTypeNames = CFMCaseRecordType__c.getAll();
        List<RecordType> rt = [ SELECT Id, Name 
                                FROM RecordType 
                                WHERE sObjectType = 'Case' 
                                    AND Name IN :cfmRecordTypeNames.keySet()];
        Set<Id> recordTypeIds = new Set<Id>();
        for(RecordType recType : rt) {
            recordTypeIds.add(recType.Id);   
        }
        */
        
        for(Contact conRec : contacts) {
            List<Case> cases = conRec.Cases;
            for(Case caseRecord : cases) {
                if(!caseRecord.IsMinCorroCase__c) {
                    cfmCaseCount.put(conRec.Id, cfmCaseCount.get(conRec.Id) + 1);
                }
            }
        }
    }
    
    public class InvalidParameterException extends Exception {}
}