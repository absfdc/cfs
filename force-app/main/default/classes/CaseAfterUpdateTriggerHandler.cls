/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   After Update handler class for the Case trigger
               
Test Class:    CaseTriggerDispatcher_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
14/04/2015     Manish Damle       Created
12/01/2017     Arxxus             Optimised usage of soql queries 
19/04/2017     Ian Fitzgerald     Keep static map of Owner and Agency changes that have been processed
                                  to save on SOQL queries. 
28/09/2017     Ian Fitzgerald     Added check for MinCorro before updating Contact Made/Attempted Timestamps
                                  Added check for child case status in closeTheChildCasesNonCampaignNonCFM    
                                                              
-----------------------------------------------------------------------------------------*/
public without sharing class CaseAfterUpdateTriggerHandler extends TriggerHandlerBase {
    
    private static boolean hasrun = false;
    
    /*********************************************************************************
     Added by Ian F. 19/Apr/2017 to store the Owners and Agencies that have been 
     processed. 
     *********************************************************************************/
    private static Map<Id, Id> ownerChangeProcessed = new Map<Id, Id>();
    private static Map<Id, String> ownerAgencyProcessed = new Map<Id, String>();
    /*********************************************************************************
     END -Added by Ian F. 19/Apr/2017
     *********************************************************************************/
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        if (CaseEntitlementUtil.isReassigned==true) return;//dont execute for reassignment
        processInProgress(tp);
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   1. Chage the Owner of the notes and attachments under case to new 
                      case owner whenever case owner is updated
                   2. Close the action plan records if no action required on case 
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    14/04/2015     Manish Damle       Created
     -------------------------------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try {
            NoteOrAttachmentOwnershipUpdater ownershipUpdater = new NoteOrAttachmentOwnershipUpdater();
            ownershipUpdater.updateOwnership(tp);
    
            ActionPlanStatusUpdater aPlanStatusUpdater = new ActionPlanStatusUpdater();
            aPlanStatusUpdater.closeRelatedActionPlan(tp);
            
            Map<Id,Case> parentCaseByIdForChildUpdate= new Map<Id,Case>();
            
            //Relcalculate the sharing of action Plan records if ownership of the case is changed.
            set <Id> caseIds = new set <Id>();
            Map<Id,Set<Id>> caseMilestonesByIdForUpdate= new Map<Id,Set<Id>> ();

            CaseEntitlementUtil entitle=new 
            CaseEntitlementUtil();
            //If we have oldEntitlemntIdByCaseID the milestones for which need to be deleted then lets do it
            List<CaseMilestone> milestonesForReset=entitle.getOldMilestones();
            if (milestonesForReset!=null &&  milestonesForReset.size()>0)  update milestonesForReset;
            Set<Id> casesForTargetDateUpdate = new Set<Id>();
            Set<Id> suspectOwnerAgencyChangedParent= new Set<Id> ();//determineMultiAgency

            for (Id aCaseId:tp.newMap.keySet()){ 

                //get the old and new case records
                Case oldCase=(Case)tp.oldMap.get(aCaseId);
                Case newCase=(Case)tp.newMap.get(aCaseId);
                 //determineMultiAgency
                 
                /*********************************************************************************
                 Added by Ian F. 19/Apr/2017 to check if the Owner and/or Agency has already been 
                 processed.  
                 There is a Workflow rule that updates a counter on the Case called "Returned to Queue Count"
                 when the owner changes from a user to a queue.
                 This update fires the triggers a second time and they are unnecessarily executing the 
                 sharing rule logic a second time.
               **********************************************************************************/  
                Id processedOwner = ownerChangeProcessed.get(newCase.Id);
                Boolean ownerProcessed = (processedOwner!=null && processedOwner==newCase.OwnerId);
                System.debug('CaseAfterUpdateTriggerHandler ownerProcessed : '+ownerProcessed);
                System.debug('CaseAfterUpdateTriggerHandler newCase.Id : '+newCase.Id +'  processedOwner : '+processedOwner + '  newCase.OwnerId : '+newCase.OwnerId + '  oldCase.OwnerId : '+oldCase.OwnerId);
                ownerChangeProcessed.put(newCase.Id, newCase.OwnerId);
            
                String processedAgency = ownerAgencyProcessed.get(newCase.Id);
                Boolean agencyProcessed = (processedAgency!=null && processedAgency==newCase.OwnerAgency__c);
                ownerAgencyProcessed.put(newCase.Id, newCase.OwnerAgency__c);
                /*********************************************************************************
                 END - Added by Ian F. 19/Apr/2017
                **********************************************************************************/   
                
                if ( agencyProcessed==false &&
                    (oldCase.OwnerAgency__c!=newCase.OwnerAgency__c || 
                    (oldCase.OwnerAgency__c==null && newCase.OwnerAgency__c!=null) )
                    && newCase.ParentId!=null){
                     suspectOwnerAgencyChangedParent.add(newCase.ParentId);
                }
                
                //if child are catagorised first and parent assigned later, determineMultiAgency requires to be called
                if(ownerProcessed==false &&
                   (oldCase.ownerId!=newCase.OwnerId || 
                   (oldCase.ownerId==null && newCase.ownerId!=null)) 
                   && newCase.ParentId==null){
                    suspectOwnerAgencyChangedParent.add(newCase.Id);
                }
                
                //check milestone completion 
                Set<Id> completedMilestones=entitle.checkMilestoneCompletion(oldCase,newCase);
                if(completedMilestones.size()>0) caseMilestonesByIdForUpdate.put(aCaseId,completedMilestones);

                System.debug('CaseAfterUpdateTriggerHandler adding caseIDs ownerProcessed : '+ownerProcessed);
                System.debug('CaseAfterUpdateTriggerHandler adding caseIDs  newCase.OwnerId : '+newCase.OwnerId + '  oldCase.OwnerId : '+oldCase.OwnerId);
                
                if(ownerProcessed==false && oldCase.OwnerId != newCase.OwnerId) {
                    caseIds.add(newCase.Id);
                }
                
                /****************************************************************************************************
                 Ian F. 28/Oct/2017 - Added check for Min Corro, updating these timestamps not required for Min Corro
                ******************************************************************************************************/
                //if modes__c is Multi Issue and Contact_Attempted_Timestamp__c or Contact_Made_Timestamp__c is updated then update the same in child
                if(newCase.modes__c==GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE && newCase.IsMinCorroCase__c==false){
                    if (newCase.Contact_Attempted_Timestamp__c!=oldCase.Contact_Attempted_Timestamp__c && newCase.Contact_Attempted_Timestamp__c!=null){
                        parentCaseByIdForChildUpdate.put(newCase.Id, newCase);
                    }
                    if (newCase.Contact_Made_Timestamp__c!=oldCase.Contact_Made_Timestamp__c && newCase.Contact_Made_Timestamp__c!=null){
                        parentCaseByIdForChildUpdate.put(newCase.Id, newCase);
                    }
                }
                

                //check milestone assignment
                if ( (agencyProcessed==false && oldCase.OwnerAgency__c!=newCase.OwnerAgency__c)
                    || oldCase.Origin !=newCase.Origin
                    || oldCase.Response_Requested__c !=newCase.Response_Requested__c
                    || oldCase.Type !=newCase.Type
                    || oldCase.Status !=newCase.Status
                    || oldCase.Priority !=newCase.Priority
                    || (oldCase.Agency__c!=newCase.Agency__c && newCase.ClosureTargetDate__C==null)
                ){
                    casesForTargetDateUpdate.add(newCase.Id);
                }


            }
            if(CaseEntitlementUtil.isReassigned == null || CaseEntitlementUtil.isReassigned == false ){
                //determineMultiAgency
                Map<Case,List<Case>> suspectParentChild = new Map<Case,List<Case>>();
                
                if(suspectOwnerAgencyChangedParent.size() > 0) {
                
                 for (Case parent:[select Id, MultiAgency__c, Agency__c,OwnerAgency__c,ownerId, parentId,(select Id, Agency__c,MultiAgency__c, OwnerAgency__c, parentId,ownerId from cases ) from case where Id in :suspectOwnerAgencyChangedParent]){
                    suspectParentChild.put(parent,parent.cases);
                 }
                }
                
                if(suspectParentChild.size()>0) {
                    Map<Id,Case> updateMultiagency=entitle.determineMultiAgency(suspectParentChild);
                    if (updateMultiagency!=null && updateMultiagency.size()>0)  {
                        Map<Id,Id> caseVsOwnerIds= new Map<Id,Id>();
                        Map<Id,boolean> caseVsMultiAgency= new Map<Id,boolean>();

                        for (Case aCase:updateMultiagency.values()) {
                            caseVsMultiAgency.put(aCase.Id, aCase.MultiAgency__c);
                            Id ownerId=aCase.ownerId;
                            if(tp.oldMap.containsKey(aCase.Id)){
                                ownerId=((Case)tp.oldMap.get(aCase.Id)).ownerId;
                                caseVsOwnerIds.put(aCase.Id,ownerId);

                            }
                        }
                        //basically call to updateCaseTargetDate is chained here
                        if (AssignCase_Cx.pressed==true && !System.isFuture()) CaseEntitlementUtil.reassignCaseWithActiveRule(caseVsOwnerIds,caseVsMultiAgency,casesForTargetDateUpdate);
                        system.debug('updateMultiagency - '+updateMultiagency.values());
                        update updateMultiagency.values();
                    }
                }
            }
            
            for (Id aCaseId:tp.newMap.keySet()){
                Case newCase=(Case)tp.newMap.get(aCaseId);
                if(GlobalConstants.MULTI_ISSUE_TYPE.equalsIgnoreCase(newCase.Type) && newCase.ClosureTargetDate__c == null) {
                    casesForTargetDateUpdate.add(newCase.Id);
                }
            }
                        
            if(casesForTargetDateUpdate.size()>0 && !System.isFuture() && !System.isBatch()){
                CaseEntitlementUtil.updateCaseTargetDate(casesForTargetDateUpdate);
            }


            //copy Contact_Attempted_Timestamp__c or Contact_Made_Timestamp__c from parent to child cases
            if(parentCaseByIdForChildUpdate.size()>0){
                Map <Id, Case> casesToUpdate=
                entitle.percolateContactedTimestamps(parentCaseByIdForChildUpdate);
                if (casesToUpdate.size()>0) update casesToUpdate.values();
            
            }
           
             //complete the milestones
            if (caseMilestonesByIdForUpdate.size()>0){
                List<CaseMilestone> completed=entitle.completeMilestones(caseMilestonesByIdForUpdate);
                if (completed.size()>0) update completed;

            }

            if(caseIds.size() > 0) {
                list <Action_Plan__c> actionsPlans =  [Select Id, Parent_Case__c, OwnerId, Parent_Action_Plan__c 
                                                       From Action_Plan__c 
                                                       Where Parent_Case__c In: caseIds];
                database.update(actionsPlans, false);
            }
            
            CaseCustomRollUpImpl rollUp = new CaseCustomRollUpImpl();
            rollUp.calculateRollUp((map <Id, Case>) tp.newMap, (map <Id, Case>) tp.oldMap);  
            changeTheCampaignMemberOwnerToCampaignOwner(tp);
            restrictUserFromChangingTheCaseStatusIfOpenActionPlansPresent(tp);
            closeTheChildCasesNonCampaignNonCFM(tp);
            reCalculateCaseSharing(tp);
            
            List<Id> casesToShare = new List<Id>();
            for(Case caseRecord : (List<Case>) tp.newList) {
                if(isCategorisationUpdated(((Case) tp.oldMap.get(caseRecord.Id)), caseRecord)) {
                    casesToShare.add(caseRecord.Id);
                }
            }
            if(!casesToShare.isEmpty()) {
                //ShareCaseOnCategorisationUpdate.checkForSNSWSharing(casesToShare);
            }
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseAfterUpdateTriggerHandler';
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
        }
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   close child case milestones on a parent case event Ex: contact made milestones
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    14/04/2015     Dipankar Barman       Created
     -------------------------------------------------------------------------------------*/
    private void processInProgress(TriggerParameters tp) {
        try {
           
            Map<Id,Set<Id>> caseMilestonesByIdForUpdate= new Map<Id,Set<Id>> ();
            CaseEntitlementUtil entitle=new 
            CaseEntitlementUtil();
            
            for (Id aCaseId:tp.newMap.keySet()){ 
                //get the old and new case records
                Case oldCase=(Case)tp.oldMap.get(aCaseId);
                Case newCase=(Case)tp.newMap.get(aCaseId);
                
                //check milestone completion 
                Set<Id> completedMilestones=entitle.checkMilestoneCompletion(oldCase,newCase);
                if(completedMilestones.size()>0) caseMilestonesByIdForUpdate.put(aCaseId,completedMilestones);

                

            }
            
            //complete the milestones
            if (caseMilestonesByIdForUpdate.size()>0){
                List<CaseMilestone> completed=entitle.completeMilestones(caseMilestonesByIdForUpdate);
                if (completed.size()>0) update completed;

            }
            
            
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseAfterUpdateTriggerHandler';
            message.sourceFunction='processInProgres';
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
        }
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This methid will recalculate the sharing for child cases

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    05/06/2015     Dipankar Barman    Created
    -------------------------------------------------------------------------------------*/
    private void reCalculateCaseSharing(TriggerParameters tp) {
        List<Case> oldCases = new List<Case>();
        List<Case> casesToCreateSharing = new List<Case>();
        List<Id> parentCaseIdsToReProcess = new List<Id>();
        for(Case caseRecord : (List<Case>) tp.newList) {
            if(caseRecord.OwnerId != ((map <Id, Case>) tp.oldMap).get(caseRecord.Id).OwnerId) {
                if(caseRecord.ParentId != null) {
                    casesToCreateSharing.add(caseRecord);
                } else {
                    parentCaseIdsToReProcess.add(caseRecord.Id);
                    oldCases.add(((map <Id, Case>) tp.oldMap).get(caseRecord.Id));
                }
            }
        }
        if(!parentCaseIdsToReProcess.isEmpty()) {
            casesToCreateSharing.addAll([SELECT Id, RecordTypeId, ParentId FROM Case WHERE ParentId IN :parentCaseIdsToReProcess]);
        }
        if(!oldCases.isEmpty()) {
            ChildCaseShareRemover shareRemover = new ChildCaseShareRemover(oldCases);
            shareRemover.deleteShare();
        }
        if(!casesToCreateSharing.isEmpty()) {
            ChildCaseSharingCreator shareCreator = new ChildCaseSharingCreator(casesToCreateSharing);
            shareCreator.createShareRecords();
        }
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Whenever campaign owner is changed then Owner of the child campaigns shoudl be changed
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    21/04/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/    
    private void changeTheCampaignMemberOwnerToCampaignOwner(TriggerParameters tp) {
        map <Id, Id> campaigns = new map <Id, Id> ();
        for(Case c : (list <Case>) tp.newList) {
            Case oldCase = (Case) tp.oldMap.get(c.Id);
            Case newCase = (Case) tp.newMap.get(c.Id);
            if(newCase.RecordTypeId == CaseTriggerDispatcher.caseRecordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGN) 
               && newCase.OwnerId != oldCase.OwnerId) {
                campaigns.put(newCase.Id, newCase.OwnerId);
            }
        }
        
        if(campaigns.size() > 0) {
            system.debug('----Campaigns-----' + campaigns);
            list <Case> campaignMembers = [Select Id, OwnerId, ParentId From Case Where ParentId IN: campaigns.keySet()];
            system.debug('----Campaign Members-----' + campaignMembers);
            for(Case c : campaignMembers) {
                system.debug('----Old OwnerId-----' + c.OwnerId);
                c.OwnerId = campaigns.get(c.ParentId);
                system.debug('----New OwnerId-----' + c.OwnerId);
            }
            update campaignMembers;
        }
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will restrict the user from changing status from Awaiting Advice
                   to other if its has non closed action plans
    
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    01/06/2015     Manish Damle       Created
    09/07/2015     Manish Damle       Skip the validation if status is On Hold (WI-0001032)
    25/01/2017     Sharath Krishnaraj SFCOE-46 - Skip validation if status is Action Plan Rejected
    -------------------------------------------------------------------------------------*/ 
    private void restrictUserFromChangingTheCaseStatusIfOpenActionPlansPresent(TriggerParameters tp) {
        set <Id> caseIds = new set <Id>();
        for(Case c : (list <Case>) tp.newList) {
            Case oldCase = (Case) tp.oldMap.get(c.Id);
            Case newCase = (Case) tp.newMap.get(c.Id);
            system.debug('------Case Number----' + newCase.CaseNumber + '--' + newCase.Status + '---' + oldCase.Status);
            if(oldCase.Status == GlobalConstants.AWAITING_ADVICE_MIN_CORRO 
                && newCase.status != GlobalConstants.AWAITING_ADVICE_MIN_CORRO  
                && newCase.status != GlobalConstants.ON_HOLD_MIN_CORRO
                && newCase.status != GlobalConstants.REJECTED_STATUS_MIN_CORRO
                && newCase.Response_Type__c != GlobalConstants.CASE_NRR_RESPONSE_TYPE
                && CaseTriggerDispatcher.recordTypesMinCorro.contains(newCase.RecordTypeId)) {
                caseIds.add(newCase.Id);
            }
        }
        
        if(caseIds.size() > 0) {
            system.debug('------Case Ids For Validation----' + caseIds);
            map <Id, Integer> parentVsChildCount = ActionPlanUtility.createCaseVsNoOfActionPlansMap(null, caseIds);
            for(Id caseId : caseIds) {
                if(parentVsChildCount.containsKey(caseId) && parentVsChildCount.get(caseId) > 0) {
                    Case newCase = (Case) tp.newMap.get(caseId);
                    newCase.addError('You can not change the status because case has action plans which are not closed.');
                }
            }
        }   
    }
    
     /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will close the child cases if parent case is closed.
                   Consider Case Record Types : Roads_Freight_Ministerial_Correspondence 
                                                General_Ministerial_Correspondence
                                                Transport_Ministerial_Correspondence    
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    17/06/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/ 
    private void closeTheChildCasesNonCampaignNonCFM(TriggerParameters tp) {
        set <Id> parentCaseIds = new set <Id>();
        for(Case caseRecord : (list <Case>) tp.newList) {
            if((caseRecord.status == GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO || caseRecord.Response_Type__c == GlobalConstants.CASE_NRR_RESPONSE_TYPE) 
               && caseRecord.ParentId == null
               && CaseTriggerDispatcher.recordTypesMinCorroNonCampaign.contains(caseRecord.RecordTypeId)) {
               parentCaseIds.add(caseRecord.Id);
            }
        }

        if(parentCaseIds.size() > 0) {
        	/****************************************************************************************************
               Ian F. 28/Oct/2017 - Added check for closed status, no point updating status to closed if it is already closed.
                                    Trigger were being fired unnecessarily increasing SOQL count
            ******************************************************************************************************/
            list <Case> childCases = [Select Id, Status From Case Where ParentId IN: parentCaseIds and 
                                             Status != :GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO];
            if(childCases!=null && childCases.size()>0) {
                for(Case childCase : childCases) {
                    childCase.Status = GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO;
                }
                update childCases;
            }
        }
    }
    
    private Boolean isCategorisationUpdated(Case oldCase, Case newCase) {
        Boolean flag = false;
        if(oldCase.Taxonomy_Moment__c != newCase.Taxonomy_Moment__c ||
            oldCase.Taxonomy_Transaction__c != newCase.Taxonomy_Transaction__c ||
            oldCase.Taxonomy_Symptom__c != newCase.Taxonomy_Symptom__c) {
            flag = true;
        }
        return flag;
    }
}