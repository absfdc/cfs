/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Before Insert handler class for the Case trigger
it checks the subject and body for key words that are configured as high priority

Test Class:    CaseTriggerDispatcher_Test
History
30 Mar 2015      Dipankar Barman     created
25-Aug-2017      Arxxus      Updated. Due date calculation logic added for weekends and public holidays
25-June-2018     Ian Fitzgerald,TfNSW  Added check for On Demand record type in method syncPortalPBOFields
------------------------------------------------------------*/
public with sharing class CaseBeforeInsertTriggerHandler extends TriggerHandlerBase{
    
    //25/08/2017: Pawan Tiwari => added
    private static BusinessHours stdBusinessHours = NULL;

    public override void mainEntry(TriggerParameters tp) {
        System.debug('-@CaseBeforeInsert-Main Entry----');
        process(tp);
    }
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    Static boolean PBOFieldSynced = false;    //SFCOE-880 22/04/2017    
    
    /*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   checks the subject and body for key words that are configured as high priority
Inputs:        Trigger context parameters

History
<Date>      <Authors Name>     <Brief Description of Change>
14-Apr-2015 B. Cawrse          Execute assigment rules for web2case
9/05/2015   Manish Damle       Update the code to capture the 
Case Resolution Date and Reopen Till Date
4-Jun-2015 B.Cawrse            Removed assignment rule override
------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            //for detecting agency change
            Set<Id> cfmCaseIDOwnerChanged= new Set<Id> ();
            Set<Id> cfmOldAndNewUser= new Set<Id> ();
            //flip case record type based on mode for cfm
            CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip((List<Case>) tp.newList);
            rtFlip.flipRecordTypes();
            //fetch the MinCorro case recordTypes to check against reprioritising them
            Set<Id> scannedTypes = CasePriorityUtility.getScannedRecTypeIds();
            Set<String> scannedorigins=CasePriorityUtility.getScannedOrigins();
            boolean gotAssignmentRules = false;
            Database.DMLOptions assignRuleDMLOptions = new Database.DMLOptions();
            List<Id> ownerIds= new List<Id>();
            List<Case> rmsCaseOwnershipChanged= new List<Case> ();//cases where ownership changes to RMS* branches
            //assignRuleDMLOptions.assignmentRuleHeader.useDefaultRule = false; //TODO: Clean up: introduced temporarily for playback
            
            
            ApplicationLogMessage log;
            for (Case aCase:(List<Case>)tp.newList ){
                System.debug('aCase status: ' + aCase.Status);
                
                //set the business hrs if agency is populated
                if(aCase.ownerAgency__c !=null) aCase.BusinessHoursId=BusinessHoursUtil.getBusinessHour(aCase.ownerAgency__c);
                //cases where ownership changes to RMS* branches
                if (aCase.ownerId!=null) ownerIds.add(aCase.ownerId);
                //roundup all cfm cases where owner changed for detecting agency change later
                if (!aCase.IsMinCorroCase__c) {
                    cfmCaseIDOwnerChanged.add(aCase.Id);
                    if(((String) aCase.OwnerId).startsWith(GlobalConstants.USER_ID_PREFIX) )  cfmOldAndNewUser.add(aCase.OwnerId);
                }
                
                //14-APR-2015 B.Cawrse: Added to execute assignment rules when added from Web
                //13-May-2015 D.Barman: Added extra filter for disabling the assignment rules
                if (scannedorigins.contains(aCase.Origin) && aCase.parentId==null) {
                    
                    if (!gotAssignmentRules){ //this is the first web to case, get the DML options
                        assignRuleDMLOptions = retrieveCaseAssignmentRuleDMLOption();
                    }
                    
                    aCase.setOptions(assignRuleDMLOptions);
                    
                    //Group q = [Select Id, Name from Group WHERE NAME  = 'Serco - Web Triage'];
                    //aCase.OwnerId = q.Id;
                }

                /* Arxxus: 25/08/2017
                   Entry Criteria for Due Date calculation. Replaced with 'Set Response Due Date' and 'Set Response Due Date - RMS Registration Scenario' workflow rule
                   For Case Priority => MP - Standard, Add 15 busniess days
                   For Case Priority => Individual - Standard, Add 20 busniess days
				   busniess days (15 and 20) are stored in custom setting: Case_Due_Date_By_Priority__c
                */
                if(aCase.Due_Date__c == NULL && (((aCase.Priority == GlobalConstants.CASE_PRIORITY_MP_STANDARD || aCase.Priority == GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD) 
                    && aCase.Due_date__c == null && aCase.Status == GlobalConstants.ALLOCATION_STATUS_MIN_CORRO) || 
                    ((aCase.Priority == GlobalConstants.CASE_PRIORITY_MP_STANDARD || aCase.Priority == GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD)
                      && aCase.Due_date__c == null && aCase.Status == GlobalConstants.DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS 
                      && aCase.Signatory__c == GlobalConstants.RMS_CE_SIGNATORY 
                       ))){
					//stdBusinessHours is static variable hence the query within loop would not have impact on soql governor limit.
                    if(stdBusinessHours == NULL)
                        stdBusinessHours = [Select Id from BusinessHours where BusinessHours.Name =: GlobalConstants.BUSINESSHOURS_NAME LIMIT 1];

                    aCase.Due_Date__c = UtilityClass.getDueDate(aCase.Priority, System.now(),stdBusinessHours);
                } // End for due date calculation logic
                
            }//end for
            
            CaseEntitlementUtil  entitle= new CaseEntitlementUtil();
            //DB commented detect agency change just yet
            entitle.detectAgencyChange( tp,cfmCaseIDOwnerChanged,cfmOldAndNewUser,messages);
            system.debug('------@CaseBeforeInsert--CaseEntitlementUtil--Finished----');
            
            Map<Id,Group> rmsQueues= new Map<Id,Group>([Select Id, Name, DeveloperName, Type from Group where Type = 'Queue' and Id in:ownerIds and DeveloperName like :GlobalConstants.RMS_QUEUE_PREFIX]);
            for (Case thisCase:(List<Case>)tp.newList){
                System.debug('thisCase status: '+ thisCase.Status);
                Group queue=rmsQueues.get(thisCase.ownerId);
                if (queue==null) {
                    system.debug('skipping case owner-'+thisCase.ownerId);
                    continue;//skip setting branch for this case
                }
                String queueName=queue.DeveloperName;
                String branch;
                List<String> queueNameSplit=queueName.split('_',0);
                system.debug('queueName-'+queueName);
                if (queueNameSplit.size()>=4){
                    queueNameSplit.remove(queueNameSplit.size()-1);//remove last
                    queueNameSplit.remove(0);
                    queueNameSplit.remove(0);
                    
                    for (String part:queueNameSplit){
                        branch=branch==null ? part : branch+' '+part;
                    }
                    thisCase.branch__c=branch.toUpperCase();
                }
                
            }
            
            map<String,Decimal> agencyDuration= new map<String,Decimal>();//get the custom settings
            for(ReopenDuration__c r: ReopenDuration__c.getAll().values()) {
                agencyDuration.put(r.name, r.Duration__c);
            }
            
            for(Case newCase : (list <Case>) tp.newList){
                //Capture the date when Status is changed to Resolved
                if(newCase.Status == GlobalConstants.CASE_SOFTCLOSED_STATUS) {
                    newCase.Case_Resolution_Date__c = date.today();
                    if(newCase.OwnerAgency__c != null && agencyDuration.containsKey(newCase.OwnerAgency__c)) {
                        newCase.Reopen_Till_Date__c = date.today().addDays(agencyDuration.get(newCase.OwnerAgency__c).intValue());
                    }
                }
                system.debug('-----Case Resolved------' + newCase.Case_Resolution_Date__c + ' --- ' + newCase.Reopen_Till_Date__c);
            }
            
            //AssignedToAgencyStatusSelector  assignedAgencyDateSelector = new AssignedToAgencyStatusSelector((list <Case>) tp.newList);
            //assignedAgencyDateSelector.selectStatus();
            determineLastAssignedQueue(tp);
            determinePBOLROEmailAddress(tp);
            
            system.debug('------@CaseBeforeInsert--Before ApplicationLogUtility----' + messages);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            system.debug('------@CaseBeforeInsert--ApplicationLogUtility Logged----');
            
            //SFCOE-880
            Map<String, Id> IssueTaxonomyMap = prepareIssueTaxonomyList(tp);
            Map<String, Id> locationTaxonomyMap = prepareLocationTaxonomyList(tp);
            syncPortalPBOFields(tp, IssueTaxonomyMap, locationTaxonomyMap);
            //SFCOE-880
            
            
        }catch(Exception e){
            System.debug('-------@CaseBeforeInsert----Exception----' + e.getMessage() + '---' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseBeforeInsertTriggerHandler';
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
                    
        // auto triage
        Long exStart = DateTime.now().getTime(); 
        CaseAutoTriage caseTraige = new CaseAutoTriage(trigger.new);
        caseTraige.ProfanityFilterandHPScoreCalculator(); 
        Long exEnd = DateTime.now().getTime();
        system.debug('Total Execution Time For Case Auto Triage(Milliseconds) : ' + (exEnd - exStart));
        
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This method will populate the last Assigned queue.
Inputs:        Trigger context parameters

History
<Date>        <Authors Name>     <Brief Description of Change>
11/09/2015     Manish Damle       Created
------------------------------------------------------------*/
    public void determineLastAssignedQueue(TriggerParameters tp) {
        map <Id,Id> caseIdVsOwnerQueueId = new map <Id,Id>();
        map <Id,Group> queues = CaseTriggerDispatcher.queues;        
        for (Case newCase : (list<Case>) tp.newList){
            //If owner is queue then capture that Queue Name
            if(((String) newCase.OwnerId).startsWith(GlobalConstants.GROUP_ID_PREFIX))  {
                caseIdVsOwnerQueueId.put(newCase.Id, newCase.OwnerId);
            }
        }
        
        for(Case newCase : (list<Case>) tp.newList){
            if(caseIdVsOwnerQueueId.containsKey(newCase.Id) && queues.containsKey(caseIdVsOwnerQueueId.get(newCase.Id))) {
                newCase.Last_Queue_Assigned__c = queues.get(caseIdVsOwnerQueueId.get(newCase.Id)).DeveloperName;
                newCase.Datetime_last_assigned_queue__c = System.now();
                
            //SFCOE-88 Stamp email address of Last Assigned Queue - Start
            //Added email
            	String lastQueueEmail = queues.get(caseIdVsOwnerQueueId.get(newCase.Id)).Email;
                if(!String.isEmpty(lastQueueEmail))
                	newCase.Last_Queue_Assigned_Email__c = lastQueueEmail;
                
            //SFCOE-88 Stamp email address of Last Assigned Queue - End                
                
            }
        }
        System.debug('-------@CaseBeforeInsert----Last Assigned Queue Stamped----');
    }
    
    public void determinePBOLROEmailAddress(TriggerParameters tp) {
        map<String,String> l1vsEmail = new map<String,String>(); //get the custom settings
        for(PBOLROEmailAddressConfiguration__c r: PBOLROEmailAddressConfiguration__c.getAll().values()) {
            l1vsEmail.put(r.Location_Level_1__c, r.Email__c);
        }
        System.debug('Size of map: ' + tp.newList.size());
        for(Case newCase:(List<Case>)tp.newList) {
            System.debug('Taxonomy Location: ' + newCase.Taxonomy_Location_Type__c);
            if(!String.isBlank(newCase.Taxonomy_Location_Type__c) && l1vsEmail.containsKey(newCase.Taxonomy_Location_Type__c)) {
                newCase.PBLROperator_Email_Address__c = l1vsEmail.get(newCase.Taxonomy_Location_Type__c);
                System.debug('PBO/LRO email set to: ' + newCase.PBLROperator_Email_Address__c);
            } else {
                newCase.PBLROperator_Email_Address__c = null;
                System.debug('PBO/LRO email set to blank');
            }
        }
        System.debug('-------@CaseBeforeInsert----PBO/LRO email Stamped----');
    }
    
    private Database.DMLOptions retrieveCaseAssignmentRuleDMLOption() {
        List<AssignmentRule> rules = new List<AssignmentRule>();
        AssignmentRule rule = new AssignmentRule();
        rules = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        
        if (rules != null && rules.size() == 1){
            rule = rules[0];
            system.debug('Found a rule');
        } else {
            system.debug('Error: there should be only one');
        }
        
        //Create the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();        
        dmlOpts.assignmentRuleHeader.assignmentRuleId= rule.id;
        system.debug('Options set');
        return dmlOpts;
    }
    
    
    //SFCOE-880 22/04/2017 Start
    //Synchronize Issue and Location Taxonomy fields used by PBO Portal
    
    private void syncPortalPBOFields(TriggerParameters tp, Map<String, Id> IssueTaxonomyMap, Map<String, Id> locationTaxonomyMap){
        boolean isRTPO = false;        
        
        if(!PBOFieldSynced){
            PBOFieldSynced = true;
            try{
                System.debug('CaseBeforeInsertTriggerHandler:: Size of map: ' + tp.newList.size());
                List<RecordType> rtpo = [Select Id From RecordType where developername in ('Private_Operators','Light_Rail', 'On_Demand')];                
                
                for(Case newCase:(List<Case>)tp.newList) {
                    System.debug('CaseBeforeInsertTriggerHandler:: syncPortalPBOFields:: Issue: ' + newCase.Issue_Level_3__c + newCase.Issue_Level_2__c + newCase.Issue_Level_1__c);
                    System.debug('CaseBeforeInsertTriggerHandler:: syncPortalPBOFields:: Location: ' + newCase.Taxonomy_Location__c + newCase.Taxonomy_Area__c + newCase.Taxonomy_Location_Type__c);
                    
                    if(!String.isBlank(newCase.Issue_Level_1__c) && !String.isBlank(newCase.Issue_Level_2__c) && !String.isBlank(newCase.Issue_Level_3__c)) 
                    {
                           for (RecordType rt:rtpo){if (newCase.RecordTypeId == rt.id) isRTPO = true;}
                           if(isRTPO){   
                        
                           //Calculate Taxonomy Symptom and Stamp on Case record 
                           System.debug('CaseBeforeInsertTriggerHandler:: syncPortalPBOFields:: Issue: ' + newCase.Issue_Level_3__c + newCase.Issue_Level_2__c + newCase.Issue_Level_1__c);
                           
                           Id issueTaxonomyId = IssueTaxonomyMap.get(newCase.Issue_Level_3__c+newCase.Issue_Level_2__c+newCase.Issue_Level_1__c);
                           System.debug('CaseBeforeInsertTriggerHandler:: syncPortalPBOFields:: Issue: ' + newCase.Issue_Level_3__c + newCase.Issue_Level_2__c + newCase.Issue_Level_1__c);
                           
                           if(issueTaxonomyId!=null) {
                               newCase.Taxonomy_Symptom_Id__c = issueTaxonomyId;
                               newCase.Taxonomy_Moment__c = newCase.Issue_Level_1__c;
                               newCase.Taxonomy_Transaction__c = newCase.Issue_Level_2__c;
                               newCase.Taxonomy_Symptom__c = newCase.Issue_Level_3__c;
                               System.debug('CaseBeforeInsertTriggerHandler:: Portal Changes:: Updated Taxonomy_Symptom_Id__c ' + issueTaxonomyId + ' on Case: ' + newCase.casenumber);
                           }
                           }
                       }
                    System.debug('Location MAP Size: ' + locationTaxonomyMap.size());
                    
                    if(!String.isBlank(newCase.Taxonomy_Location__c) && !String.isBlank(newCase.Taxonomy_Area__c) && !String.isBlank(newCase.Taxonomy_Location_Type__c)) {
                        Id locationTaxonomyId = locationTaxonomyMap.get(newCase.Taxonomy_Location__c+newCase.Taxonomy_Area__c+newCase.Taxonomy_Location_Type__c);
                        System.debug('CaseBeforeInsertTriggerHandler:: locationTaxonomyId:: ' + locationTaxonomyId);
                        
                        if(locationTaxonomyId != null) {
                            newCase.Taxonomy_Location_Id__c = locationTaxonomyId;
                            System.debug('CaseBeforeInsertTriggerHandler:: Non-Portal Changes:: Updated Location_Level_3__c ' + locationTaxonomyId + ' on Case: ' + newCase.casenumber);
                        }
                    }                 
                }
            }catch(Exception e){
                system.debug('-------CaseBefore Insert Exception-----' + e.getMessage() + '----' + e.getLineNumber());
                ApplicationLogMessage message= new ApplicationLogMessage();
                message.source='CaseBeforeInsertTriggerHandler';
                message.sourceFunction='process:syncPortalPBOFields';
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
    
    
    private Map<String, Id> prepareIssueTaxonomyList(TriggerParameters tp){
        List<Taxonomy_Metadata__c> newCaseIssueList = new List<Taxonomy_Metadata__c>();
        Map<String, Id> txMap = new Map<String, Id>();
        List<Case> caseList = new List<Case>();
        
        Set<String> lvl1 = new Set<String>();
        Set<String> lvl2 = new Set<String>();
        Set<String> lvl3 = new Set<String>();
        
        try{
            for(Case newCase:(List<Case>)tp.newList) {
                caseList.add(newCase);
            }
            
            for (Case newCase : caseList){
                lvl1.add(newCase.Issue_Level_1__c);
                lvl2.add(newCase.Issue_Level_2__c);
                lvl3.add(newCase.Issue_Level_3__c);
            }
            
            system.debug(lvl1);  
            system.debug(lvl2);  
            system.debug(lvl3);  
            
            List< Taxonomy_Metadata__c> txList = [SELECT Id, Name, Parent_Id__r.name, Parent_Id__r.Parent_Id__r.Name  FROM Taxonomy_Metadata__c WHERE Type__c = 'Issue' 
                                                  AND name in :lvl3  AND Parent_Id__r.name in :lvl2 
                                                  AND Parent_Id__r.Parent_Id__r.Name in :lvl1];
            
            For (Taxonomy_Metadata__c tx : txList){
                txMap.put( tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name , tx.Id);
            }
            system.debug(txMap);            
        }catch(Exception e){
            system.debug('-------CaseBefore Update Exception-----' + e.getMessage() + '----' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseBeforeInsertTriggerHandler';
            message.sourceFunction='prepareIssueTaxonomyList';
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            Throw(e);
        } 
        return txMap;
        
    }
    
    private Map<String, Id> prepareLocationTaxonomyList(TriggerParameters tp){
        List<Taxonomy_Metadata__c> newCaseLocationList = new List<Taxonomy_Metadata__c>();
        Map<String, Id> txMap = new Map<String, Id>();
        List<Case> caseList = new List<Case>();
        
        Set<String> lvl1 = new Set<String>();
        Set<String> lvl2 = new Set<String>();
        Set<String> lvl3 = new Set<String>();
        
        try{
            for(Case newCase:(List<Case>)tp.newList) {
                caseList.add(newCase);
            }
            
            for (Case newCase : caseList){
                lvl1.add(newCase.Taxonomy_Location_Type__c);
                lvl2.add(newCase.Taxonomy_Area__c);
                lvl3.add(newCase.Taxonomy_Location__c);
            }
            
            system.debug(lvl1);  
            system.debug(lvl2);  
            system.debug(lvl3);  
            
            List< Taxonomy_Metadata__c> txList = [SELECT Id, Name, Parent_Id__r.name, Parent_Id__r.Parent_Id__r.Name  FROM Taxonomy_Metadata__c WHERE Type__c = 'Location' 
                                                  AND name in :lvl3  AND Parent_Id__r.name in :lvl2 
                                                  AND Parent_Id__r.Parent_Id__r.Name in :lvl1];
            
            For (Taxonomy_Metadata__c tx : txList){
                txMap.put( tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name , tx.Id);
                system.debug('prepareLocationTaxonomyList:: Added to Location Map: ' + tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name + ' id: ' + tx.Id);
            }
            system.debug('prepareLocationTaxonomyList:: Location Map: ' + txMap);            
        }catch(Exception e){
            system.debug('-------CaseBefore Insert Exception-----' + e.getMessage() + '----' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseBeforeInsertTriggerHandler';
            message.sourceFunction='prepareLocationTaxonomyList';
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            Throw(e);
        } 
        return txMap;
    }
    
    //SFCOE-880 22/04/2017 END    
    
    
    
    
}