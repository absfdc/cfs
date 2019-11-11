/*------------------------------------------------------------
Author:        Yogiraj Sarode
Company:       Arxxus.com
Description:   Batch to delete the PO Upload staging record created before N days
               (N is the number of days specified in 'No. of Days to Delete BU Staging recs' metadata)

History
07/07/2017       Yogiraj Sarode        Created   
------------------------------------------------------------*/
public class DeleteBUStagingRecords implements BatchExecutor.CustomBatchable,Database.Stateful {
    
    List<BU_Staging__c> buStagingRecordToDelete = new List<BU_Staging__c>();
    
    public void execute(List<BU_Staging__c> targetObjectData) {
        
        for(BU_Staging__c  getbuStagingRecord : targetObjectData){
            buStagingRecordToDelete.add(getbuStagingRecord);
        }
    }
    
    public void finish() {
        
        if(buStagingRecordToDelete.size() > 0)
            delete buStagingRecordToDelete;
    }
}