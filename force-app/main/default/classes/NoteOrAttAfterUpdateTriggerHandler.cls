/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the Private Note trigger

Test Class:    NoteOrAttachmentTriggerDispatcher_Test
History
20/04/2015     Manish Damle       Created
14/11/2016     Arxxus             Updated - Added code to generate PDF using conga for
                                  file of type application/msword and name starting as response_
------------------------------------------------------------*/
public class NoteOrAttAfterUpdateTriggerHandler extends TriggerHandlerBase {

    List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

    public boolean exceptionInvoked = FALSE;

    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }

    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Handler function updates the number of private notes 
                   on a particular case record.
    
    History
    20/04/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{

            system.debug('---Private_NoteAfterUpdateTriggerHandler---');

            list<NoteOrAttachment__c> sharingToBeRecalculated = new list<NoteOrAttachment__c>();
            NoteOrAttachmentCustomRollUpImpl.calculateRollUp((map<Id, NoteOrAttachment__c>) tp.newMap, (map<Id,NoteOrAttachment__c>) tp.oldMap);
            NoteOrAttachmentSharingHandler sharingHandler = new NoteOrAttachmentSharingHandler();

            for(NoteOrAttachment__c att : (list<NoteOrAttachment__c>) tp.newList) {

                NoteOrAttachment__c newNoteOrAttachment = (NoteOrAttachment__c) tp.newMap.get(att.Id);
                NoteOrAttachment__c oldNoteOrAttachment = (NoteOrAttachment__c) tp.oldMap.get(att.Id);
                if((newNoteOrAttachment.OwnerId != oldNoteOrAttachment.OwnerId) 
                   || (oldNoteOrAttachment.Privacy__c != newNoteOrAttachment.Privacy__c)) {
                    sharingToBeRecalculated.add(att);
                }

                System.debug('Attachment Record New: ' + newNoteOrAttachment);
                System.debug('Attachment Record Old: ' + oldNoteOrAttachment);

                if(newNoteOrAttachment.Attachment_Id__c != NULL 
                    && newNoteOrAttachment.ContentType__c == 'application/msword' 
                    && newNoteOrAttachment.Conga_Response_PDF_Generated__c == FALSE
                    && newNoteOrAttachment.name.startsWith('response_')) {

                    GenerateResponsePDF.generate(newNoteOrAttachment.Case__c, newNoteOrAttachment.Id, newNoteOrAttachment.Attachment_Id__c, newNoteOrAttachment.Name, UserInfo.getSessionId());
                }

            }

            sharingHandler.share(sharingToBeRecalculated);

            if(NoteOrAttachmentTriggerDispatcher.currentUserIsKnowledgeUser) {
                AttachmentToKnowledgeArticleConverter converter = new AttachmentToKnowledgeArticleConverter(tp);
                converter.convert();
                converter.attachCaseArticleToNewCase();
            }

        }
        catch(Exception e) {

            exceptionInvoked = TRUE;

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'NoteOrAttAfterUpdateTriggerHandler';
            message.sourceFunction = 'process';
            if(tp != null && tp.oldMap != null) 
                message.referenceInfo = JSON.serialize(tp.oldMap.keySet());
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
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