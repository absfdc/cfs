/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    Action_PlanTriggerDispatcher_Test
History
01/06/2015     Manish Damle       Created
------------------------------------------------------------*/
public class ActionPlanAfterDeleteTriggerHandler extends TriggerHandlerBase {
    
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    private void process(TriggerParameters tp) {
        try {
            list <Case> casesToBeUpdated = new list <Case> ();
            map <Id, Integer> parentVsChildCount = ActionPlanUtility.createCaseVsNoOfActionPlansMap((list <Action_Plan__c>) tp.oldList);
            for(Id caseId : parentVsChildCount.keySet()) {
                casesToBeUpdated.add(new Case(Id = caseId, NoOfActiveActionPlans__c = parentVsChildCount.get(caseId)));                    
            }
            
            if(casesToBeUpdated.size() > 0)
                update casesToBeUpdated;
            
            List<Action_Plan__c> childActionPlans = new List<Action_Plan__c>();
            for(Action_Plan__c ap : (List<Action_Plan__c>) tp.oldList) {
                if(!String.isBlank(ap.Parent_Action_Plan__c)) {
                    childActionPlans.add(ap);
                }
            }
            if(!childActionPlans.isEmpty()) {
                ChildActionPlanCounter childCounter = new ChildActionPlanCounter(childActionPlans);
                childCounter.updateChildActionPlanCounter();
            }
            
        } catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanAfterDeleteTriggerHandler';
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