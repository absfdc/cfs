/*------------------------------------------------------------
Author:        Pawan Tiwari
Description:   Before Insert handler class for the BUStaging trigger
               Invoke the BUStagingBeforeInsertTriggerHandlerHlpr class(Used for staging record validation)

History
15-June-2017   Pawan Tiwari       Created.
------------------------------------------------------------*/
public with sharing class BUStagingBeforeInsertTriggerHandler extends TriggerHandlerBase{
	
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
     private void process(TriggerParameters tp) {
        if(tp.newList.size() > 0){
          	BUStagingBeforeInsertTriggerHandlerHlpr hlpr = new BUStagingBeforeInsertTriggerHandlerHlpr();
            hlpr.processStagingRecords(tp.newList);

            system.debug('***getCpuTime()***'+Limits.getCpuTime());
    	}
    
    }

}