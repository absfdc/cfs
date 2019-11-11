/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus
Description:   Task before update handler
Test Class:    TaskTriggerDispatcher_Test
History
14 Aug 2015      Manish Damle  Created
------------------------------------------------------------*/
public class TaskBeforeUpdateTriggerHandler extends TriggerHandlerBase{
	
	List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

	public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }

    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus
    Description:   WI 905
    Inputs:        Trigger context parameters
    History
    14 Aug 2015      Manish Damle  Created
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{ 
        	System.debug('--@Task trigger before update--');
            for(Task t : (list <Task>) tp.newList) {
                Task oldTask = (Task) tp.oldMap.get(t.Id);
                Task newTask = (Task) tp.newMap.get(t.Id);
                if(oldTask.Status != 'Completed' && newTask.Status == 'Completed') {
                    newTask.RecordTypeId = TaskTriggerDispatcher.completedTaskRecordType.Id;
                }
            }
    		ActivityValidationHandler taskValidator = new ActivityValidationHandler();
        	taskValidator.preventTaskEditing(tp);
        }catch(Exception e){
            System.debug(e);
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='TaskBeforeUpdateTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.oldMap!=null)  message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
}