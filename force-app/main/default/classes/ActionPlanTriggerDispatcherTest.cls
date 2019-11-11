@isTest
private class ActionPlanTriggerDispatcherTest
{
    @testSetup static void setup() {
        system.debug('-------Data Setup------');
        RetrieveNextUtils_WS_Test.createTestUser('CRGS Admin','CRGS_Admin');
        RetrieveNextUtils_WS_Test.createTestUser('MAGS Officer','MAGS_Officer');
		system.debug('-------Data Setup Finished------');
    }
    
    @isTest
	static void testOwnerChangedToAssignedSmeBeforeInsert() {
        Action_Plan__c ap;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME limit 1];
            ap = new Action_Plan__c();
            ap.RecordTypeId = rt.Id;
            ap.AssignedSME__c = UserInfo.getUserId();
            ap.Status__c = 'New';
            insert ap;
        }
        
        Test.startTest();
        	Action_Plan__c ap1 = [Select Id,AssignedSME__c,TempAssignedSME__c From Action_Plan__c Where Id =: ap.Id];
        	system.assertEquals(UserInfo.getUserId(), ap1.TempAssignedSME__c);
        	system.assertEquals(null, ap1.AssignedSME__c);
        Test.stopTest();
	}
    
    
    @isTest
	static void createApVsNoOfChildActionPlansMapTest() {	
        Action_Plan__c ap, childAp;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.ACTION_PLAN_MCWS_AP_RECORD_TYPE_NAME limit 1];
            ap = new Action_Plan__c();
            ap.RecordTypeId = rt.Id;
            ap.AssignedSME__c = UserInfo.getUserId();
            ap.Status__c = 'New';
            insert ap;
        }
        
        Test.startTest();
            childAp = new Action_Plan__c();
            RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CHILD_AP_RECORDTYPE_API_NAME limit 1];
            childAp.RecordTypeId = rt.Id;
            childAp.AssignedSME__c = UserInfo.getUserId();
            childAp.Status__c = 'New';
        	childAp.Parent_Action_Plan__c = ap.Id;
        Test.stopTest(); 
        map <Id, Integer> countMap = ActionPlanUtility.createApVsNoOfChildActionPlansMap(new list <Action_Plan__c> {childAp},null);
        system.assert(countMap != null);
	}
    
    @isTest
	static void updateErrorIfTriggerParameterNotProper()
	{
		ApplicationLog_Test.setLoggingSettings();
		ActionPlanBeforeUpdateTriggerHandler updater= new ActionPlanBeforeUpdateTriggerHandler();
		
		updater.mainEntry(null);
		List<Application_Log__c> caseTriggerLogs= [select Id ,Debug_Level__c from Application_Log__c ];
		system.assertEquals(GlobalConstants.ERROR,caseTriggerLogs[0].Debug_Level__c);

	}
    
   
    @isTest
    static void testCreateNewAdviceRequestActionPlanUpdatesCaseStatusAwaitingAdvice() {
    	List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
		RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
        Case busCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
								Description='I was Injured because of the sharp metal jutting out ',
								RecordTypeId=BUS.Id,
								Status='New',
								Origin='Email',
								Priority='Normal');
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');

        insert busCase;
        Id cfmActionPlanRecordTypeId=Action_PlanTriggerDispatcher.actionPlanRecordTypes.get( GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME);

        Id fakeId= UtilityClass.getFakeId(Action_Plan__c.SObjectType);
		Action_Plan__c ap= new Action_Plan__c(Id=fakeId,Parent_Case__c=busCase.Id,assignedSme__c=UserInfo.getUserId(), ownerId=null,Status__c='New',RecordTypeId=cfmActionPlanRecordTypeId,Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
		Action_Plan__c oldAp= new Action_Plan__c(Id=fakeId,Parent_Case__c=busCase.Id,assignedSme__c=UserInfo.getUserId(), ownerId=null,Status__c='New',RecordTypeId=cfmActionPlanRecordTypeId,Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
		List<Action_Plan__c> oldList= new List<Action_Plan__c>();

		List<Action_Plan__c> newList= new List<Action_Plan__c>();
		newList.add(ap);
		oldList.add(oldAp);
		Map<Id, Action_Plan__c> newMap=new Map<Id, Action_Plan__c>(newList);
		Map<Id, Action_Plan__c> oldMap=new Map<Id, Action_Plan__c>(oldList);

		TriggerParameters tp=new TriggerParameters(oldList, newList, oldMap, newMap,
								false, true, false, true, false, false, false);
		ActionPlanAfterInsertTriggerHandler th= new ActionPlanAfterInsertTriggerHandler();
		Test.startTest();
		th.mainEntry(tp);
		Test.stopTest();
		Case busCaseAfter=[select Status from Case where Id=:busCase.Id];
		system.assertEquals(GlobalConstants.CASE_STATUS_AWAITING_ADVICE,busCaseAfter.Status);
    }
	
    @isTest
    static void testReceiveAdviceRequestResponseActionPlanCompletedCaseStatusReceivedAdvice() {
    	List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
		RecordType BUS = caseTypes.size() == 0 ? null : caseTypes[0];
        Case busCase=new Case(Subject = 'I was Injured because of the sharp metal jutting out ',
							  Description = 'I was Injured because of the sharp metal jutting out ',
						      RecordTypeId = BUS.Id,
						      Status = 'New',
						      Origin = 'Email',
						      Priority = 'Normal');
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        
        
        insert busCase;
        
        
        Id cfmActionPlanRecordTypeId = Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME);
        
        Action_Plan__c ap =  new Action_Plan__c(Parent_Case__c = busCase.Id, 
                                                Status__c = 'New',
                                                RecordTypeId = cfmActionPlanRecordTypeId,
                                                Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert ap;
        }
        
        Test.startTest();
        ActionPlanAfterUpdateTriggerHandler.firstTimers=null;
        Action_Plan__c completedAp = [Select Id, Status__c From Action_Plan__c Where Id =: ap.Id];
        completedAp.Status__c = 'Completed';
        system.debug('going to update actionplan status completed');
        update completedAp;
        Test.stopTest();

        
        Case busCaseAfter = [Select Id, Status From Case Where Id =: busCase.Id];
        system.assertEquals(GlobalConstants.CASE_STATUS_ADVICE_RECEIVED,busCaseAfter.Status);
        
    }
    
     @isTest
    static void testActionPlanDelete() {
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
		RecordType BUS = caseTypes.size() == 0 ? null : caseTypes[0];
        Case busCase=new Case(Subject = 'I was Injured because of the sharp metal jutting out ',
							  Description = 'I was Injured because of the sharp metal jutting out ',
						      RecordTypeId = BUS.Id,
						      Status = 'New',
						      Origin = 'Email',
						      Priority = 'Normal');
        
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        system.runAs(new User(Id = UserInfo.getUserId())) {
        	insert busCase;
        }
        
        Id cfmActionPlanRecordTypeId = Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME);
        
        Action_Plan__c ap =  new Action_Plan__c(Parent_Case__c = busCase.Id, 
                                                assignedSme__c = UserInfo.getUserId(), 
                                                Status__c = 'New',
                                                RecordTypeId = cfmActionPlanRecordTypeId,
                                                Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert ap;
        }
        
        system.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
        	    Action_Plan__c completedAp = [Select Id, Status__c From Action_Plan__c Where Id =: ap.Id];
            	delete completedAp;
            Test.stopTest();
            list <Action_Plan__c> Aps = [Select Id, Status__c From Action_Plan__c Where Id =: ap.Id];
            system.assertEquals(0, aps.size());
            
            //Error test
            ActionPlanAfterDeleteTriggerHandler handler = new ActionPlanAfterDeleteTriggerHandler();
            handler.mainEntry(null);
            
            ActionPlanAfterInsertTriggerHandler handler1 = new ActionPlanAfterInsertTriggerHandler();
            handler1.mainEntry(null);
        }
    }
}