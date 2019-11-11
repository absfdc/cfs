public without sharing class DraftBeforeUpdateTriggerHandler  extends TriggerHandlerBase{
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    private void process(TriggerParameters tp) {
        try {
            for(TH1__Draft__c draft : (list <TH1__Draft__c>) tp.newList) {
                System.debug('-----Submitted For Approval----' + draft.Submited_For_Approval__c);
                if(draft.Submited_For_Approval__c 
                    && DraftTriggerDispatcher.magsRoles.containsKey(UserInfo.getUserRoleId())
                    && GlobalConstants.MAGS_ROLE_NAMES_VS_DRAFT_STATUS.containsKey(DraftTriggerDispatcher.magsRoles.get(UserInfo.getUserRoleId()))) {
                    draft.Status__c = GlobalConstants.MAGS_ROLE_NAMES_VS_DRAFT_STATUS.get(DraftTriggerDispatcher.magsRoles.get(UserInfo.getUserRoleId()));
                    draft.Submited_For_Approval__c = false;
                    System.debug('-----Submitted For Approval New Status----' + draft.Status__c);
                }
            }
            
        } catch(Exception e){
            list <ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='DraftBeforeUpdateTriggerHandler';
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