@isTest
private class ChildActionPlanCounter_Test {

    private static List<Action_Plan__c> childActionPlans;
    private static Action_Plan__c parentActionPlan;
    
    @testSetup
    public static void setup() {
        PermissionSet pset = [Select Id From PermissionSet Where Name =: GlobalConstants.PERMISSION_SET_CORRO_OFFICER limit 1];
        List<PermissionSetAssignment> assignment = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :pset.id];
        if(assignment.isEmpty())
            insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(), PermissionSetId=pset.id);
    }
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            ChildActionPlanCounter childCounter = new ChildActionPlanCounter(childActionPlans);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        
        try {
            childActionPlans = new List<Action_Plan__c>();
            ChildActionPlanCounter childCounter = new ChildActionPlanCounter(childActionPlans);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForChildActionPlanCount() {
        setupTestData(1);
        System.Test.startTest();
        ChildActionPlanCounter counter = new ChildActionPlanCounter(childActionPlans);
        counter.updateChildActionPlanCounter();
        System.Test.stopTest();
        List<Action_Plan__c> parentAP = [SELECT Id, Child_Action_Plans__c, Completed_Child_Action_Plans__c FROM Action_Plan__c WHERE Id = :parentActionPlan.Id];
        System.assert(!parentAP.isEmpty());
        System.assert(parentAP[0].Completed_Child_Action_Plans__c == 0);
        System.assert(parentAP[0].Child_Action_Plans__c == 1);
    }
    
    private static testMethod void testForCompletedChildActionPlan() {
        setupTestData(1);
        for(Action_Plan__c child : childActionPlans) {
            child.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
        }
        System.Test.startTest();
        system.runAs(new User(Id = UserInfo.getUserId())){
            update childActionPlans;
        }
        
        ChildActionPlanCounter counter = new ChildActionPlanCounter(childActionPlans);
        counter.updateChildActionPlanCounter();
        System.Test.stopTest();
        List<Action_Plan__c> parentAP = [SELECT Id, Child_Action_Plans__c, Completed_Child_Action_Plans__c FROM Action_Plan__c WHERE Id = :parentActionPlan.Id];
        System.assert(!parentAP.isEmpty());
        System.assert(parentAP[0].Completed_Child_Action_Plans__c == 1);
        System.assert(parentAP[0].Child_Action_Plans__c == 1);
    }
    
    private static testMethod void testForBulkification() {
        setupTestData(200);
        
        System.Test.startTest();
        ChildActionPlanCounter counter = new ChildActionPlanCounter(childActionPlans);
        counter.updateChildActionPlanCounter();
        System.Test.stopTest();
        List<Action_Plan__c> parentAP = [SELECT Id, Child_Action_Plans__c, Completed_Child_Action_Plans__c FROM Action_Plan__c WHERE Id = :parentActionPlan.Id];
        System.assert(!parentAP.isEmpty());
        System.assert(parentAP[0].Completed_Child_Action_Plans__c == 0);
        System.assert(parentAP[0].Child_Action_Plans__c == 200);
    }
    
    private static void setupTestData(Integer actionplanCount) {
        Id recordType = retrieveNonCfmRecordTypeOfAp();
        createParentActionPlan(recordType);
        createChildActionPlans(actionplanCount, recordType);
    }
    
    private static void createChildActionPlans(Integer actionplanCount, Id recordType) {
        childActionPlans = new List<Action_Plan__c>();
        Id childActionPlanRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CHILD_AP_RECORDTYPE_API_NAME limit 1].Id;
        for(Integer index=0; index < actionplanCount; index++) {
            Action_Plan__c ap = new Action_Plan__c();
            ap.Parent_Action_Plan__c = parentActionPlan.Id;
            ap.Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
            ap.RecordTypeId = childActionPlanRecordTypeId;
            ap.Response__c = 'Test response';
            childActionPlans.add(ap);
        }
        
        if(!childActionPlans.isEmpty()) {
            insert childActionPlans;
        }
    }
    
    private static void createParentActionPlan(Id recordType) {
        parentActionPlan = new Action_Plan__c();
        parentActionPlan.Agency__c = 'TfNSW';
        
        insert parentActionPlan;
    }
    
    private static Id retrieveNonCfmRecordTypeOfAp() {
        List<RecordType> rt = [SELECT Id, Name 
                                FROM RecordType 
                                WHERE sObjectType = 'Action_Plan__c' 
                                    AND DeveloperName != :GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME];
        if(rt.isEmpty()) {
            return null;
        }
        return rt[0].Id;
    }
}