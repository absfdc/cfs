@isTest
private class TaskTriggerDispatcherTest {	
    static RecordType HOUSEHOLD;
	static RecordType CUSTOMER;
	static RecordType ORGANIZATION;
	
    private static void createKeyWordSettings(){
		List<Keywords__c> adviceSubjects= new List<Keywords__c>();
		adviceSubjects.add(new Keywords__c(Name='injured',Priority__c=GlobalConstants.CASE_PRIORITY_HIGH));
		adviceSubjects.add(new Keywords__c(Name='blood',Priority__c=GlobalConstants.CASE_PRIORITY_HIGH));
		adviceSubjects.add(new Keywords__c(Name='hospital',Priority__c=GlobalConstants.CASE_PRIORITY_HIGH));
		insert adviceSubjects;
	}
	
	static void setup(){
		//insert the recordtypes and set them 
		HOUSEHOLD = [SELECT ID FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = 'household'];
		CUSTOMER = [SELECT ID FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'Customer'];
		ORGANIZATION= [SELECT ID FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName != 'household' limit 1];
	}
 
	private static Task getTestTask(){
		setup();
		Account existingAccount=new Account(
				Name='preexisting',
				RecordTypeId=ORGANIZATION.Id
			);
		insert existingAccount;
		Contact cont= new Contact(
				FirstName='AB',
				LastName='Normal',
				RecordTypeId=CUSTOMER.Id,
				AccountId=existingAccount.Id
			);
		
		insert cont;
		createKeyWordSettings();
		String pattern= '%'+GlobalConstants.MIN_CORRO_RECTYPE_NAME+'%';
		List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName Like :pattern];
		RecordType MINCORRO = caseTypes.size()==0?null:caseTypes[0];
		Case minCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
								Description='I was Injured because of the sharp metal jutting out ',
								RecordTypeId=MINCORRO.Id,
								Status='New',
								Origin='Web',
								Priority='Normal');
		insert minCase;
		return  new Task(
						    ActivityDate = Date.today().addDays(7),
						    Subject='Sample Task',
						    WhoId = cont.Id,
						    WhatId=minCase.Id,
						    OwnerId = UserInfo.getUserId(),
						    Status='In Progress',
						    Call_Status__c='Contacted');
	}
		

	@isTest
	static void preventDeletionTest()
	{
		Task testTask;
		User nonAdmin = [select Id,ProfileId from User where Profile.Name != 'System Administrator' And Profile.Name != 'TfNSW Operator Portal User' And isActive = true limit 1];
		system.runAs(nonAdmin){
			testTask=getTestTask();
			insert testTask;
			Task obtained=[select id from task where Id =:testTask.Id];
			system.assertNotEquals(null,obtained);

			try{
				delete obtained;
			}catch(Exception e){
				Task obtained2=[select id from task where Id =:testTask.Id];
				system.assertNotEquals(null,obtained2);

			}
		}
        
		delete testTask;
		List<Task> obtained3=[select id from task where Id =:testTask.Id];
		system.assertEquals(0,obtained3.size());
	}
 	
    	@isTest
	static void preventUpdationTest()
	{
		Task testTask;
        User nonAdmin=[select Id,ProfileId from User where Profile.Name != 'System Administrator' And Profile.Name != 'TfNSW Operator Portal User' And isActive = true  limit 1];
        system.runAs(new User(Id= UserInfo.getUserId())){
            testTask = getTestTask();
            testTask.OwnerId = nonAdmin.Id;
			insert testTask;
        }
        
        system.runAs(new User(Id= UserInfo.getUserId())){
            Task obtained = [select id,Status from task where Id =:testTask.Id];
            testTask.Status = 'Completed';
			update testTask;
        }
        
        boolean error = false;
        
		system.runAs(nonAdmin){
			Task obtained = [select id from task where Id =:testTask.Id];
			try{
				update obtained;
			} catch(Exception e) {
				error = true;
                system.debug('---@Test---' + e.getMessage());
			}
            system.assertEquals(true,error);
		}
	}
    
	@isTest
	static void deleteErrorTaskBeforeDeleteTriggerHandler() {
		ApplicationLog_Test.setLoggingSettings();
		TaskBeforeDeleteTriggerHandler deleter= new TaskBeforeDeleteTriggerHandler();
		User nonAdmin = [select Id, ProfileId from User where Profile.Name != 'System Administrator' And Profile.Name != 'TfNSW Operator Portal User' And isActive = true  limit 1];
		
		system.runAs(nonAdmin){
			deleter.mainEntry(null);
		}
        
		List<Application_Log__c> taskErrorLogs= [select Id ,Debug_Level__c from Application_Log__c ];
		system.assertEquals(GlobalConstants.ERROR,taskErrorLogs[0].Debug_Level__c);
	}
    
    @isTest
	static void updateErrorTaskBeforeUpdateTriggerHandler() {
		ApplicationLog_Test.setLoggingSettings();
		TaskBeforeUpdateTriggerHandler deleter= new TaskBeforeUpdateTriggerHandler();
		User nonAdmin = [select Id,ProfileId from User where Profile.Name != 'System Administrator' And Profile.Name != 'TfNSW Operator Portal User' And isActive = true  limit 1];
		
		system.runAs(nonAdmin){
			deleter.mainEntry(null);
		}
        
		List<Application_Log__c> taskErrorLogs= [select Id ,Debug_Level__c from Application_Log__c ];
		system.assertEquals(GlobalConstants.ERROR,taskErrorLogs[0].Debug_Level__c);
	}
    
}