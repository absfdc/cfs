/*------------------------------------------------------------
Author:        Yogiraj Sarode
Company:       Arxxus.com
Description:   Schedulabler class to schedulable a batch to delete the BU Staging object records
                with number of days specified in 'No of Days to Delete BU Staging recs' custom metadata
History
10/07/2017       Yogiraj Sarode        Created   
------------------------------------------------------------*/
global class ScheduleDeleteBUStagingRecords implements Schedulable {
    global void execute(SchedulableContext sc) {
        
        No_of_Days_to_Delete_BU_Staging_recs__mdt metadataRec = [SELECT Number_of_Days__c 
                                                                 FROM No_of_Days_to_Delete_BU_Staging_recs__mdt 
                                                                 WHERE DeveloperName = 'Mapping_001' 
                                                                 LIMIT 1];
        Integer numberOfdays = metadataRec.Number_of_Days__c.intValue();
        
        System.debug('Time: '+System.now().addDays(-numberOfdays).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        String dateTimeFormat = System.now().addDays(-numberOfdays).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        String query = 'Select Id FROM BU_Staging__c WHERE CreatedDate < '+dateTimeFormat;
        
        if(!Test.isRunningTest())  {              
            Database.executeBatch(new BatchExecutor(new DeleteBUStagingRecords(), query, null)); 
        }
    }
}