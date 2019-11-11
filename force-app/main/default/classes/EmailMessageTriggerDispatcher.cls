/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the EmailMessage trigger

Test Class:    EmailMessageTriggerDispatcher_Test
History
16 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/

public class EmailMessageTriggerDispatcher extends TriggerDispatcherBase{
	private static Boolean isBeforeInsertProcessing = false;
    private static Boolean isBeforeDeleteProcessing = false;
    
	private static Boolean isBypassed = null;
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Function to decide if the corresponding handler 
					should  simply fire, or the one already running 
					and responsible for triggering this invocation should be notified
	Inputs:        Trigger parameters
	Returns:       void
	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
	public virtual override void beforeInsert(TriggerParameters tp) {
		if(checkBypassed()==true) return ;
		if(!isBeforeInsertProcessing) {
			isBeforeInsertProcessing = true;
			execute(new EmailMessageBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
			isBeforeInsertProcessing = false;
		}
		else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
	}
	
    /*------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   Function to decide if the corresponding handler 
				    should  simply fire, or the one already running 
					and responsible for triggering this invocation should be notified
	Inputs:        Trigger parameters
	Returns:       void
	History
	<Date>        <Authors Name>     <Brief Description of Change>
    19/08/2015     Manish Damle 		Created(WI905)
	------------------------------------------------------------*/
	public virtual override void beforeDelete(TriggerParameters tp) {
		if(checkBypassed()==true) return;
        
		if(!isBeforeDeleteProcessing) {
			isBeforeDeleteProcessing = true;
			execute(new EmailMessageBeforeDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeDelete);
			isBeforeDeleteProcessing = false;
		}
		else execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
	}
    
	public Boolean checkBypassed(){
		if (isBypassed==null){
			User invoker=[select Id, Bypass_Triggers__c from User where Id=:UserInfo.getUserId()];
			if (invoker.Bypass_Triggers__c!=null){
				Set<String> bypassed=new Set <String>(invoker.Bypass_Triggers__c.split(';',0));
				if (bypassed.contains('EmailMessage')){
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