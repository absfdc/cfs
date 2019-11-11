/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    Action_PlanTriggerDispatcher_Test
History
04/05/2015     Dipankar Barman       Created
19/04/2017     Ian Fitzgerald        Check conditions in changeActionPlanOwnerToCaseOwnerWhenIncorrectAssignment 
                                     before making SOQL calls to save on limits 
------------------------------------------------------------*/
public without sharing class ActionPlanBeforeUpdateTriggerHandler extends TriggerHandlerBase{

    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
        changeActionPlanOwnerToCaseOwnerWhenIncorrectAssignment(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('ActionPlanBeforeUpdateTriggerHandler: This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Handler function to track response history in a large text area when status waiting for approval
    
    History
    04/05/2015     Dipankar Barman       Created
    22/06/2015     Manish Damle          Added check for completed status of the 
                                         action plan to trach the response history.
    ------------------------------------------------------------*/ 
    private void process(TriggerParameters tp) {
        try{
            system.debug('---ActionPlanBeforeUpdateTriggerHandler---' + Action_PlanTriggerDispatcher.triggerLoopCount);
            if(Action_PlanTriggerDispatcher.triggerLoopCount == 0) { //STATIC VARIABLE TO ALLOW THE CODE TO RUN ONLY ONCE
                system.debug('---ActionPlanBeforeUpdateTriggerHandler Loop count 0---');
                for (Action_plan__c anAp:(List<Action_plan__c>)tp.newList) {
                    //set the business hrs if agency is populated
                    if(anAp.Agency__c != null) anAp.BusinessHours__c = BusinessHoursUtil.getBusinessHour(anAp.Agency__c);
                    Action_plan__c oldAp = (Action_plan__c)tp.oldMap.get(anAp.Id);
                    system.debug('---Response History---' + anAp);  
                    if (anAp.status__c != oldAp.status__c 
                        &&((anAp.status__c.equalsIgnoreCase(GlobalConstants.ACTION_PLAN_WAITING_APPROVAL)
                            || anAp.status__c.equalsIgnoreCase(GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT)
                            || anAp.status__c.equalsIgnoreCase(GlobalConstants.ACTION_PLAN_CLOSED_STATUS)
                            ) 
                                || (anAp.status__c.equalsIgnoreCase(GlobalConstants.ACTION_PLAN_NEW_APPROVED) && !String.isBlank(anAp.Parent_Action_Plan__c)))){
                                    
                        system.debug('---Response History---');                                    
                        String currentText = '<br/>-----------------------------------<br/>' + 
                                             (anAp.response__c == null ? '' : anAp.response__c) + 
                                             '<br/><i>Submitted By - </i>' + 
                                             UserInfo.getName() + 
                                             ' <i>on - </i>' + 
                                             system.now().format() + 
                                             ' <i>Status - </i>' + anAp.Status__c;
                        anAp.ResponseHistory__c = anAp.ResponseHistory__c == null? currentText : currentText + anAp.ResponseHistory__c; 
                        system.debug('---Response History---' + anAp.ResponseHistory__c);              
                        if(anAp.ResponseHistory__c!=null && anAp.ResponseHistory__c.length() > 131071)
                            anAp.ResponseHistory__c = anAp.ResponseHistory__c.substring(0,131071);
                    }
                    
                    //Fix for WI1358 - Assigned sme is removed once the Action Plan is assigned.
                    if(anAp.RecordTypeId == Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME) && anAp.AssignedSme__c != null ) {
                        anAp.ownerId = anAp.AssignedSme__c;
                        anAp.TempAssignedSME__c = anAp.AssignedSme__c;
                        anAp.AssignedSme__c = null;
                    }
                }//for
                
                 //WI-0001584 - Stamp the OldStatus
                for (Action_plan__c anAp :(List<Action_plan__c>)tp.newList){
                    Action_plan__c oldAp = (Action_plan__c) tp.oldMap.get(anAp.Id);
                    anAp.OldStatus__c = oldAp.Status__c;
                    system.debug('-------Changed ap.Status__c-----' + anAp.Status__c);
                    system.debug('-------Changed ap.OldStatus__c-----' + anAp.OldStatus__c);
                }
                
                if(Action_PlanTriggerDispatcher.magsAndCrgsAdminRoles.containsKey(UserInfo.getUserRoleId())) {
                    ActionPlanUtility.stampDueDateOnActionPlan((list <Action_plan__c>) tp.newList);
                }
                Action_PlanTriggerDispatcher.triggerLoopCount ++;
            }
            changeTheOwnershipOfCAPWhenApproved(tp);
            validateChildActionPlansAreClosed(tp);
            
            DateStamperOnStatusChange dateStamper = new DateStamperOnStatusChange((List<Action_Plan__c>) tp.newList, (Map<Id, Action_Plan__c>) tp.oldMap);
            dateStamper.stampDate();
            
            TimeSpentInStatusCalculator calc = new TimeSpentInStatusCalculator((List<Action_Plan__c>) tp.newList, (Map<Id, Action_Plan__c>) tp.oldMap);
            calc.stampTimeSpent();
        }catch(Exception e){ 
            system.debug('-----ActionPlanBeforeUpdateTriggerHandler Exception---' + e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanBeforeUpdateTriggerHandler';
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
        
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Change the owner of the action plan to case owner when status of the action plan
                   changed to "Rejected-Incorrect Assignment".
                   Timebased workflow will be triggered to do this.
    History
    27/05/2015     Manish Damle       Created
    15/07/2015     Manish Damle       Updated the if condition.(WI#1083)        
    19/04/2017     Ian Fitzgerald     Check conditions before making SOQL calls to save on limits                             
    ------------------------------------------------------------*/     
    private void changeActionPlanOwnerToCaseOwnerWhenIncorrectAssignment(TriggerParameters tp) {
        try{
            set <Id> parentCaseIds = new set <Id>();
            for (Action_plan__c anAp:(List<Action_plan__c>) tp.newList) {
                Action_plan__c oldAp = (Action_plan__c) tp.oldMap.get(anAp.Id); 
                if(anAp.Parent_Case__c != null && anAp.Status__c == GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT
                   && oldAp.ReturnToOwner__c!=anAp.ReturnToOwner__c && anAp.ReturnToOwner__c==true) {
                    parentCaseIds.add(anAp.Parent_Case__c);
                }
            }
            
            if(parentCaseIds.size() > 0) {
                map<Id, Case> parentCases = new map <Id, Case> ([Select Id, OwnerId From Case Where Id IN: parentCaseIds]);
                RecordType mcws_AP_recordType = [Select Id From RecordType Where DeveloperName =: GlobalConstants.ACTION_PLAN_MCWS_AP_RECORD_TYPE_NAME limit 1];
                system.debug('----parentCases----' + parentCases);
                for (Action_plan__c anAp:(List<Action_plan__c>) tp.newList) {            
                     Action_plan__c newAp = (Action_plan__c) tp.newMap.get(anAp.Id);      
                     Action_plan__c oldAp = (Action_plan__c) tp.oldMap.get(anAp.Id);  
                     system.debug('----newAp.Status__c----' + newAp.Status__c);
                     system.debug('----oldAp.Status__c----' + oldAp.Status__c);
                     if(anAp.Parent_Case__c != null && parentCases.containsKey(anAp.Parent_Case__c))    {
                        newAp.OwnerId = parentCases.get(anAp.Parent_Case__c).OwnerId;
                        newAp.ReturnToOwner__c = false;
                        newAp.RecordTypeId = mcws_AP_recordType.Id;
                     }
                }
            }
        }catch(Exception e){
            system.debug('-----ActionPlanBeforeUpdateTriggerHandler Exception---' + e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanBeforeUpdateTriggerHandler';
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
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will validate that the child action plan should be closed before closing the parent action plan
    
    History
    27/05/2015     Manish Damle       Created
    ------------------------------------------------------------*/     
    private void validateChildActionPlansAreClosed(TriggerParameters tp) {
        set <Id> parentActionPlans = new set <Id> ();
        for(Action_plan__c anAp : (list <Action_Plan__c>) tp.newList) {
            if(anAp.SkipValidations__c == false && anAp.Parent_Action_Plan__c == null && anAp.Status__c == GlobalConstants.ACTION_PLAN_CLOSED_STATUS) {
                parentActionPlans.add(anAp.Id);
            } 
        }
        
        map <Id, Integer> parentVsChildCount = ActionPlanUtility.createApVsNoOfChildActionPlansMap(null, parentActionPlans);
        for(Id apId : parentVsChildCount.keySet()) {
            if(parentVsChildCount.get(apId) > 0) {
                tp.newMap.get(apId).addError('Action plan cannot be closed. Please close all the linked action plans before closing an action plan');
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Whenever child action Plan is approved then ownership is
                   changed to CO i.e new status = "Action Plan in Progress".
                   #WI-0001645
    History
    12/10/2015     Manish Damle       Created
    19/04/2017     Ian Fitzgerald     Check conditions before making SOQL calls to save on limits  
    ------------------------------------------------------------*/
    private void changeTheOwnershipOfCAPWhenApproved(TriggerParameters tp) {
        map <Id,Id> childApIdVsparentId =  new map <Id, Id>();
        for(Action_plan__c anAp : (list <Action_Plan__c>) tp.newList) {
            Action_plan__c oldAp = (Action_Plan__c) tp.oldMap.get(anAp.Id);
            if(anAp.Status__c != oldAp.Status__c 
               && anAp.Status__c == GlobalConstants.ACTION_PLAN_NEW_APPROVED 
               && anAp.Parent_Action_Plan__c != null) {
                childApIdVsparentId.put(anAp.Id, anAp.Parent_Action_Plan__c); 
            }
        }
        
        System.debug('----@Approved CAPS-----' + childApIdVsparentId);
        
        if(childApIdVsparentId.size() > 0){
            map <Id, Action_Plan__c> parents = new map <Id, Action_Plan__c>([Select Id, OwnerId 
                                                                             From Action_Plan__c 
                                                                             Where Id IN: childApIdVsparentId.values()]);
            System.debug('----@Approved CAPS Parents-----' + parents);
            for(Id key : childApIdVsparentId.keySet()) {
                Action_Plan__c anAp = (Action_Plan__c) tp.newMap.get(key);
                if(parents.containsKey(childApIdVsparentId.get(key))) {
                    anAp.OwnerId = parents.get(childApIdVsparentId.get(key)).OwnerId;
                    System.debug('----@Approved CAPS Owner Updated-----' + anAp.OwnerId);
                }
            }
        }
    }
}