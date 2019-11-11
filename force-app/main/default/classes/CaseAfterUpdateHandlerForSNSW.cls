public without sharing class CaseAfterUpdateHandlerForSNSW extends TriggerHandlerBase {
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {

    }

    private void process(TriggerParameters tp) {
        try {
            List<Case> cases = (List<Case>) tp.newList;
            Map<Id,Case> oldMap = (Map<Id, Case>) tp.oldMap;
            List<Case> sharedCases = new List<Case>();
            Map<Id, Id> casesToShare = new Map<Id,Id>();
            for(Case caseRecord : cases) {
                if(caseRecord.Shared__c && !oldMap.get(caseRecord.Id).Shared__c) {
                    sharedCases.add(caseRecord);
                    casesToShare.put(caseRecord.Id, null);
                }
            }
            
            List<CaseComment> commentsToShare = new List<CaseComment>();
            for(CaseComment comment : [ SELECT Id, IsPublished, ConnectionReceivedId FROM CaseComment 
                                        WHERE ParentId IN :sharedCases 
                                            AND IsPublished = false ]) {
                if(comment.ConnectionReceivedId == null) {
                    comment.IsPublished = true;
                    commentsToShare.add(comment);
                }                                 
            }            
            
            //Make case comments public so as to share with SNSW via S2S interface
            if(!commentsToShare.isEmpty()) {
                update commentsToShare;
            }
            
            //Share case with SNSS via S2S interface
            if(!casesToShare.isEmpty()) {
                S2SConnectionHelper.shareRecord(casesToShare, GlobalConstants.S2S_CONNECTION_NAME);
            }
            
            //Share case attachments if any
            CaseAttachmentsSharedWithSNSW sharingInstance = new CaseAttachmentsSharedWithSNSW((List<Case>) tp.newList);
            sharingInstance.shareAttachments();
            
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source = 'CaseAfterUpdateHandlerForSNSW';
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
}