/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Attachment Trigger

Test Class:    AttachmentTriggerDispatcher_Test
History
04/05/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public without sharing class AttachmentAfterUndeleteTriggerHandler extends TriggerHandlerBase{
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
        	NoteOrAttachment__c noteOrAttachment;
	        for(Attachment attachment: (List<Attachment>)tp.newlist) {
	           	//Check to see if Parent Id is a Case Id
	           	if (((String)attachment.ParentId).startsWith(GlobalConstants.CASE_ID_PREFIX)) {
					//Create a NoteOrAttachment record
					noteOrAttachment = new NoteOrAttachment__c();
					noteOrAttachment.Attachment__c        = attachment.Id;
					noteOrAttachment.Case__c              = attachment.ParentId;
					noteOrAttachment.File_Name__c         = attachment.Name;
					noteOrAttachment.Requires_Printing__c = false;
					noteOrAttachments.add(noteOrAttachment);
	           	}   
	        }
	        
	        //insert NoteOrAttachments
	        if (!noteOrAttachments.isEmpty()) insert noteOrAttachments;

        }catch(Exception e){
        	system.debug('-----AttachmentAfterUndeleteTriggerHandler Exception---' + e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='AttachmentAfterUndeleteTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.newMap!=null)  message.referenceInfo=JSON.serialize(tp.newMap.keySet());
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