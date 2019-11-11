/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the contact trigger

Test Class:    ContactTriggerDispatcher_Test
History
16 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/
public with sharing class ContactAfterDeleteTriggerHandler extends TriggerHandlerBase{
	public override void mainEntry(TriggerParameters tp) {
		process(tp);
	}
	public override void inProgressEntry(TriggerParameters tp) {
		System.debug('This is an example for reentrant code...');
	}
	List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Handler function deletes  household Accounts when associated contacts are deleted
	Inputs:        Trigger context parameters

	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
	private void process(TriggerParameters tp) {
		try{
			RecordType HOUSEHOLD = [SELECT ID FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = :GlobalConstants.B2C_ACCNT_RECTYPE_NAME];
			RecordType CUSTOMER = [SELECT ID FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = :GlobalConstants.CUSTOMER_CONTACT_RECTYPE_NAME];

	    	Map<Id, Account> aMap = new Map<Id, Account>();
			//if  contact  associated with household account delete household account
			Set<ID> householdIdsToDelete= new Set<Id>();
			for(contact cust:(List<Contact>)tp.oldList){

				if (cust.recordTypeId==CUSTOMER.Id && cust.AccountId!=null) {
					householdIdsToDelete.add(cust.AccountId);
				}
			}
			if (householdIdsToDelete.size()==0) return;

		    List<Account> householdsToDelete =[select Id from Account where Id in:householdIdsToDelete and recordTypeId=:HOUSEHOLD.Id];
		    if (householdsToDelete.size()>0 ) delete householdsToDelete;
			ApplicationLogUtility.logMessage(messages);
			messages.clear();
		}catch(Exception e){
			ApplicationLogMessage message= new ApplicationLogMessage();
			message.source='ContactAfterDeleteTriggerHandler';
			message.sourceFunction='process';
			if (tp!=null && tp.oldMap!=null)  message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
			message.logMessage=e.getMessage();
			message.ex=e;
			message.debugLevel='Error';
			messages.add(message);
			ApplicationLogUtility.logMessage(messages);
			messages.clear();
			//THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
		}

	}

}