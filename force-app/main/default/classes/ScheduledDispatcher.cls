/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Used to schedule a job

Test Class:    ScheduledDispatcher_Test
History
26 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/
global class ScheduledDispatcher implements Schedulable{
	private Type schedulableHandler;
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Create a new instance of this ScheduledDispatcher w
	Inputs:			Type of the contrete handler class that has logic to be run in a schedule
	History
	26 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public ScheduledDispatcher(Type schedulableHandler) {
		System.debug('Creating new dispatcher for class: ' + schedulableHandler.getName());
		this.schedulableHandler = schedulableHandler;
	}

	global void execute(SchedulableContext sc) {
		((ISchedulableHandler)schedulableHandler.newInstance()).execute(sc);
	}

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Actual logic thats to be executed in a scheduled manner
					can reside in a concrete handler class that implements this

	History
	26 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public interface ISchedulableHandler {
		void execute(SchedulableContext sc);
	}
}