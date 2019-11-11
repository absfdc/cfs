/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    Helper class for creating action plan for a case.
Inputs:         "emails" - advice request mails which needs to be processed to create action plan
Test Class:     ActionPlanCreator_Test
History:
------------------------------------------------------------*/
public with sharing class ActionPlanCreator {

    private Map<Id, Case> caseRecords;
    private List<EmailMessage> emails;
    private set <Id> queuesSupportingActionPlan;
    list <ApplicationLogMessage> messages = new list <ApplicationLogMessage>();
    map <Id, String> queues = new map <Id, String>();
    Id cfmActionPlanRecordTypeId = null;
    
    public ActionPlanCreator(List<EmailMessage> emails) {
        if(emails == null || emails.isEmpty()) {
            throw new InvalidParameterException('Failed to create action plan. Email details missing');
        }
        
        this.emails = emails;
        Set<Id> caseIds = new Set<Id>();
        queuesSupportingActionPlan = new set <Id>();
        
        for(EmailMessage message : this.emails) {
            if(!String.isBlank(message.ParentId)) {
                caseIds.add(message.ParentId);
            }
        }
        
        caseRecords = new Map<Id, Case> ([Select Id, Taxonomy_Moment__c, Taxonomy_Symptom__c, Taxonomy_Transaction__c,Description, Subject, Priority, CaseNumber,
                                                 Taxonomy_Area__c, Taxonomy_Location__c, Taxonomy_Location_Type__c, OwnerId, Modes__c,Agency__c,Branch__c,ContactId,
                                                 Taxonomy_Symptom_Id__c, Taxonomy_Location_Id__c
                                          From Case
                                          Where Id IN :caseIds]);
        //fetch all the Queues who support Action Plan Object.
        for(QueueSobject obj :  [Select QueueId, SObjectType 
                                 From QueueSobject 
                                 Where SObjectType = 'Action_Plan__c']) {
            queuesSupportingActionPlan.add(obj.QueueId);
        }
        
        for(Group g : [Select Id, Name From Group Where Type = 'Queue']) {
            queues.put(g.Id, g.Name);
        }
        //CFM Action Plan Record Type: added by Manish Damle on 20/05/2015
        cfmActionPlanRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME limit 1].Id;
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Function creates new action plan with New status on sending advice request email for a case.
    Inputs:         
    Returns:        List<Action_Plan__c> - list of action plans that are created for advice requests sent
    History:
    ------------------------------------------------------------*/
    public List<Action_Plan__c> createAdviceRequestPlans() {
        List<Action_Plan__c> adviceRequestPlans = new List<Action_Plan__c>();
        
        for(EmailMessage message :emails) {
            if(!String.isBlank(message.ParentId) && caseRecords.get(message.ParentId) != null) {
                adviceRequestPlans.add(createActionPlan(message, caseRecords.get(message.ParentId)));
            }
        }
        
        if(messages.size() > 0) {
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
        }
        return adviceRequestPlans;
    }
    
    private Action_Plan__c createActionPlan(EmailMessage message, Case caseRecord) {
        Action_Plan__c actionPlan = new Action_Plan__c();
        actionPlan.Status__c = GlobalConstants.ACTION_PLAN_NEW_STATUS;
        actionPlan.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        actionPlan.SME_Email__c = message.ToAddress;
        actionPlan.Parent_Case__c = caseRecord.Id;
        actionPlan.Mode__c = caseRecord.Modes__c;
        actionPlan.Location_Level_3__c = caseRecord.Taxonomy_Location__c;
        actionPlan.Location_Level_2__c = caseRecord.Taxonomy_Area__c;
        actionPlan.Location_Level_1__c = caseRecord.Taxonomy_Location_Type__c;
        actionPlan.Issue_Level_3__c = caseRecord.Taxonomy_Symptom__c;
        actionPlan.Issue_Level_2__c = caseRecord.Taxonomy_Transaction__c;
        actionPlan.Issue_Level_1__c = caseRecord.Taxonomy_Moment__c;   
        actionPlan.RecordTypeId = cfmActionPlanRecordTypeId;
        actionPlan.Branch__c=caseRecord.Branch__c;
        actionPlan.Agency__c = caseRecord.Agency__c;
        actionPlan.Customer__c =  caseRecord.ContactId;
        actionPlan.Issue_Level_3_Id__c = caseRecord.Taxonomy_Symptom_Id__c;
        actionPlan.Location_Level_3_Id__c = caseRecord.Taxonomy_Location_Id__c;
        if(((String) caseRecord.OwnerId).startsWith(GlobalConstants.USER_ID_PREFIX)) {
            actionPlan.OwnerId = caseRecord.OwnerId; //Case Owner is a user 
        } else if(((String) caseRecord.OwnerId).startsWith(GlobalConstants.GROUP_ID_PREFIX) && queuesSupportingActionPlan.contains(caseRecord.OwnerId)){
            actionPlan.OwnerId = caseRecord.OwnerId; //Case Owner is a queue
        } else {
            actionPlan.OwnerId = UserInfo.getUserId(); //Action Plan Owner is current user
            String missingQueueName = queues.containsKey(caseRecord.OwnerId) ? queues.get(caseRecord.OwnerId) : 'Id:' + caseRecord.OwnerId;
            ApplicationLogMessage logMessage= new ApplicationLogMessage();
            logMessage.source='ActionPlanCreator';
            logMessage.sourceFunction='CreateActionPlan';
            logMessage.payLoad = '\nCase Number: ' + caseRecord.CaseNumber +
                          '\nSubject: '     +  caseRecord.Subject +
                          '\nDescription: ' + caseRecord.Description +
                          '\nPriority: ' + caseRecord.Priority + '\n\n New Advise Request from Case created an Action Plan record with missing queue : ' + missingQueueName;
            
            logMessage.debugLevel = GlobalConstants.WARNING;
            messages.add(logMessage);
        }
        return actionPlan;
    }
    
    public class InvalidParameterException extends Exception {}
}