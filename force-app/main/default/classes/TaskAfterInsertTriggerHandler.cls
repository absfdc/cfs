/*------------------------------------------------------------
Author:        Brett Cawrse
Company:       Salesforce
Description:   After Insert handler class for the task tp
                 

Test Class:    taskTriggerDispatcher_Test,TaskAfterInsertTriggerHandler_Test
History
14 Apr 2015      Brett Cawrse     created
------------------------------------------------------------*/
public class TaskAfterInsertTriggerHandler extends TriggerHandlerBase{
    public override void mainEntry(TriggerParameters tp) {
        system.debug('hello world');
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

    /*------------------------------------------------------------
    Author:        Brett Cawrse
    Company:       Salesforce.com
    Description:   Requirement (WI 460)
    // Whenever an activity (Task) is logged against a Case, based on the "Call Status" custom field on the Task record, the following should happen:
    // If "Call Status" equals 'Left a message' or 'Call went unanswered', set the parent case "Contact Attempted Timestamp" field to current date and time (now()).
    // If "Call Status" equals 'Contacted' or 'Letter sent out', set the parent Case "Contact Made Timestamp" field to current date and time (now())
    // However, if any of the above fields are populated already earlier, do NOT overwrite them. Leave them as they are.

    Inputs:        Trigger context parameters

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20/08/2015 Manish Damle         Updated. WI-0000986
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{            
            
            map <Id,Case> casesToBeUpdated = new map<Id, Case>();
            Set<Id> caseIds = new Set<Id>();
            Set<Id> contactMadeCases = new Set<Id>();
            Set<Id> contactAttemptedCases = new Set<Id>();
            Set<Id> logCallOnCases = new Set<Id>();
    
            for (Task currentTask : (List<Task>)tp.newList) {
                if(currentTask.Call_Status__c != null) {
                    if (currentTask.Call_Status__c.equals(GlobalConstants.TASK_CALL_STATUS_LEFT_MESSAGE) || currentTask.Call_Status__c.equals(GlobalConstants.TASK_CALL_STATUS_CALL_UNANSWERED)) {
                        contactAttemptedCases.add(currentTask.WhatId);
                    } else if (currentTask.Call_Status__c.equals(GlobalConstants.TASK_CALL_STATUS_CONTACTED) || currentTask.Call_Status__c.equals(GlobalConstants.TASK_CALL_STATUS_LETTER_SENT)) {
                        contactMadeCases.add(currentTask.WhatId);
                    }   
                }
                //Log a call activity will set the Recent Activity Flag to false
                if(currentTask.Subject == 'Call' || currentTask.Subject == 'Call log') {
                    logCallOnCases.add(currentTask.WhatId);
                }
            }
            system.debug('contactAttemptedCases -'+contactAttemptedCases);
            system.debug('contactMadeCases -'+contactMadeCases);

            system.debug('logCallOnCases -'+logCallOnCases);

            system.debug('tp.newMap.keySet() -'+tp.newMap.keySet());
            Set<String> STA_AND_NEWCASTLE_AGENCY = new Set<String>{GlobalConstants.STA_AGENCY, GlobalConstants.NEWCASTLE_TRANSPORT_AGENCY};
            if (contactAttemptedCases.size()>0){
                for (Case caseWithStaUnansweredTask :[select Id, ownerAgency__c,
                                                            (select Id,Call_Status__c 
                                                             from Tasks 
                                                             where Id in:tp.newMap.keySet() and Call_Status__c='Call went unanswered') 
                                                    from Case 
                                                    where Id in: contactAttemptedCases and ownerAgency__c IN: STA_AND_NEWCASTLE_AGENCY]){
                    if (caseWithStaUnansweredTask.tasks!=null && caseWithStaUnansweredTask.tasks.size()>0 ) contactAttemptedCases.remove(caseWithStaUnansweredTask.Id);
                    system.debug('removed case id-'+caseWithStaUnansweredTask.Id);
                }
            }
            system.debug('contactAttemptedCases -'+contactAttemptedCases);
            system.debug('contactMadeCases -'+contactMadeCases);

            system.debug('logCallOnCases -'+logCallOnCases);

            caseIds.addAll(contactAttemptedCases);
            caseIds.addAll(contactMadeCases);
            caseIds.addAll(logCallOnCases);

            if(!caseIds.isEmpty()) 
        {
                List<Case> cases = [SELECT Id, Contact_Attempted_Timestamp__c, RecentActivityFlag__c, Contact_Made_Timestamp__c from CASE where Id =:caseIds];
                for(Case caseRecord: cases) {
                    boolean updateCaseRecord = false;
                    if (caseRecord.Contact_Attempted_Timestamp__c == null && contactAttemptedCases.contains(caseRecord.Id)) {   
                        caseRecord.Contact_Attempted_Timestamp__c = System.now();  
                        updateCaseRecord = true;
                    } else if (caseRecord.Contact_Made_Timestamp__c == null && contactMadeCases.contains(caseRecord.Id)) {
                        caseRecord.Contact_Made_Timestamp__c = System.now();   
                        updateCaseRecord = true;
                    }
                    
                    if(logCallOnCases.contains(caseRecord.Id)) {
                        caseRecord.RecentActivityFlag__c = false;
                        updateCaseRecord = true;
                    }
                    
                    if(updateCaseRecord){
                        casesToBeUpdated.put(caseRecord.Id, caseRecord);
                    }
                }
            }

            if(!casesToBeUpdated.isEmpty()) {
                system.debug('casesToBeUpdated -'+casesToBeUpdated.values());

                update casesToBeUpdated.values();
            }
            
        }catch(Exception e){
            System.debug(e);
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='TaskAfterInserTriggerHandler';
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