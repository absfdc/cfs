@isTest
private class DeleteBUStagingRecords_Test {
	
	@testSetup
    static void setUpTestData(){

    	BU_Staging__c buStagingRecord = new BU_Staging__c(Bus_Driver_ID__c = 'Test Driver ID',Case_Id__c = 'Dummy Id',Case_Manager__c = 'Test Manager');
    	insert buStagingRecord;
    }

    @isTest 
    static void testDeleteBUStagingRecords() {

    	Test.startTest();
            No_of_Days_to_Delete_BU_Staging_recs__mdt metadataRec = [SELECT Number_of_Days__c 
                                                                 FROM No_of_Days_to_Delete_BU_Staging_recs__mdt 
                                                                 WHERE DeveloperName = 'Mapping_001' 
                                                                 LIMIT 1];
        Integer numberOfdays = metadataRec.Number_of_Days__c.intValue();
        
        System.debug('Time: '+System.now().addDays(-numberOfdays).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        String dateTimeFormat = System.now().addDays(-numberOfdays).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        String query = 'Select Id FROM BU_Staging__c WHERE CreatedDate > '+dateTimeFormat;

            Database.executeBatch(new BatchExecutor(new DeleteBUStagingRecords(), query, null));
        
        Test.stopTest();

    }
}