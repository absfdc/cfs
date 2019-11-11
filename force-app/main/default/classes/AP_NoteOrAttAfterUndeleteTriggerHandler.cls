/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Private Note trigger

Test Class:    NoteOrAttachmentTriggerDispatcher_Test
History
20/04/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public class AP_NoteOrAttAfterUndeleteTriggerHandler extends TriggerHandlerBase{
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Handler function updates the number of private notes 
                   on a particular case record.
    
    History
    20/04/2015     Dipankar Barman       Created
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            system.debug('---AP_NoteAfterUndeleteTriggerHandler---');
            NoteOrAttachmentSharingHandler sharingHandler = new NoteOrAttachmentSharingHandler();
            sharingHandler.shareWithActionPlanOwners((list <AP_NoteOrAttachment__c>) tp.newList);
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='Private_NoteAfterUndeleteTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.oldMap!=null)  message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel='Error';
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