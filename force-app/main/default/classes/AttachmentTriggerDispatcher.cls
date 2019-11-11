/*------------------------------------------------------------
Author:       Dipankar
Company:       Arxxus.com
Description:   A dispatcher class for the Attachment trigger

Test Class:    AttachmentTriggerDispatcher_Test
History
04/05/2015    Dipankar       Created
19/05/2017    Pawan Tiwari   Updated. Added beforeInsert method.
------------------------------------------------------------*/
public class AttachmentTriggerDispatcher extends TriggerDispatcherBase {
    
    private static Boolean isbeforeInsertProcessing = false;
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isAfterUndeleteProcessing = false;
    private static Boolean isAfterDeleteProcessing = false;

    private static Boolean isBypassed = null;
  
    /*------------------------------------------------------------
    Author:       Pawan Tiwari
    Company:       Arxxus.com
    Description:   Function to decide if the After Insert handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History 
    19/05/2017    Pawan Tiwari       Created  
    ------------------------------------------------------------*/
    public virtual override void beforeInsert(TriggerParameters tp) {
        system.debug('AttachmentTriggerDispatcher : beforeInsert');
        /*
         * SNSW Changes START: Changes to bypass after insert attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(!isRunningUserConnectionUser() && checkBypassed() == true) return ;
        /*
         * SNSW Changes END: Changes to bypass after insert attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
        
        if(!isbeforeInsertProcessing) {
            isbeforeInsertProcessing = true;
            execute(new AttachmentBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
            isbeforeInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
    }
    /*------------------------------------------------------------
    Author:       Dipankar
    Company:       Arxxus.com
    Description:   Function to decide if the After Insert handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History 
    04/05/2015    Dipankar       Created  
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass after insert attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(!isRunningUserConnectionUser() && checkBypassed() == true) return ;
        /*
         * SNSW Changes END: Changes to bypass after insert attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
        
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new AttachmentAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            isAfterInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
    }
    
   
    /*------------------------------------------------------------
    Author:       Dipankar
    Company:       Arxxus.com
    Description:   Function to decide if the After undelete handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    04/05/2015    Dipankar       Created   
    ------------------------------------------------------------*/
    public virtual override void afterUnDelete(TriggerParameters tp) {
    
        /*
         * SNSW Changes START: Changes to bypass after undelete attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass after undelete attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
         
        system.debug('-----------afterUnDelete-----------');
        if(checkBypassed() == true) return ;
        if(!isAfterUndeleteProcessing) {
            isAfterUndeleteProcessing = true;
            execute(new AttachmentAfterUndeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUnDelete);
            isAfterUndeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUnDelete);
    }
    
   /*------------------------------------------------------------
    Author:       Dipankar
    Company:       Arxxus.com
    Description:   Function to decide if the After delete handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    04/05/2015    Dipankar       Created   
    ------------------------------------------------------------*/
    public virtual override void afterDelete(TriggerParameters tp) {
    
        /*
         * SNSW Changes START: Changes to bypass after delete attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass after delete attachment trigger logic of CFM and MinCorro for user record with name as connection user
         */
         
        system.debug('-----------afterDelete-----------');
        if(checkBypassed() == true) return ;
        if(!isAfterDeleteProcessing) {
            isAfterDeleteProcessing = true;
            execute(new AttachmentAfterDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterDelete);
            isAfterDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterDelete);
    }
    
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(',',0));
                if (bypassed.contains('Attachment')){
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
     * SNSW Changes START: Changes to bypass existing attachment trigger logic of CFM and MinCorro for user record with name as connection user
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
    * SNSW Changes END: Changes to bypass existing attachment trigger logic of CFM and MinCorro for user record with name as connection user
    */
}