/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   After Update handler class for the Draft trigger
               
Test Classes:    DraftTriggerDispatcher_Test
                 ByPassMAGSEditor_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
03/06/2015     Manish Damle       Created
10/10/2016     Arxxus             Updated changeTheCaseStatusWhenDraftIsInApprovel method
25/10/2017     Arxxus             Oct release - Solution to identify Cases which are MO Amended.
23/04/2018     Ian Fitzgerald     Added processing for signed/unsigned draft (generateSmartCorroPdf). 
24/05/2018     Ian Fitzgerald     Updated processing for signed/unsigned draft (split out 
                                  methods processWorkItemCases and processSubmitCases).
-----------------------------------------------------------------------------------------*/
public without sharing class DraftAfterUpdateTriggerHandler extends TriggerHandlerBase{
    public class testException extends Exception {}
    //TH1__Draft__c
    public static boolean corroGenerated = FALSE;
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('DraftAfterUpdateTriggerHandler. This is an example for reentrant code...');
    }
    
    private void process(TriggerParameters tp) {
        //Added by Ian F.  23/04/2018
        system.debug('DraftAfterUpdateTriggerHandler.process DraftAfterUpdateTriggerHandler.corroGenerated : '+DraftAfterUpdateTriggerHandler.corroGenerated);
        if (tp!=null && DraftAfterUpdateTriggerHandler.corroGenerated==FALSE){
            system.debug('Before generateUnsignedCorro tp.newList[0] : '+tp.newList[0]);
            
            generateUnsignedCorro(tp);
        }
        //End added by Ian F.  23/04/2018
        try {
          
          changeTheCaseStatusWhenDraftIsInApprovel(tp);
        } 
        catch(Exception e) {
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
            
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='DraftAfterUpdateTriggerHandler';
            message.sourceFunction='process';
            
            if (tp!=null && tp.newMap!=null) message.referenceInfo=JSON.serialize(tp.newMap.keySet());
            
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
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method is responsible for changing the status of the case when Draft is
                   in approval process.
                   1. If draft status equals Senior Review | Editor Review | Manager Review then case status shoud be Awaiting Approval
                   2. If draft status equals Ready For Printing then case status should be Ready For Printing (Removed - WI-1068)
                   3. If draft status equals MAGS Approved then case status shoud be MAGS Approved
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    03/06/2015     Manish Damle       Created
    10/10/2016     Arxxus             Update to include MAGS Approved status change automation
    25/09/2017     Arxxus             Draft Amended Date/Time stamp added
    -------------------------------------------------------------------------------------*/
    private void changeTheCaseStatusWhenDraftIsInApprovel(TriggerParameters tp) {
        
        Map<Id,Case> caseIdsVscasesToBeUpdated = new Map<Id,Case>();
        Set <Id> parentCaseId = new Set<Id>();
        
        for(TH1__Draft__c draft : (List <TH1__Draft__c>) tp.newList) {
            if(draft.Related_Lookup_Case__c != NULL) {
                parentCaseId.add(draft.Related_Lookup_Case__c);             
            }
        }
        
        if(parentCaseId.size() > 0) {
            
            Map <Id, Case> cases = new Map<Id, Case>([Select Id, Status From Case Where Id IN: parentCaseId]);
            
            for(TH1__Draft__c draft : (List<TH1__Draft__c>) tp.newList) {
            
                TH1__Draft__c newDraft = (TH1__Draft__c) tp.newMap.get(draft.Id);
                TH1__Draft__c oldDraft = (TH1__Draft__c) tp.oldMap.get(draft.Id);

                if(newDraft.Related_Lookup_Case__c != null) {

                    if(newDraft.Status__c != oldDraft.Status__c 
                        && GlobalConstants.draftStatus.contains(newDraft.Status__c)
                        && cases.containsKey(newDraft.Related_Lookup_Case__c)) {

                        caseIdsVscasesToBeUpdated.put(newDraft.Related_Lookup_Case__c,new Case(Id = newDraft.Related_Lookup_Case__c, Status = newDraft.Status__c));
                    } 
                    else if(newDraft.Status__c != oldDraft.Status__c
                             && newDraft.Status__c == GlobalConstants.DRAFT_RESPONSE_STATUS_MIN_CORRO
                             && cases.containsKey(newDraft.Related_Lookup_Case__c) 
                             && cases.get(newDraft.Related_Lookup_Case__c).Status != GlobalConstants.DRAFT_IN_PROGRESS_MIN_CORRO) {
                        
                        //casesToBeUpdated.add(new Case(Id = newDraft.Related_Lookup_Case__c, Status = GlobalConstants.DRAFT_IN_PROGRESS_MIN_CORRO));
                        caseIdsVscasesToBeUpdated.put(newDraft.Related_Lookup_Case__c,new Case(Id = newDraft.Related_Lookup_Case__c, Status = GlobalConstants.DRAFT_IN_PROGRESS_MIN_CORRO));         
                    }
                    else if(newDraft.Status__c != oldDraft.Status__c
                             && newDraft.Status__c == GlobalConstants.MAGS_Approved_MIN_CORRO
                             && cases.containsKey(newDraft.Related_Lookup_Case__c) 
                             && cases.get(newDraft.Related_Lookup_Case__c).Status != GlobalConstants.MAGS_Approved_MIN_CORRO) {
                        
                        caseIdsVscasesToBeUpdated.put(newDraft.Related_Lookup_Case__c,new Case(Id = newDraft.Related_Lookup_Case__c, Status = GlobalConstants.MAGS_Approved_MIN_CORRO));                  
                    }
                    if(newDraft.Approval_Status__c != oldDraft.Approval_Status__c){
                        Datetime draftAmended = newDraft.Approval_Status__c == GlobalConstants.DRAFT_APPROVAL_STATUS_REJECTED ? System.now() : NULL;
                        if(caseIdsVscasesToBeUpdated.containskey(newDraft.Related_Lookup_Case__c)) {
                            Case caseRec = caseIdsVscasesToBeUpdated.get(newDraft.Related_Lookup_Case__c);
                            caseRec.Date_Time_Draft_Rejected__c = draftAmended;
                            caseIdsVscasesToBeUpdated.put(newDraft.Related_Lookup_Case__c,caseRec);
                        }else{
                            Case caseRec = caseIdsVscasesToBeUpdated.get(newDraft.Related_Lookup_Case__c);
                            caseIdsVscasesToBeUpdated.put(newDraft.Related_Lookup_Case__c,new Case(Id = newDraft.Related_Lookup_Case__c, Date_Time_Draft_Rejected__c = draftAmended));
                        }
                    }
                }  
            }
            if(caseIdsVscasesToBeUpdated.size() > 0)
             update caseIdsVscasesToBeUpdated.values();
           
        }
    }
    
    /*************************************************************************
     Generates an unsigned pdf when draft goes to "Mags Approved" by editing the Draft XML to 
     remove the signature.  The existing Draft XML is backed up to be used later to generated 
     the signed corro
     Ian F. 23/04/2018
    ***************************************************************************/
    private void generateUnsignedCorro(TriggerParameters tp){
        List<Id> caseIds = new List<Id>();
        List<Id> attIds = new List<Id>();
        List<Id> draftIds = new List<Id>();
        List<TH1__Draft__c> approvedDrafts = new List<TH1__Draft__c>();
        
        system.debug('In generateUnsignedCorro tp.newList[0] : '+tp.newList[0]);
        for(TH1__Draft__c draft : (List<TH1__Draft__c>) tp.newList) {
            TH1__Draft__c newDraft = (TH1__Draft__c) tp.newMap.get(draft.Id);
            TH1__Draft__c oldDraft = (TH1__Draft__c) tp.oldMap.get(draft.Id);
            
            system.debug('In generateUnsignedCorro newDraft.Status__c : '+newDraft.Status__c);
            system.debug('In generateUnsignedCorro loop oldDraft.Related_Lookup_Case__c : '+oldDraft.Related_Lookup_Case__c);
            
            if (newDraft.Status__c=='MAGS Approved' && oldDraft.Status__c!='MAGS Approved'){
                caseIds.add(newDraft.Related_Lookup_Case__c);
                attIds.add(newDraft.TH1__Draft_XML_Attachment_Id__c);
                draftIds.add(newDraft.Id);
                approvedDrafts.add(newDraft);
            }
        }
        system.debug('In generateUnsignedCorro caseIds after loop : '+caseIds);
        system.debug('In generateUnsignedCorro attIds after loop : '+attIds);
        system.debug('In generateUnsignedCorro approvedDrafts after loop : '+approvedDrafts);
        if (draftIds.size()>0){
            DraftAfterUpdateTriggerHandler.corroGenerated=TRUE;
            backupDraftXML(approvedDrafts, caseIds, attIds);
            if(!System.isFuture() && !System.isBatch()){
                system.debug('In generateUnsignedCorro calling generateSmartCorroPdf');
                generateSmartCorroPdf(draftIds);
            }
            else{
                system.debug('In generateUnsignedCorro generateSmartCorroPdf did not execute due to future or batch');
            }
        }
    }
    
    //Delete any existing backed up Draft XML and back up current Draft XML
    @TestVisible
    private void backupDraftXML(List<TH1__Draft__c> drafts, List<Id> caseIds, List<Id> attIds ){
        List<Attachment> upsertList = new List<Attachment>();
        
        //Delete any existing Draft XML backups on these Cases   
        List<Attachment> draftXMLList = [select Id from Attachment where ParentId in :caseIds and Name = 'Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA'];
        if (draftXMLList!=null && draftXMLList.size()>0){
            delete draftXMLList;
        }
        
        List<Attachment> draftXMLAttachments = [select Id, ContentType, Body, ParentId from Attachment where Id in :attIds];
        
        for (Attachment draftXMLAttachment: draftXMLAttachments){
        	//Update draft XML to remove signature tag if it exists so that unsigned corro can be generated
            String draftXML =  draftXMLAttachment.body.toString();
            if (draftXML.indexOf('{{IMAGE:CASE_SIGNATURE_IMAGE_URL:W=300:H=100}}')>0){
                TH1__Draft__c parentDraft = (TH1__Draft__c)Trigger.newMap.get(draftXMLAttachment.ParentId);
                //Backup existing XML
                Attachment backupXML = new Attachment(ContentType=draftXMLAttachment.ContentType, Body=draftXMLAttachment.Body, ParentId = parentDraft.Related_Lookup_Case__c, Name = 'Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA');
                upsertList.add(backupXML);
                  
                //Remove Signature place-holder from Draft XML
                draftXML = draftXML.replace('{{IMAGE:CASE_SIGNATURE_IMAGE_URL:W=300:H=100}}',
                              '');                
                draftXMLAttachment.body = Blob.valueOf(draftXML);
                upsertList.add(draftXMLAttachment);
            }
        }
        //update the existing draft and insert the backed up draft XML in the same upsert
        if (upsertList.size()>0){
            upsert upsertList;
        }
    }
    
    @TestVisible
    @future(callout=true)
    private static void generateSmartCorroPdf(List<Id> draftIds){
        system.debug('generateSmartCorroPdf::Start');
        
        List<Id> caseIds= new List<Id>();
        List<Id> targetCaseIds = new List<Id>();
        Set<Id> tempCaseIds = new Set<Id>();
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        List<NoteOrAttachment__c> updateNoA = new List<NoteOrAttachment__c>();
        
        try{
            List<TH1__Draft__c> draftList = [select Id, Related_Lookup_Case__c, TH1__Draft_XML_Attachment_Id__c from TH1__Draft__c
                                             where Id in :draftIds];
             
            DateTime createdAfter = Datetime.Now();
             
            for (TH1__Draft__c draft : draftList){
                if(Test.isRunningTest()==false){
                    TH1.GLOBAL_API_V1.finaliseDraft(draft.Id);
                }
                else{
                    Case c = [select Id, subject from Case where Id =:draft.Related_Lookup_Case__c limit 1];
                    if (c.subject=='Throw Test Exception'){
                        throw (new testException('Test exception finalising draft'));
                    }
                    else{
                        //insert a dummy response for test purposes
                        Attachment attach = new Attachment();    
                        attach.Name = 'Response_Dummy_unsigned.pdf';
                        Blob bodyBlob = Blob.valueOf('Dummy SC PDF Response');
                        attach.body = bodyBlob;
                        attach.parentId = draft.Related_Lookup_Case__c;
                        insert attach;
                        //insert a dummy backup XML for test purposes
                        Attachment attach2 = new Attachment();    
                        attach2.Name = 'Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA';
                        bodyBlob = Blob.valueOf('Dummy XML');
                        attach2.body = bodyBlob;
                        attach2.parentId = draft.Related_Lookup_Case__c;
                        insert attach2;
                    }
                }
                caseIds.add(draft.Related_Lookup_Case__c);
            }
                           
            //Find auto-generated related custom NoteOrAttachment__c record
            List<NoteOrAttachment__c> relatedNoteOrAttachmentRecord = [SELECT Name, Category__c, Attachment_Id__c, Attachment__c
                                                                       FROM NoteOrAttachment__c
                                                                       WHERE Name like 'Response_%'
                                                                       AND Case__c in: caseIds
                                                                       AND CreatedDate > :createdAfter];
              
                                                                       
            if(relatedNoteOrAttachmentRecord!=null && relatedNoteOrAttachmentRecord.size() > 0) {
                for (NoteOrAttachment__c NoA : relatedNoteOrAttachmentRecord){
                    NoA.Category__c = GlobalConstants.UNSIGNED_RESPONSE;
                    NoA.Response_PDF__c = TRUE;
                    updateNoA.add(NoA);
                }
                update updateNoA;
            }
            
            //Replace Draft XML with original XML with signature tag
            List<Attachment> draftXMLList = [select Id, ParentId, Body from Attachment where ParentId in :caseIds and Name = 'Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA'];
            System.debug('createAuthorisationRecordAndUpdateSignatureURL draftXMLList : '+draftXMLList);
            
            if (draftXMLList!=null && draftXMLList.size()>0) 
            {
                Map<Id,Blob> backupDraftMap = new Map<Id,Blob>();
                for (Attachment draftXML : draftXMLList){
                    backupDraftMap.put(draftXML.ParentId, draftXML.body);
                }
            
                List<Attachment> draftXMLAttachments = new List<Attachment>();
                for (TH1__Draft__c draft : draftList){
                    Blob backupXML = backupDraftMap.get(draft.Related_Lookup_Case__c);
                    if (backupXML!=null){
                        draftXMLAttachments.add(new Attachment(Id=draft.TH1__Draft_XML_Attachment_Id__c, Body=backupXML));
                    }
                }
            
                update draftXMLAttachments;
            
                delete draftXMLList;
            }
            
            system.debug('generateSmartCorroPdf::Create Approval Process');
            //Create Approval Process
            User loggedInUser = [SELECT Id, Role_Dev_Name__c FROM User WHERE Id =: UserInfo.getUserId() limit 1];
            
            Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId, Response_Type__c, Status, Signatory__c, MO_User__c, Signatory_Person__c, doNotUseApprovalProcess__c
                                                       FROM Case WHERE Id in: caseIds]);
            
            List<ProcessInstanceWorkitem> currentUserworkItems = [SELECT Id, ProcessInstanceId, ActorId FROM ProcessInstanceWorkitem 
                                                                  WHERE ProcessInstance.TargetObjectId =: caseIds AND ActorId =: UserInfo.getUserId() limit 1 ];            
            
            
            Map<Id, Case> workitemCaseMap = new Map<Id, Case>(); 
            Map<Id, Case> submitCaseMap = new Map<Id, Case>();
            for ( Id caseId : caseIds){                                            
                 Case targetTempCase = caseMap.get(caseId);
                 //Ignore Cases where Response Type is 'Referred to other portfolio'
                 if(targetTempCase.Response_Type__c != GlobalConstants.CASE_RESPONSE_TYPE_ADMIN_REFERRAL) 
                 {
                    if(currentUserworkItems.size() > 0 &&
                       targetTempCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE &&
                       targetTempCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE &&
                       targetTempCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE &&
                       targetTempCase.MO_User__c != NULL &&
                       GlobalConstants.MO_DLO_AND_PA_ROLE_NAMES.contains(loggedInUser.Role_Dev_Name__c)) 
                    {
                        workitemCaseMap.put(targetTempCase.Id, targetTempCase);
                    }
                    else if (targetTempCase.doNotUseApprovalProcess__c==false){
                        if(!Approval.isLocked(targetTempCase)){
                        	submitCaseMap.put(targetTempCase.Id, targetTempCase);
                        }
                    }
                 }
            }
            
            if (workitemCaseMap.size()>0){
                processWorkItemCases(workitemCaseMap);
            }
            
            if (submitCaseMap.size()>0){
                processSubmitCases(submitCaseMap);
            }
        }
        catch(Exception e){
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'DraftAfterUpdateTriggerHandler';
            message.sourceFunction = 'generateSmartCorroPdf';
            message.logMessage = e.getMessage();
            message.referenceInfo = e.getStackTraceString();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages, true);
            messages.clear();
            
            //Replace Draft XML with original XML with signature tag
            List<TH1__Draft__c> draftList = [select Id, Related_Lookup_Case__c, TH1__Draft_XML_Attachment_Id__c from TH1__Draft__c
                                                 where Id in :draftIds];
             
            for (TH1__Draft__c draft : draftList){        
                caseIds.add(draft.Related_Lookup_Case__c);
            }     
                              
            List<Attachment> draftXMLList = [select Id, ParentId, Body from Attachment where ParentId in :caseIds and Name = 'Draft_XML_Backup_@098765ABCDEFG_DoNotCreateNOA'];
            System.debug('createAuthorisationRecordAndUpdateSignatureURL **EXCEPTION** draftXMLList : '+draftXMLList);
            
            if ((draftXMLList!=null && draftXMLList.size()>0) || Test.isRunningTest()){
                Map<Id,Blob> backupDraftMap = new Map<Id,Blob>();
                for (Attachment draftXML : draftXMLList){
                    backupDraftMap.put(draftXML.ParentId, draftXML.body);
                }
            
                List<Attachment> draftXMLAttachments = new List<Attachment>();
                for (TH1__Draft__c draft : draftList){
                    Blob backupXML = backupDraftMap.get(draft.Related_Lookup_Case__c);
                    if (backupXML!=null){
                        draftXMLAttachments.add(new Attachment(Id=draft.TH1__Draft_XML_Attachment_Id__c, Body=backupXML));
                    }
                }
         
                if (draftXMLAttachments.size()>0){
                    update draftXMLAttachments;
                }
            
                delete draftXMLList;
            }
        
        }
        system.debug('generateSmartCorroPdf::END');
    }//END method generateSmartCorroPdf
    
    //case is in MO Contact approval and needs auto-approval as they have generated new revised doc. using thunderhead
    //also checking that logged in user who has revised the draft is DLO/PA user only
    //may come in this flow from Mark for Desktop Editing button
    @TestVisible
    private static void processWorkItemCases(Map<Id,Case> workitemCaseMap){
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();                                               
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ActorId, ProcessInstance.TargetObjectId
                                                   FROM ProcessInstanceWorkitem
                                                   WHERE ProcessInstance.TargetObjectId in: workitemCaseMap.keySet()
                                                   AND ActorId =: UserInfo.getUserId()];   
                                                      
        Map<Id, ProcessInstanceWorkitem> approvalMap = new Map<Id, ProcessInstanceWorkitem>();
        for (ProcessInstanceWorkitem item : workItems){
            approvalMap.put(item.ProcessInstance.TargetObjectId, item);
        }
        system.debug('processWorkItemCases::approvalMap : '+approvalMap);

        for ( Case targetTempCase : workitemCaseMap.values()){
            ProcessInstanceWorkitem workItem = approvalMap.get(targetTempCase.Id);
            
            if( workItem!=null){
                Approval.ProcessWorkitemRequest appReq = new Approval.ProcessWorkitemRequest();
                appReq.setWorkitemId(workItem.Id);
                appReq.setAction('Approve');
                requests.add(appReq);
            }
            else{
                workitemCaseMap.remove(targetTempCase.Id);
            }
        }
        
        if (requests.size()>0){
            Approval.ProcessResult[] processResults = Approval.process(requests);
            
            for (Approval.ProcessResult result : processResults){
                if (!result.isSuccess()) {
                    ApplicationLogMessage message = new ApplicationLogMessage();
                    message.source = 'DraftAfterUpdateTriggerHandler';
                    message.sourceFunction = 'processWorkItemCases';
                    message.referenceId = result.getEntityId();
                    message.logMessage = 'Mo Contact Auto Approval failed: ' + processResults[0].getErrors()[0];
                    message.debugLevel = GlobalConstants.ERROR;
                    messages.add(message);
                }
            }
                                   
            // Unlock the cases
            Approval.UnlockResult[] lrList = Approval.unlock(new List<Id>(workitemCaseMap.keyset()), false);
                                   
            // Iterate through each returned result
            for (Approval.UnlockResult lr: lrList) {
                if (!lr.isSuccess()) {
                    // Operation failed, so get all errors                
                    for (Database.Error err: lr.getErrors()) {
                        ApplicationLogMessage message = new ApplicationLogMessage();
                        message.source = 'DraftAfterUpdateTriggerHandler';
                        message.sourceFunction = 'processWorkItemCases';
                        message.referenceId = lr.getId();
                        message.logMessage = 'Approval auto-unlock failed: ' + err.getMessage();
                        message.debugLevel = GlobalConstants.ERROR;
                        messages.add(message);
                    }
                }
            }
            if (messages.size()>0){
                ApplicationLogUtility.logMessage(messages);
                messages.clear();
            }
        }
    }//END Method processWorkItemCases
    
    private static void processSubmitCases(Map<Id,Case> submitCaseMap){
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        List<Id> unlockCaseIds = new List<Id>();
        List<Case> updateCaseOwner = new List<Case>();
        
        for (Case submitCase : submitCaseMap.values()){
             Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
             tempReq.setComments('Submitting response for approval');
             tempReq.setObjectId(submitCase.Id);
                               
             if((submitCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE &&
                 submitCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE &&
                 submitCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) &&
                 submitCase.MO_User__c != NULL) 
             {
                 tempReq.setSubmitterId(submitCase.MO_User__c);
             }
             system.debug('generateSmartCorroPdf:: tempReq '+tempReq);  
             
            if(!Approval.isLocked(submitCase.Id))
            	approvalRequests.add(tempReq);
             unlockCaseIds.add(submitCase.Id);
        }//end Case for-loop
        
        if (approvalRequests.size()>0){
            Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);
            system.debug('generateSmartCorroPdf:: processResults '+processResults); 
            for(Approval.ProcessResult tempProcessResult: processResults) {
                system.debug('generateSmartCorroPdf:: tempProcessResult.isSuccess() '+tempProcessResult.isSuccess());
                system.debug('generateSmartCorroPdf:: tempProcessResult.getEntityId() '+tempProcessResult.getEntityId());
                if(!tempProcessResult.isSuccess()) {
                    ApplicationLogMessage message = new ApplicationLogMessage();
                    message.source = 'DraftAfterUpdateTriggerHandler';
                    message.sourceFunction = 'processSubmitCases';
                    message.referenceId = tempProcessResult.getEntityId();
                    message.logMessage = 'Approval auto-submission failed: ' + tempProcessResult.getErrors()[0];
                    message.debugLevel = GlobalConstants.ERROR;
                    messages.add(message);
                }
            }
            System.debug('processSubmitCases unlockCaseIds '+unlockCaseIds);
           
            Approval.UnlockResult[] lrList = Approval.unlock(unlockCaseIds, false);
            
            System.debug('Approval.UnlockResult '+lrList[0]);
            // Iterate through each returned result
            for(Approval.UnlockResult lr: lrList) {                                     
                if (!lr.isSuccess()) {                                           
                // Operation failed, so get all errors                
                    for (Database.Error err: lr.getErrors()) {
                        ApplicationLogMessage message = new ApplicationLogMessage();
                        message.source = 'DraftAfterUpdateTriggerHandler';
                        message.sourceFunction = 'generateSmartCorroPdf';
                        message.referenceId = lr.getId();
                        message.logMessage = 'Approval auto-unlock failed: ' + err.getMessage();
                        message.debugLevel = GlobalConstants.ERROR;
                        messages.add(message);
                    }
                }
            }
           
        }//end if approvalRequests.size()>0
        
        //Need to retrieve the Case again as it has been updated by the Approval Process
        List<Case> targetCaseList = [SELECT OwnerId, Signatory__c, Signatory_Person__c, MO_User__c FROM Case WHERE Id in :submitCaseMap.keyset()];
        
        for (Case targetCase : targetCaseList){    
            System.debug('DraftAfterUpdateTriggerHandler:processSubmitCases update owner for-loop CaseId: '+targetCase.Id);     
            System.debug('DraftAfterUpdateTriggerHandler:processSubmitCases update owner for-loop Signatory: '+targetCase.Signatory__c); 
            System.debug('DraftAfterUpdateTriggerHandler:processSubmitCases update owner for-loop MO_User: '+targetCase.MO_User__c);                      
            System.debug('DraftAfterUpdateTriggerHandler:processSubmitCases update owner for-loop OwnerId: '+targetCase.OwnerId);
            if((targetCase.Signatory__c == GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE ||
                targetCase.Signatory__c == GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE ||
                targetCase.Signatory__c == GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) &&
                targetCase.Signatory_Person__c != NULL &&
                targetCase.OwnerId != targetCase.Signatory_Person__c) 
            {
                targetCase.OwnerId = targetCase.Signatory_Person__c;
                updateCaseOwner.add(targetCase);
            }
            else if (targetCase.Signatory__c != '' && targetCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE &&
                     targetCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE &&
                     targetCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE &&
                     targetCase.MO_User__c != NULL && targetCase.OwnerId != targetCase.MO_User__c) 
            {
                targetCase.OwnerId = targetCase.MO_User__c;
                updateCaseOwner.add(targetCase);
            }
        }//end targetCaseList for-loop
        
        if (updateCaseOwner.size()>0){
            update updateCaseOwner;
        }
        
        if (messages.size()>0){
             ApplicationLogUtility.logMessage(messages);
             messages.clear();
        }
    }//END processSubmitCases
}