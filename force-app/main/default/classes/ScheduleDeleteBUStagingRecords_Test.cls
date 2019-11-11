@isTest
private class ScheduleDeleteBUStagingRecords_Test {
    
    @testSetup
    static void setUpTestData(){

    	BU_Staging__c buStagingRecord = new BU_Staging__c(Bus_Driver_ID__c = 'Test Driver ID',Case_Id__c = 'Dummy Id',Case_Manager__c = 'Test Manager');
    	insert buStagingRecord;
    }   

    @isTest 
    static void testScheduleDeleteBUStagingRecords() {

        Test.startTest();
            
            DateTime currentDateTime = System.Now();
            DateTime nextScheduleDateTime = currentDateTime.addMinutes(1);

            String CRON_EXP = '0 '+ nextScheduleDateTime.minute() + ' * ' + nextScheduleDateTime.day() + ' ' + nextScheduleDateTime.month() + ' ? ' + nextScheduleDateTime.year();
            String jobId = System.schedule('Test_Job', CRON_EXP, new ScheduleDeleteBUStagingRecords() );   

            // Get the information from the CronTrigger API object
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                                FROM CronTrigger WHERE id = :jobId];

            // Verify the expressions are the same
            System.assertEquals(CRON_EXP, ct.CronExpression);

            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest();
    }

    
}