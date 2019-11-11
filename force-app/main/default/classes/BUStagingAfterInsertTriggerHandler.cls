/*------------------------------------------------------------
Author:        Pawan Tiwari
Description:   After Insert handler class for the BUStaging trigger
               Invoke the  UpsertContactHandler class to insert/update the contact 
               Invoke the UpsertCaseHandler class to insert/update the case

History
15-June-2017   Pawan Tiwari       Created.
------------------------------------------------------------*/
public with sharing class BUStagingAfterInsertTriggerHandler extends TriggerHandlerBase{
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    

    private void process(TriggerParameters tp) {
       
        List<BU_Staging__c> stagingList = (List<BU_Staging__c>)tp.newList;

        Map<String,String> stagingWithContactMap = new Map<String,String>();
        Map<String,String> stagingWithCaseMap = new Map<String,String>();

        // Apex class responsible for insert/update of the contact records
        UpsertContactHandler upsertContactHandler = new UpsertContactHandler(stagingList);
        stagingWithContactMap = upsertContactHandler.exceute();
        system.debug('stagingWithContactMap :: ' + stagingWithContactMap);

        // Query to reterive the staging object record updated by UpsertContactHandler apex class 
        String soqlQuery = 'select Case__c, Processing_Status__c, Contact__c, Location_Level_3__c, '+MappingRecord.stagingApiName+' FROM BU_Staging__c WHERE Id IN :stagingList';
        System.debug('soqlQuery :: ' + soqlQuery);
        List<BU_Staging__c> stagingRecordList = Database.Query(soqlQuery);
        
        // Apex class responsible for insert/update of the case records
        UpsertCaseHandler upsertCaseHandler = new UpsertCaseHandler(stagingRecordList);
        stagingWithCaseMap = upsertCaseHandler.exceute(stagingWithContactMap);
        system.debug('stagingWithCaseMap :: ' + stagingWithCaseMap);

        system.debug('***getCpuTime()***'+Limits.getCpuTime());
 
    }

}