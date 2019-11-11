/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Salesforce
Description:   Before Delete handler class for the event trigger
               prevents delete for non admin user 

Test Class:    eventTriggerDispatcher_Test
History
14 Apr 2015      Dipankar Barman     created
------------------------------------------------------------*/
public class EventBeforeDeleteTriggerHandler extends TriggerHandlerBase{
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Salesforce.com
    Description:   prevents delete for non admin user
    Inputs:        Trigger context parameters

    History
    
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{ 
        	System.debug('--@Event trigger before delete--');
        	ActivityValidationHandler taskValidator = new ActivityValidationHandler();
            taskValidator.preventEventDeletion(tp);
        }catch(Exception e){
            System.debug(e);
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='EventBeforeDeleteTriggerHandler';
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