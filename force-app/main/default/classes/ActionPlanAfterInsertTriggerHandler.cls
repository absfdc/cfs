/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    Action_PlanTriggerDispatcher_Test
History
04/05/2015     Manish Damle       Created
------------------------------------------------------------*/
public without sharing class ActionPlanAfterInsertTriggerHandler extends TriggerHandlerBase {
    
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
    06/05/2015     Vishnu Belkone     Updated
                                      Added actionPlanPDF generator functionality.
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            list <Case> casesToBeUpdated = new list <Case> ();
            system.debug('---ActionPlanAfterInsertTriggerHandler---');
            ActionPlanSharingHandler sharingHandler = new ActionPlanSharingHandler();
            sharingHandler.share((list <Action_Plan__c>) tp.newList);
            //Calculate the number of active action plans
            map <Id, Integer> parentVsChildCount = ActionPlanUtility.createCaseVsNoOfActionPlansMap((list <Action_Plan__c>) tp.newList);
            for(Id caseId : parentVsChildCount.keySet()) {
                casesToBeUpdated.add(new Case(Id = caseId, NoOfActiveActionPlans__c = parentVsChildCount.get(caseId)));                    
            }
             //update the parent case status if this action plan is advice request and for cfm, and new
            Id cfmActionPlanRecordTypeId=Action_PlanTriggerDispatcher.actionPlanRecordTypes.get( GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME);
            for(Action_Plan__c ap : (list <Action_Plan__c>) tp.newList) {
                if(ap.Parent_Case__c != null && ap.RecordTypeId == cfmActionPlanRecordTypeId && ap.Status__c == GlobalConstants.ACTION_PLAN_NEW_STATUS && ap.Type__c == GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST){
                    casesToBeUpdated.add(new Case(Id = ap.Parent_Case__c, Status = GlobalConstants.CASE_STATUS_AWAITING_ADVICE));                    
                }
            }
            if(casesToBeUpdated.size() > 0)
                update casesToBeUpdated;
            
            ActionPlanPDFGenerator actionPlanPdfG = new ActionPlanPDFGenerator();
            actionPlanPdfG.generateActionPlanPDF(tp);
            
            List<Action_Plan__c> childActionPlans = new List<Action_Plan__c>();
            for(Action_Plan__c ap : (List<Action_Plan__c>) tp.newList) {
                if(!String.isBlank(ap.Parent_Action_Plan__c)) {
                    childActionPlans.add(ap);
                }
            }
            if(!childActionPlans.isEmpty()) {
                ChildActionPlanCounter childCounter = new ChildActionPlanCounter(childActionPlans);
                childCounter.updateChildActionPlanCounter();
            }
            
            Set<Id> parentCaseIds = new Set<Id>();
            for(Action_Plan__c ap : (List<Action_Plan__c>) tp.newList) {
                parentCaseIds.add(ap.Parent_Case__c);
            }
            if(!parentCaseIds.isEmpty()) {
                TimeWithAdminCalculator calculator = new TimeWithAdminCalculator(parentCaseIds);
                calculator.calculate();
            }
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanAfterInsertTriggerHandler';
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