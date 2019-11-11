@isTest
private class EventTriggerDispatcherTest
{	static RecordType HOUSEHOLD;
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
	private static Event getTestEvent(){
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
		return  new Event(
            OwnerId = UserInfo.getUserId(),
            WhatId = minCase.Id,
            StartDateTime = System.today(),
            EndDateTime = System.today()+1,
            Subject = 'Go Live'

        );
		 
	}
		

	@isTest
	static void itShould()
	{
		Event testEvent;
		User nonAdmin=[select Id,ProfileId from User where Profile.Name != 'System Administrator' And Profile.Name != 'TfNSW Operator Portal User' And isActive = true limit 1];
		system.runAs(nonAdmin){
			testEvent=getTestEvent();
			insert testEvent;
			Event obtained=[select id from Event where Id =:testEvent.Id];
			system.assertNotEquals(null,obtained);

			try{
				delete obtained;
			}catch(Exception e){
				Event obtained2=[select id from Event where Id =:testEvent.Id];
				system.assertNotEquals(null,obtained2);

			}
			

		}
		delete testEvent;
		List<Event> obtained3=[select id from event where Id =:testEvent.Id];
		system.assertEquals(0,obtained3.size());
		

		

	}
	@isTest
	static void deleteErrorEventBeforeDeleteTriggerHandler()
	{

		ApplicationLog_Test.setLoggingSettings();
		EventBeforeDeleteTriggerHandler deleter= new EventBeforeDeleteTriggerHandler();
		User nonAdmin=[select Id,ProfileId from User where Profile.Name != 'System Administrator' And Profile.Name != 'TfNSW Operator Portal User' and isActive = true limit 1];
		
		system.runAs(nonAdmin){
			deleter.mainEntry(null);
		}
		List<Application_Log__c> eventErrorLogs= [select Id ,Debug_Level__c from Application_Log__c ];
		system.assertEquals(GlobalConstants.ERROR,eventErrorLogs[0].Debug_Level__c);

	}
}