/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A dispatcher class for the Task trigger

Test Class:    TaskTriggerDispatcher_Test
History
04/05/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public with sharing class TaskTriggerDispatcher extends TriggerDispatcherBase {
    
    public static Integer triggerLoopCount = 0;
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isBeforeDeleteProcessing = false;
    private static Boolean isBeforeInsertProcessing = false;
    private static Boolean isBeforeUpdateProcessing = false;
    private static Boolean isBypassed = null;
    public static RecordType completedTaskRecordType;
    
    static {
        completedTaskRecordType = [Select Id From RecordType Where SobjectType = 'Task' And DeveloperName  =: GlobalConstants.COMPLETED_TASK_RECORD_TYPE_NAME limit 1];         
    }
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Function to decide if the After Insert handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History 
    04/05/2015     Dipankar Barman       Created  
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        /*
         * SNSW Changes START: Changes to bypass after insert task trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass after insert task trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(checkBypassed() == true) return ;
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new TaskAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            isAfterInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
    }
    
  
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
        /*
         * SNSW Changes START: Changes to bypass before delete task trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass before delete task trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(checkBypassed() == true) return ;
        if(!isBeforeDeleteProcessing) {
            isBeforeDeleteProcessing = true;
            execute(new TaskBeforeDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeDelete);
            isBeforeDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Before update trigger handler
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/
    public virtual override void beforeUpdate(TriggerParameters tp) {
        system.debug('-----------beforeUpdate-----------');
        /*
         * SNSW Changes START: Changes to bypass before update task trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass before update task trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(checkBypassed() == true) return ;
        if(!isBeforeUpdateProcessing) {
            isBeforeUpdateProcessing = true;
            execute(new TaskBeforeUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
            isBeforeUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
    }
    
     /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Before Insert trigger handler
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/
    public virtual override void beforeInsert(TriggerParameters tp) {
        system.debug('-----------beforeInsert-----------');
        /*
         * SNSW Changes START: Changes to bypass before insert task trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass before insert trigger trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(checkBypassed() == true) return ;
        if(!isBeforeInsertProcessing) {
            isBeforeInsertProcessing = true;
            execute(new TaskBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
            isBeforeInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
    }
    
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(';',0));
                if (bypassed.contains('Task') || bypassed.contains('Task')){
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
     * SNSW Changes START: Changes to bypass existing case trigger logic of CFM and MinCorro for user record with name as connection user
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
    * SNSW Changes END: Changes to bypass existing case trigger logic of CFM and MinCorro for user record with name as connection user
    */
}