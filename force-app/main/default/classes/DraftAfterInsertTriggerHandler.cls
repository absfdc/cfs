/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   After Insert handler class for the Draft trigger
               
Test Class:    DraftTriggerDispatcher_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
25/06/2015     Manish Damle       Created
-----------------------------------------------------------------------------------------*/
public without sharing class DraftAfterInsertTriggerHandler extends TriggerHandlerBase {

    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    private void process(TriggerParameters tp) {
        try {
            //changeCaseStatusToDraftInProgress(tp);
        } catch(Exception e){
            list <ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='DraftAfterInsertTriggerHandler';
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
    Description:   Whenever new draft is created then case status should be changed to Draft in Progress
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    25/06/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    private void changeCaseStatusToDraftInProgress(TriggerParameters tp) {
        list <Case> casesToBeUpdated = new list <Case> ();
        set <Id> parentCaseId = new set <Id> ();
        for(TH1__Draft__c draft : (list <TH1__Draft__c>) tp.newList) {
            if(draft.Related_Lookup_Case__c != null) {
                parentCaseId.add(draft.Related_Lookup_Case__c);             
            }
        }
        
        if(parentCaseId.size() > 0) {
            map <Id, Case> cases = new map <Id, Case>([Select Id, Status From Case Where Id IN: parentCaseId]);
            for(TH1__Draft__c draft : (list <TH1__Draft__c>) tp.newList) {
                if(draft.Related_Lookup_Case__c != null 
                   && cases.containsKey(draft.Related_Lookup_Case__c) 
                   && cases.get(draft.Related_Lookup_Case__c).Status != GlobalConstants.DRAFT_IN_PROGRESS_MIN_CORRO) {
                    casesToBeUpdated.add(new case(Id = cases.get(draft.Related_Lookup_Case__c).Id, Status = GlobalConstants.DRAFT_IN_PROGRESS_MIN_CORRO ));
                }
            }
            
            if(casesToBeUpdated.size() > 0)
                update casesToBeUpdated;
         }
    }
}