/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the contact trigger

Test Class:    ContactTriggerDispatcher_Test
History
16 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/

public class ContactTriggerDispatcher extends TriggerDispatcherBase{
	private static Boolean isBeforeInsertProcessing = false;
	private static Boolean isBeforeUpdateProcessing = false;
	private static Boolean isAfterInsertProcessing = false;
	private static Boolean isAfterUpdateProcessing = false; 
	private static Boolean isAfterDeleteProcessing = false; 
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
			System.debug('call execute method');
			//TODO when we have a handler we need to uncomment the line below
			execute(new ContactBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
			isBeforeInsertProcessing = false;
		}
		else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
	}
	
	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Function to decide if the corresponding handler 
					should  simply fired, or the one already running 
					and responsible for triggering this invocation should be notified
	Inputs:        Trigger parameters
	Returns:       void
	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
	public virtual override void beforeUpdate(TriggerParameters tp) {
		if(checkBypassed() == true) return ;

		if(!isBeforeUpdateProcessing) {
			isBeforeUpdateProcessing = true;
			execute(new ContactBeforeUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
			isBeforeUpdateProcessing = false;
		}
		else execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
	}

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Function to decide if the corresponding handler 
					should  simply fired, or the one already running 
					and responsible for triggering this invocation should be notified
	Inputs:        Trigger parameters
	Returns:       void
	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
	public virtual override void afterInsert(TriggerParameters tp) {
		if(checkBypassed()==true) return ;

		if(!isAfterInsertProcessing) {
			isAfterInsertProcessing = true;
			execute(new ContactAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
			isAfterInsertProcessing = false;
		}
		else execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
	}

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Function to decide if the corresponding handler 
					should  simply fired, or the one already running 
					and responsible for triggering this invocation should be notified
	Inputs:        Trigger parameters
	Returns:       void
	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
	public virtual override void afterUpdate(TriggerParameters tp) {
		if(checkBypassed()==true) return ;

		if(!isAfterUpdateProcessing) {
			isAfterUpdateProcessing = true;
			//TODO when we have a handler we need to uncomment the line below
			//execute(new ContactAfterUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUpdate);
			isAfterUpdateProcessing = false;
		}
		else execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
	}


	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Function to decide if the corresponding handler 
					should  simply fired, or the one already running 
					and responsible for triggering this invocation should be notified
	Inputs:        Trigger parameters
	Returns:       void
	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
	public virtual override void afterDelete(TriggerParameters tp) {
		if(checkBypassed()==true) return ;

		if(!isAfterDeleteProcessing) {
			isAfterDeleteProcessing = true;
			execute(new ContactAfterDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUpdate);
			isAfterDeleteProcessing = false;
		}
		else execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
	}

	public Boolean checkBypassed(){
		if (isBypassed==null){
			if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
				Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(',',0));
				if (bypassed.contains('Contact')){
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