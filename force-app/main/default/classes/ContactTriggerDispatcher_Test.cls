@isTest
private class ContactTriggerDispatcher_Test
{	
	static RecordType HOUSEHOLD;
	static RecordType CUSTOMER;
	static RecordType ORGANIZATION;

	static void setup(){
		//insert the recordtypes and set them 
		HOUSEHOLD = [SELECT ID FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = 'household'];
		CUSTOMER = [SELECT ID FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'Customer'];
		ORGANIZATION= [SELECT ID FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName != 'household' limit 1];
	}
	@isTest
	static void deletingContactOrganizationAccountUnScathed()
	{
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
		Test.startTest();
		delete cont;
		Test.stopTest();
		List<Account> correspondingAccounts=[select Id, Name,recordTypeId from Account];
		system.assertEquals(correspondingAccounts.size(),1);


	}
	@isTest
	static void createAccountOnInsertContact()
	{
		setup();

		Contact cont= new Contact(
				FirstName='AB',
				LastName='Normal',
				RecordTypeId=CUSTOMER.Id
			);
		Test.startTest();
		insert cont;
		Test.stopTest();
		Account correspondingAccount=[select Id, Name,recordTypeId from Account where Primary_Contact_Id__c=:cont.Id];
		system.assertNotEquals(correspondingAccount,null);
		system.assertEquals(correspondingAccount.Name,'AB Normal Account');

	}

	@isTest
	static void updateAccountNameOnUpdateContact()
	{
		setup();

		Contact cont= new Contact(
				FirstName='AB',
				LastName='Normal',
				RecordTypeId=CUSTOMER.Id
				
			);
		
		insert cont;
		Test.startTest();
		cont.FirstName='Perfectly';
		update cont;
		Test.stopTest();
		Account correspondingAccount=[select Id, Name,recordTypeId from Account where Primary_Contact_Id__c=:cont.Id];
		system.assertEquals(correspondingAccount.Name,'Perfectly Normal Account');
	}
	@isTest
	static void deletingContactDeletesAccount()
	{
		setup();

		Contact cont= new Contact(
				FirstName='AB',
				LastName='Normal',
				RecordTypeId=CUSTOMER.Id
			);
		
		insert cont;
		Test.startTest();
		delete cont;
		Test.stopTest();
		List<Account> correspondingAccounts=[select Id, Name,recordTypeId from Account];
		system.assertEquals(correspondingAccounts.size(),0);

	}
	@isTest
	static void creatingContactWithAccountCreatesNoAccount()
	{
		setup();
		Account existingAccount=new Account(
				Name='preexisting'
			);
		insert existingAccount;
		Contact cont= new Contact(
				FirstName='AB',
				LastName='Normal',
				AccountId=existingAccount.Id,
				RecordTypeId=CUSTOMER.Id
			);
		Test.startTest();
		insert cont;

		
		Test.stopTest();
		List<Account> correspondingAccounts=[select Id, Name,recordTypeId from Account where Name!='preexisting'];
		system.assertEquals(correspondingAccounts.size(),0);

	}
	@isTest
	static void insert101householdContacts()
	{
		setup();
		List<Contact> contacts=new List<Contact>();
		for(integer ii=0; ii<100;ii++){
			contacts.add(new Contact(
				FirstName='AB'+ii,
				LastName='Normal',
				RecordTypeId=CUSTOMER.Id
			));
		}
		
		Test.startTest();
		insert contacts;
		Test.stopTest();
		List<Account> correspondingAccounts=[select Id, Name,recordTypeId from Account];
		system.assertEquals(correspondingAccounts.size(),100);

	}

	@isTest
	static void insert101householdContactsBypassTrigger()
	{
		setup();
		User invoker=[select Id, Bypass_Triggers__c from User where Id=:UserInfo.getUserId()];
		invoker.Bypass_Triggers__c='Contact';
		update invoker;
		List<Contact> contacts=new List<Contact>();
		for(integer ii=0; ii<100;ii++){
			contacts.add(new Contact(
				FirstName='AB'+ii,
				LastName='Normal',
				RecordTypeId=CUSTOMER.Id
			));
		}
		
		Test.startTest();
		insert contacts;
		Test.stopTest();
		List<Account> correspondingAccounts=[select Id, Name,recordTypeId from Account];
		system.assertEquals(correspondingAccounts.size(),0);

	}
	@isTest
	static void updateErrorIfTriggerParameterNotProper()
	{

		ApplicationLog_Test.setLoggingSettings();
		ContactBeforeUpdateTriggerHandler updater= new ContactBeforeUpdateTriggerHandler();
		
		updater.mainEntry(null);
		List<Application_Log__c> caseTriggerLogs= [select Id ,Debug_Level__c from Application_Log__c ];
		system.assertEquals(GlobalConstants.ERROR,caseTriggerLogs[0].Debug_Level__c);

	}
	@isTest
	static void insertErrorIfTriggerParameterNotProper()
	{

		ApplicationLog_Test.setLoggingSettings();

		ContactAfterInsertTriggerHandler inserter= new ContactAfterInsertTriggerHandler();
		inserter.mainEntry(null);
		List<Application_Log__c> caseTriggerLogs= [select Id ,Debug_Level__c from Application_Log__c ];
		system.assertEquals(GlobalConstants.ERROR,caseTriggerLogs[0].Debug_Level__c);

	}
	@isTest
	static void deleteErrorIfTriggerParameterNotProper()
	{

		ApplicationLog_Test.setLoggingSettings();
		ContactAfterDeleteTriggerHandler updater= new ContactAfterDeleteTriggerHandler();
		
		updater.mainEntry(null);
		List<Application_Log__c> caseTriggerLogs= [select Id ,Debug_Level__c from Application_Log__c ];
		system.assertEquals(GlobalConstants.ERROR,caseTriggerLogs[0].Debug_Level__c);

	}

}