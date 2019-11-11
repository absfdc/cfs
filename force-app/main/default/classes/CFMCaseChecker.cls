/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    utility class for checking if a case is of CFM record type.
Inputs:         
Test Class:     CFMCaseChecker_Test
History:
------------------------------------------------------------*/
public with sharing class CFMCaseChecker {

    private static Set<Id> cfmCaseRecordTypes;
    
    private static void retrieveCfmRecordTypes() {
        List<BusinessProcess> businessProcesses = [ Select Id 
                                                    From BusinessProcess
                                                    WHERE TableEnumOrId = 'Case'
                                                        AND IsActive = true
                                                        AND Name = :Label.CFM_Case_Support_Process LIMIT 1];
        cfmCaseRecordTypes = new Set<Id>();
        if(!businessProcesses.isEmpty()) {
            List<RecordType> cfmRecordTypes = [ Select Id
                                                FROM RecordType
                                                WHERE SobjectType = 'Case'
                                                    AND IsActive = true
                                                    AND BusinessProcessId = :businessProcesses[0].Id];
            for(RecordType rt: cfmRecordTypes) {
                cfmCaseRecordTypes.add(rt.Id);
            }
        }
    }
    
    public static Boolean isCfmCase(Case caseRecord) {
        if(cfmCaseRecordTypes == null) {
            retrieveCfmRecordTypes();
        }
        
        return cfmCaseRecordTypes.contains(caseRecord.RecordTypeId);
    }
}