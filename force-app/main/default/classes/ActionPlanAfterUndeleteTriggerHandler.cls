/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    Action_PlanTriggerDispatcher_Test
History
04/05/2015     Manish Damle       Created
------------------------------------------------------------*/
public without sharing class ActionPlanAfterUndeleteTriggerHandler extends TriggerHandlerBase {
    
  	List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Handler function to call the sharing handler
    
    History
    04/05/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            list <Case> casesToBeUpdated = new list <Case> ();
            system.debug('---ActionPlanAfterUndeleteTriggerHandler---');
            ActionPlanSharingHandler sharingHandler = new ActionPlanSharingHandler();
            sharingHandler.share((list <Action_Plan__c>) tp.newList);
            map <Id, Integer> parentVsChildCount = ActionPlanUtility.createCaseVsNoOfActionPlansMap((list <Action_Plan__c>) tp.oldList);
            for(Id caseId : parentVsChildCount.keySet()) {
				casesToBeUpdated.add(new Case(Id = caseId, NoOfActiveActionPlans__c = parentVsChildCount.get(caseId)));                    
            }
            list <AP_NoteOrAttachment__c> relatedAttachemnts=[select Id, Note_Attachment__c,Action_Plan__c from AP_NoteOrAttachment__c where Action_Plan__c in: tp.newMap.keySet()];
            if (relatedAttachemnts.size()>0) {
                NoteOrAttachmentSharingHandler handler= new NoteOrAttachmentSharingHandler();
                handler.shareWithActionPlanOwners(relatedAttachemnts);
            }
            if(casesToBeUpdated.size() > 0)
            	update casesToBeUpdated;
            
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanAfterUndeleteTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.oldMap!=null)  message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel='Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear(); 
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
            	Throw(e);
            }
        }
    }
}