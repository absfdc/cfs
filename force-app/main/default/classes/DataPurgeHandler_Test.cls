@isTest
private class DataPurgeHandler_Test {
	//since these settings mean logs are to be deleted even if they are logged tomorrow

	public static void setPurgingSettings(){
		Data_Purge__c purgeSettings= new Data_Purge__c(
			Name='Application_Log__c',
			Retention_Period__c=-1
		);
		insert purgeSettings;
	}
	//since these settings mean logs are to be retained for long when this is applicable logs should not get deleted
	public static void setNonPurgingSettings(){
		Data_Purge__c purgeSettings= new Data_Purge__c(
			Name='Application_Log__c',
			Retention_Period__c=90
		);
		insert purgeSettings;
	}
	@isTest
	static void testPurgeBatch(){
		ApplicationLog_Test.setLoggingSettings();
		setPurgingSettings();
		List<ApplicationLogMessage> messages= new List<ApplicationLogMessage>();
		//populate 9998k logs
		for(Integer ii=0; ii<4998; ii++){
			ApplicationLogMessage message= new ApplicationLogMessage();

			message.source='ApplicationLog_Test';
			message.sourceFunction='testBatchLog';
			message.referenceId='abcdefghijklmnopqr';
			message.referenceInfo=''+ii;
			message.logMessage='test log message -'+ii;
			message.payLoad='test payload';
			message.debugLevel='Debug';
			message.timer=1.0.longValue();
			messages.add(message);

		}
		ApplicationLogUtility.logMessage(messages);
		//start the purge job
		DateTime fireTime = DateTime.Now().addSeconds(5);
		String nextFireCron = ScheduledHelper.createCronExpressionFromDateTime(fireTime);
		List<Application_Log__c> initial= [select Id from Application_Log__c where Source__c='ApplicationLog_Test'];
		system.assertEquals(4998,initial.size());


		Test.startTest();
		Database.executeBatch(new DataPurge_Batch(), DataPurge_Batch.SCOPE_SIZE);
		Test.stopTest();
		//assert the purge jobs run
		List<Application_Log__c> leftOver= [select Id from Application_Log__c where Source__c='ApplicationLog_Test'];
		system.assertEquals(0,leftOver.size());


	}
	@isTest
	static void testPurgeBatchNotDeletingIfLongRetentionConfigured(){
		ApplicationLog_Test.setLoggingSettings();
		setNonPurgingSettings();
		List<ApplicationLogMessage> messages= new List<ApplicationLogMessage>();
		//populate 9998k logs
		for(Integer ii=0; ii<9998; ii++){
			ApplicationLogMessage message= new ApplicationLogMessage();

			message.source='ApplicationLog_Test';
			message.sourceFunction='testBatchLog';
			message.referenceId='abcdefghijklmnopqr';
			message.referenceInfo=''+ii;
			message.logMessage='test log message -'+ii;
			message.payLoad='test payload';
			message.debugLevel='Debug';
			message.timer=1.0.longValue();
			messages.add(message);

		}
		ApplicationLogUtility.logMessage(messages);
		//start the purge job
		DateTime fireTime = DateTime.Now().addSeconds(5);
		String nextFireCron = ScheduledHelper.createCronExpressionFromDateTime(fireTime);
		List<Application_Log__c> initial= [select Id from Application_Log__c where Source__c='ApplicationLog_Test'];
		system.assertEquals(9998,initial.size());


		Test.startTest();
		Database.executeBatch(new DataPurge_Batch(), DataPurge_Batch.SCOPE_SIZE);
		Test.stopTest();
		//assert the purge jobs run
		List<Application_Log__c> leftOver= [select Id from Application_Log__c where Source__c='ApplicationLog_Test'];
		system.assertEquals(9998,leftOver.size());


	}
}