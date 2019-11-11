/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the EmailMessage trigger

Test Class:    EmailMessageTriggerDispatcher_Test
History
16 Mar 2015    Dipankar Barman     created
06/05/2015      Dipankar Barman     Updated 
Updated logic to reopen the case           
------------------------------------------------------------*/
public class EmailMessageBeforeInsertTriggerHandler extends TriggerHandlerBase {
    static String orgId= (String) UserInfo.getOrganizationId();
    static final string WEB_TRIAGE_QUEUE = 'Serco_Web_Triage_CFM';
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    Static final String CASE_REF_REGEX='(?<=(ref:))(.*?)(?=(:ref))';
    List<ApplicationLogMessage> logs =new List<ApplicationLogMessage>();
    
    /*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Handler function creates a task for an outbound
email request seeking advice from sme and if an
email is received on a closed case it conditionally
reopens the closed case if within a duration otherwise
it creates a separate case.
Inputs:        Trigger context parameters

History
<Date>      <Authors Name>     <Brief Description of Change>
------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            List<SMEActivitySubject__c> smeActivitySubjects=[select Id, Name from SMEActivitySubject__c limit 9999];
            String regexPre='(?i).*(';
            String regexPost=').*';
            String regexMid;
            for (SMEActivitySubject__c aSub:smeActivitySubjects){
                regexMid=regexMid==null?aSub.Name:regexMid+'|'+aSub.Name;
            }
            //prepare pre compiled pattern
            String activitySubjectRegex=regexPre+regexMid+regexPost;
            Pattern activitySubjectPattern=Pattern.compile(activitySubjectRegex);
            List<Action_Plan__c> possibleNewActionPlans = new List<Action_Plan__c>(); //list of new advice request action plans
            List<Action_Plan__c> oldActionPlans = new List<Action_Plan__c>(); //list of old action plans to be marked completed based on response
            Map<Id,String> outgoingCaseIdVsSmeEmailId= new Map<Id,String>();//Will fetch all waiting tasks for this cases and this SME
            List<Id> recentlyClosed= new List<Id>();//recently closed cases to be reopened
            //customerResponseCaseIdVsSenderEmailId & incomingCustomerCaseIdVsMessage  are used for incoming customer emails
            Map<Id,String> customerResponseCaseIdVsSenderEmailId= new Map<Id,String> ();//caseid vs message sender email
            Map<Id,EmailMessage> incomingCustomerCaseIdVsMessage= new Map<Id,EmailMessage> ();//caseid vs message
            Map<Id,EmailMessage> caseIdVsSnswReferralResponse = new Map<Id,EmailMessage>();//caseid vs snsw response
            
            //sender email id vs from id of incoming mails from SME's, these emails should have had corresponding old tasks open
            Map<Id,String> incomingCaseIdVsSmeEmailId= new Map<Id,String>();
            Map<Id,String> incomingCaseIdVsSmeEmailResponse = new Map<Id,String>();
            ApplicationLogMessage log;
            List<EmailMessage> listOfAdviceRequestEmails = new List<EmailMessage>();
            Map<Id, EmailMessage> probableResponseToCustomer = new Map<Id, EmailMessage>();
            List<EmailMessage> freshEmailsFromCustomer = new List<EmailMessage>();
            
            for (EmailMessage message:(List<EmailMessage>)tp.newList){
                log= new ApplicationLogMessage();
                log.source='EmailMessageBeforeInsertTriggerHandler';
                log.sourceFunction='process';
                log.debugLevel='Debug';
                log.payLoad='\nMessageDate:'+message.MessageDate+
                    '\nFrom:'+message.FromAddress+
                    '\nTo:'+message.ToAddress+
                    '\nSubject:'+message.Subject+
                    '\nBody:'+message.TextBody+
                    '\nIncoming:'+message.Incoming+
                    '\nMessageDate:'+message.MessageDate+
                    '\nParentId:'+message.ParentId+
                    '\nStatus:'+message.Status;
                
                logs.add(log);
                Boolean matchesActivitySubjectPattern = false;
                if(message.subject!=null){
                    String cleanSubject=message.subject.normalizeSpace();
                    Matcher subjectMatcher= activitySubjectPattern.matcher(cleanSubject);
                    matchesActivitySubjectPattern=subjectMatcher.matches();
                    system.debug('Advice request pattern matches - '+ matchesActivitySubjectPattern + ' message.ToAddress - '+message.ToAddress);
                }
                
                if (message.incoming==false
                    && matchesActivitySubjectPattern==true
                    && message.ParentId.getSObjectType() == Case.sObjectType
                    && !(message.FromAddress.endsWith(GlobalConstants.SNSW_EMAIL_DOMAIN ) 
                         || message.Subject.contains(Label.SNSW_referral_subject))){
                             listOfAdviceRequestEmails.add(message);
                             if (message.ParentId!=null) outgoingCaseIdVsSmeEmailId.put(message.ParentId,message.ToAddress);
                         }else if (!message.incoming
                                   && !matchesActivitySubjectPattern
                                   && message.ParentId.getSObjectType() == Case.sObjectType){
                                       probableResponseToCustomer.put(message.ParentId, message);
                                   }else if (message.incoming==true ){
                                       if (matchesActivitySubjectPattern == true
                                           && !(message.FromAddress.endsWith(GlobalConstants.SNSW_EMAIL_DOMAIN ) 
                                                || message.Subject.contains(Label.SNSW_referral_subject))){
                                                    incomingCaseIdVsSmeEmailId.put(message.parentId,message.fromAddress);
                                                    incomingCaseIdVsSmeEmailResponse.put(message.parentId,message.HtmlBody);
                                                }else {
                                                    //SFCOE-2345 - 19/04/2018 - Defect - Cases not returning to last assigned queue - Start
                                                    /*
string threadId = 'ref:'+ getThreadId(message.ParentId) +':ref'; 
String parentId = message.ParentId;
String caseIdRef = parentId.substring(0,4) + parentId.substring(10,15);
System.debug('Case reference id: ' + caseIdRef);

String subject = message.Subject;

Integer startIndex = subject.lastIndexOf('._');
Integer endIndex = subject.lastIndexOf(':ref');
String subRefStr = null;                        
if((startIndex + 2) < endIndex) {
subRefStr = subject.substring(startIndex + 2, endIndex);
subRefStr = subRefStr.subString(0,4) + subRefStr.subString(5);
System.debug('Reference id from subject: ' + subRefStr);
}


//SFCOE-103 Code Changes by Gary - commenting below code and adding new code for handling Plain Text Emails - start
//String body = message.HtmlBody;

String body = null;
if (message.HtmlBody!= null)
body = message.HtmlBody;
else if (message.TextBody!= null)
body = message.TextBody;

//SFCOE-103 Code Changes by Gary - end


String bodyRefStr = null;

//SFCOE-1893 - 07/04 - Start
startIndex = (body!=null)?body.lastIndexOf('._'):0;
endIndex = (body!=null)?body.lastIndexOf(':ref'):0;

//startIndex = body.lastIndexOf('._');
//endIndex = body.lastIndexOf(':ref');

//SFCOE-1893 - 07/04 - End

if((startIndex + 2) < endIndex) {
bodyRefStr = body.substring(startIndex + 2, endIndex);
bodyRefStr = bodyRefStr.subString(0,4) + bodyRefStr.subString(5);
System.debug('Reference id from body: ' + bodyRefStr);
}

system.debug('---Customer Replied From Address ThreadId---' + threadId);
//if((message.HtmlBody!=null && message.HtmlBody.contains(threadId) )|| (message.Subject!=null && message.Subject.contains(threadId)) ){ //Added check for ref: id in the subject and choose that email only.
if((bodyRefStr != null && bodyRefStr.equals(caseIdRef) )|| (subRefStr != null && subRefStr.equals(caseIdRef)) ){

*/
                                                    //SFCOE-2345 - End
                                                    
                                                    
                                                    system.debug('---ThreadId Message.Subject---' + message.Subject);
                                                    system.debug('---Customer Replied From Address---' + message.FromAddress);
                                                    if(message.ParentId != null){
                                                        if((message.FromAddress.endsWith(GlobalConstants.SNSW_EMAIL_DOMAIN ) 
                                                            || message.Subject.contains(Label.SNSW_referral_subject))) {
                                                                System.debug(LoggingLevel.INFO, 'Response received from SNSW');
                                                                caseIdVsSnswReferralResponse.put(message.ParentId, message);
                                                            } else {
                                                                customerResponseCaseIdVsSenderEmailId.put(message.ParentId, message.FromAddress);
                                                                incomingCustomerCaseIdVsMessage.put(message.ParentId,message);
                                                            }
                                                    }
                                                    else{
                                                        //Log incident in App log where parent id of an inbound email is NULL
                                                        ApplicationLogMessage logNoParentOfEmail = new ApplicationLogMessage();
                                                        logNoParentOfEmail.source='EmailMessageBeforeInsertTriggerHandler';
                                                        logNoParentOfEmail.sourceFunction='process';
                                                        logNoParentOfEmail.debugLevel='Info';
                                                        logNoParentOfEmail.payLoad='\nMessageDate:'+message.MessageDate+
                                                            '\nFrom:'+message.FromAddress+
                                                            '\nTo:'+message.ToAddress+
                                                            '\nSubject:'+message.Subject+
                                                            '\nBody:'+message.TextBody+
                                                            '\nIncoming:'+message.Incoming+
                                                            '\nMessageDate:'+message.MessageDate+
                                                            '\nParentId:'+message.ParentId+
                                                            '\nStatus:'+message.Status;
                                                        logNoParentOfEmail.logMessage='Inbound Email Missing Parent';
                                                        logs.add(logNoParentOfEmail);
                                                    }
                                                }
                                   }
            }
            
            // August 2017 SFCOE-2124 removing method processOutgoingCustomerResponse below
            
            
            /*if(!probableResponseToCustomer.isEmpty()){
processOutgoingCustomerResponse(probableResponseToCustomer);
}*/
            
            if(!caseIdVsSnswReferralResponse.isEmpty()) {
                SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(caseIdVsSnswReferralResponse);
                snswResponseProcessor.processSnswResponses();
            }
            processCustomerResponses(customerResponseCaseIdVsSenderEmailId, incomingCustomerCaseIdVsMessage);
            
            if(!listOfAdviceRequestEmails.isEmpty()) {
                System.debug('List of advice request emails: ' + listOfAdviceRequestEmails.size());
                ActionPlanCreator apCreator = new ActionPlanCreator(listOfAdviceRequestEmails);
                possibleNewActionPlans = apCreator.createAdviceRequestPlans();
                System.debug('Action plan created: ' + possibleNewActionPlans);
            }
            
            //Close off old tasks, on receiopt of response from SME
            Set<Id> casesThatReceivedAdvice = new Set<Id>();
            if (incomingCaseIdVsSmeEmailId.size()>0 ){
                system.debug('incomingCaseIdVsSmeEmailId- '+ incomingCaseIdVsSmeEmailId); 
                //for each old action plan for which we have a response,i.e. email having SME's email Id, and related to cases for which we have received SME response
                for (Action_Plan__c actionPlan:[select Id, Status__c, Type__c, SME_Email__c, Parent_Case__c, Response_time_in_secs__c, CreatedDate,RecordTypeId 
                                                from Action_Plan__c 
                                                where Status__c =:GlobalConstants.ACTION_PLAN_NEW_STATUS 
                                                and Type__c =:GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST 
                                                and SME_Email__c IN :incomingCaseIdVsSmeEmailId.values() 
                                                and Parent_Case__c IN :incomingCaseIdVsSmeEmailId.keySet()]){
                                                    String htmlString = incomingCaseIdVsSmeEmailResponse.get(actionPlan.Parent_Case__c);
                                                    actionPlan.Response__c = HTMLRemover.remove(htmlString);
                                                    actionPlan.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
                                                    actionPlan.Response_time_in_secs__c = ((system.Now().getTime()-actionPlan.CreatedDate.getTime())/1000.00).intValue() ;
                                                    oldActionPlans.add(actionPlan); 
                                                    casesThatReceivedAdvice.add(actionPlan.Parent_Case__c);
                                                }                
                System.debug('Old action plans: ' + oldActionPlans.size());
            }else{
                system.debug('no incomingCaseIdVsSmeEmailId');
            }
            List<Case> casesToUpdateStatus = new List<Case>();/* [  SELECT Id FROM Case 
WHERE Id IN :casesThatReceivedAdvice 
AND Status != :GlobalConstants.CASE_CLOSED_STATUS 
AND Status != :GlobalConstants.CASE_SOFTCLOSED_STATUS];
for(Case caseRecord: casesToUpdateStatus) {
caseRecord.Status = GlobalConstants.CASE_STATUS_ADVICE_RECEIVED;
}*/
            
            if (possibleNewActionPlans.size() > 0) {
                List<Id> caseIdToUpdateInitialAdviceRequestSentOn= new List<Id>();
                Map<Id,Action_Plan__c> caseIdVsWaitingActionPlans= new Map<Id,Action_Plan__c>();
                //get the waiting tasks for same case and SME combination
                List<Action_Plan__c> waitingActionPlanIfAnyForSameCaseAndSME = [select Id, Parent_Case__c,SME_Email__c,Status__c,RecordTypeId 
                                                                                from Action_Plan__c 
                                                                                where Parent_Case__c in :outgoingCaseIdVsSmeEmailId.keySet() 
                                                                                and SME_Email__c in :outgoingCaseIdVsSmeEmailId.values() 
                                                                                and Status__c = :GlobalConstants.ACTION_PLAN_NEW_STATUS 
                                                                                and SME_Email__c != NULL];
                system.debug('waitingActionPlanIfAnyForSameCaseAndSME - '+waitingActionPlanIfAnyForSameCaseAndSME);
                for (Action_Plan__c aWaitingPlan :waitingActionPlanIfAnyForSameCaseAndSME){
                    caseIdVsWaitingActionPlans.put(aWaitingPlan.Parent_Case__c,aWaitingPlan);
                }
                
                //check each possible new ACTION PLAN vs waiting ACTION PLAN    
                Integer ii = 0;
                String additionalCaseDescMessage = '';
                Integer caseDescLength = Case.description.getDescribe().getLength();
                
                While ( ii<possibleNewActionPlans.size()){
                    Action_Plan__c aPossibleNewPlan = possibleNewActionPlans[ii];
                    if (caseIdVsWaitingActionPlans.containsKey(aPossibleNewPlan.Parent_Case__c)&&
                        caseIdVsWaitingActionPlans.get(aPossibleNewPlan.Parent_Case__c).SME_Email__c.equalsIgnoreCase(aPossibleNewPlan.SME_Email__c)){
                            System.debug('About to remove: ' + possibleNewActionPlans[ii]);
                            possibleNewActionPlans.remove(ii);
                        }else{
                            ii++;
                            caseIdToUpdateInitialAdviceRequestSentOn.add(aPossibleNewPlan.Parent_Case__c);
                        }
                }
                
                if (possibleNewActionPlans.size()>0) {
                    insert possibleNewActionPlans;
                    List<Case> casesToUpdateInitialAdviceRequestSentOn = [  Select Id,description,Initial_Advice_Request_Sent_On__c 
                                                                          From Case 
                                                                          Where Id IN :caseIdToUpdateInitialAdviceRequestSentOn
                                                                          AND Status != :GlobalConstants.CASE_CLOSED_STATUS 
                                                                          AND Status != :GlobalConstants.CASE_SOFTCLOSED_STATUS];
                    for(Case aCaseWithAdviceInitiated:casesToUpdateInitialAdviceRequestSentOn){
                        aCaseWithAdviceInitiated.Initial_Advice_Request_Sent_On__c = system.today();
                        aCaseWithAdviceInitiated.Status = GlobalConstants.CASE_STATUS_AWAITING_ADVICE;
                        
                        //SFCOE-2142 - Identifying Action Plans sent to off-system recipients - 13-04-2018 - Start
                        // try{
                        
                        system.debug('Case Record ID: ' + aCaseWithAdviceInitiated.RecordTypeId);
                        system.debug(Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.TAXONOMY_LEVEL_1_ROAD).getRecordTypeId());
                        
                        if(aCaseWithAdviceInitiated.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.TAXONOMY_LEVEL_1_ROAD).getRecordTypeId()){
                            additionalCaseDescMessage = '\n\n' + system.now() + ' - Sent to Offline SME';
                            if ((aCaseWithAdviceInitiated.description + additionalCaseDescMessage).length() > caseDescLength) aCaseWithAdviceInitiated.description = (aCaseWithAdviceInitiated.description + additionalCaseDescMessage).substring(0,caseDescLength-1);
                            aCaseWithAdviceInitiated.description = aCaseWithAdviceInitiated.description + additionalCaseDescMessage;
                            system.debug('Case Description: ' + aCaseWithAdviceInitiated.description);
                        }
                        //   } catch(Exception ex){System.debug('Could not update Case description: ' + ex.getStackTraceString());}
                        //SFCOE-2142 - End
                        
                        
                        casesToUpdateStatus.add(aCaseWithAdviceInitiated);
                    }                    
                }
            }
            
            if(!casesToUpdateStatus.isEmpty()) {
                update casesToUpdateStatus;
            }
            //Update old action plans
            if (oldActionPlans.size() > 0) update oldActionPlans;
            ApplicationLogUtility.logMessage(logs);
            logs.clear();
        }catch(Exception e){
            system.debug('----Caught exception----'+ e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage log= new ApplicationLogMessage();
            log.source='EmailMessageBeforeInsertTriggerHandler';
            log.sourceFunction='process';
            log.logMessage=e.getMessage();
            log.ex=e;
            log.debugLevel='Error';
            logs.add(log);
            ApplicationLogUtility.logMessage(logs);
            logs.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
    // August 2017 SFCOE-2124 removing method to prevent update to Contact_Made_Timestamp__c when an email is sent to customer
    // Existing workflow rule - Update Contact Emailed Timestamp when sending 1st email to Case Contact - already updates the contact_made and contact_emailed timestamp fields on case
    // If method is required in the future, ensure the entitlement completion dates are not impacted
    
    /*
private void processOutgoingCustomerResponse(Map<Id, EmailMessage> outgoingCustomerResponse) {
List<Case> casesToUpdate = new List<Case>();        
for(Case caseRecord : [SELECT Id, Contact.Email, Contact_Made_Timestamp__c FROM Case WHERE Id IN :outgoingCustomerResponse.keySet()]) {
if(caseRecord.Contact_Made_Timestamp__c == null && caseRecord.Contact.Email != null 
&& caseRecord.Contact.Email.toLowerCase() == outgoingCustomerResponse.get(caseRecord.Id).ToAddress.toLowerCase()) {
System.debug('Customer response sent to: ' + caseRecord.Contact.Email);
caseRecord.Contact_Made_Timestamp__c = System.now();
casesToUpdate.add(caseRecord);
}
}
if(!casesToUpdate.isEmpty()) {
update casesToUpdate;
}
}*/
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   1. If status of case = Closed
If last queue assigned != null and last queue assigned still exists,set Owner to last queue assigned
else if owner is active do nothing
else assign to default case owner
2. If status of case = Finalised
create new case with same origin and origin details
and associate the EmailMessage with the new case.
Inputs:        Trigger context parameters

History
<Date>      <Authors Name>     <Brief Description of Change>
06/05/2015  Manish Damle       Created                           
20/08/2015  Manish Damle       Updated code as per the WI-0000986
------------------------------------------------------------*/
    private void processCustomerResponses(Map<Id,String> customerResponseCaseIdVsSenderEmailId, Map<Id,EmailMessage> incomingCustomerCaseIdVsMessage) {
        system.debug('---Process Customer Responses---');
        //reopen old or create new case if mail was from customer
        Map <Id, Case> casesToBeUpdated = new Map <Id,Case> ();
        Map<String, Id> queueNameVsId = new  Map<String,Id>();
        Map<Id,Case>oldIdvsClones = new Map<Id,Case>();//very old case Id vs corresponding cloned cases
        if(customerResponseCaseIdVsSenderEmailId.size() > 0 ) {
            String defaultCaseOwnerId;
            //Get the default owner from custom setting. Query will avoid creation of custom settings in all test classes
            list <CaseObjectConfigurations__c> defaultOwners = [Select Name, Value__c From CaseObjectConfigurations__c Where Name = :GlobalConstants.CASE_OBJECT_CONFIGURATION_NAME_DEFAULT_CASE_OWNER];
            if(defaultOwners.size() > 0) {
                defaultCaseOwnerId = defaultOwners[0].Value__c;
            } else {
                defaultCaseOwnerId = null;
            }
            
            //Get all the Queues with developer name
            for(Group g : [Select Id, DeveloperName From Group Where Type = 'Queue']) {
                queueNameVsId.put(g.DeveloperName, g.Id);
            }
            
            list <Case> existingCases = [Select Id,SuppliedEmail,Contact.Email,CaseNumber, ClosedDate, Case_Resolution_Date__c, OwnerId, Owner.IsActive, RecentActivityFlag__c, OwnerAgency__c,
                                         Description, Status, Origin, ParentId, Agency__c, Subject, Last_Queue_Assigned__c,RecordType.Name
                                         From Case 
                                         Where Id In: customerResponseCaseIdVsSenderEmailId.keySet()
                                         And (SuppliedEmail In :customerResponseCaseIdVsSenderEmailId.values() 
                                              Or Contact.Email In :customerResponseCaseIdVsSenderEmailId.values())];
            system.debug('---Existing Cases---' + existingCases.size()); 
            //search the closed cases associated with incoming messages from customer
            for (case caseRecord : existingCases) {  
                system.debug('---Found a case for which customer replied---' + caseRecord);
                if((customerResponseCaseIdVsSenderEmailId.get(caseRecord.Id).equalsIgnoreCase(caseRecord.Contact.Email) 
                    ||customerResponseCaseIdVsSenderEmailId.get(caseRecord.Id).equalsIgnoreCase(caseRecord.suppliedEmail))) {
                        //WI-0000986
                        //Make the flag true Bulb is on when customer sends an response.
                        caseRecord.RecentActivityFlag__c = true;
                        //casesToBeUpdated.add(caseRecord);
                        
                        casesToBeUpdated.put(caseRecord.Id, caseRecord);
                        
                        system.debug('---Case Status---' + caseRecord.Status + '--RT--' + caseRecord.RecordType.Name);
                        system.debug('---Last Queue Assigned---' + caseRecord.Last_Queue_Assigned__c);
                        if(caseRecord.Status == GlobalConstants.CASE_SOFTCLOSED_STATUS) {
                            if(caseRecord.Last_Queue_Assigned__c != null && queueNameVsId.containsKey(caseRecord.Last_Queue_Assigned__c)) {
                                //Last Assigned Queue is not null and Queue exisits then assign the case back to queue
                                caseRecord.OwnerId =  queueNameVsId.get(caseRecord.Last_Queue_Assigned__c);
                                //caseRecord.Status = GlobalConstants.REOPENED_CASE_STATUS_CUSTOMER_COMMUNICATION; 22/05/2015 Manish Damle
                                //casesToBeUpdated.add(caseRecord);
                                system.debug('---Owner Changed To Last Queue Assigned---' + caseRecord.OwnerId);
                            } else if(((String) caseRecord.OwnerId).startsWith('005') && caseRecord.Owner.IsActive) {
                                //If case Owner User active then do not do anything
                                if(GlobalConstants.AGENCY_SYDNEY_TRAINS.equalsIgnoreCase(caseRecord.OwnerAgency__c) || GlobalConstants.AGENCY_NSW_TRAINS.equalsIgnoreCase(caseRecord.OwnerAgency__c)) {
                                    casesToBeUpdated.remove(caseRecord.Id);
                                }
                                continue;
                            } else {
                                //Assign to default owner if owner is not active and case was not assigned to queue last time.
                                if(caseRecord.OwnerId != null) {
                                    caseRecord.OwnerId = defaultCaseOwnerId;
                                    //caseRecord.Status = GlobalConstants.REOPENED_CASE_STATUS_CUSTOMER_COMMUNICATION; 22/05/2015 Manish Damle
                                    //casesToBeUpdated.add(caseRecord);
                                }
                            }
                        } else if(caseRecord.Status == GlobalConstants.CASE_CLOSED_STATUS) {
                            casesToBeUpdated.remove(caseRecord.Id);
                            system.debug('----New Case Created After Customer Response Received On Hard Closed Case-----');
                            //If case is hard closed and customer sends respose then create new case attach email message to new case
                            Case cloneCase = caseRecord.clone(false,true);
                            //Last Assigned Queue is not null and Queue exisits then assign the case back to queue else web traige queue
                            if(caseRecord.Last_Queue_Assigned__c != null && queueNameVsId.containsKey(caseRecord.Last_Queue_Assigned__c)) {
                                cloneCase.OwnerId = queueNameVsId.get(caseRecord.Last_Queue_Assigned__c);
                            } else if(queueNameVsId.containsKey(WEB_TRIAGE_QUEUE)){
                                cloneCase.OwnerId = queueNameVsId.get(WEB_TRIAGE_QUEUE);
                            }
                            //cloneCase.ParentId = CaseRecord.Id; WI1457
                            cloneCase.Origin = GlobalConstants.CLONED_CASE_ORIGIN_CUSTOMER_COMMUNICATION;
                            cloneCase.Status = GlobalConstants.CLONED_CASE_STATUS_CUSTOMER_COMMUNICATION;
                            cloneCase.Description = 'ref: ' + caseRecord.CaseNumber + '\n\n' + incomingCustomerCaseIdVsMessage.get(caseRecord.Id).TextBody;
                            cloneCase.Subject = caseRecord.Subject;
                            oldIdvsClones.put(caseRecord.Id, cloneCase);
                            system.debug('---oldIdvsClones---' + oldIdvsClones);
                        }                       
                    }
            }
        }
        
        //DMl section
        if(casesToBeUpdated.size() > 0) {
            update casesToBeUpdated.values();
        }
        
        if (oldIdvsClones.size() > 0){
            insert oldIdvsClones.values();//to get the id
            system.debug('---Inserted oldIdvsClones---' + oldIdvsClones);
            for (Id oldCaseId: oldIdvsClones.keySet()){
                Case clone = oldIdvsClones.get(oldCaseId);
                EmailMessage datedMessage = incomingCustomerCaseIdVsMessage.get(oldCaseId);
                datedMessage.ParentId = clone.Id;
                datedMessage.Subject = datedMessage.Subject.replaceFirst(CASE_REF_REGEX, getThreadId(clone.Id));
            }
        }
    }
    
    private String getThreadId(String caseid) {
        String caseThreadId = '_'+
            ((string)orgId).substring(0,((string)orgId).substring(3,4)=='0'?3:4)+
            ((string)orgId).substring(4+((string)orgId).substring(4).indexOfAnyBut('0')-1,15)
            +'._'+
            ((string)caseId).subString(0,((string)caseId).substring(3,4)=='0'?3:4)+
            ((string)caseId).substring(4+((string)caseId).substring(4).indexOfAnyBut('0')-1,15);
        
        return caseThreadId;
    }    
}