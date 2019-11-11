public with sharing class CaseRecordTypeFlip {
    
    private List<Case> newCases;
    private static Map<String, Id> recordTypeNameVsId;
    private static Map<Id, String> recordTypeIdVsName;
    
    static {
        Map<String, CaseRecordTypesToExcludeFromRtFlip__c> rtToExclude = CaseRecordTypesToExcludeFromRtFlip__c.getAll();
        Set<String> rtNamesToExclude = new Set<String>();
        for(CaseRecordTypesToExcludeFromRtFlip__c rtName: rtToExclude.values()) {
            rtNamesToExclude.add(rtName.Record_Type_Name__c);
        }
        
        recordTypeNameVsId = new Map<String, Id>();
        recordTypeIdVsName = new Map<Id, String>();
        for(RecordType rt :  [ SELECT Id, Name FROM RecordType WHERE sObjectType = 'Case' AND Name NOT IN :rtNamesToExclude]) {
            recordTypeNameVsId.put(rt.Name, rt.Id);
            recordTypeIdVsName.put(rt.Id, rt.Name);
            if(rt.Name == GlobalConstants.NON_MODAL_RECORD_TYPE_NAME) {
                recordTypeNameVsId.put(GlobalConstants.NON_MODAL_CASE_MODE, rt.Id);
                recordTypeIdVsName.put(rt.Id, GlobalConstants.NON_MODAL_CASE_MODE);
            }
        }
    }
    
    public CaseRecordTypeFlip(List<Case> newCases) {
        if(newCases == null || newCases.isEmpty()) {
            throw new InvalidDataException('Case record types cannot be flipped. Case details missing');
        }
        this.newCases = newCases;       
    }
    
    public void flipRecordTypes() {
        System.debug('Record types to include: ' + recordTypeIdVsName);
        for(Case caseRecord: newCases) {
            if(recordTypeIdVsName.containsKey(caseRecord.RecordTypeId) 
                    && recordTypeIdVsName.get(caseRecord.RecordTypeId) != caseRecord.Modes__c
                    && recordTypeIdVsName.get(caseRecord.RecordTypeId) != null) {
                caseRecord.RecordTypeId = recordTypeNameVsId.get(caseRecord.Modes__c);
            }
        }
    }
    
    public class InvalidDataException extends Exception {}
}