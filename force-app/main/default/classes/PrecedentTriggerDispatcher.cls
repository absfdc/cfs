/*------------------------------------------------------------
Author:        Arxxus
Description:   A dispatcher class for precdent case trigger

History
<Date>        <Authors Name>     <Brief Description of Change>
12-DEC-2016   Arxxus          Comments and cleanup
------------------------------------------------------------*/

public class PrecedentTriggerDispatcher extends TriggerDispatcherBase {
            
    private static Boolean isBeforeInsertProcessing = false;
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isBeforeUpdateProcessing = false;
    private static Boolean isBeforeDeleteProcessing = false;
    private static Boolean isAfterUpdateProcessing = false;
    private static Boolean isAfterDeleteProcessing = false;
    private static Boolean isAfterUndeleteProcessing = false;

    public PrecedentTriggerDispatcher() {
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   function to decide after insert handler should fire
    Inputs:        trigger parameter
    
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    12-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new PrecedentAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            isAfterInsertProcessing = false;
        }else{
            execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);  
        } 

    }    


    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   function to decide before delete should fire
    Inputs:        trigger parameter
    
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    12-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/

    public virtual override void beforeDelete(TriggerParameters tp) {
                 
        system.debug('PrecedentBeforeDeleteTriggerHandler beforeDelete:: ');
        if(!isBeforeDeleteProcessing) {
            isBeforeDeleteProcessing = true;
            execute(new PrecedentBeforeDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeDelete);
            isBeforeDeleteProcessing = false;
        }
        else{
            execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
        } 
    }


}