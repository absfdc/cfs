/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Some utility methods that help in scheduling jobs

Test Class:    ScheduledDispatcher_Test
History
26 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/
public with sharing class ScheduledHelper {

	public static final String CRON_MIDNIGHT = '59 59 23 ? * 1,2,3,4,5,6,7';

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Can be called by Anonymous Apex to schedule the Purge daily
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public static void schedulePurgeDaily() {
		scheduleJob(DataPurgeHandler_BatchSchedule.class, CRON_MIDNIGHT);
	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   To schedule a schedulableHandler, the Schedulable Handler name is
					used as the jobName.
	Inputs:			targetType-	type of the handler
					cronExpression- cron expression such as midnight-'59 59 23 * * ?'
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public static void scheduleJob(Type targetType, String cronExpression) {
		String jobName = targetType.getName();
		scheduleJob(targetType, jobName, cronExpression);
	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   To schedule a schedulableHandler
	Inputs:			targetType-	type of the handler
					jobName- String name of the job that we will create for reference
					cronExpression- cron expression such as midnight-'59 59 23 * * ?'
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public static void scheduleJob(Type targetType, String jobName, String cronExpression) {
		abortJob(jobName);
		ScheduledDispatcher scheduledDispatcher = new ScheduledDispatcher(targetType);
		System.schedule(jobName, cronExpression, scheduledDispatcher);
	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   To abort a job by job name
	Inputs:			jobName- String name of the job that we had given while scheduling
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public static void abortJob(String jobName) {
		//these are no more going to execute
		Set<String> stateList = new Set<String>{GlobalConstants.JOB_COMPLETED, GlobalConstants.JOB_ERROR, GlobalConstants.JOB_DELETED};
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name = :jobName
			AND State NOT IN :stateList
		];

		if (jobs.size()>0) {
			System.abortJob(jobs[0].Id);
		}
	}
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Returns a chron expression to mean exactly same Date and time
	Inputs:			Date time
	History
	27 Mar 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	public static String createCronExpressionFromDateTime(DateTime fireTime) {
		List<String> timeParts = new List<String>();
		timeParts.add(String.valueof(fireTime.second()));
		timeParts.add(String.valueof(fireTime.minute()));
		timeParts.add(String.valueof(fireTime.hour()));
		timeParts.add(String.valueof(fireTime.day()));
		timeParts.add(String.valueof(fireTime.month()));
		timeParts.add('?');
		timeParts.add(String.valueof(fireTime.year()));

		return String.join(timeParts, ' ');
	}
}