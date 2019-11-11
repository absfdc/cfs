/*------------------------------------------------------------
Author:        Pawan Tiwari
Description:   A dispatcher class for BUStaging object trigger

History
<Date>        <Authors Name>     <Brief Description of Change>
15-June-2017   Pawan Tiwari      Created
------------------------------------------------------------*/
public with sharing class BU_StagingTriggerDispatcher extends TriggerDispatcherBase{
	
	private static Boolean isBeforeInsertProcessing = false;
    private static Boolean isAfterInsertProcessing = false;
   
	public BU_StagingTriggerDispatcher() {
		
	}

	/*------------------------------------------------------------
    Author:        Pawan Tiwari
    Description:   function to decide before insert handler should fire
    Inputs:        trigger parameter
    
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    15-June-2017   Pawan Tiwari          Created
    ------------------------------------------------------------*/
    public virtual override void beforeInsert(TriggerParameters tp) {
        
        if(!isBeforeInsertProcessing) {
            isBeforeInsertProcessing = true;
            execute(new BUStagingBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
            isBeforeInsertProcessing = false;
        }else{
            execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);  
        } 

    }    

	/*------------------------------------------------------------
    Author:        Pawan Tiwari
    Description:   function to decide after insert handler should fire
    Inputs:        trigger parameter
    
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    15-June-2017   Pawan Tiwari          Created
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new BUStagingAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            isAfterInsertProcessing = false;
        }else{
            execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);  
        } 

    }    

}