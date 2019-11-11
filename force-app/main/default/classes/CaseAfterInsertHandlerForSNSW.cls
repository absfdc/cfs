public without sharing class CaseAfterInsertHandlerForSNSW extends TriggerHandlerBase {
    private static Id sharedCaseOwner;
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {

    }

    private void process(TriggerParameters tp) {
        try {
            Set<Id> caseIDs = new Set<Id>();
            for(Case caseRecord: (List<Case>) tp.newList) {
                caseIDs.add(caseRecord.Id);
            }
            DryUpdateSharedCases.updateCases(caseIDs);
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'CaseAfterInsertHandlerForSNSW';
            message.sourceFunction = 'process';
            if (tp!=null && tp.newMap!=null) message.referenceInfo = JSON.serialize(tp.newMap.keySet());
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
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