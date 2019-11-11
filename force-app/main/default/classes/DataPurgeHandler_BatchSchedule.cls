/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Data purge Schedulable handler, it runs the batchable purge jobs

Test Class:    DataPurgeHandler_Test
History
26 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/
public with sharing class DataPurgeHandler_BatchSchedule
				implements ScheduledDispatcher.ISchedulableHandler {

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   When a new instance of scheduled dispatcher will be constructed with this concrete type
					and executed, this will be instanciated and our execute will be called
	Inputs:			This is a system callback parameter
	History
	26 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public void execute(SchedulableContext sc) {
		// start the data purge in a batch operation
		DataPurge_Batch purger= new DataPurge_Batch();
		Database.executeBatch(purger,DataPurge_Batch.SCOPE_SIZE);//passing only one record because its required
	}

}