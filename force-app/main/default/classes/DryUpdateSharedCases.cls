public without sharing class DryUpdateSharedCases {

    @Future
    public static void updateCases(Set<Id> caseIds) {
        List<Case> cases = [SELECT Id, Status FROM Case WHERE Id IN :caseIds];
        update cases;
    }
}