/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the EmailMessage trigger
Test Class:    EmailMessageTriggerDispatcher_Test

History
19/08/2015 Manish Damle created      
------------------------------------------------------------*/
public class EmailMessageBeforeDeleteTriggerHandler extends TriggerHandlerBase {
	
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    List<ApplicationLogMessage> logs =new List<ApplicationLogMessage>();
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Handler function creates a task for an outbound
                    email request seeking advice from sme and if an
                    email is received on a closed case it conditionally
                    reopens the closed case if within a duration otherwise
                    it creates a separate case.
    Inputs:        Trigger context parameters

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try {
            ActivityValidationHandler validationHandler = new ActivityValidationHandler();
            validationHandler.preventEmailMessgeDeletion(tp);
        } catch(Exception e) {
            system.debug('----Caught Exception----'+ e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage log= new ApplicationLogMessage();
            log.source='EmailMessageBeforeDeleteTriggerHandler';
            log.sourceFunction='process';
            log.logMessage=e.getMessage();
            log.ex=e;
            log.debugLevel='Error';
            logs.add(log);
            ApplicationLogUtility.logMessage(logs);
            logs.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
}