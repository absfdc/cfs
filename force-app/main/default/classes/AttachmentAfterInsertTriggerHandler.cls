/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Attachment Trigger

Test Class:    AttachmentTriggerDispatcher_Test
History
04/05/2015     Dipankar Barman       Created
10/03/2017     Arxxus                Updated - Optimised code to avoid 101 SOQL limit
06/07/2018     Ian Fitzgerald        Added check for "DoNotCreateNOA" in file name
------------------------------------------------------------*/
public without sharing class AttachmentAfterInsertTriggerHandler extends TriggerHandlerBase{
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    static final String HTML_COMPONENT_PREFIX =  '02S';//added for send referral 101 soql
    static Id ATTACHMENT_RECORDTYPE_ID=null;//added for send referral 101 soql
    public override void mainEntry(TriggerParameters tp) {
        process(tp);        
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    private static List<String> inProgressJobStatus = new List<String> {'Queued', 'Preparing', 'Processing', 'Holding'};
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Handler function to create NotesAndAttachment objects on inserting corresponding related attachemnts 
    History
    04/05/2015     Dipankar Barman       Created
    25/06/2015     Manish Damle          Added record type and removed the File Name
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        List<NoteOrAttachment__c> noteOrAttachments = new List<NoteOrAttachment__c>();
        try{
            //added for send referral 101 soql
            if (ATTACHMENT_RECORDTYPE_ID==null){
                ATTACHMENT_RECORDTYPE_ID = [Select Id From RecordType Where SObjectType = 'NoteOrAttachment__c' And DeveloperName = 'Attachment'].Id;
            }

            Set<Id> parentIds = new Set<Id>();
            MAP<Id,Attachment> nonCaseParentIds= new MAP<Id,Attachment>();
            system.debug('get attachment :: ' + tp.newList);
            for(Attachment attach : (List<Attachment>)tp.newList){
                //Check to see if Parent Id is a Case Id
                if (((String)attach.ParentId).startsWith(GlobalConstants.CASE_ID_PREFIX)) {
                    parentIds.add(attach.ParentId);
                }else if(attach.ParentId!=null && !((String)attach.ParentId).startsWith(HTML_COMPONENT_PREFIX)) {//added for send referral 101 soql
                    nonCaseParentIds.put(attach.ParentId, attach);
                }
            }
            Map<Id,NoteOrAttachment__c> noteOrAttachmentMapForUpdate = new Map<Id,NoteOrAttachment__c>([SELECT Id, OwnerId, Name, RecordTypeId, CreatedDate, CreatedById,  Attachment_Id__c, Attachment__c, Body__c, CaseArticle__c, CaseNumber__c, Case__c, Category__c, ContentType__c, File_Name__c, IsMinCorroCaseNote__c, IsMinCorroRelated__c, Is_Image__c, PDF_Attachment__c, Privacy__c, Requires_Printing__c, Sequence__c, Type__c, View__c, Attachment_DateTime__c, Conga_Response_PDF_Generated__c, Desktop_Editing__c, Response_PDF__c, Rejection_Comment__c FROM NoteOrAttachment__c WHERE Id IN :nonCaseParentIds.keySet() and CreatedBy.Name=:GlobalConstants.MIN_COR_API_INTEGRATION_USERNAME]);
            system.debug('thisattachment by ::: ' + noteOrAttachmentMapForUpdate );
            for (Id noteOrAttachmentId: noteOrAttachmentMapForUpdate.keySet()){
                NoteOrAttachment__c noteOrAttachment=noteOrAttachmentMapForUpdate.get(noteOrAttachmentId);
                Attachment attach=nonCaseParentIds.get(noteOrAttachmentId);
                noteOrAttachment.Attachment__c=attach.Id;
                noteOrAttachment.Category__c=GlobalConstants.INCOMING;
                noteOrAttachment.ContentType__c=attach.ContentType;
            }


            Map<Id,Case> caseMap = null;//broken in two lines for send referral 101 soql
            if (parentIds.size()>0) caseMap= new Map<Id,Case>([SELECT Id, OwnerId FROM Case WHERE Id IN :parentIds]);
            /*
             * SNSW Changes START: Changes to share case attachments with SNSW
             */
            Map<Id, Id> attachmentVsCase = new Map<Id,Id>();
            /*
             * SNSW Changes END: Changes to share case attachments with SNSW
             */
            for(Attachment attachment: (List<Attachment>)tp.newList){
               //Check to see if Parent Id is a Case Id
               if (((String)attachment.ParentId).startsWith(GlobalConstants.CASE_ID_PREFIX) &&
                     !attachment.Name.contains('DoNotCreateNOA')) {
                    //Create a NoteOrAttachment record
                    NoteOrAttachment__c noteOrAttachment = new NoteOrAttachment__c();
                    noteOrAttachment.Attachment__c        = attachment.Id;
                    noteOrAttachment.Case__c              = attachment.ParentId;
                    noteOrAttachment.Name                 = attachment.Name;
                    noteOrAttachment.Requires_Printing__c = false;
                    noteOrAttachment.OwnerId              = attachment.OwnerId;
                    noteOrAttachment.ContentType__c       = attachment.ContentType;
                    noteOrAttachment.RecordTypeId         = ATTACHMENT_RECORDTYPE_ID;
                    
                    if(noteOrAttachment.Name.length() > 80) {
                     
                     String name = noteOrAttachment.Name;
                     
                     String fileExtension = name.substring(name.lastIndexOf('.'), name.length());
                     name = name.substring(0, 80-fileExtension.length());
                     noteOrAttachment.Name = name+fileExtension;
                    }
                    noteOrAttachments.add(noteOrAttachment);
                    /*
                     * SNSW Changes START: Changes to share case attachments with SNSW
                     */
                    if(!attachment.IsPartnerShared) {
                        System.debug(LoggingLevel.INFO, 'Attachment is not shared by partner');
                        attachmentVsCase.put(attachment.Id, attachment.ParentId);
                    } else if(caseMap.get(attachment.ParentId) != null) {
                        noteOrAttachment.OwnerId = caseMap.get(attachment.ParentId).OwnerId;
                    }
                    /*
                     * SNSW Changes END: Changes to share case attachments with SNSW
                     */
               }   
            }
            if(!noteOrAttachmentMapForUpdate.isEmpty()) update noteOrAttachmentMapForUpdate.values();
            
            //insert NoteOrAttachments
            System.debug(LoggingLevel.INFO, 'Number of custom attachments to create: ' + noteOrAttachments.size());
            if (!noteOrAttachments.isEmpty() && !S2SAttachmentShareStatusRetriever.shareAttachment) insert noteOrAttachments;
            /*
             * SNSW Changes START: Changes to share case attachments with SNSW
             */
            System.debug(LoggingLevel.INFO, 'Current attachment share status flag: ' + S2SAttachmentShareStatusRetriever.shareAttachment);
            if(!attachmentVsCase.isEmpty() && S2SAttachmentShareStatusRetriever.shareAttachment) {
                System.debug(LoggingLevel.INFO, 'Sharing ' + attachmentVsCase.size() + ' attachments.');
                List<ApexClass> batchClass = [SELECT Id FROM ApexClass WHERE Name = 'ShareAttachmentsBatch'];

                List<AsyncApexJob> existingJobs = [ SELECT Id, Status 
                                                    FROM AsyncApexJob 
                                                    WHERE Status IN :inProgressJobStatus
                                                        AND ApexClassId = :batchClass[0].Id];
                if(existingJobs.isEmpty()) {
                    System.debug(LoggingLevel.INFO, 'Execute batch to share attachments');
                    ShareAttachmentsBatch shareAttBatch = new ShareAttachmentsBatch();
                    System.scheduleBatch(shareAttBatch, 'Share attachments with SNSW',  5);
                }
            }
            /*
             * SNSW Changes END: Changes to share case attachments with SNSW
             */
        }catch(Exception e){
            system.debug('-----AttachmentAfterInsertTriggerHandler Exception---' + e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='AttachmentAfterInsertTriggerHandler';
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