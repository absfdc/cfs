/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Attachment Trigger

Test Class:    AttachmentTriggerDispatcher_Test
History
04/05/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public without sharing class AttachmentAfterDeleteTriggerHandler extends TriggerHandlerBase{
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
    Description:   Handler function to restore NotesAndAttachment objects on undeleting corresponding related attachemnts 
    History
    04/05/2015     Dipankar Barman       Created
    
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
    	List<NoteOrAttachment__c> noteOrAttachments = new List<NoteOrAttachment__c>();

        try{
        	Set<Id> attachmentIds = new Set<Id>();
        
	        for(Attachment attachment:  (List<Attachment>)tp.oldList) {
	           //Check to see if Parent Id is a Case Id
	           if (((String)attachment.ParentId).startsWith(GlobalConstants.CASE_ID_PREFIX))
	              attachmentIds.add(attachment.Id);
	        }
	        
	        //insert NoteOrAttachments
	        if (!attachmentIds.isEmpty()) {
	            noteOrAttachments = [SELECT Id FROM NoteOrAttachment__c WHERE Attachment__c IN :attachmentIds];
	            delete noteOrAttachments;    
	        }

        }catch(Exception e){
        	system.debug('-----AttachmentAfterDeleteTriggerHandler Exception---' + e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='AttachmentAfterDeleteTriggerHandler';
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