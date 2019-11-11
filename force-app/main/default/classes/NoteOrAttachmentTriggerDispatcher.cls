/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A dispatcher class for the NoteOrAttachment trigger

Test Class:    NoteOrAttachmentTriggerDispatcher_Test
History
20/04/2015     Manish Damle       Created
21/04/2015     Manish Damle       Object ref changed NoteOrAttachment
19/05/2017     Pawan Tiwari       Updated. Added beforeInsert method.
------------------------------------------------------------*/
public with sharing class NoteOrAttachmentTriggerDispatcher extends TriggerDispatcherBase {
    private static Boolean isBeforeInsertProcessing = false;
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isAfterUpdateProcessing = false;
    private static Boolean isBeforeUpdateProcessing = false;
    private static Boolean isAfterDeleteProcessing = false;
    private static Boolean isAfterUndeleteProcessing = false;
    public static Boolean  currentUserIsKnowledgeUser = false;
    
    private static Boolean isBypassed = null;
    
    static {
        if(!isRunningUserConnectionUser()) {
            currentUserIsKnowledgeUser = [Select Id, UserPermissionsKnowledgeUser From User Where Id =: UserInfo.getUserId() limit 1].UserPermissionsKnowledgeUser;
        }        
    }
    
    /*------------------------------------------------------------
    Author:        Pawan Tiwari
    Company:       Arxxus.com
    Description:   Function to decide if the After Insert handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    19/05/2017     Pawan Tiwari     Created   
    ------------------------------------------------------------*/
    public virtual override void beforeInsert(TriggerParameters tp) {
        if(isRunningUserConnectionUser()) return;
        if(checkBypassed() == true) return ;
        if(!isBeforeInsertProcessing) {
            isBeforeInsertProcessing = true;
            execute(new NoteOrAttBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
            isBeforeInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the After Insert handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    20/04/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        if(isRunningUserConnectionUser()) return;
        if(checkBypassed() == true) return ;
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new NoteOrAttAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            isAfterInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the After Update handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    20/04/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void afterUpdate(TriggerParameters tp) {
        if(isRunningUserConnectionUser()) return;
        if(checkBypassed() == true) return ;
        if(!isAfterUpdateProcessing) {
            isAfterUpdateProcessing = true;
            execute(new NoteOrAttAfterUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUpdate);
            isAfterUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the After delete handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    20/04/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void afterDelete(TriggerParameters tp) {
        if(isRunningUserConnectionUser()) return;
        if(checkBypassed() == true) return ;
        if(!isAfterDeleteProcessing) {
            isAfterDeleteProcessing = true;
            execute(new NoteOrAttAfterDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterDelete);
            isAfterDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterDelete);
    }
    
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the After undelete handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    20/04/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void afterUnDelete(TriggerParameters tp) {      
        system.debug('-----------afterUnDelete-----------');
        if(checkBypassed() == true) return ;
        if(!isAfterUndeleteProcessing) {
            isAfterUndeleteProcessing = true;
            execute(new NoteOrAttAfterUndeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUnDelete);
            isAfterUndeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUnDelete);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the before update handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    20/07/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void beforeUpdate(TriggerParameters tp) {
        if(isRunningUserConnectionUser()) return;
        system.debug('-----------beforeUpdate-----------');
        if(checkBypassed() == true) return ;
        if(!isBeforeUpdateProcessing) {
            isBeforeUpdateProcessing = true;
            execute(new NoteOrAttBeforeUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
            isBeforeUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
    }
    
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(',',0));
                if (bypassed.contains('NoteOrAttachement') || bypassed.contains('NoteOrAttachement__c') || bypassed.contains('Note & Attachement')){
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
    
    /*
     * SNSW Changes START: Changes to bypass existing custom attachment trigger logic of CFM and MinCorro for user record with name as connection user
     */
    public static Boolean isRunningUserConnectionUser() {
        Boolean flag = false;
        String username = UserInfo.getName();
        System.debug(LoggingLevel.INFO, 'Current running user: ' + username);
        if(GlobalConstants.CONNECTION_USER_NAME.equalsIgnoreCase(username)) {
            flag = true;
        }
        return flag;
    }
    /*
    * SNSW Changes END: Changes to bypass existing custom attachment trigger logic of CFM and MinCorro for user record with name as connection user
    */
}