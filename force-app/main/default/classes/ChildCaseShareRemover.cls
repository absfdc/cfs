public without sharing class ChildCaseShareRemover{

    private List<Case> cases;
    private static final String ROW_CAUSE_FOR_CHILD_SHARE = 'Manual';
    private static final String READ_ACCESS_LEVEL = 'Read';
    private static final String GROUP_TYPE_ROLE = 'Role';
    
    public ChildCaseShareRemover(List<Case> cases) {
        if(cases == null || cases.isEmpty()){
            throw new InvalidDataException('Failed to remove share. Case details missing');
        }
        this.cases = cases;
    }
    
    public void deleteShare() {        
        Set<Id> caseOwnerID = new Set<Id>();                                              
        for(Case caseRecord : cases) {
            caseOwnerID.add(caseRecord.OwnerId);
        }       
        
        List<Case> childCases = [SELECT Id FROM Case WHERE ParentId IN :cases];
                
        if(!childCases.isEmpty()) {
            Set<Id> roleIds = new Set<Id>();
            for(User caseOwners : [SELECT Id, UserRoleId FROM User WHERE Id IN :caseOwnerID]){
                roleIds.add(caseOwners.UserRoleId);
            }
            List<Group> groups = [SELECT Id FROM Group WHERE RelatedId IN :roleIds AND Type = :GROUP_TYPE_ROLE];
            List<CaseShare> caseSharing = [ SELECT Id 
                                            FROM CaseShare 
                                            WHERE CaseAccessLevel = :READ_ACCESS_LEVEL
                                                AND RowCause = :ROW_CAUSE_FOR_CHILD_SHARE
                                                AND CaseId IN :childCases
                                                AND UserOrGroupId IN :groups];
            delete caseSharing;
        }
    }
    
    public class InvalidDataException extends Exception {}
}