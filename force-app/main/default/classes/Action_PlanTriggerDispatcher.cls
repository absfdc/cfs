/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A dispatcher class for the Action Plan trigger

Test Class:    Action_PlanTriggerDispatcher_Test
History
04/05/2015     Manish Damle       Created
------------------------------------------------------------*/
public without sharing class Action_PlanTriggerDispatcher extends TriggerDispatcherBase {
    
    public static map <String, Id> actionPlanRecordTypes;
    public static Integer triggerLoopCount = 0;
    public static EmailTemplate childAPStatusChangedEmailTemplate;
    public static map<Id,UserRole> magsAndCrgsAdminRoles;
    public static Id noReplyOrgWideEmailAddressId;
    private static Boolean isBeforeInsertProcessing = false;
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isAfterDeleteProcessing = false;
    private static Boolean isAfterUpdateProcessing = false;
    private static Boolean isAfterUndeleteProcessing = false;
    private static Boolean isBeforeUpdateProcessing = false;
    private static Boolean isBeforeDeleteProcessing = false;
    private static Boolean isBypassed = null;
    public static Boolean preventEmailResending = false;
    
    static {
    	actionPlanRecordTypes = new map <String, Id>();
    	for(RecordType rt: [Select Id, DeveloperName From RecordType Where SobjectType = 'Action_Plan__c']) {
    		actionPlanRecordTypes.put(rt.DeveloperName, rt.Id);
    	} 
        
        childAPStatusChangedEmailTemplate = [Select Id
                                             From EmailTemplate 
                                             Where DeveloperName =: GlobalConstants.CHILD_AP_STATUS_CHANGE_NOTIFICATION_EMAIL_TEMPLATE limit 1];
        
        noReplyOrgWideEmailAddressId = [Select Id 
                                        From OrgWideEmailAddress 
                                        Where DisplayName =: GlobalConstants.NOREPLY_ORGWIDE_EMAIL limit 1].Id;
        
        magsAndCrgsAdminRoles = new map<Id,UserRole>([Select Id 
                          							  From UserRole 
                          							  Where DeveloperName IN: GlobalConstants.AP_DUE_DATE_CALCULATION_ALLOWED_ROLE_NAMES]);
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
    04/05/2015     Manish Damle       Created  
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new ActionPlanAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
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
    04/05/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    public virtual override void afterUpdate(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isAfterUpdateProcessing) {
            isAfterUpdateProcessing = true;
            execute(new ActionPlanAfterUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUpdate);
            isAfterUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Function to decide if the Before Update handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    04/05/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    public virtual override void beforeUpdate(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isBeforeUpdateProcessing) {
            isBeforeUpdateProcessing = true;
            execute(new ActionPlanBeforeUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
            isBeforeUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
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
    04/05/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void afterUnDelete(TriggerParameters tp) {
        system.debug('-----------afterUnDelete-----------');
        if(checkBypassed() == true) return ;
        if(!isAfterUndeleteProcessing) {
            isAfterUndeleteProcessing = true;
            execute(new ActionPlanAfterUndeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUnDelete);
            isAfterUndeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUnDelete);
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
    01/06/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void afterDelete(TriggerParameters tp) {
        system.debug('-----------afterDelete-----------');
        if(checkBypassed() == true) return ;
        if(!isAfterDeleteProcessing) {
            isAfterDeleteProcessing = true;
            execute(new ActionPlanAfterDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterDelete);
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
    04/05/2015     Manish Damle       Created   
    ------------------------------------------------------------*/
    public virtual override void beforeInsert(TriggerParameters tp) {
        system.debug('-----------beforeInsert-----------');
        if(checkBypassed() == true) return ;
        if(!isBeforeInsertProcessing) {
            isBeforeInsertProcessing = true;
            execute(new ActionPlanBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
            isBeforeInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
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
        if(checkBypassed() == true) return ;
        if(!isBeforeDeleteProcessing) {
            isBeforeDeleteProcessing = true;
            execute(new ActionPlanBeforeDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeDelete);
            isBeforeDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
    }
    
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(',',0));
                if (bypassed.contains('Action Plan') || bypassed.contains('Action_Plan')){
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