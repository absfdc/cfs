/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Before Update handler class for the Case trigger
it checks the subject and body for key words that are configured as high priority

Test Class:    CaseTriggerDispatcher_Test
History
30 Mar 2015      Dipankar Barman     created
10/01/2017       Arxxus              updated - to include MAGS team queues for allocation
08/05/2017       Ian Fitzgerald      Added "validate" method to replace validation rule "Only_SydneyOrNSW_Trains_users_assign_SME"
10/07/2017       Pawan Tiwari        Updated. Added record type flip logic for Bus and LightRail mode   
25/08/2017       Arxxus        Updated. Added Duedate Calculation Logic.
06/09/2017       Pawan Tiwari        Updated. Added code to auto update owner to Responsible MAGS Officer.
06/09/2017       Pawan Tiwari        Oct release: Added code to auto update owner to Responsible MAGS Officer.
28/09/2017       Ian Fitzgerald      PBO Synch code changes to only query Taxonomy once.
09/11/2017       Ian Fitzgerald      PBO Synch code changes to correct exception.
25-June-2018     Ian Fitzgerald      Added check for On Demand record type in method syncPortalPBOFields
------------------------------------------------------------*/
public without sharing class CaseBeforeUpdateTriggerHandler extends TriggerHandlerBase{
    
    //25/08/2017: Arxxus => added
    private static BusinessHours stdBusinessHours = NULL;

    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    Static boolean PBOFieldSynced = false;    //SFCOE-880 22/04/2017    
    
    // 06/09/2017: Pawan Tiwari
    public static List<Case_Status_Value__mdt> caseStatusValuesList = null;   

    public override void mainEntry(TriggerParameters tp) {
        validate(tp);
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        reProcess(tp);
    }
    
    private void reProcess(TriggerParameters tp){
        Map<Id,Id> parentCaseVsQueue = new Map<Id,Id>();
        Map<Id,Id> parentCaseVsOwner = new Map<Id,Id>();
        
        CaseEntitlementUtil  entitle= new CaseEntitlementUtil();
        //for detecting agency change
        Set<Id> cfmCaseIDOwnerChanged= new Set<Id> ();
        Set<Id> cfmOldAndNewUser= new Set<Id> ();
        
        for (Id aCaseId : tp.newMap.keySet()) {
            //determine the cases to be scanned
            Case oldCase = (Case) tp.oldMap.get(aCaseId);
            Case newCase = (Case) tp.newMap.get(aCaseId);
            
            //set the business hrs if agency is populated
            if(newCase.ownerAgency__c !=null) newCase.BusinessHoursId=BusinessHoursUtil.getBusinessHour(newCase.ownerAgency__c);
            
            //determine case where entitlement require to be applied without ownership undergoing change
            if (((oldCase.OwnerAgency__c ==null && newCase.OwnerAgency__c!=null)|| (oldCase.EntitlementId==null && newCase.EntitlementId!=null) ) && !String.isEmpty(newCase.OwnerAgency__c) && newCase.Date_Assigned_to_Agency__c!=null && (newCase.ownerId==oldCase.ownerId)) {
                entitle.assign(newCase);
            }
            //check if owner changed
            system.debug('----New Id: ' + newCase.ownerId + 'Old Id: ' + oldCase.ownerId  + 'GetNext:' + newCase.IsGetNext__c);
            
            if (oldCase.ownerId != newCase.ownerId){
                //roundup all cfm cases where owner changed for detecting agency change later
                if (!newCase.IsMinCorroCase__c) {
                    cfmCaseIDOwnerChanged.add(aCaseId);
                    if(((String) newCase.OwnerId).startsWith('005') )  cfmOldAndNewUser.add(newCase.OwnerId);
                    if(((String) oldCase.OwnerId).startsWith('005') )  cfmOldAndNewUser.add(oldCase.OwnerId);
                }
            }
        }
        System.debug('detectAgencyChange XX2: '+cfmCaseIDOwnerChanged); 
        System.debug('detectAgencyChange XX3: '+cfmOldAndNewUser);
        entitle.detectAgencyChange( tp,cfmCaseIDOwnerChanged,cfmOldAndNewUser,messages);
        
    }

//SFCOE-2156 - Portal - Email Notification - When owner changed - 10-05-2018 - Start
private void sendEmailNotificationToAPOwnerOnChildAPStatusChange(TriggerParameters tp) {
   try {
		if(Action_PlanTriggerDispatcher.preventEmailResending == false) {
			Id childActionPlanRecordTypeId = Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.CHILD_AP_RECORDTYPE_API_NAME);
			List <Messaging.SingleEmailMessage> emails = new list <Messaging.SingleEmailMessage>();

			for(Action_Plan__c ap : (List<Action_Plan__c>) tp.newList) {
				Action_plan__c oldAp = (Action_plan__c) tp.oldMap.get(ap.Id);
				
	if(oldAp.status__c != ap.Status__c && childActionPlanRecordTypeId == ap.RecordTypeId && ap.Parent_AP_Owner_Id__c != UserInfo.getUserId()) {
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
//SFCOE-2156 - Portal - Email Notification - When owner changed - 10-05-2018 - End
    
    /*------------------------------------------------------------
Author:        Ian Fitzgerald
Description:   Executes validation which was moved to apex from Validation Rule to save on spanning relationships
Inputs:        Trigger context parameters

History
<Date>      <Authors Name>     <Brief Description of Change>
08-May-2015  Ian Fitzgerald    Created.                                      
------------------------------------------------------------*/
    private void validate(TriggerParameters tp) {
        List<Id> caseChangedSMEIds = new List<Id>();
        List<Id> changedSMEIds = new List<Id>();
        
        if (tp!=null && Trigger.isUpdate){
            for (Id aCaseId : tp.newMap.keySet()) {
                //determine the cases to be scanned
                Case oldCase = (Case) tp.oldMap.get(aCaseId);
                Case newCase = (Case) tp.newMap.get(aCaseId);
                if (newCase.Assigned_SME__c!=null && oldCase.Assigned_SME__c!=newCase.Assigned_SME__c && 
                    newCase.IsMinCorroCase__c==false && newCase.ChangeOfGovernmentBypass__c==false &&
                    (newCase.ConnectionReceivedId==null || oldCase.ConnectionReceivedId==newCase.ConnectionReceivedId)
                   )
                {
                    caseChangedSMEIds.add(newCase.Id);
                    changedSMEIds.add(newCase.Assigned_SME__c);
                }    
            }
            
            if ( changedSMEIds.size()>0){
                String currentUserRoleName='';
                User currentUser = [select Id, Alias, UserRoleId, UserRole.DeveloperName from User where Id = :UserInfo.getUserId() limit 1];
                if(currentUser.UserRoleId!=null){
                    currentUserRoleName = currentUser.UserRole.DeveloperName;
                }
                
                Map<Id, Contact> SMEs = new Map<Id, Contact>([select Id, Account.ParentId, Account.Parent.Name from Contact where Id in :changedSMEIds]); 
                for (Id caseId : caseChangedSMEIds){
                    String currentSMEParentAccountName='';
                    Case newCase = (Case) tp.newMap.get(caseId);
                    Contact caseAssignedSME = SMEs.get(newCase.Assigned_SME__c);
                    if(caseAssignedSME.Account.ParentId!=null){
                        currentSMEParentAccountName = caseAssignedSME.Account.Parent.Name;
                    }
                    if (currentUser.Alias.indexOf('pnet')<0){
                        system.debug('Before If');
                        if (( currentUserRoleName.startsWithIgnoreCase('Sydney_Trains')==false && 
                             currentUserRoleName.startsWithIgnoreCase('Syd_Trains')==false &&
                             currentSMEParentAccountName.indexOf('Sydney Trains')>=0
                            ) ||
                            ( currentUserRoleName.startsWithIgnoreCase('Sydney_Trains_')==false && 
                             currentUserRoleName.startsWithIgnoreCase('Syd_Trains')==false &&
                             currentUserRoleName.startsWithIgnoreCase('NSW_Trains')==false &&
                             currentSMEParentAccountName.indexOf('NSW Trains')>=0
                            )){
                                newCase.addError('You are not allowed to assign other departments SME to Case');
                            }
                    }
                }
            }
        }
    }
    
    /*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   checks the subject and body for key words that are configured as high priority
Inputs:        Trigger context parameters

History
<Date>      <Authors Name>     <Brief Description of Change>
25-May-2015  B. Cawrse          Updated to reject owner change if user is marked as anti cherry picking
and the change was not via the getNext button
01/06/2015   Manish Damle       Moved running user query to the CaseTriggerDispatcher 
so that it will not get called again again.                                      
------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            system.debug('CaseBeforeUpdateTriggerHandler.process start');

            //Start=> 06/09/2017: Pawan Tiwari 
            Set<String> caseValuesSet = new Set<String>();

            if(caseStatusValuesList == null){
                caseStatusValuesList = [Select Id,Case_Status__c from Case_Status_Value__mdt where Case_Status__c != NULL];
                System.debug('caseStatusValuesList ::' + caseStatusValuesList);
                for(Case_Status_Value__mdt caseStatus : caseStatusValuesList){
                    caseValuesSet.add(caseStatus.Case_Status__c);
                }
                
            }// End

            //flip case record type based on mode for cfm
            CaseRecordTypeFlip rtFlip = new CaseRecordTypeFlip((List<Case>) tp.newList);
            rtFlip.flipRecordTypes();
            Set<Id> pboOwnerIds = new Set<Id>();
            
            populateCampaignMemberFieldsFromCampaign(tp);
            
            //for detecting agency change
            Set<Id> cfmCaseIDOwnerChanged= new Set<Id> ();
            Set<Id> cfmOldAndNewUser= new Set<Id> ();
            setRecentActivityFlagOnCase(tp);   
            //fetch the MinCorro case recordTypes to check against reprioritising them
            Set<Id> scannedTypes = CasePriorityUtility.getScannedRecTypeIds();
            Set<String> scannedorigins=CasePriorityUtility.getScannedOrigins();
            ApplicationLogMessage log;
            List<Id> owners= new List<Id> ();
            boolean isAntiCherryPicking = false;
            
            //Get context of current user executing this transaction
            if (CaseTriggerDispatcher.runningUser != null) isAntiCherryPicking = CaseTriggerDispatcher.runningUser[0].Anti_Cherry_Picking__c; 
            
            for (Case aCase:(List<Case>)tp.newMap.values() ){
                owners.add(aCase.ownerId);
            }
            
            //Map<Id,Group> rmsQueues= new Map<Id,Group>([Select Id, Name, DeveloperName, Type from Group where Type = 'Queue' and Id in:owners and DeveloperName like :GlobalConstants.RMS_QUEUE_PREFIX]);
            Boolean resetFlag = false;
            Map<Id,Id> parentCaseVsQueue = new Map<Id,Id>();
            Map<Id,Id> parentCaseVsOwner = new Map<Id,Id>();
            
            CaseEntitlementUtil  entitle= new CaseEntitlementUtil();
            Set<Id> newOwnerIds = new Set<Id>();
            
            for (Id aCaseId : tp.newMap.keySet()) {
                //determine the cases to be scanned
                Case oldCase = (Case) tp.oldMap.get(aCaseId);
                Case newCase = (Case) tp.newMap.get(aCaseId);
                
                //determine case where entitlement require to be applied without ownership undergoing change
                if (((oldCase.OwnerAgency__c ==null && newCase.OwnerAgency__c!=null)|| (oldCase.EntitlementId==null && newCase.EntitlementId!=null) ) && !String.isEmpty(newCase.OwnerAgency__c) && newCase.Date_Assigned_to_Agency__c!=null && (newCase.ownerId==oldCase.ownerId)) {
                    entitle.assign(newCase);
                }
                //check if owner changed
                system.debug('----New Id: ' + newCase.ownerId + 'Old Id: ' + oldCase.ownerId + 'ACP:' + isAntiCherryPicking + 'GetNext:' + newCase.IsGetNext__c);
                
                if (oldCase.ownerId != newCase.ownerId){
                    system.debug('owner '+newCase.Owner.Name);
                    
                    //roundup all cfm cases where owner changed for detecting agency change later
                    if (!newCase.IsMinCorroCase__c) {
                        cfmCaseIDOwnerChanged.add(aCaseId);
                        if(((String) newCase.OwnerId).startsWith('005') )  cfmOldAndNewUser.add(newCase.OwnerId);
                        if(((String) oldCase.OwnerId).startsWith('005') )  cfmOldAndNewUser.add(oldCase.OwnerId);
                    }
                    
                    //Anti-Cherry picking code
                    if( CaseEntitlementUtil.isReassigned!=true && isAntiCherryPicking &&
                       ((String) newCase.OwnerId).startsWith('005') && //now case owned by User 
                       !((String) oldCase.OwnerId).startsWith('005') && //was not owned by User (i.e. Queue or Group)
                       !newCase.IsGetNext__c && !CaseTriggerDispatcher.getNextFlagReset) { //ownership was not changed through get next button
                           system.debug('----creating error ACP ----');
                           system.debug('CaseEntitlementUtil.isReassigned - '+CaseEntitlementUtil.isReassigned);
                           newCase.addError(GlobalConstants.CASE_ERROR_CHERRY_PICKING);
                       } else {
                           resetFlag = true;
                           newCase.isGetNext__c = false; //reset Get Next Flag
                           if(!((String) oldCase.OwnerId).startsWith('005')) {
                               parentCaseVsQueue.put(newCase.Id, oldCase.OwnerId);
                               parentCaseVsOwner.put(newCase.Id, newCase.OwnerId);
                           }
                       }
                    
                    
                    //Stamp the Agency when Owner Is Changed
                    String ownerId = newCase.OwnerId;
                    //new owner is a queue
                    if(ownerId.startsWith('00G') 
                       && CaseTriggerDispatcher.queues.get(newCase.OwnerId) != null 
                       && CaseTriggerDispatcher.queueNameVsAgencyDivBranch.containsKey(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName)) {
                           //Check for Case Group D: Parent of Multi Agency
                           //Agency = null && MultiAgency__c = true && ParentId = null && RecordTypeName = "Multi_Issue"
                           if((newCase.OwnerAgency__c == null || newCase.OwnerAgency__c == '') 
                              && newCase.MultiAgency__c == true 
                              && newCase.ParentId == null 
                              && newCase.RecordTypeId == CaseTriggerDispatcher.caseRecordTypes.get(GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE_DEV)) {
                                  newCase.OwnerAgency__c =  CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName).Agency__c;       
                                  system.debug('---@Agency Stamped On Multi Issue Parent---' + newCase.OwnerAgency__c);
                              }
                           newCase.OwnerAgency__c = CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName).Agency__c;
                           System.debug('New Agency: ' + newCase.OwnerAgency__c);
                           System.debug('Qnamw: ' + CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName).Agency__c);   
                           //Agency on the case is present in the custom settings then copy the branch and div.                    
                           //if(newCase.OwnerAgency__c == CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName).Agency__c) {
                           newCase.Division__c = CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName).Division__c;
                           newCase.Branch__c =  CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName).Branch__c;
                           //WI944
                           if(newCase.OwnerAgency__c == 'STA') {
                               newCase.Manager_Email__c = CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName).ManagerEmail__c;
                           }
                           //}
                           system.debug('---@OwnerAgency/Div/Branch Stamped---' + newCase.OwnerAgency__c + '-|-' + newCase.Division__c + '-|-' + newCase.Branch__c);                       
                       }
                }
                
                //check if sub or description modified and is not minCorr and priority has not been set to high
                if (scannedorigins.contains(newCase.Origin)
                    && (oldCase.Subject!=newCase.Subject || oldCase.Description!=newCase.Description)
                    && newCase.Priority!=GlobalConstants.CASE_PRIORITY_HIGH
                    && scannedTypes.contains(newCase.recordTypeId)){
                        //scan for high priority cases
                        //create a matcher for subject and description after normalizing space
                        if (CasePriorityUtility.checkMatchesKeyword(newCase.Description)
                            ||CasePriorityUtility.checkMatchesKeyword(newCase.Subject)){
                                log= new ApplicationLogMessage();
                                log.source='CaseBeforeInsertTriggerHandler';
                                log.sourceFunction='process';
                                log.debugLevel=GlobalConstants.DEBUG;
                                log.payLoad=' Id:'+newCase.Id +
                                    ' Subject:'+newCase.Subject+
                                    ' Description:'+newCase.Description+
                                    ' Priority Before:'+oldCase.Priority;
                                
                                messages.add(log);
                                newCase.Priority=GlobalConstants.CASE_PRIORITY_HIGH;
                            }
                    }

                    /* Start=> Added By Pawan Tiwari:  06/09/2017
                    * Update Case owner as Responsible MAGS officer for the case status value 
                    * specified in the 'Case Status Values' custom metadata types
                    */
                    System.debug('caseValuesSet :: ' + caseValuesSet);
                    System.debug('newCase.Status :: ' + newCase.Status);
                    System.debug('Owner :: ' + newCase.OwnerId +'--'+ newCase.Responsible_MAGS_Officer__c);
                    if(caseValuesSet.contains(newCase.Status) 
                      && newCase.Responsible_MAGS_Officer__c != null
                      && newCase.Responsible_MAGS_Officer__c != oldCase.Responsible_MAGS_Officer__c
                      && newCase.OwnerId != newCase.Responsible_MAGS_Officer__c){
                          newCase.OwnerId = newCase.Responsible_MAGS_Officer__c;

                    }// End

                    /* Arxxus: 25/08/2017
                    Entry Criteria for Due Date calculation. Replaced with 'Set Response Due Date' and 'Set Response Due Date - RMS Registration Scenario' workflow rule
                    For Case Priority => MP - Standard, Add 15 working days
                    For Case Priority => Individual - Standard, Add 20 working days
                    */
                    if( newCase.Due_Date__c == NULL && (((oldCase.Priority != newCase.Priority || newCase.Status != oldCase.Status) 
                      && (newCase.Priority == GlobalConstants.CASE_PRIORITY_MP_STANDARD || newCase.Priority == GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD) 
                      && newCase.Status == GlobalConstants.ALLOCATION_STATUS_MIN_CORRO) || 
                      ((oldCase.Priority != newCase.Priority || newCase.Status != oldCase.Status) 
                        &&(newCase.Priority == GlobalConstants.CASE_PRIORITY_MP_STANDARD || newCase.Priority == GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD)
                        && newCase.Status == GlobalConstants.DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS 
                        && newCase.Signatory__c == GlobalConstants.RMS_CE_SIGNATORY 
                        ))){
                        //stdBusinessHours is static variable hence the query within loop would not have impact on soql governor limit.
                          if(stdBusinessHours == NULL)
                              stdBusinessHours = [Select Id from BusinessHours where BusinessHours.Name =: GlobalConstants.BUSINESSHOURS_NAME LIMIT 1];

                          newCase.Due_Date__c = UtilityClass.getDueDate(newCase.Priority, System.now(),stdBusinessHours);
                    } // End for due date calculation logic
                
            } //end for


            // Updated => Pawan Tiwari : 06/09/2017=> Moved from line no. 152
            changeMinCorroCaseStatus(tp);
            
            for (Id aCaseId : tp.newMap.keySet()) {
                //determine the cases to be scanned
                Case oldCase = (Case) tp.oldMap.get(aCaseId);
                Case newCase = (Case) tp.newMap.get(aCaseId);
                String ownerId = newCase.OwnerId;
                System.debug('oldId and New Id: '+oldCase.ownerId+' new: '+newCase.ownerId);
                if (oldCase.ownerId != newCase.ownerId && ownerId.startsWith('00G')){
                    system.debug('owner '+newCase.Owner.Name);
                    String ownerAgency = '';
                    if(CaseTriggerDispatcher.queues.containsKey(newCase.OwnerId)){
                        String qDevName = CaseTriggerDispatcher.queues.get(newCase.OwnerId).DeveloperName;
                        if(CaseTriggerDispatcher.queueNameVsAgencyDivBranch.containsKey(qDevName)){
                            System.debug('queueVsAgency: '+CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(qDevName).Agency__c);
                            ownerAgency = CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(qDevName).Agency__c;
                        }
                    }
                    System.debug('ownerAgency: '+ownerAgency);
                    if((ownerAgency.equalsIgnoreCase('PBO') ) && 
                       (newcase.Modes__c == 'Bus')){
                           System.debug('ownerId: '+newCase.OwnerId);   
                           pboOwnerIds.add(newCase.OwnerId);
                       }
                    // End
                }
            }
            
            //Start: 10/07/2017 Pawan Tiwari Record type flip functionality for private opereators and light rail 
            if(pboOwnerIds.size() > 0){
                System.debug('pboOwnerIds: '+pboOwnerIds);
                PORecordTypeFlip poRTFlip = new PORecordTypeFlip();
                poRTFlip.setPORecType();
                System.debug('agencyVsRTId: '+PORecordTypeFlip.agencyVsRTId);
                if(PORecordTypeFlip.agencyVsRTId != NULL && PORecordTypeFlip.agencyVsRTId.size() > 0 && PORecordTypeFlip.pboQueueIds != NULL && PORecordTypeFlip.pboQueueIds.size() >0)
                    for(Case cs : (List<Case>)tp.newList) {
                        System.debug('case record type to be fliped: '+PORecordTypeFlip.agencyVsRTId);
                        if(PORecordTypeFlip.pboQueueIds.contains(cs.OwnerId) && PORecordTypeFlip.agencyVsRTId.containsKey(cs.OwnerAgency__c)) {
                            cs.RecordTypeId = PORecordTypeFlip.agencyVsRTId.get(cs.OwnerAgency__c);
                        }
                    }
            }
            entitle.detectAgencyChange( tp,cfmCaseIDOwnerChanged,cfmOldAndNewUser,messages);
            //parent ownership changed back in future because wrong assignment being manually rolled back and reassignment should not trigger this
            if(!System.isFuture())transferChildCases(parentCaseVsQueue, parentCaseVsOwner);
            CaseTriggerDispatcher.getNextFlagReset = true;
            
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            
            SNSWReferralEmailIdentifier snswReferralIdentifier = new SNSWReferralEmailIdentifier((List<Case>)tp.newMap.values());
            snswReferralIdentifier.populateSNSWReferral();
            
            determineLastAssignedQueue(tp);
            determinePBOLROEmailAddress(tp);
            validateChildCasesAreClosed(tp);
            
            ReopenedCaseReassigner caseReassigner = new ReopenedCaseReassigner((Map<Id,Case>) tp.oldMap, (Map<Id,Case>) tp.newMap, CaseTriggerDispatcher.queues);
            caseReassigner.reassignCaseOwner();
            
            //stampAgencyOnMultiIssueParentCase(tp); //WI-0000938 fix
            
            if(CaseTriggerDispatcher.updateClosureTargetDate) {
                List<Case> cases = new List<Case>();        
                cases = [select id, isClosed, OwnerAgency__c, ClosureTargetDate__c, Responsible_Party__c, (select  Id, CaseId, TargetDate, CompletionDate,MilestoneType.Name FROM CaseMilestones ORDER BY TargetDate ASC) from Case where Id in:Trigger.newMap.keySet()];
                Map<Id,Case> forUpdateTarget = CaseEntitlementUtil.populateClosureTargetDate(cases);
                for(Id caseId : forUpdateTarget.keySet()) {
                    Case record = (Case)Trigger.newMap.get(caseId);
                    record.ClosureTargetDate__c = forUpdateTarget.get(caseId).ClosureTargetDate__c;
                }
                CaseTriggerDispatcher.updateClosureTargetDate = false;
            }
            
            //SFCOE-880
            /*********************************************************************************************************
            28/09/2017 Ian Fitzgerald - changes to retrieve all required Taxonomy in one place rather than 3 separate queries
            **********************************************************************************************************/ 
            if(!PBOFieldSynced){
                PBOFieldSynced = true;
                List<Taxonomy_Metadata__c> txList = retrieveTaxonomyList(tp);
                Map<String, Id> issueTaxonomyMap = prepareIssueTaxonomyMap(txList);
                Map<String, Id> locationTaxonomyMap = prepareLocationTaxonomyMap(txList);
                Map<Id, String> portalLocationTaxonomyMap = preparePortalLocationTaxonomyMap(txList);
                syncPortalPBOFields(tp, issueTaxonomyMap, locationTaxonomyMap,portalLocationTaxonomyMap);
            }
            //SFCOE-880
            
        }catch(Exception e){
            system.debug('-------CaseBefore Update Exception-----' + e.getMessage() + '----' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseBeforeUpdateTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.newMap!=null) message.referenceInfo=JSON.serialize(tp.newMap.keySet());
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
        }finally{
            if (messages.size()>0){
                ApplicationLogUtility.logMessage(messages);
            }
            messages.clear();
        }
    }
    
    
    //SFCOE-880 22/04/2017 Start
    //Synchronize Issue and Location Taxonomy fields used by PBO Portal
    
    private void syncPortalPBOFields(TriggerParameters tp, Map<String, Id> IssueTaxonomyMap, Map<String, Id> locationTaxonomyMap, Map<Id, String> portalLocationTaxonomyMap){
        boolean isRTPO = false;
        
        System.debug('CaseBeforeUpdateTriggerHandler:: Size of map: ' + tp.newList.size());
        List<RecordType> rtpo = [Select Id From RecordType where developername in ('Private_Operators','Light_Rail','On_Demand')];                
        Id TfNSWOperatorPortalProfileId = [select Id, Name from Profile where name ='TfNSW Operator Portal User'].id;
                
        for(Case newCase:(List<Case>)tp.newList) {
            System.debug('CaseBeforeUpdateTriggerHandler:: syncPortalPBOFields:: Issue: ' + newCase.Issue_Level_3__c + newCase.Issue_Level_2__c + newCase.Issue_Level_1__c);
            System.debug('CaseBeforeUpdateTriggerHandler:: syncPortalPBOFields:: Location: ' + newCase.Taxonomy_Location__c + newCase.Taxonomy_Area__c + newCase.Taxonomy_Location_Type__c);
                    
            for (RecordType rt:rtpo){if (newCase.RecordTypeId == rt.id) isRTPO = true;}
            if(isRTPO){
                if(!String.isBlank(newCase.Issue_Level_1__c) && !String.isBlank(newCase.Issue_Level_2__c) && !String.isBlank(newCase.Issue_Level_3__c))
                {
                    System.debug('Size of IssueTaxonomyMap: ' + IssueTaxonomyMap.size());
                    Id issueTaxonomyId = IssueTaxonomyMap.get((newCase.Issue_Level_3__c+newCase.Issue_Level_2__c+newCase.Issue_Level_1__c).toLowerCase());
                    System.debug('CaseBeforeUpdateTriggerHandler:: syncPortalPBOFields:: Issue: ' + (newCase.Issue_Level_3__c+newCase.Issue_Level_2__c+newCase.Issue_Level_1__c).toLowerCase());
                    if(issueTaxonomyId !=null) system.debug('CaseBeforeUpdateTriggerHandler:: syncPortalPBOFields:: Issue: issueTaxonomyId: ' + issueTaxonomyId); else system.debug('issueTaxonomyId not found in map');
                            
                    if(issueTaxonomyId != null) {
                        system.debug('CaseBeforeUpdateTriggerHandler:: UserInfo.getProfileId():: ' + UserInfo.getProfileId());
                        if(UserInfo.getProfileId()==TfNSWOperatorPortalProfileId){
                        /*    newCase.Taxonomy_Symptom_Id__c = issueTaxonomyId;
                            newCase.Taxonomy_Moment__c = newCase.Issue_Level_1__c;
                            newCase.Taxonomy_Transaction__c = newCase.Issue_Level_2__c;
                            newCase.Taxonomy_Symptom__c = newCase.Issue_Level_3__c;
                            System.debug('CaseBeforeUpdateTriggerHandler:: Portal Changes:: Updated Taxonomy_Symptom_Id__c ' + issueTaxonomyId + ' on Case: ' + newCase.casenumber);
						*/
                         }
                         else System.debug('CaseBeforeUpdateTriggerHandler:: Portal Changes:: Is Portal User so Not resynchronizing Issue Taxonomy');
                    }
                    else System.debug('CaseBeforeUpdateTriggerHandler:: issueTaxonomyId not found for combination: ' + (newCase.Issue_Level_3__c+newCase.Issue_Level_2__c+newCase.Issue_Level_1__c).toLowerCase());
                }
                        
                for (Case oldCase: (List<Case>)tp.oldList){
                    if(oldCase.Id == newCase.Id){
                                //Portal Changes in Location Field, so synchronize SFDC Location Field
                       if(oldCase.Location_Level_3__c!=newCase.Location_Level_3__c && oldCase.Taxonomy_Location__c==newCase.Taxonomy_Location__c){
                           newCase.Taxonomy_Location_Id__c = newCase.Location_Level_3__c;
                           String newLocationTaxonomyFields = portalLocationTaxonomyMap.get(newCase.Location_Level_3__c);
                          //09/11/2017       Ian Fitzgerald      PBO Synch code changes to correct exception in lastIndexOf method.
                           newCase.Taxonomy_Location__c = newLocationTaxonomyFields.substring(0,newLocationTaxonomyFields.indexOf('$'));
                           newCase.Taxonomy_Area__c = newLocationTaxonomyFields.substring(newLocationTaxonomyFields.indexOf('$')+1, newLocationTaxonomyFields.lastIndexOf('$'));
                           newCase.Taxonomy_Location_Type__c = newLocationTaxonomyFields.substring(newLocationTaxonomyFields.lastIndexOf('$')+1);

                           System.debug('NEW LOCATION KEY: ' + newLocationTaxonomyFields);

                       }
                    }
               }
                        
                        
               if(!String.isBlank(newCase.Taxonomy_Location__c) && !String.isBlank(newCase.Taxonomy_Area__c) && !String.isBlank(newCase.Taxonomy_Location_Type__c)) {
                   System.debug('Size of locationTaxonomyMap: ' + locationTaxonomyMap.size());
                            
                   if (newCase.Taxonomy_Location_Id__c==null){//newCase.RecordTypeId!=rtpo.Id || 
                       Id locationTaxonomyId = locationTaxonomyMap.get((newCase.Taxonomy_Location__c+newCase.Taxonomy_Area__c+newCase.Taxonomy_Location_Type__c).toLowerCase());
                       System.debug('CaseBeforeUpdateTriggerHandler:: locationTaxonomyId:: ' + locationTaxonomyId);
                                
                       if(locationTaxonomyId != null) {
                          newCase.Taxonomy_Location_Id__c = locationTaxonomyId;
                          if(UserInfo.getProfileId()==TfNSWOperatorPortalProfileId){
                             newCase.Location_Level_3__c = locationTaxonomyId;
                          }
                          System.debug('CaseBeforeUpdateTriggerHandler:: Non-Portal Changes:: Updated Location_Level_3__c ' + locationTaxonomyId + ' on Case: ' + newCase.casenumber);
                       }
                       else System.debug('CaseBeforeUpdateTriggerHandler:: issueTaxonomyId not found for combination: ' + (newCase.Taxonomy_Location__c+newCase.Taxonomy_Area__c+newCase.Taxonomy_Location_Type__c + ' locationTaxonomyId: ' + locationTaxonomyId).toLowerCase());
                    }
                }                 
           }//if - is PO/LRO Record Type  
        }//trigger for-loop
    }
    
    
    /*********************************************************************************************************
       28/09/2017 Ian Fitzgerald - Retrieve all required Taxonomy in one place rather than 3 separate queries
    **********************************************************************************************************/   
    private List<Taxonomy_Metadata__c> retrieveTaxonomyList(TriggerParameters tp){
        
        Set<String> lvl1 = new Set<String>();
        Set<String> lvl2 = new Set<String>();
        Set<String> lvl3 = new Set<String>();
        Set<String> loc_lvl1 = new Set<String>();
        Set<String> loc_lvl2 = new Set<String>();
        Set<String> loc_lvl3 = new Set<String>();
        Set<String> portalLocationIds = new Set<String>();
        
        System.debug('prepareIssueTaxonomyList: tp size' + tp.newList.size());
        
        for (Case newCase : (List<Case>)tp.newList){
            lvl1.add(newCase.Issue_Level_1__c);
            lvl2.add(newCase.Issue_Level_2__c);
            lvl3.add(newCase.Issue_Level_3__c);
            loc_lvl1.add(newCase.Taxonomy_Location_Type__c);
            loc_lvl2.add(newCase.Taxonomy_Area__c);
            loc_lvl3.add(newCase.Taxonomy_Location__c);
            if(newCase.Location_Level_3__c!=null)
                portalLocationIds.add(newCase.Location_Level_3__c);
        }
            
        system.debug('retrieveTaxonomyList lvl1: ' + lvl1);  
        system.debug('retrieveTaxonomyList lvl2: ' + lvl2);  
        system.debug('retrieveTaxonomyList lvl3: ' + lvl3); 
        system.debug('retrieveTaxonomyList loc_lvl1: ' + loc_lvl1);  
        system.debug('retrieveTaxonomyList loc_lvl2: ' + loc_lvl2);  
        system.debug('retrieveTaxonomyList loc_lvl3: ' + loc_lvl3);  
        system.debug('retrieveTaxonomyList portalLocationIds: ' + portalLocationIds);
            
        List< Taxonomy_Metadata__c> txList = [SELECT Id, Type__c, Name, Parent_Id__r.name, Parent_Id__r.Parent_Id__r.Name  FROM Taxonomy_Metadata__c 
                                                  WHERE (Type__c = 'Issue' 
                                                        AND name in :lvl3  AND Parent_Id__r.name in :lvl2 
                                                        AND Parent_Id__r.Parent_Id__r.Name in :lvl1)
                                                  OR    (Type__c = 'Location' 
                                                         AND name in :loc_lvl3  AND Parent_Id__r.name in :loc_lvl2 
                                                         AND Parent_Id__r.Parent_Id__r.Name in :loc_lvl1)
                                                  OR     (Type__c = 'Location' 
                                                         AND Id in :portalLocationIds)];
            
            
        return txList;
    }
    
    private Map<String, Id> prepareIssueTaxonomyMap(List<Taxonomy_Metadata__c> txList){
        Map<String, Id> txMap = new Map<String, Id>();
        
        For (Taxonomy_Metadata__c tx : txList){
            if (tx.Type__c=='Issue'){
                txMap.put((tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name).toLowerCase() , tx.Id);
                system.debug('prepareIssueTaxonomyList:: Added to Issue Map: ' + tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name + ' id: ' + tx.Id);
            }
        }
        system.debug('Location Map' + txMap);            
        
        return txMap;
    }
    
    private Map<String, Id> prepareLocationTaxonomyMap(List<Taxonomy_Metadata__c> txList){
        Map<String, Id> txMap = new Map<String, Id>();
        
        For (Taxonomy_Metadata__c tx : txList){
            if (tx.Type__c=='Location'){
                txMap.put((tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name).toLowerCase() , tx.Id);
                system.debug('Added to Location Map: ' + tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name + ' id: ' + tx.Id);
            }
        }
        system.debug('Location Map' + txMap);            
        
        return txMap;
    }

    private Map<Id, String> preparePortalLocationTaxonomyMap(List<Taxonomy_Metadata__c> txList){
        Map<Id, String> txMap = new Map<Id, String>();

        for (Taxonomy_Metadata__c tx : txList){
            if(tx.Type__c=='Location'){
                txMap.put(tx.Id, tx.Name + '$' + tx.Parent_Id__r.name + '$'  + tx.Parent_Id__r.Parent_Id__r.Name);
                system.debug('Added to Portal Location Map: ' + tx.Name + tx.Parent_Id__r.name + tx.Parent_Id__r.Parent_Id__r.Name + ' id: ' + tx.Id);
            }
        }
        system.debug('Location Map' + txMap);            
        return txMap;
    } 
    //SFCOE-880 22/04/2017 END  
    
   // Updated to check if child case is already being updated as part of the trigger.  this can happen
   // in bulk updates which causes a SELF_REFERENCE trigger error when updated again within the trigger
   // Ian F  26/09/2017
    private void transferChildCases(Map<Id,Id> parentCaseVsQueue, Map<Id,Id> parentCaseVsOwner) {
        if(parentCaseVsQueue.isEmpty()) {
            return;
        }
        System.debug('ParentCaseVsQueue: ' + parentCaseVsQueue);
        System.debug('ParentCaseVsOwner: ' + parentCaseVsOwner);
        List<Case> childCasesToUpdate = new List<Case>();
        for(Case childCase : [SELECT Id, OwnerId, IsGetNext__c, ParentId FROM Case WHERE ParentId IN :parentCaseVsQueue.keySet() ]) {
            //if previous owner of parent and child case is same queue
            if(parentCaseVsQueue.get(childCase.ParentId) == childCase.OwnerId) {
                Case triggerChildCase = (Case)trigger.newMap.get(childCase.Id);
                if (triggerChildCase != null){
                    triggerChildCase.OwnerId = parentCaseVsOwner.get(childCase.ParentId);
                } else {
                    childCase.OwnerId = parentCaseVsOwner.get(childCase.ParentId);
                    childCase.IsGetNext__c = true;
                    System.debug('Child case ' + childCase.Id + ' Owner changed to ' + childCase.OwnerId);
                    childCasesToUpdate.add(childCase);
                }
            }
        }
        
        if(childCasesToUpdate.isEmpty()) {
            return;
        }
        update childCasesToUpdate;
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This method will set the RecentActivityFlag to true if the case status is changed to reopened.
Inputs:        Trigger context parameters

History
<Date>        <Authors Name>     <Brief Description of Change>
20/08/2015    Manish Damle       Created
------------------------------------------------------------*/
    public void setRecentActivityFlagOnCase(TriggerParameters tp) {
        map <Id,Id> caseIdVsOwnerQueueId = new map <Id,Id>();
        DateTime now = DateTime.now();
        for (Id aCaseId:tp.newMap.keySet()){
            Case oldCase = (Case)tp.oldMap.get(aCaseId);
            Case newCase = (Case)tp.newMap.get(aCaseId);
            
            if((oldCase.Status == GlobalConstants.CASE_SOFTCLOSED_STATUS || oldCase.Status == GlobalConstants.CASE_CLOSED_STATUS ) 
               && newCase.Status == GlobalConstants.CASE_REOPENED_STATUS)  {
                   newCase.RecentActivityFlag__c = true;
               }
        }
        
        //Any field update performed by the user will turn off the bulb
        for(Id aCaseId:tp.newMap.keySet()){
            Case oldCase = (Case)tp.oldMap.get(aCaseId);
            Case newCase = (Case)tp.newMap.get(aCaseId);
            if(oldCase.LastModifiedDate != null) {
                Long elapsedSeconds = (now.getTime() - oldCase.LastModifiedDate.getTime())/1000;            
                system.debug('--------@Set Activity Flag---Time Diff-----' + now + ' - ' + oldCase.LastModifiedDate + ' -> ' + elapsedSeconds);                 
                if(elapsedSeconds > 3 && oldCase.RecentActivityFlag__c == true && newCase.RecentActivityFlag__c == true) {
                    newCase.RecentActivityFlag__c = false;
                }
            }
        }
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This method will populate the last Assigned queue also it will calculate the hard close date.
Inputs:        Trigger context parameters

History
<Date>        <Authors Name>     <Brief Description of Change>
08/05/2015    Manish Damle       Created
------------------------------------------------------------*/
    public void determineLastAssignedQueue(TriggerParameters tp) {
        map <Id,Id> caseIdVsOwnerQueueId = new map <Id,Id>();
        for (Id aCaseId:tp.newMap.keySet()){
            Case oldCase=(Case)tp.oldMap.get(aCaseId);
            Case newCase=(Case)tp.newMap.get(aCaseId);
            //If owner is changed to queue then capture that Queue Name
            if(oldCase.OwnerId != newCase.OwnerId && ((String) newCase.OwnerId).startsWith('00G'))  {
                caseIdVsOwnerQueueId.put(newCase.Id, newCase.OwnerId);
            }
        }
        
        //Capture Last Queue Assigned
        //map <Id,Group> queues = new map <Id, Group> ([Select Id,DeveloperName From Group Where Id IN: caseIdVsOwnerQueueId.values()]);
        map <Id,Group> queues = CaseTriggerDispatcher.queues;
        map<String,Decimal> agencyDuration= new map<String,Decimal>(); //get the custom settings
        for(ReopenDuration__c r: ReopenDuration__c.getAll().values()) {
            agencyDuration.put(r.name, r.Duration__c);
        }
        System.debug('caseIdVsOwnerQueueId' + caseIdVsOwnerQueueId);
        for(Id aCaseId:tp.newMap.keySet()){
            Case oldCase = (Case)tp.oldMap.get(aCaseId);
            Case newCase = (Case) tp.newMap.get(aCaseId);
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
            
            //Capture the date when Status is changed to Resolved
            if(oldCase.Status != GlobalConstants.CASE_SOFTCLOSED_STATUS && newCase.Status == GlobalConstants.CASE_SOFTCLOSED_STATUS) {
                newCase.Case_Resolution_Date__c = date.today();
                if(newCase.OwnerAgency__c != null && agencyDuration.containsKey(newCase.OwnerAgency__c)) {
                    newCase.Reopen_Till_Date__c = date.today().addDays(agencyDuration.get(newCase.OwnerAgency__c).intValue());
                } else {
                    Integer days = agencyDuration.containsKey('Default') ? agencyDuration.get('Default').intValue() : 0;
                    newCase.Reopen_Till_Date__c = date.today().addDays(days);
                }
            } else if(oldCase.Status == GlobalConstants.CASE_SOFTCLOSED_STATUS && newCase.Status != GlobalConstants.CASE_SOFTCLOSED_STATUS){
                newCase.Case_Resolution_Date__c = null;
                newCase.Reopen_Till_Date__c = null;
            }
            system.debug('-----Case Resolved------' + newCase.Case_Resolution_Date__c);
        }
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This method will populate the PBO/LRO email address from custom settings.
Inputs:        Trigger context parameters

History
<Date>        <Authors Name>     <Brief Description of Change>
13/05/2015    Manish Damle       Created
------------------------------------------------------------*/
    public void determinePBOLROEmailAddress(TriggerParameters tp) {
        map<String,String> l1vsEmail = new map<String,String>(); //get the custom settings
        for(PBOLROEmailAddressConfiguration__c r: PBOLROEmailAddressConfiguration__c.getAll().values()) {
            l1vsEmail.put(r.Location_Level_1__c, r.Email__c);
        }
        
        for(Case newCase:(List<Case>)tp.newList) {            
            if(newCase.Taxonomy_Location_Type__c != null && newCase.Taxonomy_Location_Type__c != '' && l1vsEmail.containsKey(newCase.Taxonomy_Location_Type__c)) {
                newCase.PBLROperator_Email_Address__c = l1vsEmail.get(newCase.Taxonomy_Location_Type__c);
            } else {
                newCase.PBLROperator_Email_Address__c = null;
            }
        }
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This method will validate whether all the child campaigns/cases  
are closed or not before closing the Campaign/cases
Inputs:        Trigger context parameters

History
<Date>        <Authors Name>     <Brief Description of Change>
21/05/2015    Manish Damle       Created
25/05/2015    Manish Damle       Updated to support all types of cases.
10/07/2015    Manish Damle       Added Closed - NRR status as an exception for Child Cases.(WI-0001062)
------------------------------------------------------------*/
    private void validateChildCasesAreClosed(TriggerParameters tp){
        set <Id> parentCases = new set<Id>();
        for(Case c : (list <Case>)tp.newList) {
            system.debug('----Case----' + c);
            if(c.ParentId == null 
               && c.Response_Type__c != GlobalConstants.CASE_NRR_RESPONSE_TYPE
               && (c.Status == GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO 
                   || c.Status == GlobalConstants.CASE_CLOSED_STATUS
                   || c.Status == GlobalConstants.CASE_SOFTCLOSED_STATUS)) {
                       parentCases.add(c.Id);
                   }
            
        }
        
        if(parentCases.size() > 0) {
            system.debug('----Parent Campaigns----' + parentCases);
            map<Id, Integer> parentVsChildCount = new map<Id, Integer>();
            set <String> status = new set<String> { GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO ,
                GlobalConstants.CASE_CLOSED_STATUS,
                GlobalConstants.CASE_SOFTCLOSED_STATUS,
                GlobalConstants.CASE_NRR_STATUS_MIN_CORRO };
                    for(AggregateResult agResult : [Select COUNT(ID) childCases, ParentId parent 
                                                    From Case 
                                                    Where ParentId IN : parentCases 
                                                    And Status NOT IN: status
                                                    Group By ParentId] ) {
                                                        parentVsChildCount.put((Id) agResult.get('parent'), Integer.valueOf(agResult.get('childCases')));
                                                    }
            
            system.debug('----parentVsChildCount----' + parentVsChildCount);
            
            for(Id caseId : parentCases) { 
                if(parentVsChildCount.containsKey(caseId) && tp.newMap.containsKey(caseId)) {
                    case caseRecord = (Case) tp.newMap.get(caseId);
                    if(parentVsChildCount.get(caseId) > 0){
                        //Validation should run only for Campains and CFM record types.
                        if(caseRecord.RecordTypeId == CaseTriggerDispatcher.caseRecordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGN)) { 
                            caseRecord.addError('Campaign cannot be closed. Please close all the linked cases before closing a campaign');
                        } else if(!CaseTriggerDispatcher.recordTypesMinCorroNonCampaign.contains(caseRecord.RecordTypeId)){
                            //Skip the NON CFM and Campaign record types.
                            caseRecord.addError('Case cannot be closed. Please close all the linked cases before closing a parent case');
                        }
                    }
                }
            }     
        }
    }
    
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Copy Campaign details to Campaign Member only when Parent record Is Changed.
1. Owner
2. Subject if blank on the Campaign Member
3. Description (Concatenate the Description to existing content)
4. Categorisation
5. Priority
6. Classification
7. Minister
8. Signatory

Inputs:        Trigger context parameters

History
<Date>        <Authors Name>     <Brief Description of Change>
21/05/2015    Manish Damle       Created
28/05/2015    Manish Damle       Updated. Added new fields to copy.
------------------------------------------------------------*/
    private void populateCampaignMemberFieldsFromCampaign(TriggerParameters tp) {   
        System.debug('-----------populateCampaignMemberFieldsFromCampaign--------' + CaseTriggerDispatcher.blockReentryToCampaignMemberFieldsFromCampaignMethod);
        if(CaseTriggerDispatcher.blockReentryToCampaignMemberFieldsFromCampaignMethod == false) {
            list <Case> campaignMembers = new list <Case>();
            map <Id,Id> campaignMemberVsCampaignId = new map <Id,Id>();
            System.debug('-----------Populate Campaign Member Fields From Campaign Member--------');
            for(Case c : (list <Case>) tp.newList) {
                System.debug('-----------c.RecordTypeId--------' + c.RecordTypeId + ' -> ' + c.ParentId);
                if(c.RecordTypeId == CaseTriggerDispatcher.caseRecordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGNMEMBER)) {
                    Case oldCase = (Case) tp.oldMap.get(c.Id); 
                    Case newCase = (Case) tp.newMap.get(c.Id);   
                    System.debug('-----------Parent Ids--------' + oldCase.ParentId + ' -> ' + newCase.ParentId);
                    if(oldCase.ParentId != newCase.ParentId && newCase.ParentId != null) {
                        campaignMembers.add(newCase);
                        campaignMemberVsCampaignId.put(newCase.Id, newCase.ParentId);
                    }
                }
            }      
            System.debug('-----------Populate Campaign Member Fields From Campaign Member--------' + campaignMemberVsCampaignId);
            if(campaignMemberVsCampaignId.size() > 0) {
                map <Id, Case> campaigns = new map <Id, Case> ([Select Id, CaseNumber, Description, Subject, OwnerId, OBO__c, ContactId,
                                                                Priority, Classification__c,Minister__c,Minister_User__c, Signatory__c,Other_Signatory__c, 
                                                                Taxonomy_Moment__c,Taxonomy_Transaction__c, Taxonomy_Location_Type__c,
                                                                Taxonomy_Symptom__c, Taxonomy_Location__c, Taxonomy_Area__c,Modes__c
                                                                From Case 
                                                                Where Id IN: campaignMemberVsCampaignId.values()]);
                for(Case newCase : campaignMembers) {
                    newCase.OwnerId = campaigns.get(newCase.ParentId).OwnerId;
                    newCase.Subject = newCase.Subject == null ? campaigns.get(newCase.ParentId).Subject : newCase.Subject;
                    //String caseDescription = campaigns.get(newCase.ParentId).Description == null ? '' : '-----Campaign Description-----\n' + campaigns.get(newCase.ParentId).Description + '\n\n' + (newCase.Description == null ? '' : newCase.Description); 
                    
                    //Changes by Gary on 06/02/2016:: Issue Faced by Nick Race - Description getting removed on Child Cases 
                    String caseDescription = campaigns.get(newCase.ParentId).Description == null ? newCase.Description : '-----Campaign Description-----\n' + campaigns.get(newCase.ParentId).Description + '\n\n' + (newCase.Description == null ? '' : newCase.Description);                    
                    System.debug('Child Case Description Before Evaluation: ' + newCase.Description);
                    
                    newCase.Description =  caseDescription;
                    System.debug('Child Case Description After Evaluation: ' + newCase.Description);
                    
                    newCase.Taxonomy_Moment__c = campaigns.get(newCase.ParentId).Taxonomy_Moment__c;
                    newCase.Taxonomy_Transaction__c = campaigns.get(newCase.ParentId).Taxonomy_Transaction__c;
                    newCase.Taxonomy_Location_Type__c = campaigns.get(newCase.ParentId).Taxonomy_Location_Type__c;
                    newCase.Taxonomy_Symptom__c = campaigns.get(newCase.ParentId).Taxonomy_Symptom__c;
                    newCase.Taxonomy_Location__c = campaigns.get(newCase.ParentId).Taxonomy_Location__c;
                    newCase.Taxonomy_Area__c = campaigns.get(newCase.ParentId).Taxonomy_Area__c;
                    newCase.Modes__c = campaigns.get(newCase.ParentId).Modes__c;
                    newCase.Priority = campaigns.get(newCase.ParentId).Priority;
                    newCase.Classification__c = campaigns.get(newCase.ParentId).Classification__c;
                    newCase.Minister__c = campaigns.get(newCase.ParentId).Minister__c;
                    newCase.Minister_User__c = campaigns.get(newCase.ParentId).Minister_User__c;
                    newCase.Signatory__c = campaigns.get(newCase.ParentId).Signatory__c;
                    newCase.Other_Signatory__c = campaigns.get(newCase.ParentId).Other_Signatory__c;
                }
            }
            CaseTriggerDispatcher.blockReentryToCampaignMemberFieldsFromCampaignMethod = true;
        }
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Change the status of the Case when ownership changes.
CRGS Admin User => MAGS Queue = Allocation
MAGS Queue => MAGS officer or MAGS manager = Research
GIS Admin => RMS Corro Officer Queue = Allocation
RMS Corro Officer Queue => Corro Officer = Research
Inputs:        Trigger context parameters

History
<Date>        <Authors Name>     <Brief Description of Change>
28/05/2015    Manish Damle       Created
22/06/2015    Manish Damle       Updated
23/07/2015    Manish Damle       If case is Classification is Contentious 
and if the status is Manage Review then do not
change the status else change the status to Editor Review
WI1068
------------------------------------------------------------*/  
    @testVisible
    private void changeMinCorroCaseStatus(TriggerParameters tp) {
        
        for(Case c : (list <Case>) tp.newList) {
            Case oldCase = (Case) tp.oldMap.get(c.Id); 
            Case newCase = (Case) tp.newMap.get(c.Id);  
            if(oldCase.Status != newCase.Status 
               && newCase.Status == GlobalConstants.DRAFT_MANAGER_REVIEW_STATUS 
               && newCase.Classification__c != null 
               && !GlobalConstants.draftCaseClassifications.contains(newCase.Classification__c)) {
                   newCase.Status =  oldCase.Status;
                   //WI1068
               }
            system.debug('---@Case Status Flow---' + oldCase.ownerId + ' -> ' +  newCase.OwnerId);
            system.debug('---@Case Status Flow CRGS Admis---' + CaseTriggerDispatcher.crgsAdmins);
            system.debug('---@Case Status Flow Queues---' + CaseTriggerDispatcher.minCorroQueues);
            if(oldCase.ownerId != newCase.OwnerId) {
                
                if(CaseTriggerDispatcher.crgsAdmins.contains(oldCase.OwnerId) 
                   && (CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME) 
                       || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_A_QUEUE_NAME)
                       || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_B_QUEUE_NAME)
                       || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_C_QUEUE_NAME)
                       || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_D_QUEUE_NAME)
                       || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_E_QUEUE_NAME)
                       || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_F_QUEUE_NAME)
                      )
                   && (newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME)
                       || newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_A_QUEUE_NAME)
                       || newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_B_QUEUE_NAME)
                       || newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_C_QUEUE_NAME)
                       || newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_D_QUEUE_NAME)
                       || newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_E_QUEUE_NAME)
                       || newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_F_QUEUE_NAME)
                      )) {
                          newCase.Status =  GlobalConstants.ALLOCATION_STATUS_MIN_CORRO;  
                          system.debug('---@Case Status Flow---Status Changed To--1' + newCase.Status);           
                      } 
                else if((CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME) 
                         || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_A_QUEUE_NAME)
                         || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_B_QUEUE_NAME)
                         || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_C_QUEUE_NAME)
                         || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_D_QUEUE_NAME)
                         || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_E_QUEUE_NAME)
                         || CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.MAGS_TEAM_F_QUEUE_NAME)  
                        )
                        && (oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME) 
                            || oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_A_QUEUE_NAME)
                            || oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_B_QUEUE_NAME)
                            || oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_C_QUEUE_NAME)
                            || oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_D_QUEUE_NAME)
                            || oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_E_QUEUE_NAME)
                            || oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.MAGS_TEAM_F_QUEUE_NAME)
                           )
                        && CaseTriggerDispatcher.magsAdmins.contains(newCase.OwnerId)) {
                            newCase.Status =  GlobalConstants.RESEARCH_STATUS_MIN_CORRO;   
                            system.debug('---@Case Status Flow---Status Changed To--2' + newCase.Status);           
                        } 
                else if(CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.RMS_CORRO_OFFICER_QUEUE_API_NAME) 
                        && newCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.RMS_CORRO_OFFICER_QUEUE_API_NAME)) {
                            newCase.Status =  GlobalConstants.ALLOCATION_STATUS_MIN_CORRO;    
                            system.debug('---@Case Status Flow---Status Changed To--3' + newCase.Status);           
                        } 
                else if(CaseTriggerDispatcher.minCorroQueues.containsKey(GlobalConstants.RMS_CORRO_OFFICER_QUEUE_API_NAME)
                        && oldCase.OwnerId == CaseTriggerDispatcher.minCorroQueues.get(GlobalConstants.RMS_CORRO_OFFICER_QUEUE_API_NAME)
                        && CaseTriggerDispatcher.corroOfficers.contains(newCase.OwnerId)) {
                            newCase.Status =  GlobalConstants.RESEARCH_STATUS_MIN_CORRO;            
                            system.debug('---@Case Status Flow---Status Changed To--4' + newCase.Status);           
                        }
            }
        }
    }
}