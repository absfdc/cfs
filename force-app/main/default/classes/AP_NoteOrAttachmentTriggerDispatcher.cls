/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A dispatcher class for the NoteOrAttachment trigger

Test Class:    AP_NoteOrAttachmentTriggerDispatcher_Test
History
10/6/2015     Dipankar Barman       Created
21/04/2015     Dipankar Barman       Object ref changed NoteOrAttachment
------------------------------------------------------------*/
public with sharing class AP_NoteOrAttachmentTriggerDispatcher extends TriggerDispatcherBase {
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isAfterDeleteProcessing = false;
    private static Boolean isAfterUndeleteProcessing = false;
    
    private static Boolean isBypassed = null;
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Function to decide if the After Insert handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    10/6/2015     Dipankar Barman       Created   
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new AP_NoteOrAttAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            isAfterInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
    }
    
    
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Function to decide if the After delete handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    10/6/2015     Dipankar Barman       Created   
    ------------------------------------------------------------*/
    public virtual override void afterDelete(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isAfterDeleteProcessing) {
            isAfterDeleteProcessing = true;
            execute(new AP_NoteOrAttAfterDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterDelete);
            isAfterDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterDelete);
    }
    
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Function to decide if the After undelete handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    10/6/2015     Dipankar Barman       Created   
    ------------------------------------------------------------*/
    public virtual override void afterUnDelete(TriggerParameters tp) {
        system.debug('-----------afterUnDelete-----------');
        if(checkBypassed() == true) return ;
        if(!isAfterUndeleteProcessing) {
            isAfterUndeleteProcessing = true;
            execute(new AP_NoteOrAttAfterUndeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUnDelete);
            isAfterUndeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUnDelete);
    }
    
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(',',0));
                if (bypassed.contains('AP_NoteOrAttachement') || bypassed.contains('AP_NoteOrAttachement__c') || bypassed.contains('Note & Attachement')){
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