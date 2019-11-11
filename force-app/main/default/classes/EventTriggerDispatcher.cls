/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A dispatcher class for the Event trigger

Test Class:    EventTriggerDispatcher_Test
History
04/05/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public with sharing class EventTriggerDispatcher extends TriggerDispatcherBase {
    
    public static Integer triggerLoopCount = 0;
    private static Boolean isBeforeDeleteProcessing = false;
    private static Boolean isBypassed = null;
   
    
 
    
  
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   run the sharing operation on the detail records related records before they are obliterated
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/
    public virtual override void beforeDelete(TriggerParameters tp) {
        system.debug('-----------beforeDelete-----------');
        if(checkBypassed() == true) return ;
        if(!isBeforeDeleteProcessing) {
            isBeforeDeleteProcessing = true;
            execute(new EventBeforeDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeDelete);
            isBeforeDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
    }
    
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(',',0));
                if (bypassed.contains('Event') || bypassed.contains('Event')){
                    isBypassed=true;
                }else{
                    isBypassed=false;
                }
            }else{
                isBypassed=false;
            }

        }
        return isBypassed;
    }
}