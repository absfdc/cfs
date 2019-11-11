/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus
Description:   This class is reposible for hadling the various validation on Tasks.
Test Class:    TaskTriggerDispatcher_Test
History
14 Aug 2015      Manish Damle  Created
------------------------------------------------------------*/
public class ActivityValidationHandler {
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus
    Description:   This method will present the non admin user from deleting the task
    Test Class:    TaskTriggerDispatcher_Test
    History
    14 Aug 2015      Manish Damle  Created
	------------------------------------------------------------*/
    public void preventTaskDeletion(TriggerParameters tp) {
        If(!GlobalConstants.SYS_ADMIN_IDS.contains(UserInfo.getUserId()) ) {
        	for (sObject aTask : tp.oldList) aTask.addError(GlobalConstants.TASK_PREVENT_DELETE_ERROR_MESSAGE);
            system.debug('--@Task delete user is not system admin--');
        }else{
            system.debug('--@Task delete user is A system admin--');
        }
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus
    Description:   This method will present the non admin user from updating the completed tasks
    Test Class:    TaskTriggerDispatcher_Test
    History
    14 Aug 2015      Manish Damle  Created
    ------------------------------------------------------------*/
    public void preventTaskEditing(TriggerParameters tp){
        If(!GlobalConstants.SYS_ADMIN_IDS.contains(UserInfo.getUserId()) ) {
            system.debug('--@Task update user is not system admin--');
            for(Task t : (list <Task>) tp.newList) {
                Task oldTask = (Task) tp.oldMap.get(t.Id);
                Task newTask = (Task) tp.newMap.get(t.Id);
                if(oldTask.Status == GlobalConstants.ADVICE_TASK_COMPLETED_STATUS && newTask.IsClosed) {
                    newTask.addError(GlobalConstants.TASK_PREVENT_UPDATE_ERROR_MESSAGE);
                }
            }
        } else {
            system.debug('--@Task update user is system admin--');
        }
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus
    Description:   This method will present the non admin user from deleting the event
    Test Class:    TaskTriggerDispatcher_Test
    History
    14 Aug 2015      Manish Damle  Created
	------------------------------------------------------------*/
    public void preventEventDeletion(TriggerParameters tp) {
        If(!GlobalConstants.SYS_ADMIN_IDS.contains(UserInfo.getUserId()) ) {
        	for (sObject anEvent : tp.oldList) anEvent.addError(GlobalConstants.EVENT_PREVENT_DELETE_ERROR_MESSAGE);
            system.debug('--@Event delete user is not system admin--');
        }else{
            system.debug('--@Event delete user is A system admin--');
        }
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus
    Description:   This method will present the non admin user from deleting the Email Messages
    Test Class:    TaskTriggerDispatcher_Test
    History
    19 Aug 2015      Manish Damle  Created
	------------------------------------------------------------*/
    public void preventEmailMessgeDeletion(TriggerParameters tp) {
        If(!GlobalConstants.SYS_ADMIN_IDS.contains(UserInfo.getUserId()) ) {
        	for (sObject anEmailMessage : tp.oldList) anEmailMessage.addError(GlobalConstants.EMAIL_MESSAGE_PREVENT_DELETE_ERROR_MESSAGE);
            system.debug('--@EmailMessage delete user is not system admin--');
        }else{
            system.debug('--@EmailMessage delete user is A system admin--');
        }
    }
}