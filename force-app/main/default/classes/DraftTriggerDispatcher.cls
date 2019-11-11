public class DraftTriggerDispatcher extends TriggerDispatcherBase {
	private static Boolean isBeforeUpdateProcessing = false;
    private static Boolean isAfterUpdateProcessing = false;
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isBypassed = null;
    public static map <String, String> magsRoles;
    
    static {
        magsRoles = new map <String, String>();
        for(UserRole role : [Select Id, DeveloperName From UserRole Where DeveloperName IN: GlobalConstants.MAGS_ROLE_NAMES]){
            magsRoles.put(role.Id, role.DeveloperName);
        }
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the after inserthandler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    05/06/2015     Manish Damle Created
    ------------------------------------------------------------*/
    public virtual override void afterInsert(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new DraftAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
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
    03/06/2015     Manish Damle Created
    ------------------------------------------------------------*/
    public virtual override void afterUpdate(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isAfterUpdateProcessing) {
            isAfterUpdateProcessing = true;
            execute(new DraftAfterUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUpdate);
            isAfterUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
    }
	
	/*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the before Update handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    05/06/2015     Manish Damle Created
    ------------------------------------------------------------*/
    public virtual override void beforeUpdate(TriggerParameters tp) {
        if(checkBypassed() == true) return ;
        if(!isBeforeUpdateProcessing) {
            isBeforeUpdateProcessing = true;
            execute(new DraftBeforeUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
            isBeforeUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
    }    
    
    
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(',',0));
                if (bypassed.contains('Draft')){
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