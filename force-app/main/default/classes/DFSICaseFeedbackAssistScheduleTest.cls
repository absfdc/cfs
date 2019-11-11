@istest
global class DFSICaseFeedbackAssistScheduleTest {
    
    @testSetup
    static void init() {
        DFSIScheduledJobRun__c jobSetting = new DFSIScheduledJobRun__c(Name='DFSI', LastJobEndTime__c = Datetime.now());
        insert jobSetting;
    }
    @istest
    static void testSchedule(){
		init();        
        Test.startTest();

        DFSICaseFeedbackAssistSchedule ds = new DFSICaseFeedbackAssistSchedule();
		String sch = '0 0 23 * * ?'; 
        
        Id jobID=system.schedule('Test DFSI Feedback Assist Schedule', sch, ds); 
        CronTrigger ct = [SELECT TimesTriggered, NextFireTime
    					  FROM CronTrigger 
                          WHERE Id = :jobID];
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }
}