/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    Action_PlanTriggerDispatcher_Test
History
04/05/2015     Manish Damle       Created
03/05/2017     Ian Fitzgerald     Added check to see if no. of Action Plans on a Case had
                                  changed before updating the Case
------------------------------------------------------------*/
public without sharing class ActionPlanAfterUpdateTriggerHandler extends TriggerHandlerBase {
    @TestVisible
    static Set<Id> firstTimers{get;set;}//the Ids that came first time
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('ActionPlanAfterUpdateTriggerHandler: This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Handler function to call the sharing handler
    
    History
    04/05/2015     Manish Damle       Created
    07/05/2015     Vishnu Belkone     Updated
                                      Added actionPlanPDF generator functionality.
    02/07/2015     Brett Cawrse       Write customer response to case on approval
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            if(firstTimers!=null && firstTimers.equals(tp.newMap.keySet())){
                system.debug('rerunning after workflow exiting');
                return;
            }else{
               system.debug('first time setting Ids');

               firstTimers= new Set<Id>();
               firstTimers.addAll(tp.newMap.keySet());
            }
            set <Id> parentActionPlans = new set <Id> ();
            MAP <Id,Case> casesToBeUpdated = new MAP <Id,Case> ();
            system.debug('---ActionPlanAfterUpdateTriggerHandler---');
            changeTheCaseStatusBasedOnTheAPStatus(tp);
            Set<Id> changedOwners = new Set<Id>();
            Id cfmActionPlanRecordTypeId=Action_PlanTriggerDispatcher.actionPlanRecordTypes.get( GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME);
            Map<Id,Id> caseIdByClosedActionPlanId =  new Map<Id,Id> ();
            ActionPlanSharingHandler sharingHandler = new ActionPlanSharingHandler();
            for(Action_Plan__c ap : (list <Action_Plan__c>) tp.newList) {
                Action_Plan__c newAp = (Action_Plan__c) tp.newMap.get(ap.Id);
                Action_Plan__c oldAp = (Action_Plan__c) tp.oldMap.get(ap.Id);
                if(oldAp.OwnerId != newAp.OwnerId ) {
                    if (newAp.Owner_Is_User__c && newAp.Parent_Action_Plan__c == null) parentActionPlans.add(newAp.Id);
                    changedOwners.add(ap.Id);
                }
                if(newAP.Type__c == GlobalConstants.ACTION_PLAN_CUST_RESP && 
                    (oldAp.Status__c != newAp.Status__c && newAp.Status__c == GlobalConstants.ACTION_PLAN_NEW_APPROVED)){
                    //newly approved customer facing response; write it to case
                    if (!casesToBeUpdated.containsKey(newAp.Parent_Case__c)){
                        casesToBeUpdated.put(newAp.Parent_Case__c,new Case(Id = newAp.Parent_Case__c, Customer_Facing_Response__c = newAp.Response__c));
                    }else{
                        Case aCase=casesToBeUpdated.get(newAp.Parent_Case__c);
                        aCase.Customer_Facing_Response__c = newAp.Response__c;
                    }
                }
                system.debug('------@Case Status Change---' + oldAp.Status__c + ' -- ' + ap.Status__c + '--' + ap.Type__c + '-' + ap.Parent_Case__c);
                //update the parent case status if this action plan is advice request and for cfm, and new
                if(oldAp.Status__c != GlobalConstants.ACTION_PLAN_CLOSED_STATUS && 
                   ap.Status__c == GlobalConstants.ACTION_PLAN_CLOSED_STATUS && 
                   ap.Type__c == GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST && 
                   ap.Parent_Case__c != null && 
                   ap.RecordTypeId == cfmActionPlanRecordTypeId){
                    caseIdByClosedActionPlanId.put(ap.Id,ap.Parent_Case__c);                    
                }
            }
            system.debug('------@Case Status Change---' + caseIdByClosedActionPlanId);
            //fetch Cases with closed action plans which are in status awaiting advice, with related other child CFM action plans which are not closed, if no such other action plans exists we can change the status of the case
            if (caseIdByClosedActionPlanId.size()>0){
                for(Case aCase:[select Id, Status,
                (select Id, Status__c from Action_Plans__r where Type__c = :GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST and RecordTypeId = :cfmActionPlanRecordTypeId and Id not in: caseIdByClosedActionPlanId.keySet() and Status__c !=:GlobalConstants.ACTION_PLAN_CLOSED_STATUS) 
                from Case where Id in:caseIdByClosedActionPlanId.values() and status=:GlobalConstants.CASE_STATUS_AWAITING_ADVICE])
                {
                    system.debug('------@Case Status Change-ap--' + aCase.Action_Plans__r.size());
                    if (aCase.Action_Plans__r.size()==0) {
                        if (!casesToBeUpdated.containsKey(aCase.Id)){
                            casesToBeUpdated.put(aCase.Id,new Case(Id = aCase.Id, Status = GlobalConstants.CASE_STATUS_ADVICE_RECEIVED));
                        }else{
                            Case thisCase=casesToBeUpdated.get(aCase.Id);
                            thisCase.Status = GlobalConstants.CASE_STATUS_ADVICE_RECEIVED;
                        }
                    }
                } 
            }
            
            
            //fetch child action plans and share them with new owner
            list <Action_Plan__c>  childActionPlans = [Select Id, Name, Parent_Action_Plan__c, OwnerId 
                                                       From Action_Plan__c 
                                                       Where Parent_Action_Plan__c IN: parentActionPlans];
            sharingHandler.share(childActionPlans);
            
            //Calculate the number of active action plans
            map <Id, Integer> parentVsChildCount = ActionPlanUtility.createCaseVsNoOfActionPlansMap((list <Action_Plan__c>) tp.newList);
            
            //03/05/2017 Ian Fitzgerald retrieve existing number of Action PLans on the Cases
            Map<Id, Case> caseActionPlanCountMap;
            if (parentVsChildCount.size()>0){
                caseActionPlanCountMap = new Map<Id, Case>([Select Id, NoOfActiveActionPlans__c from Case where Id in :parentVsChildCount.keySet()]);
            }
            
            for(Id caseId : parentVsChildCount.keySet()) {
                 //03/05/2017 Ian Fitzgerald check if number of Action PLans on the Case has changed
                Case currentCase = caseActionPlanCountMap.get(caseId);
                if (currentCase.NoOfActiveActionPlans__c!=parentVsChildCount.get(caseId)){
                    if (!casesToBeUpdated.containsKey(caseId)){
                        casesToBeUpdated.put(caseId,new Case(Id = caseId, NoOfActiveActionPlans__c = parentVsChildCount.get(caseId)));
                    }else{
                        Case aCase=casesToBeUpdated.get(caseId);
                        aCase.NoOfActiveActionPlans__c = parentVsChildCount.get(caseId);
                    }
                }
            }
            
            system.debug('ActionPlanAfterUpdateTriggerHandler.tp.newList -'+tp.newList);
            list <AP_NoteOrAttachment__c> relatedAttachemnts=[select Id, Note_Attachment__c,Action_Plan__c from AP_NoteOrAttachment__c where Action_Plan__c in: changedOwners];
            if (relatedAttachemnts.size()>0) {
                NoteOrAttachmentSharingHandler handler= new NoteOrAttachmentSharingHandler();
                handler.shareWithActionPlanOwners(relatedAttachemnts);
            }
        
            if(casesToBeUpdated.size() > 0)
                update casesToBeUpdated.values();
            
            ActionPlanPDFGenerator actionPlanPdfG = new ActionPlanPDFGenerator();
            actionPlanPdfG.generateActionPlanPDF(tp);
            
            List<Action_Plan__c> childAPs = new List<Action_Plan__c>();
            for(Action_Plan__c ap : (List<Action_Plan__c>) tp.newList) {
                if(!String.isBlank(ap.Parent_Action_Plan__c) 
                    && GlobalConstants.ACTION_PLAN_CLOSED_STATUS.equalsIgnoreCase(ap.Status__c)) {
                    childAPs.add(ap);
                }
            }
            if(!childAPs.isEmpty()) {
                ChildActionPlanCounter childCounter = new ChildActionPlanCounter(childAPs);
                childCounter.updateChildActionPlanCounter();
            }
            stampDateFirstChildAssignedOnParent(tp);
            sendEmailNotificationToAPOwnerOnChildAPStatusChange(tp);
        }catch(Exception e){
            system.debug('-----Action Plan After Update Trigger Exception---' + e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanAfterUpdateTriggerHandler';
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
    Description: AP Status     | Case Status
                ---------------------------------   
                 Not Completed | Awaiting Advice  (If any AP is not completed)
                 Completed     | Draft in Progress (If all the AP's are completed)
    
    History
    01/06/2015     Manish Damle       Created
    12/08/2015     Manish Damle       Added check for null parent case.
    ------------------------------------------------------------*/
    private void changeTheCaseStatusBasedOnTheAPStatus(TriggerParameters tp) {
         list <Case> casesToBeUpdated = new list <Case> ();
         map <Id, Integer> parentVsChildCount = ActionPlanUtility.createCaseVsNoOfActionPlansMap((List<Action_plan__c>) tp.newList, null);

         for(Action_plan__c anAp:(List<Action_plan__c>) tp.newList) {      
            Action_plan__c newAp = (Action_plan__c) tp.newMap.get(anAp.Id);      
            Action_plan__c oldAp = (Action_plan__c) tp.oldMap.get(anAp.Id);
            //Skip the action plan if parent case is null
            if(newAp.Parent_Case__c == null) continue;
            //Skip the action plan if record type is CFM
            if(newAp.RecordTypeId == Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME)) continue;

            system.debug('---------New Action Plan Status------' + newAp.Status__c);
            system.debug('---------Old Action Plan Status------' + oldAp.Status__c);
            system.debug('---------Parent Action Plan Status------' + newAp.Parent_Case__c);
            system.debug('---------parentVsChildCount.size()------' + parentVsChildCount.size());      
            if(ActionPlanUtility.skipStatuses.contains(newAp.Status__c) 
                && !ActionPlanUtility.skipStatuses.contains(oldAp.Status__c)
                && newAp.Parent_Case__c != null
                && parentVsChildCount.containsKey(newAp.Parent_Case__c)
                && parentVsChildCount.get(newAp.Parent_Case__c) > 0) {
                system.debug('---------Case Status Changed To AWAITING_ADVICE_MIN_CORRO------');                
                casesToBeUpdated.add(new Case(Id = anAp.Parent_Case__c, Status = GlobalConstants.AWAITING_ADVICE_MIN_CORRO));       
            } else if(ActionPlanUtility.skipStatuses.contains(newAp.Status__c) 
                       && !ActionPlanUtility.skipStatuses.contains(oldAp.Status__c)
                       && newAp.Parent_Case__c != null
                       && (parentVsChildCount.size() == 0 || (parentVsChildCount.containsKey(newAp.Parent_Case__c) 
                                                                && parentVsChildCount.get(newAp.Parent_Case__c) == 0))) {

                    system.debug('---------Case Status Changed To DRAFT_IN_PROGRESS_MIN_CORRO------'); 
                    
                    String parentStatus = GlobalConstants.DRAFT_IN_PROGRESS_MIN_CORRO;
                    if(GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT.equalsIgnoreCase(newAp.Status__c)) parentStatus = GlobalConstants.RESEARCH_STATUS_MIN_CORRO;
                    system.debug('Status of Action Plan: ' + newAp.Status__c);
                    system.debug('Status to updated on Parent Case: ' + parentStatus);
                    
                    casesToBeUpdated.add(new Case(Id = anAp.Parent_Case__c, Status = parentStatus));   //DRAFT_IN_PROGRESS_MIN_CORRO
            } else if(newAp.Status__c != oldAp.Status__c && !ActionPlanUtility.skipStatuses.contains(newAp.Status__c)){
                system.debug('---------Case Status Changed To DRAFT_IN_PROGRESS_MIN_CORRO1------'); 
                casesToBeUpdated.add(new Case(Id = anAp.Parent_Case__c, Status = GlobalConstants.AWAITING_ADVICE_MIN_CORRO));      
            }           
         }
         
         update casesToBeUpdated;
    } 
        
    private void stampDateFirstChildAssignedOnParent(TriggerParameters tp) {
        Set<Id> parentIds = new Set<Id>();
        for(Action_Plan__c ap : (List<Action_Plan__c>) tp.newList) {
            if(!String.isBlank(ap.Parent_Action_Plan__c) && GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(ap.Status__c) 
                    && ((Action_Plan__c)tp.oldMap.get(ap.Id)).Status__c != ap.Status__c) {
                parentIds.add(ap.Parent_Action_Plan__c);
            }
        }
        
        if(!parentIds.isEmpty()) {
            StampDateFirstChildAssignedOnParent parentUpdater = new StampDateFirstChildAssignedOnParent(parentIds);
            parentUpdater.stampDate(); 
        }
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Send email notification to PAP owner when child action plan status is changed.
    History
    02/10/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    private void sendEmailNotificationToAPOwnerOnChildAPStatusChange(TriggerParameters tp) {
       try {
            if(Action_PlanTriggerDispatcher.preventEmailResending == false) {
                Id childActionPlanRecordTypeId = Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.CHILD_AP_RECORDTYPE_API_NAME);
                List <Messaging.SingleEmailMessage> emails = new list <Messaging.SingleEmailMessage>();
                for(Action_Plan__c ap : (List<Action_Plan__c>) tp.newList) {
                    Action_plan__c oldAp = (Action_plan__c) tp.oldMap.get(ap.Id);
                    if(ap.Status__c == GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT || ap.Status__c == GlobalConstants.ACTION_PLAN_NEW_APPROVED)
                        continue;
                    
                    if(oldAp.status__c != ap.Status__c && 
                        childActionPlanRecordTypeId == ap.RecordTypeId && 
                        ap.Parent_AP_Owner_Id__c != UserInfo.getUserId()) {    
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setTargetObjectId(Id.valueOf(ap.Parent_AP_Owner_Id__c));
                        email.setWhatId(ap.Id);
                        email.setOrgWideEmailAddressId(Action_PlanTriggerDispatcher.noReplyOrgWideEmailAddressId);
                        email.setTemplateId(Action_PlanTriggerDispatcher.childAPStatusChangedEmailTemplate.Id);
                        email.setSaveAsActivity(false);
                        emails.add(email);
                    }
                }
                Messaging.sendEmail(emails);
                System.debug('-------Email Sent-----');
                Action_PlanTriggerDispatcher.preventEmailResending = true;
            }
        }Catch(Exception e) {
            System.debug('-------Exception-----' + e.getMessage());
            Throw(e);
        }
    }
}