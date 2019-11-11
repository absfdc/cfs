/*---------------------------------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Called from After Update handler class for the Case trigger
               
Test Class:    CaseEntitlementUtil_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
7/08/2015      Dipankar Barman    Created
13/01/2017     Arxxus             Updated - Optimised to avoid 101 soql queries. 
03/11/2017     Ian F              Update to method populateClosureTargetDate, if Case is a Sydney Trains or NSW Trains 
                                  Case and it is closed then do not update the Closure Target Date.  This was filling 
                                  the logs with a validation rule error
-----------------------------------------------------------------------------------------*/
public without sharing class CaseEntitlementUtil {
    public static boolean isReassigned{get;set;}
    
    public static MAP<Id,Id>caseIdvsOwnerIdForReAssignment{get;set;}

    @TestVisible
    public static Set<Id> casesWithOldEntitlements = new Set<Id>();

    @TestVisible
    private static Map<String,Id> entitlementIdByAgencyName= new Map<String,Id>();
    @TestVisible
    private static Map<String, Id> milestoneIdByString= new Map<String, Id>() ;
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Requires to be instanciated before usage and there we pick up all the configured Entitlements

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    public CaseEntitlementUtil() {
        
        if(entitlementIdByAgencyName.isEmpty()) {
            for(Entitlement e:[select Name, Id from  Entitlement limit 100]) {
                entitlementIdByAgencyName.put(e.Name,e.Id);
            }       
        }
        
        if(milestoneIdByString.isEmpty()) {
            for(MilestoneType m:[SELECT Id, Name FROM MilestoneType limit 100]){
                milestoneIdByString.put(m.Name,m.Id);
            }       
        }        
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   input a case
                    the cases is updated if corresponding entitlements for the agency is in DB 
                    sets a static map of Case vs entitlement, the milestones for which is to be deleted in the after trigger

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    public void assign(Case aCase){
        try{
            system.debug('entered assign for case -'+aCase);
            system.debug('eentitlementIdByAgencyName -'+entitlementIdByAgencyName);
            
            if (aCase.OwnerAgency__c!=null) {
                Id entitlementId=entitlementIdByAgencyName.get(aCase.OwnerAgency__c);
                if (entitlementId!=null) {
                    if (aCase.EntitlementId!=entitlementId){
                        casesWithOldEntitlements.add(aCase.Id);
                        aCase.EntitlementId=entitlementId;
                        aCase.Contact_Attempted_Timestamp__c=null;
                        aCase.Contact_Made_Timestamp__c=null;

                    }
                } else{
                    aCase.EntitlementId=null;
                }
            }else{
                system.debug('no owner agency found for case- '+aCase);
            }
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='assign';
            message.referenceInfo=JSON.serialize(aCase);
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   input void
                    get rid of old case milestones
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman    Created
    13/01/2017     Arxxus             Updated - Optimised to avoid 101 soql queries.  
     -------------------------------------------------------------------------------------*/
    public List<CaseMilestone> getOldMilestones(){
        system.debug('Enter getOldMilestones');

        List<CaseMilestone> milestonesForReset;
        try{
            if (casesWithOldEntitlements.size()<1){
                system.debug('no cases with old entitlements');
                return null;
            } 
            //added isViolated=false and isCompleted=false in the where clause
            milestonesForReset= [select Id,CaseId,CompletionDate from CaseMilestone where CaseId in:casesWithOldEntitlements and isViolated=false and isCompleted=false];
            for (CaseMilestone aMile:milestonesForReset) aMile.CompletionDate=null;
            
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='getOldMilestones';
            message.referenceInfo=JSON.serialize(casesWithOldEntitlements);
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        return milestonesForReset;
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   input a map of caseId vs their agency
                    the cases to be updated if corresponding entitlements are in DB will be returned in a list

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    public List<Case> assign(Map<Id,String> agencyByCaseId){
        List<Case> casesForEntitlementUpdate= new List<Case>();

        for (Id caseId: agencyByCaseId.keySet()){
            String agency=agencyByCaseId.get(caseId);
            if (agency!=null) {
                Id entitlementId=entitlementIdByAgencyName.get(agency);
                if (entitlementId!=null) 
                {
                    casesForEntitlementUpdate.add(new Case(Id=caseId,EntitlementId=entitlementId));
                }else{
                    system.debug('no entitlement found for agency- '+agency);
                    casesForEntitlementUpdate.add(new Case(Id=caseId,EntitlementId=null));
                }
            }else{
                system.debug('no agency found for case- '+caseId);
            }
        }
        return casesForEntitlementUpdate;
        
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   input a map of caseId vs case with contacted timestamps
                    the child cases to be updated with corresponding field values will be returned in a map.

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    public Map<Id,Case> percolateContactedTimestamps(Map<Id,Case> parentCaseByIdForChildUpdate){
        Map<Id,Case> casesToUpdate= new Map<Id,Case> ();
        try{
            for (Case parent: [select Id,OwnerAgency__c,(select Id, Contact_Attempted_Timestamp__c, Contact_Made_Timestamp__c,OwnerAgency__c from Cases ) from Case where Id in:parentCaseByIdForChildUpdate.keySet()]){
                Case parentSent=parentCaseByIdForChildUpdate.get(parent.Id);
                for(Case child:parent.Cases){
                    if (child.OwnerAgency__c!=parent.OwnerAgency__c) continue;//only for child belonging to same agency re:WI-1281 zlto's comment
                    if(child.Contact_Attempted_Timestamp__c==null &&  parentSent.Contact_Attempted_Timestamp__c!=null ){
                        child.Contact_Attempted_Timestamp__c=parentSent.Contact_Attempted_Timestamp__c;
                        casesToUpdate.put(child.Id,child);
                    }
                    if(child.Contact_Made_Timestamp__c==null &&  parentSent.Contact_Made_Timestamp__c!=null){
                        child.Contact_Made_Timestamp__c=parentSent.Contact_Made_Timestamp__c;
                        casesToUpdate.put(child.Id,child);
                    }
                }

            }

            
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='percolateContactedTimestamps';
            message.referenceInfo=JSON.serialize(parentCaseByIdForChildUpdate);
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        return casesToUpdate;
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   input old and new case return list of milestone Type ids that can be completed by CaseId.

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    public Set<Id> checkMilestoneCompletion(Case oldCase, Case newCase){
        Set<Id> completed= new Set<Id>();
        try{
            //completion criteria not met on old case && met on new case && agency one of where this criteria applies
            if ( (oldCase.Contact_Attempted_Timestamp__c==null && newCase.Contact_Attempted_Timestamp__c!=null)
                ||(oldCase.Contact_Made_Timestamp__c==null && newCase.Contact_Made_Timestamp__c!=null)
                ||(oldCase.status!=GlobalConstants.CASE_SOFTCLOSED_STATUS && newCase.status==GlobalConstants.CASE_SOFTCLOSED_STATUS)
                /*!(oldCase.Contact_Attempted_Timestamp__c!=null || oldCase.Contact_Made_Timestamp__c!=null || oldCase.status==GlobalConstants.CASE_SOFTCLOSED_STATUS)
                &&(newCase.Contact_Attempted_Timestamp__c!=null || newCase.Contact_Made_Timestamp__c!=null || newCase.status==GlobalConstants.CASE_SOFTCLOSED_STATUS)*/
            ){
                if (newCase.OwnerAgency__c==GlobalConstants.AGENCY_SYDNEY_TRAINS || newCase.OwnerAgency__c==GlobalConstants.AGENCY_NSW_TRAINS){
                    completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_IN_PROGRESS_TRAINS));
                    completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_SEND_LETTER));
                }else if(newCase.OwnerAgency__c==GlobalConstants.AGENCY_TFNSW){
                    completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_IN_PROGRESS));
                }
            }
            if (oldCase.Contact_Made_Timestamp__c==null && newCase.Contact_Made_Timestamp__c!=null && newCase.OwnerAgency__c==GlobalConstants.AGENCY_HCF){
                completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_CONTACT_MADE));
            }
            if (((oldCase.Contact_Made_Timestamp__c==null && newCase.Contact_Made_Timestamp__c!=null) || (oldCase.Contact_Attempted_Timestamp__c==null && newCase.Contact_Attempted_Timestamp__c!=null)) && (newCase.OwnerAgency__c == GlobalConstants.STA_AGENCY || newCase.OwnerAgency__c == GlobalConstants.NEWCASTLE_TRANSPORT_AGENCY || newCase.OwnerAgency__c == GlobalConstants.AGENCY_MTS)){
                completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_CONTACT_MADE));
            }
            if (oldCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS_STA && oldCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS && (newCase.Status==GlobalConstants.CASE_SOFTCLOSED_STATUS_STA || newCase.Status==GlobalConstants.CASE_SOFTCLOSED_STATUS) && (newCase.OwnerAgency__c == GlobalConstants.STA_AGENCY || newCase.OwnerAgency__c == GlobalConstants.NEWCASTLE_TRANSPORT_AGENCY || newCase.OwnerAgency__c == GlobalConstants.AGENCY_MTS)){
                completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_CASE_CLOSED));
                if(newCase.OwnerAgency__c != GlobalConstants.AGENCY_MTS)
                completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_CASE_CLOSED_95));
            }
            if (oldCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS && newCase.Status==GlobalConstants.CASE_SOFTCLOSED_STATUS && (newCase.OwnerAgency__c==GlobalConstants.AGENCY_HCF||newCase.OwnerAgency__c==GlobalConstants.AGENCY_TFNSW)){
                completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_CASE_CLOSED));
            }
            //for RMS added Wi-1997
            if (    newCase.OwnerAgency__c==GlobalConstants.RMS_AGENCY
                    &&(     (oldCase.Contact_Attempted_Timestamp__c==null && newCase.Contact_Attempted_Timestamp__c!=null)
                        ||(oldCase.Contact_Made_Timestamp__c==null && newCase.Contact_Made_Timestamp__c!=null)
                        ||(oldCase.status!=GlobalConstants.CASE_SOFTCLOSED_STATUS && newCase.status==GlobalConstants.CASE_SOFTCLOSED_STATUS)
                        ||(oldCase.Contact_Emailed_Timestamp__c==null && newCase.Contact_Emailed_Timestamp__c!=null)
                    )
            ){
                completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_IN_PROGRESS));
                completed.add(milestoneIdByString.get(GlobalConstants.MILESTONE_IN_PROGRESS2));

            }
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='checkMilestoneCompletion';
            message.referenceInfo=JSON.serialize(newCase);
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        return completed;
    }

    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   input list of milestone Type names that can be completed by CaseId.
                    caseMilestones that may be actually completes if milestones found in input param are returned in a list.

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    public List<CaseMilestone> completeMilestones(Map<Id,Set<Id>> caseMilestonesForUpdate){
        List<CaseMilestone> completed= new List<CaseMilestone> ();

        try{
            for(Case aCase:[select id, (select  Id, CaseId,  CompletionDate, IsCompleted,MilestoneType.Id FROM CaseMilestones where IsCompleted=false) from Case where Id in:caseMilestonesForUpdate.keySet()]){
                Set<Id> completableMilestones=caseMilestonesForUpdate.get(aCase.Id);
                for (CaseMilestone cm:aCase.CaseMilestones){
                    if (completableMilestones.contains(cm.MilestoneType.Id)){
                        cm.CompletionDate=System.now();
                        completed.add(cm);
                    }
                }
            }
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='completeMilestones';
            message.referenceInfo=JSON.serialize(caseMilestonesForUpdate);
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        return completed;
    }

    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Input set of caseId to inspect milestone change and update case target date accordingly
    Note            If both milestones present closure will be considered first
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    @future
    public static void updateCaseTargetDate(Set<Id>casesForTargetDateUpdate){        
        updateCaseTargetDateSync(casesForTargetDateUpdate);
    }
    
    public static Map<Id,Case> populateClosureTargetDate(List<Case> cases) {
        Map<Id,Case> forUpdateTarget= new Map<Id,Case> ();          
        for(Case aCase: cases){
            if(GlobalConstants.RESPONSIBLE_PARTY_SNSW.equalsIgnoreCase(aCase.Responsible_Party__c)) {
                continue;
            }
            //Added by Ian F 3/Nov/2017 
            if (aCase.IsClosed && (aCase.OwnerAgency__c=='Sydney Trains' || aCase.OwnerAgency__c=='NSW Trains') ){
                continue;
            }
            if(aCase.CaseMilestones != null && aCase.CaseMilestones.size()>0){
                for(CaseMilestone cm: aCase.CaseMilestones){
                    if (cm.MilestoneType.Name==GlobalConstants.MILESTONE_CASE_CLOSED || cm.MilestoneType.Name==GlobalConstants.MILESTONE_IN_PROGRESS || cm.MilestoneType.Name==GlobalConstants.MILESTONE_IN_PROGRESS_TRAINS){
                        System.debug(LoggingLevel.INFO, 'Closure target date updated to ' + cm.TargetDate);
                        aCase.ClosureTargetDate__c=cm.TargetDate;
                        forUpdateTarget.put(aCase.Id,aCase);
                    }
                }
            }else{
                System.debug(LoggingLevel.INFO, 'Closure target date updated to blank');
                aCase.ClosureTargetDate__c = null;
                forUpdateTarget.put(aCase.Id,aCase);
            }
        }
        return forUpdateTarget;
    }
    
    public static void updateCaseTargetDateSync(Set<Id>casesForTargetDateUpdate){
        try{            
            List<Case> cases = new List<Case>();        
            cases = [select id, isClosed, OwnerAgency__c, ClosureTargetDate__c, Responsible_Party__c, (select  Id, CaseId, TargetDate, CompletionDate,MilestoneType.Name FROM CaseMilestones ORDER BY TargetDate ASC) from Case where Id in:casesForTargetDateUpdate];
            Map<Id,Case> forUpdateTarget = populateClosureTargetDate(cases);
            
            if (forUpdateTarget.size()>0) {
                CaseTriggerDispatcher.updateClosureTargetDate = true;
                update forUpdateTarget.values();                
            }
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='updateCaseTargetDate';
            message.referenceInfo=JSON.serialize(casesForTargetDateUpdate);
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }

    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   is called from before insert and update triggers on case Input TriggerParameters case id vs owner id map and old and new user ids and log messages
    Note            detect agency change where owner changed and stamp the event related fields, except if serco owns it for the first time
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/

    public void detectAgencyChange(TriggerParameters tp,Set<Id>cfmCaseIDOwnerChanged,Set<Id>cfmOldAndNewUser,List<ApplicationLogMessage> messages){
        try{
            
            BusinessHours stdBusinessHours = [Select Id from BusinessHours where BusinessHours.Name =: GlobalConstants.BUSINESSHOURS_NAME LIMIT 1];            
            
            //get old owner and new owner agency
            if(isReassigned!=null && isReassigned==true && caseIdvsOwnerIdForReAssignment!=null && caseIdvsOwnerIdForReAssignment.size()>0){
                cfmOldAndNewUser.addAll(caseIdvsOwnerIdForReAssignment.values());
            }
            
            Map<Id,User> cfmOwnersOldAndNew = new Map<Id,User>();
            
            if(cfmOldAndNewUser.size() > 0) {
              cfmOwnersOldAndNew = new Map<Id,User>( [select Id, Agency__c from User where Id in:cfmOldAndNewUser]);
            }
            
            
            Iterator<Id> caseIdIter;
            Iterator<Case> caseIter;
            List<Id> cfmCaseIDOwnerChangedList= new List<Id> (cfmCaseIDOwnerChanged);
            
            if (tp.newMap!=null && cfmCaseIDOwnerChanged!=null && cfmCaseIDOwnerChanged.size()>0){
                caseIdIter= ((List<Id>)cfmCaseIDOwnerChangedList).iterator();
            }else if (tp.newList!=null){
                caseIter= ((List<Case>)tp.newList).iterator();
            }
            
            system.debug('cfmCaseIDOwnerChanged'+cfmCaseIDOwnerChanged.size());
            system.debug('detectAgencyChange input tp - '+tp);
            if (caseIdIter!=null) system.debug('caseIdIter.hasNext() -'+caseIdIter.hasNext());
            if(caseIter!=null) system.debug('caseIter.hasNext() -'+caseIter.hasNext());

            while(caseIdIter!=null?caseIdIter.hasNext():caseIter.hasNext()){

                Id aCaseId;
                Case newCase;
                Case oldCase;
                String newAgency;
                String oldAgency;
                if(caseIter!=null){
                    newCase=caseIter.next();
                    if (newCase.id!=null)oldCase=(Case)tp.oldMap.get(newCase.Id);
                    if (oldCase!=null) oldAgency=oldCase.OwnerAgency__c;
                    if (newCase.IsMinCorroCase__c) continue;
                }else if(caseIdIter!=null){
                    aCaseId=caseIdIter.next();
                    newCase=(Case)tp.newMap.get(aCaseId);
                    oldCase=(Case)tp.oldMap.get(aCaseId);
                    if (oldCase!=null) oldAgency=oldCase.OwnerAgency__c;
                }
             
                Id newOwner=newCase.ownerId;
                Boolean isSiteUser = UserInfo.getName().contains(GlobalConstants.SITE_USER_NAME_SIGNATURE)? true : false;
                
                Boolean isAdminUser=false;
                Boolean ownerIsUser=false;
                System.debug('New Owner: ' + newOwner);
                System.debug('isSiteUser: ' + isSiteUser );
                Id oldOwnerId;
                User oldOwner;
                if(isReassigned!=null && isReassigned==true && caseIdvsOwnerIdForReAssignment!=null && caseIdvsOwnerIdForReAssignment.containsKey(newCase.Id) ){
                    oldOwnerId=caseIdvsOwnerIdForReAssignment.get(newCase.Id);
                }
                if(((String) newOwner).startsWith(GlobalConstants.USER_ID_PREFIX) ){
                    ownerIsUser=true;
                    User newUser=cfmOwnersOldAndNew.get(newOwner);
                    if (newUser!=null && GlobalConstants.SYS_ADMIN_IDS.contains(newUser.Id)) isAdminUser=true;
                    if (isReassigned==true && newOwner==UserInfo.getUserId()){
                        newAgency=oldAgency;//bypass owner agency determination while reassigning
                    }else if (newUser!=null){
                        newAgency=newUser.Agency__c;
                        if (String.isEmpty(newAgency)){
                            ApplicationLogMessage log= new ApplicationLogMessage();
                            log.source='CaseEntitlementUtil';
                            log.sourceFunction='detectAgencyChange';
                            log.debugLevel=GlobalConstants.DEBUG;
                            log.payLoad=' User with Id:'+newOwner +
                                        ' without Agency';
                            messages.add(log);
                        }
                    }
                    
                }else if(((String) newOwner).startsWith(GlobalConstants.GROUP_ID_PREFIX)){
                    try{
                        System.debug('-----Queue is owner---Entitlement-------');
                        Group queue=CaseTriggerDispatcher.queues.get(newOwner);
                        String queueDeveloperName;
                        if (queue!=null) queueDeveloperName = queue.DeveloperName;
                        QueueVsAgency__c queueConf;
                        if (queueDeveloperName!=null) queueConf=CaseTriggerDispatcher.queueNameVsAgencyDivBranch.get(queueDeveloperName);
                        if (queueConf!=null) newAgency =  queueConf.Agency__c;       
                         //getting old agency according to last original owner before the assign button
                        if (oldOwnerId!=null) oldOwner= cfmOwnersOldAndNew.get(oldOwnerId);
                        if (oldOwner!=null) oldAgency=oldOwner.Agency__c;
                     
                         if (String.isEmpty(newAgency)){
                            ApplicationLogMessage log= new ApplicationLogMessage();
                            log.source='CaseEntitlementUtil';
                            log.sourceFunction='detectAgencyChange';
                            log.debugLevel=GlobalConstants.DEBUG;
                            log.payLoad=' Queue with:'+CaseTriggerDispatcher.queues.get(newOwner).DeveloperName +
                                            ' without Agency configuration';
                            messages.add(log);
                        }
                    }catch(Exception e){
                        ApplicationLogMessage log= new ApplicationLogMessage();
                            log.source='CaseEntitlementUtil';
                            log.sourceFunction='detectAgencyChange';
                            log.debugLevel=GlobalConstants.DEBUG;
                            log.payLoad=' Queue with:'+CaseTriggerDispatcher.queues.get(newOwner).DeveloperName +
                                            ' without Agency configuration';
                            messages.add(log);
                            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
                            if (GlobalConstants.THROW_EXCEPTIONS){
                                Throw(e);
                            }
                    }
                   
                }
                system.debug('newAgency -'+newAgency);
                system.debug('oldAgency -'+oldAgency);
                system.debug('ownerIsUser - '+ownerIsUser);
                system.debug('newCase -'+newCase);
                system.debug('oldCase -'+oldCase);
                
                if(isReassigned==null || isReassigned==false){
                    if (!String.isEmpty(newAgency)){
                        newCase.OwnerAgency__c=newAgency;
                        if(newAgency!=oldAgency){
                            newCase.Date_Assigned_to_Agency__c=System.now();
                            
                            

                            DateTime dT = UtilityClass.addBusinessDays(System.now(),2,stdBusinessHours);
                            newCase.X2_days_from_assigned_to_Agency__c = date.newinstance(dT.year(), dT.month(), dT.day());
                            dT = UtilityClass.addBusinessDays(System.now(),5,stdBusinessHours);
                            newCase.X5_days_from_assigned_to_Agency__c = date.newinstance(dT.year(), dT.month(), dT.day());
                            dT = UtilityClass.addBusinessDays(System.now(),15,stdBusinessHours);
                            newCase.X15_days_from_assigned_to_Agency__c = date.newinstance(dT.year(), dT.month(), dT.day());
                            dT = UtilityClass.addBusinessDays(System.now(),30,stdBusinessHours);
                            newCase.X30_days_from_assigned_to_Agency__c = date.newinstance(dT.year(), dT.month(), dT.day());
                            
                            if (ownerIsUser==false && newCase.Agency__c!=GlobalConstants.SNSW_AGENCY && !isSiteUser && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS &&  newCase.Status!=GlobalConstants.CASE_CLOSED_STATUS && newCase.Status!=GlobalConstants.CASE_REOPENED_STATUS && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS_STA){
                                newCase.Status=GlobalConstants.ASSIGNED_TO_AGENCY_STATUS;
                            }
                            assign(newCase);
                        }  
                        if(ownerIsUser==true && !isSiteUser && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS && newCase.Status!=GlobalConstants.CASE_CLOSED_STATUS && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS_STA && newCase.Status != GlobalConstants.CASE_STATUS_AWAITING_ADVICE ){
                            newCase.Status=GlobalConstants.CASE_IN_PROGRESS_STATUS;
                        }
                    }
                }else if(isReassigned!=null && isReassigned==true && oldOwnerId!=null && oldOwnerId!=newCase.ownerId){
                    if (!String.isEmpty(newAgency)) newCase.OwnerAgency__c=newAgency;
                    if (ownerIsUser==false && newCase.Agency__c!=GlobalConstants.SNSW_AGENCY && !isSiteUser && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS &&  newCase.Status!=GlobalConstants.CASE_CLOSED_STATUS && newCase.Status!=GlobalConstants.CASE_REOPENED_STATUS && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS_STA){
                        newCase.Status=GlobalConstants.ASSIGNED_TO_AGENCY_STATUS;
                    }else if(ownerIsUser==true && !isSiteUser && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS && newCase.Status!=GlobalConstants.CASE_CLOSED_STATUS && newCase.Status!=GlobalConstants.CASE_SOFTCLOSED_STATUS_STA){
                        System.debug(LoggingLevel.ERROR, 'Reassigned true- ' + newCase.Status);
                        newCase.Status=GlobalConstants.CASE_IN_PROGRESS_STATUS;
                    }
                    assign(newCase);
                } 
                
               
            }

        }catch(Exception e){
            system.debug('------detectAgencyChange Exception------' + e.getMessage() + '----' + e.getLineNumber());
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='detectAgencyChange';
            if (tp!=null && tp.newMap!=null) message.referenceInfo=JSON.serialize(tp.newMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        
    }
    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   is called from after  triggers on case. Input parent case with child cases which might have undergone a change in the OwnerAgency__c
                    map of case by Id which require to be updated.
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    public Map<Id,Case> determineMultiAgency(Map<Case,List<Case>> suspectParentChild){
        Map<Id,Case> casesForMultiAgencyUpdate= new Map<Id,Case>();
        try{
            system.debug('suspectParentChild - '+suspectParentChild);
            for(Case parent:suspectParentChild.keySet()){
                List<Case> children=suspectParentChild.get(parent);
                system.debug('parent - '+parent);
                system.debug('children - '+children);

                Set<String> ownerAgencies= new Set<String>();
                for (Case childCase:children) {
                    if (childCase.OwnerAgency__c!=null) ownerAgencies.add(childCase.OwnerAgency__c);
                }
                system.debug('ownerAgencies - '+ownerAgencies);

                Boolean multiAgency=false;
                if (ownerAgencies.size()==1 ){
                    parent.OwnerAgency__c=new list<string>(ownerAgencies)[0];
                    parent.Agency__c=new list<string>(ownerAgencies)[0];
                    casesForMultiAgencyUpdate.put(parent.Id,parent);
                }else if (ownerAgencies.size()>1) multiAgency=true;
                system.debug('multiAgency - '+multiAgency);

                if (parent.multiAgency__c!=multiAgency){
                    parent.multiAgency__c=multiAgency;
                    parent.Agency__c=null;//setting catagorisation agency null in parent
                    casesForMultiAgencyUpdate.put(parent.Id,parent);
                }
                for (Case childCase:children) {
                    if (childCase.multiAgency__c!=multiAgency) {
                        childCase.multiAgency__c=multiAgency;
                        casesForMultiAgencyUpdate.put(childCase.Id,childCase);
                    }
                }
                system.debug('casesForMultiAgencyUpdate - '+casesForMultiAgencyUpdate);

            }
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='determineMultiAgency';
            message.referenceInfo=JSON.serialize(suspectParentChild);
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        
        return casesForMultiAgencyUpdate;
    }

    /*---------------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Pass the cases Id vs the then owner Id for updation to a future method, and perform your ownership changea synchronously.
                    This will allow you to reassign the user correctly after the assignment rule logic has executed.
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    7/08/2015      Dipankar Barman      Created
     -------------------------------------------------------------------------------------*/
    @future
    public static void reassignCaseWithActiveRule(MAP<Id,Id>casesForReAssignment,Map<Id,boolean> caseVsMultiAgency, Set<Id> casesForTargetDateUpdate) {
        try{
            isReassigned=true;
            caseIdvsOwnerIdForReAssignment=casesForReAssignment;
            system.debug('isReassigned - '+isReassigned);

            List<Case> myCase = [select Id,description,ownerId,OwnerAgency__c, recordTypeId,recordtype.Name, multiAgency__c from Case where Id =: casesForReAssignment.keySet() limit 10000 FOR UPDATE ];
            for (Case aCase:myCase) {
                //aCase.OwnerAgency__c=null;//DB 
                aCase.multiAgency__c=caseVsMultiAgency.get(aCase.Id);
                aCase.ownerId=casesForReAssignment.get(aCase.Id);
                //there is a workflow field update that resets this field value
                aCase.SkipValidation__c= GlobalConstants.SERCO_CANT_CHANGE_OWNER_OF_OTHERS_CASE;
            }
            system.debug('casesForReAssignment - '+myCase);

            //Fetch the assignment rules on case
            List<AssignmentRule> rules = new List<AssignmentRule>();
            AssignmentRule rule = new AssignmentRule();
            rules = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];

            if (rules != null && rules.size() == 1){
                rule = rules[0];
                system.debug('Found a rule');
            } else {
                system.debug('Error: there should be only one');
                return;
            }

            //Create the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();        
            dmlOpts.assignmentRuleHeader.assignmentRuleId= rule.id;
            dmlOpts.EmailHeader.triggerUserEmail = true;
            Database.SaveResult[] result = Database.update(myCase, dmlOpts);     
            for(Database.SaveResult sResult : result) {
                if(!sResult.isSuccess())
                    System.debug(sResult.getErrors());
            }
            if(casesForTargetDateUpdate!=null && casesForTargetDateUpdate.size()>0 ){
                updateCaseTargetDateSync(casesForTargetDateUpdate);
            }
        }
        catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseEntitlementUtil';
            message.sourceFunction='reassignCaseWithActiveRule';
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
        finally{
            isReassigned=false;
            system.debug('isReassigned - '+isReassigned);
        }        
    }
}