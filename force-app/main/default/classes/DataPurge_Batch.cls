/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Data purge Batch, it runs the Purge jobs
				one execution context is forked for each configured record
				if there are more records of an object to be purged after each run
				It requeues itself for a subsequent run for the same object
Test Class:    DataPurgeHandler_Test
History
26 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/
global  class DataPurge_Batch implements Database.Batchable<sObject>, Database.Stateful{
	global Set<String> possibleLeftOver= new Set<String>();
	List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
	global static final Integer SCOPE_SIZE=1;
	global final String query;
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   The new instance might be created with a null parameter or
					with a set of objects for which it requires to rerun
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	global DataPurge_Batch(Set<String> possibleLeftOverIn){
		possibleLeftOver= possibleLeftOverIn;
		query='select Id, Name, Retention_Period__c from Data_Purge__c where Name in:possibleLeftOver';
		/*if (possibleLeftOverIn == null || possibleLeftOverIn.size()==0) {
			query='select Id, Name, Retention_Period__c from Data_Purge__c';
		}else{
			
		}*/
	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   No instance constructor convenient for calling first time
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	global DataPurge_Batch(){
			query='select Id, Name, Retention_Period__c from Data_Purge__c';
	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   It returns the list of objects which are meant to be purged
					based on the query
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	global Database.QueryLocator start(Database.BatchableContext info){
		return Database.getQueryLocator(query);
	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   It actually purges the data for exactly one object, while
					calling the scope size optional parameter should be set to one
					If it figures out that the query fetches as amany rows as the Limit set on query
					It marks the object for being tried again back to back.
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	global void execute(Database.BatchableContext info, List<Data_Purge__c> scope){
		Data_Purge__c aPurgeSetting =(Data_Purge__c) scope[0];
		ApplicationLogMessage message= new ApplicationLogMessage();
		possibleLeftOver.remove(aPurgeSetting.Name);
		message.source='DataPurge_Batch';
		message.sourceFunction='execute';
		message.logMessage='starting purge for  -'+aPurgeSetting.Name+ ' Retention period '+aPurgeSetting.Retention_Period__c;
		message.debugLevel=GlobalConstants.INFO;
		messages.add(message);
		date d = system.today().addDays(0-aPurgeSetting.Retention_Period__c.intValue());
		Integer dmlLimit= Limits.getLimitDMLRows();
		dmlLimit = dmlLimit==0 ? 0 : (dmlLimit-2)/2;
		List<sObject> forDelete=Database.query('select Id from '+aPurgeSetting.Name+' where createdDate <=:d limit :dmlLimit for update');
		system.debug('Starting delete for object - '+aPurgeSetting +' earlier than -'+d+' Limits- '+dmlLimit+' remaining -'+forDelete.size());

		if (forDelete.size()>0){
			delete forDelete;
			if (forDelete.size()==dmlLimit) possibleLeftOver.add(aPurgeSetting.Name);
			Database.EmptyRecycleBin(forDelete);
		}


	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   It actually purges the data for exactly one object, while
					calling the scope size optional parameter should be set to one
					If it figures out that the query fetches as amany rows as the Limit set on query
					It marks the object for being tried again back to back.
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	global void finish(Database.BatchableContext info){
		ApplicationLogUtility.logMessage(messages);

		if (possibleLeftOver.size()>0){
			system.debug('restarting -'+JSON.serialize(possibleLeftOver));

			Id batchInstanceId = Database.executeBatch(new DataPurge_Batch(possibleLeftOver), SCOPE_SIZE);
		}
	}
}