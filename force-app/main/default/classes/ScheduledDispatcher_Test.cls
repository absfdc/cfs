@isTest
private class ScheduledDispatcher_Test {

	public without sharing class ScheduledTestHandler
		implements ScheduledDispatcher.ISchedulableHandler {
		public void execute(SchedulableContext sc) {
			ScheduledDispatcher_Test.testFlag = true;
		}
	}

	public static Boolean testFlag;
	@isTest
	static void can_create_new_instance_of_scheduled_dispatcher() {
		ScheduledDispatcher dispatcher = new ScheduledDispatcher(ScheduledTestHandler.class);
		system.assert(dispatcher != null);

		testFlag = false;
		dispatcher.execute(null);
		System.assert(testFlag == true);
	}
	@isTest
	static  void can_schedule_new_job() {
		DateTime fireTime = DateTime.Now().addSeconds(10);
		String nextFireCron = ScheduledHelper.createCronExpressionFromDateTime(fireTime);

		Test.startTest();
		ScheduledHelper.scheduleJob(ScheduledTestHandler.class, nextFireCron);
		Test.stopTest();

		String jobName = ScheduledTestHandler.class.getName();
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name = :jobName
		];

		system.assert(jobs.size() == 1);
		system.debug('Job State: ' + jobs[0].State);
		system.assert(jobs[0].State == 'WAITING');
	}
	@isTest
	static  void can_abort_scheduled_job() {
		DateTime fireTime = DateTime.Now().addSeconds(10);
		String nextFireCron = ScheduledHelper.createCronExpressionFromDateTime(fireTime);
		ScheduledHelper.scheduleJob(ScheduledTestHandler.class, nextFireCron);

		String jobName = ScheduledTestHandler.class.getName();
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name = :jobName
		];

		system.assert(jobs.size() == 1);

		Test.startTest();
		ScheduledHelper.abortJob(jobName);
		Test.stopTest();

		jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime
			FROM CronTrigger
			WHERE CronJobDetail.Name = :jobName
		];

		system.assert(jobs.size() == 0);
	}
}