@isTest
private class APStatusTransitionForRework_Test {

    private static Action_Plan__c actionPlan;
    private static final String RMS_CORRO_OFFICER_PERM = 'RMS_Corro_Officer';
    private static final String GIS_ADMIN_PERM = 'RMS_GIS_Admin';
    private static final String AGENCY_RESPONSE = GlobalConstants.RMS_AGENCY;
    
    private static void setUpTestData(String type, String status, String agency) {
        actionPlan = new Action_Plan__c();
        actionPlan.Type__c = type;
        actionPlan.Status__c = status;
        actionPlan.Agency__c = agency;
        actionPlan.RecordTypeId = retrieveAgencyResponseRT();
        actionPlan.Approver_Name__c = 'Test User';
        actionPlan.Approval_Date__c = System.today();
        actionPlan.Approver_Role__c = 'Admin';
        insert actionPlan;
    }
    
    private static Id retrieveAgencyResponseRT() {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Action_Plan__c' AND DeveloperName = 'RMS_Action_Plan'];
        return rts.isEmpty()? null : rts[0].Id;
    }
    
    private static Id retrieveChildActionPlanRT() {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Action_Plan__c' AND DeveloperName = 'MCWS_Child_Action_Plan'];
        return rts.isEmpty()? null : rts[0].Id;
    }
        
    private static testMethod void testForInvalidData() {
        actionPlan = new Action_Plan__c();
        System.Test.startTest();
        try {           
            APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForInvalidApId() {
        actionPlan = new Action_Plan__c();
        System.Test.startTest();
        try {           
            APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework('a0bO0000006AD6y');
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForActionPlanWithBlankType() {
        setUpTestData(null, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS, AGENCY_RESPONSE);
        System.Test.startTest();
        try {           
            APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
            transitionInstance.performTransition();
            System.assert(false);
        } catch(Exception e) {
            System.assert(e.getTypeName() == 'APStatusTransitionForRework.InvalidDataException');
        }
        System.Test.stopTest();
    }
        
    private static testMethod void testForParentAgencyResponse() {
        User u = createTestUser(RMS_CORRO_OFFICER_PERM);
        System.runAs(u) {   
            setUpTestData(GlobalConstants.AP_TYPE_AGENCY_RESPONSE, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS, AGENCY_RESPONSE);            
        }
        System.Test.startTest();
        System.runAs(u) {            
            try {           
                APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
                transitionInstance.performTransition(); 
                System.assert(false);
            } catch(Exception e) {
                System.assert(e.getTypeName() == 'APStatusTransitionForRework.InvalidDataException');
            }
        }        
        System.Test.stopTest();        
    }
    
    private static testMethod void testForAdviceRequestBlankAgency() {
        User u = createTestUser(RMS_CORRO_OFFICER_PERM);
        System.runAs(u) {
            setUpTestData(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS, null);            
        }
        System.Test.startTest();
        System.runAs(u) {            
            try {           
                APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
                transitionInstance.performTransition(); 
                System.assert(false);
            } catch(Exception e) {
                System.assert(e.getTypeName() == 'APStatusTransitionForRework.InvalidDataException');
            }
        }        
        System.Test.stopTest();        
    }
    
    private static testMethod void testForAdviceRequestInvalidAgency() {
        User u = createTestUser(RMS_CORRO_OFFICER_PERM);
        System.runAs(u) {
            setUpTestData(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS, 'Invalid');            
        }
        System.Test.startTest();
        System.runAs(u) {            
            try {           
                APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
                transitionInstance.performTransition(); 
                System.assert(false);
            } catch(Exception e) {
                System.assert(e.getTypeName() == 'APStatusTransitionForRework.InvalidDataException');
            }
        }        
        System.Test.stopTest();        
    }
    
    private static testMethod void testForChildAPAdviceRequest() {
        User u = createTestUser(RMS_CORRO_OFFICER_PERM);
        Id childApId ;
        System.runAs(u) {
            setUpTestData(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS, AGENCY_RESPONSE);
            childApId = createChildActionPlan(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS, AGENCY_RESPONSE);            
        }
        System.Test.startTest();
        System.runAs(u) {
            try {           
                APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(childApId);
                transitionInstance.performTransition(); 
                System.assert(false);
            } catch(Exception e) {
                System.assert(e.getTypeName() == 'APStatusTransitionForRework.InvalidDataException');
            }
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForActionPlanOfAdviceRequestInvalidStatus() {
        User u = createTestUser(RMS_CORRO_OFFICER_PERM);
        System.runAs(u) {
            setUpTestData(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS, AGENCY_RESPONSE);
        }
        System.Test.startTest();        
        System.runAs(u) {
            try{
                APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
                transitionInstance.performTransition();
                System.assert(false);
            } catch(Exception e) {
                System.assert(e.getTypeName() == 'APStatusTransitionForRework.InvalidDataException');
            }
        }        
        System.Test.stopTest();        
    }
    
    private static testMethod void testForActionPlanOfAdviceRequest() {
        User u = createTestUser(RMS_CORRO_OFFICER_PERM);
        System.runAs(u) {
            setUpTestData(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_CLOSED_STATUS, AGENCY_RESPONSE);
        }
        System.Test.startTest();        
        System.runAs(u) {
            try{
                APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
                transitionInstance.performTransition();
            } catch(Exception e) {
                System.assert(false);
            }
        }        
        System.Test.stopTest();
        Action_Plan__c ap = [SELECT Id, IsRework__c, Status__c FROM Action_Plan__c WHERE Id = :actionPlan.Id];
        System.assert(ap.Status__c == GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED);
        System.assert(ap.IsRework__c);
    }
    
    private static testMethod void testForActionPlanAssignedToSME() {
        User u = createTestUser(RMS_CORRO_OFFICER_PERM);
        System.runAs(u) {
            setUpTestData(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_CLOSED_STATUS, AGENCY_RESPONSE);
            actionPlan.AssignedSME__c = u.id;
            update actionPlan;
        }
        System.Test.startTest();        
        System.runAs(u) {
            try{
                APStatusTransitionForRework transitionInstance = new APStatusTransitionForRework(actionPlan.Id);
                transitionInstance.performTransition();
            } catch(Exception e) {
                System.assert(false);
            }
        }        
        System.Test.stopTest();
        Action_Plan__c ap = [SELECT Id, IsRework__c, Status__c, OwnerId  FROM Action_Plan__c WHERE Id = :actionPlan.Id];
        System.assert(ap.Status__c == GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED);
        System.assert(ap.IsRework__c);
        System.assert(ap.OwnerId == u.Id);
    }
    
    private static Id createChildActionPlan(String type, String status, String agency) {
        Action_Plan__c child = new Action_Plan__c();
        child.Type__c = type;
        child.Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
        child.Status__c = status;
        child.Agency__c = agency;
        child.recordTypeId = retrieveChildActionPlanRT();
        child.Parent_Action_Plan__c = actionPlan.Id;
        insert child;
        return child.Id;
    }
    
    private static User createTestUser(String permission) {
        Profile p = [SELECT Id FROM Profile WHERE Name='RMS Case Manager'];
        User u = new User(Alias = 'standt', Email='corroofficer@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='corroofficer@nsw.gov.au.com');
        insert u;
        
        PermissionSet permSet = [Select Name, Id From PermissionSet WHERE Name = :permission];      
        PermissionSetAssignment permAssignment = new PermissionSetAssignment();
        permAssignment.AssigneeId = u.Id;
        permAssignment.PermissionSetId = permSet.Id;        
        insert permAssignment;
        return u;
    }
}