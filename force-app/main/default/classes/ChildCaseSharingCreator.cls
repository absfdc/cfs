public without sharing class ChildCaseSharingCreator{

    private List<Case> cases;
    private Set<Id> rtToExclude;
    private static final String ROW_CAUSE_FOR_CHILD_SHARE = 'Manual';
    private static final String READ_ACCESS_LEVEL = 'Read';
    private static final String GROUP_TYPE_ROLE = 'Role';
    
    public ChildCaseSharingCreator(List<Case> cases) {
        if(cases == null || cases.isEmpty()) {
            throw new InvalidParameterException('Failed to create child case sharing. Case details missing');
        }
        this.cases = cases;
        Map<String,Case_Record_Types_to_Exclude_for_Sharing__c> recordTypesToExclude = Case_Record_Types_to_Exclude_for_Sharing__c.getAll();
        List<RecordType> rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name IN :recordTypesToExclude.keySet()];
        rtToExclude = new Set<Id>();
        for(RecordType caseRecordType : rt) {
            rtToExclude.add(caseRecordType.Id);
        }
    }
    
    public void createShareRecords() {    
        Map<Id,Case> probableCasesToCreateShare = new Map<Id,Case>();
        Set<Id> parentCaseIds = new Set<Id>();
        for(Case caseRecord: cases) {
            if(!rtToExclude.contains(caseRecord.RecordTypeId) 
                        && caseRecord.ParentId != null) {
                probableCasesToCreateShare.put(caseRecord.Id, caseRecord);
                parentCaseIds.add(caseRecord.ParentId);
            }
        }
        String userKeyPrefix = Schema.SObjectType.User.getKeyPrefix();
        Map<Id, Case> parentCases = new Map<Id,Case>([SELECT Id, OwnerId, Owner.UserRoleId FROM Case WHERE Id IN :parentCaseIds]);
        List<CaseShare> caseShares = new List<CaseShare>();
        Set<Id> parentOwnerRoleIds = new Set<Id>();
        for(Case caseRecord : probableCasesToCreateShare.values()) {
            if(!String.valueOf(parentCases.get(caseRecord.ParentId).OwnerId).startsWith(userKeyPrefix)) {                
                probableCasesToCreateShare.remove(caseRecord.Id);
            } else {
                parentOwnerRoleIds.add(parentCases.get(caseRecord.ParentId).Owner.UserRoleId);
            }
        }
        
        if(!probableCasesToCreateShare.isEmpty()) {
            Map<Id, Id> roleVsGroupId = new Map<Id, Id>();
            for(Group grp :[SELECT Id, RelatedId FROM Group WHERE RelatedId IN :parentOwnerRoleIds AND Type = :GROUP_TYPE_ROLE]) {
                roleVsGroupId.put(grp.RelatedId, grp.Id);
            }
            for(Case caseRecord: probableCasesToCreateShare.values()) {
                if(!String.isBlank(parentCases.get(caseRecord.ParentId).Owner.UserRoleId) 
                        && roleVsGroupId.get(parentCases.get(caseRecord.ParentId).Owner.UserRoleId) != null) {
                    caseShares.add(createShareRecord(caseRecord.Id, roleVsGroupId.get(parentCases.get(caseRecord.ParentId).Owner.UserRoleId)));
                }                
            }
            if(!caseShares.isEmpty()) {
                insert caseShares;
            }            
        }    
    }
    
    private CaseShare createShareRecord(Id caseId, Id groupId) {
        CaseShare shareRec = new CaseShare();
        shareRec.CaseId = caseId;
        shareRec.RowCause = ROW_CAUSE_FOR_CHILD_SHARE ;
        shareRec.UserOrGroupId = groupId;
        shareRec.CaseAccessLevel = READ_ACCESS_LEVEL ;
        
        return shareRec;
        
    }
    
    public class InvalidParameterException extends Exception {}
}