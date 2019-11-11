/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the Private Note trigger

Test Class:    NoteOrAttachmentTriggerDispatcher_Test
History
20/07/2015     Manish Damle       Created
23/11/2016     Arxxus             Update to rename Thunderhead wordML file 
------------------------------------------------------------*/
public class NoteOrAttBeforeUpdateTriggerHandler extends TriggerHandlerBase{
    
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    public boolean exceptionInvoked = FALSE;

    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Handler function updates the owner of the NoteOrAttachment to case owner when
                   case lookup value changes
    
    History
    20/07/2015     Manish Damle       Created
    23/11/2016     Arxxus             Update to rename Thunderhead wordML file 
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        
        try {
            
            map <Id,Id> noteOrAttVsCaseIds = new map<Id,Id>();
            for(NoteOrAttachment__c att : (list <NoteOrAttachment__c>) tp.newList) {
                
                NoteOrAttachment__c newAtt = (NoteOrAttachment__c) tp.newMap.get(att.Id);
                NoteOrAttachment__c oldAtt = (NoteOrAttachment__c) tp.oldMap.get(att.Id);
                
                if(newAtt.Attachment__c != null 
                   && oldAtt.Case__c != null
                   && newAtt.Case__c != null
                   && oldAtt.Case__c != newAtt.Case__c 
                   && (newAtt.Category__c == 'Signed Response' || newAtt.Category__c == 'Amendment')
                   && newAtt.ContentType__c == 'application/pdf') {
                       noteOrAttVsCaseIds.put(newAtt.Id, newAtt.Case__c);
                }   
                
                // renaming the thunderhead wordML file
                if(newAtt.ContentType__c == 'application/msword' 
                   && newAtt.Conga_Response_PDF_Generated__c == FALSE
                   && newAtt.name.startsWith('response_')) {
                   
                   System.debug('Trying to rename file:'+newAtt.Name);
                   System.debug('Trying to rename file:'+newAtt.File_Name__c);
                   
                   //renaming the Thunderhead response draft
                   newAtt.Name = newAtt.Response_Document_File_Name__c+'.doc';
                }
            }
            
            if(noteOrAttVsCaseIds.size() > 0) {
                map <Id, Case> cases = new map <Id, Case> ([Select Id, OwnerId From Case Where Id IN: noteOrAttVsCaseIds.values()]);
                for(Id noteOrAttId : noteOrAttVsCaseIds.keySet()) {
                    if(cases.containsKey(noteOrAttVsCaseIds.get(noteOrAttId)) && cases.get(noteOrAttVsCaseIds.get(noteOrAttId)) != null) {
                        NoteOrAttachment__c newAtt = (NoteOrAttachment__c) tp.newMap.get(noteOrAttId);
                        newAtt.OwnerId =  cases.get(noteOrAttVsCaseIds.get(noteOrAttId)).OwnerId;
                    }
                }
            }
            
            /*
             * SNSW Changes START: Changes to share attachment with SNSW for qualified cases
             */
             System.debug(LoggingLevel.INFO, 'Checking for shared cases');
             NewAttachmentsSharedWithSNSW shareAttachInstance = new NewAttachmentsSharedWithSNSW((Map<Id,NoteOrAttachment__c>) tp.newMap);
             shareAttachInstance.shareAttachments();
             /*
              * SNSW Changes END: Changes to share attachment with SNSW for qualified cases
              */
        }
        catch(Exception e) {
            
            exceptionInvoked = TRUE;
            
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='Private_NoteBeforeUpdateTriggerHandler';
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