/*------------------------------------------------------------------------
Author:        Author
Company:       Salesforce.com
Description:   UnitTests for custom publisher action for sme selection
	           Tests executed:
	           1 - caseContextIsCaptured
	           		The context of the case in which the custom publisher action was opened is captured
	           2 - testNodeCreation
	           		Just that the bean can be set and the attributes fetched
	           3 - testGetSmes
	           		with following data setup, one NSW Trains with two test Divisions and Two smes under each setup the method returns the list of sme nodes to be displayed
	           4 - testUpdateSmes
	           		given the contact id and case id the case is updated with the sme contact id


History
10-Apr-2015	Author 	UnitTests for custom publisher action for case categorisation
----------------------------------------------------------------------------*/
@isTest
private class SmeSelectionPublisherAction_Test
{	public static Case aCase;
	static RecordType organisationType= [select Id, Name,DeveloperName from RecordType where sobjectType='Account' and DeveloperName = 'organization' limit 1];
	static RecordType staffType= [select Id, Name,DeveloperName from RecordType where sobjectType='Contact' and DeveloperName =:GlobalConstants.CASE_RECORD_TYPE_STAFF limit 1];


	@isTest
	static void caseContextIsCaptured()
	{	
		Case thisCase=setupCase('NSW Train');

		Test.startTest();
		PageReference smeSelection= Page.smeSelectionPublisherAction;
		Test.setCurrentPage(smeSelection);
		ApexPages.StandardController std=new ApexPages.StandardController(thisCase);
		SmeSelectionPublisherAction_CX ext= new SmeSelectionPublisherAction_CX(std);
		Test.stopTest();

		system.assertEquals(thisCase,ext.thisCase);


	}

	@isTest
	static void testNodeCreation()
	{
		SmeSelectionPublisherAction_CX.Node aNode= new SmeSelectionPublisherAction_CX.Node();
		aNode.id='test id';
		aNode.text='test';
		aNode.parent='test parent';
		aNode.state=new SmeSelectionPublisherAction_CX.State();
		aNode.state.selected=true;
		system.assertEquals('test id',aNode.id);
		system.assertEquals('test',aNode.text);

		system.assertEquals(true,aNode.state.selected);



	}
	@isTest
	static void testGetSmes()
	{
		Account agency=setupAgency();
		insert agency;
		List<Account> divisions=setupDivisions(agency);
		insert divisions;
		List<Contact> smes=setupSmes(divisions);
		insert smes;
		Test.startTest();
		List<SmeSelectionPublisherAction_CX.Node>  nodes= SmeSelectionPublisherAction_CX.getSmes( staffType.id, agency.name, null);
		Test.stopTest();
		system.assertnotEquals(0,nodes.size());

	}
	@isTest
	static void testUpdateSmesFailsIfSmeNotFromSameDepartment()
	{	Case thisCase=setupCase('NSW Train');
		insert thisCase;
		Contact sme= new Contact(
					LastName='test contact',
					recordtypeId=staffType.id
				);
		insert sme;
		try{
			SmeSelectionPublisherAction_CX.updateSme( thisCase.id, sme.Id);

		}catch(DmlException e){
			system.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));

		}
		
	}

	@isTest
	static void testUpdateSmes()
	{	
		Case thisCase=setupCase('NSW Train');
		insert thisCase;
		Account agency=setupAgency();
		insert agency;
		List<Account> divisions=setupDivisions(agency);
		insert divisions;
		Contact sme=new Contact(
					LastName='test contact 1 ',
					recordtypeId=staffType.id,
					accountId=divisions[0].Id
				);
		insert sme;

		UserRole r = new UserRole(name = 'NSW_Trains');
		system.runAs(new User(id=UserInfo.getUserId())){
        	insert r;
    	}
        User userWithRole = new User(alias = 'hasrole', email='userwithrole@roletest1.com', userroleid = r.id,
                            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = UserInfo.getProfileId(),
                            timezonesidkey='America/Los_Angeles', username='userwithrole@testorg.com');
        system.runAs(new User(id=UserInfo.getUserId())){
			insert userWithRole;
		}
		Test.startTest();
		system.runAs(userWithRole){
			SmeSelectionPublisherAction_CX.updateSme( thisCase.id, sme.Id);

		}
		Test.stopTest();
		thisCase=[select id, Assigned_Sme__c from Case where Id=:thisCase.Id];
		system.assertEquals(sme.id, thisCase.Assigned_Sme__c);
		
	}




	public static Account setupAgency(){
		return new Account(
			Type=GlobalConstants.ACCOUNT_TYPE_AGENCY,
			Name='NSW Trains',
			recordtypeId=organisationType.Id
		);
	}

	public static List<Account> setupDivisions(Account agency){
		List<Account> divisions=new List <Account>();
		divisions.add(new Account(
			Type=GlobalConstants.ACCOUNT_TYPE_DIVISION,
			Name='Test Division 1',
			recordtypeId=organisationType.Id,
			parentId=agency.Id
		));
		divisions.add(new Account(
			Type=GlobalConstants.ACCOUNT_TYPE_DIVISION,
			Name='Test Division 2',
			recordtypeId=organisationType.Id,
			parentId=agency.Id
		));
		return divisions;
	}
	public static List<Contact> setupSmes(List<Account> divisions){
		List<Contact> smes=new List <Contact>();
		Integer ii=0;
		for (Account division: divisions){
			ii++;
			smes.add(
				new Contact(
					LastName='test contact 1 '+ii,
					recordtypeId=staffType.id,
					accountId=division.Id
				)
			);
			smes.add(
				new Contact(
					LastName='test contact 2 '+ii,
					recordtypeId=staffType.id,
					accountId=division.Id
				)
			);
		}

		
		return smes;
	}

	public static Case setupCase(String agency){
	
		List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Train' limit 1];
		RecordType CASE_REC_TYPE = caseTypes.size()==0?null:caseTypes[0];
		aCase=new Case(Subject='I was Injured because of the sharp metal jutting out',
								Description='I was Injured because of the sharp metal jutting out',
								RecordTypeId=CASE_REC_TYPE.Id,
								Status='New',
								Origin='Web',
								Priority='Normal',
								Modes__c='Test Mode',
								OwnerAgency__c=agency
								);

		return aCase;

	}
}