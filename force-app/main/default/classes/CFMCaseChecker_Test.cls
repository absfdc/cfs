@isTest
private class CFMCaseChecker_Test{

    private static Case caseRecord;
    
    private static testMethod void testForCfmCase(){
        setUpTestData(true);
        System.Test.startTest();
        System.assert(CFMCaseChecker.isCfmCase(caseRecord));
        System.Test.stopTest();
    }
    
    private static testMethod void testForNonCfmCase(){
        setUpTestData(false);
        System.Test.startTest();
        System.assert(!CFMCaseChecker.isCfmCase(caseRecord));
        System.Test.stopTest();
    }
    
    private static void testForMultipleInvocation() {
        setUpTestData(true);
        CFMCaseChecker.isCfmCase(caseRecord);
        System.Test.startTest();
        System.assert(CFMCaseChecker.isCfmCase(caseRecord));
        System.Test.stopTest();
    }
    
    private static void setUpTestData(Boolean isCfm){
        Id recordType = retrieveCaseRecordType(isCfm);
        caseRecord = new Case();
        caseRecord.RecordTypeId = recordType;
    }    
    
    private static Id retrieveCaseRecordType(Boolean isCfm) {
        List<BusinessProcess> businessProcesses = [ Select Id, Name 
                                                    From BusinessProcess
                                                    WHERE TableEnumOrId = 'Case'
                                                        AND IsActive = true];
        
        if(!businessProcesses.isEmpty()) {
            Id businessProcessId;
            for(BusinessProcess businessProcessRecord: businessProcesses) {
                if(isCfm) {
                    if(businessProcessRecord.Name == Label.CFM_Case_Support_Process) {
                        businessProcessId = businessProcessRecord.Id;
                    }
                } else {
                    if(businessProcessRecord.Name != Label.CFM_Case_Support_Process) {
                        businessProcessId = businessProcessRecord.Id;
                    }                        
                }
            }
            List<RecordType> caseRecordTypes = [ Select Id
                                                FROM RecordType
                                                WHERE SobjectType = 'Case'
                                                    AND IsActive = true
                                                    AND BusinessProcessId = :businessProcessId];
            if(!caseRecordTypes.isEmpty()) {
                return caseRecordTypes[0].Id;
            }
        }
        return null;
    }
}