/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Before Delete handler class for the Case trigger
               
Test Class:    CaseTriggerDispatcher_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
08/05/2015     Manish Damle       Created
-----------------------------------------------------------------------------------------*/
public without sharing class CaseBeforeDeleteTriggerHandler extends TriggerHandlerBase {
    List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Delete all child Action Plans and Note Or Attahchments records
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    18/05/2015     Manish Damle       Created
     -------------------------------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try {
            system.debug('-----Case Before Delete Trigger Handler--------');
            if(tp.oldMap != null) {
                //Get all Notes and Attachments
                list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c Where Case__c IN: tp.oldMap.keySet()];
                delete attachments;
                //Get Parent/Child Action Plans
                list <Action_Plan__c> actionPlans = [Select Id From Action_Plan__c Where Parent_Case__c IN: tp.oldMap.keySet()];
                delete actionPlans;
                
                list <Case> childCases = [Select Id, MultiAgency__c, ParentId From Case Where ParentId IN: tp.oldMap.keySet() And MultiAgency__c = true];
                system.debug('-----Child Cases----' +  childCases);
                for(Case c: childCases) {
                    c.MultiAgency__c = false;
                    c.ParentId = null;
                }
                update childCases;
                system.debug('-----Child Cases Multi Issue Flag Updated----');
            }
        }catch(Exception e) {
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseBeforeDeleteTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.newMap!=null)  message.referenceInfo=JSON.serialize(tp.newMap.keySet());
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