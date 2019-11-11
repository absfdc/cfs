/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A dispatcher class for the Case trigger

Test Class:    CaseTriggerDispatcher_Test
History
16 Mar 2015     Dipankar Barman     created
01/06/2015      Manish Damle        Added Static block to initialise the
                                    case record type map and current user
                                    list
21 Jun 2015     Brett Cawrse        Updated MAGS Officer queue check to avoid
                                    'List has no rows for assignment to Sobject'
                                    error (WI-593)                
                                    
12/10/2016      Arxxus              Updated to beforeInsert, befroeUpdate and afterUpdate
                                    methods to call MO integration trigger handlers    
                                    
02/05/2017      Ian Fitzgerald      Reduce three queries on Group object to one in Static block (see inline comments)                                                                                                   
------------------------------------------------------------*/

public class CaseTriggerDispatcher extends TriggerDispatcherBase {
    public static map <String, Id> caseRecordTypes;
    public static set <Id> recordTypesMinCorro, recordTypesMinCorroNonCampaign;
    public static list <User> runningUser;
    public static map<String, Id> minCorroQueues;
    public static set <Id> crgsAdmins; 
    public static set <Id> magsAdmins;
    public static set <Id> corroOfficers;
    private static Boolean isBeforeInsertProcessing = false;
    private static Boolean isAfterInsertProcessing = false;
    private static Boolean isBeforeUpdateProcessing = false;
    private static Boolean isBeforeDeleteProcessing = false;
    private static Boolean isAfterUpdateProcessing = false;
    private static Boolean isAfterDeleteProcessing = false;
    private static Boolean isAfterUndeleteProcessing = false;
    private static Boolean isBypassed = null;
    public static Map<Id,Group> rmsQueues;
    public static Map<Id,Group> staDepotQueues;
    public static Map<String,String> roleNameByQueueName= new Map<String,String> ();
    public static Map <String, QueueVsAgency__c> queueNameVsAgencyDivBranch = new Map <String, QueueVsAgency__c>();
    public static Boolean batchForClosureTargetDateQueued = false;
    public static Boolean updateClosureTargetDate = false;
    
    public static Map<Id,Group> queues ;
    public static Boolean getNextFlagReset;
    public static Boolean blockReentryToCampaignMemberFieldsFromCampaignMethod = false;
    
    //Initialise the caseRecordType map
    static {
    
        /*
         * SNSW Changes START: Changes to bypass case trigger execution logic of CFM and MinCorro for user record with name as connection user
         */
        if(!isRunningUserConnectionUser()) {
            caseRecordTypes = new map <String,Id>();
            crgsAdmins = new set <Id>();
            magsAdmins = new set <Id>();
            corroOfficers = new set <Id>();
            recordTypesMinCorro = new set <Id>();
            recordTypesMinCorroNonCampaign = new set <Id>();
            minCorroQueues = new map <String, Id> ();
            getNextFlagReset = false;
            for(RecordType rt : [Select Id, DeveloperName 
                                 From RecordType 
                                 Where SObjectType = 'Case']) {
                caseRecordTypes.put(rt.DeveloperName, rt.Id);
                if(GlobalConstants.MINCORRORRECORDTYPENAMES.contains(rt.DeveloperName)) {
                    recordTypesMinCorro.add(rt.Id);
                }
                                     
                if(GlobalConstants.MINCORROR_NON_CAMPAIGN_RECORD_TYPE_NAMES.contains(rt.DeveloperName)) {
                    recordTypesMinCorroNonCampaign.add(rt.Id);                     
                }                                 
            }
                        
            runningUser = [Select Id, Anti_Cherry_Picking__c,UserRole.DeveloperName 
                           From User 
                           Where Id =: UserInfo.getUserId() limit 1];
            
     /*       for(Group g : [Select Id, DeveloperName  
                           From Group 
                           Where Type = 'Queue' 
                           And (DeveloperName =: GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME 
                                OR DeveloperName =: GlobalConstants.RMS_CORRO_OFFICER_QUEUE_API_NAME
                                OR DeveloperName =: GlobalConstants.MAGS_TEAM_A_QUEUE_NAME
                                OR DeveloperName =: GlobalConstants.MAGS_TEAM_B_QUEUE_NAME
                                OR DeveloperName =: GlobalConstants.MAGS_TEAM_C_QUEUE_NAME
                                OR DeveloperName =: GlobalConstants.MAGS_TEAM_D_QUEUE_NAME
                                OR DeveloperName =: GlobalConstants.MAGS_TEAM_E_QUEUE_NAME
                                OR DeveloperName =: GlobalConstants.MAGS_TEAM_F_QUEUE_NAME)]) {
                                
                minCorroQueues.put(g.DeveloperName, g.Id);
            }*/
                                  
            for(User u: [Select Id, Profile.Name, UserRole.DeveloperName
                         From User 
                         Where UserRole.DeveloperName =: GlobalConstants.MAGS_ROLE_CRGS_ADMIN 
                            or UserRole.DeveloperName IN: GlobalConstants.MAGS_ROLE_NAMES
                            or UserRole.DeveloperName IN: GlobalConstants.CORRO_OFFICER_ROLE_NAMES]) {
                if(u.UserRole.DeveloperName == GlobalConstants.MAGS_ROLE_CRGS_ADMIN
                   || u.UserRole.DeveloperName == GlobalConstants.MAGS_ROLE_SR_OFFICER
                   || u.UserRole.DeveloperName == GlobalConstants.MAGS_ROLE_CRGS_SUPER_ADMIN)    {
                    crgsAdmins.add(u.Id);
                } 
                
                if(GlobalConstants.MAGS_ROLE_NAMES.contains(u.UserRole.DeveloperName)){
                    magsAdmins.add(u.Id);
                } 
                
                if(GlobalConstants.CORRO_OFFICER_ROLE_NAMES.contains(u.UserRole.DeveloperName)) {
                    corroOfficers.add(u.Id);
                }               
            }

            //rmsQueues = new Map<Id,Group>([Select Id, Name, DeveloperName, Type from Group where Type = 'Queue' and DeveloperName like :GlobalConstants.RMS_QUEUE_PREFIX]);

            //SFCOE-88 Stamp email address of Last Assigned Queue - Start
            //Added email in SOQL query
            
            queues = new map <Id, Group> ([Select Id,DeveloperName,email From Group WHERE Type = 'Queue']);
            
            //SFCOE-88 Stamp email address of Last Assigned Queue - End
            
            // Added by Ian Fitzgerald 02/05/2017
            // Reduce three queries on Group object to one by populating minCorroQueues and rmsQueues from queues Map
            rmsQueues = new Map<Id,Group>();
            Set<String> minCorroNames = new Set<String>{GlobalConstants.MAGS_OFFICER_QUEUE_API_NAME, GlobalConstants.RMS_CORRO_OFFICER_QUEUE_API_NAME, GlobalConstants.MAGS_TEAM_A_QUEUE_NAME,
                                                        GlobalConstants.MAGS_TEAM_B_QUEUE_NAME, GlobalConstants.MAGS_TEAM_C_QUEUE_NAME, GlobalConstants.MAGS_TEAM_D_QUEUE_NAME, 
                                                        GlobalConstants.MAGS_TEAM_E_QUEUE_NAME, GlobalConstants.MAGS_TEAM_F_QUEUE_NAME};                                          
            for (Group g : queues.values()){
                if (g.DeveloperName.startswith(GlobalConstants.RMS_QUEUE_STRING)){
                    rmsQueues.put(g.Id, g);
                }
                if(minCorroNames.contains(g.DeveloperName)){
                    minCorroQueues.put(g.DeveloperName, g.Id);
                }
            }
            //END - Added by Ian Fitzgerald 02/05/2017
            
            //Populate the map of QueueName VS Custom Settings data
            Map<String, QueueVsAgency__c> queueVsAgencyCustomSettings = QueueVsAgency__c.getAll();
            for(QueueVsAgency__c cs : queueVsAgencyCustomSettings.values()) {
                queueNameVsAgencyDivBranch.put(cs.QueueName__c, cs);
            }
        }
        /*
         * SNSW Changes END: Changes to bypass case trigger execution logic of CFM and MinCorro for user record with name as connection user
         */        
    } 
    public static void setStaDepotQueues(){
        staDepotQueues = new Map<Id,Group>([Select Id, Name, DeveloperName, Type from Group where Type = 'Queue' and DeveloperName like :GlobalConstants.STA_DEPOT_QUEUE_LIKE]);
        List<GroupMember> gms=[Select UserOrGroupId ,GroupId From GroupMember where GroupId in:staDepotQueues.keySet()];
        Map<Id,Id> roleIdByQueueId= new  Map<Id,Id>();
        for(GroupMember agm:gms){
           roleIdByQueueId.put(agm.GroupId,agm.UserOrGroupId);
        }

        Map<Id,group> rolesById=new Map<Id,group>([select Id, name,developerName from group where Type='Role' and Id in:roleIdByQueueId.values()]);
        for (Id queueId:staDepotQueues.keySet()){
            Group queue=staDepotQueues.get(queueId);
            group role=rolesById.get(roleIdByQueueId.get(queueId));
            if (queue!=null && role!=null) roleNameByQueueName.put(queue.DeveloperName,role.developerName);
        }
        system.debug('staDepotQueues - '+staDepotQueues);
        system.debug('roleNameByQueueName - '+roleNameByQueueName);

    }
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Function to decide if the Before Insert handler
                    should  simply fire, or the one already running
                    and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/

    public virtual override void beforeInsert(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass before insert case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) {         
            if(!isBeforeInsertProcessing) {
                isBeforeInsertProcessing = true;
                execute(new CaseBeforeInsertHandlerForSNSW(), tp, TriggerParameters.TriggerEvent.beforeInsert);
                isBeforeInsertProcessing = false;                
            }            
            return;
        }
        /*
         * SNSW Changes END: Changes to bypass before insert case trigger logic of CFM and MinCorro for user record with name as connection user
         */
         
        if(checkBypassed()==true) return ;
        if(!isBeforeInsertProcessing) {
            isBeforeInsertProcessing = true;
            
            execute(new CaseBeforeInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeInsert);
            execute(new CaseBeforeInsertHandlerForMO(), tp, TriggerParameters.TriggerEvent.beforeInsert);
            
            isBeforeInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);        
    }

    /*------------------------------------------------------------
    Author:        Brett Cawrse
    Company:       Salesforce
    Description:   Function to decide if the After Insert handler
    should  simply fire, or the one already running
    and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    
    ------------------------------------------------------------*/
    
    public virtual override void afterInsert(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass after insert case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) {         
            if(!isAfterInsertProcessing) {
                isAfterInsertProcessing = true;
                execute(new CaseAfterInsertHandlerForSNSW(), tp, TriggerParameters.TriggerEvent.beforeInsert);
                isAfterInsertProcessing = false;                
            }            
            return;
        }
        /*
         * SNSW Changes END: Changes to bypass after insert case trigger logic of CFM and MinCorro for user record with name as connection user
         */
         
        system.debug('afterInsert');
        if(checkBypassed()==true) return;
        if(!isAfterInsertProcessing) {
            isAfterInsertProcessing = true;
            execute(new CaseAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            execute(new EinsteinAfterInsertTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterInsert);
            isAfterInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
    }    
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Function to decide if the Before Update handler
                    should  simply fire, or the one already running
                    and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/
    public virtual override void beforeUpdate(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass before update case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) {
            System.debug(LoggingLevel.INFO, 'Case updated by SNSW.');
            if(!isBeforeUpdateProcessing) {
                isBeforeUpdateProcessing = true;
                execute(new CaseBeforeUpdateHandlerForSNSW(true), tp, TriggerParameters.TriggerEvent.beforeUpdate);
                isBeforeUpdateProcessing = false;
            }
            return;
        } 
        /*
         * SNSW Changes END: Changes to bypass before update case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        /*
         * SNSW Changes START: Changes to share cases with SNSW
         */        
        if(isQualifiedForSNSWProcessing(tp)) {
            System.debug(LoggingLevel.INFO, 'Case update qualified for SNSW processing.');
            if(!isBeforeUpdateProcessing) {
                isBeforeUpdateProcessing = true;
                execute(new CaseBeforeUpdateHandlerForSNSW(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
                isBeforeUpdateProcessing = false;
            }
            return;
        } 
        /*
         * SNSW Changes END: Changes to share cases with SNSW
         */
        
        if(checkBypassed() == true) return ;
        if(!isBeforeUpdateProcessing) {
        
            isBeforeUpdateProcessing = true;
        
            execute(new CaseBeforeUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
            execute(new CaseBeforeUpdateHandlerForMO(), tp, TriggerParameters.TriggerEvent.beforeUpdate);
        
            isBeforeUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the After Update handler
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/
    public virtual override void afterUpdate(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass before update case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass before update case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        /*
         * SNSW Changes START: Changes to share cases with SNSW
         */ 
        if(isQualifiedForSNSWProcessing(tp)) {
           
            System.debug(LoggingLevel.INFO, 'Case update qualified for SNSW processing.');
           
            if(!isAfterUpdateProcessing) {
           
                isAfterUpdateProcessing = true;
                execute(new CaseAfterUpdateHandlerForSNSW(), tp, TriggerParameters.TriggerEvent.afterUpdate);
                isAfterUpdateProcessing = false;
            }
            return;
        } 
        /*
         * SNSW Changes END: Changes to share cases with SNSW
         */
        
        if(checkBypassed() == true) return ;
        if(!isAfterUpdateProcessing) {
        
            isAfterUpdateProcessing = true;
            execute(new CaseAfterUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUpdate);
            execute(new CaseAfterUpdateHandlerForMO(), tp, TriggerParameters.TriggerEvent.afterUpdate);
            isAfterUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the After Update delete
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/
    public virtual override void afterDelete(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass after delete case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass after delete case trigger logic of CFM and MinCorro for user record with name as connection user
         */
         
        if(checkBypassed() == true) return ;
        if(!isAfterDeleteProcessing) {
            isAfterDeleteProcessing = true;
            execute(new CaseAfterDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterDelete);
            isAfterDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterDelete);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the After UnDelete
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    ------------------------------------------------------------*/
    public virtual override void afterUnDelete(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass after undelete case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass after undelete case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        
        if(checkBypassed() == true) return ;
        if(!isAfterUndeleteProcessing) {
            isAfterUndeleteProcessing = true;
            execute(new CaseAfterUnDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUnDelete);
            isAfterUndeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUnDelete);
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Function to decide if the before Delete
                   Should  simply fire, or the one already running
                   and responsible for triggering this invocation should be notified
    Inputs:        Trigger parameters
    Returns:       void
    History
    18/05/2015    Manish Damle  Created
    ------------------------------------------------------------*/
    public virtual override void beforeDelete(TriggerParameters tp) {
        
        /*
         * SNSW Changes START: Changes to bypass before delete case trigger logic of CFM and MinCorro for user record with name as connection user
         */
        if(isRunningUserConnectionUser()) return;
        /*
         * SNSW Changes END: Changes to bypass before delete case trigger logic of CFM and MinCorro for user record with name as connection user
         */
         
        if(checkBypassed() == true) return ;
        if(!isBeforeDeleteProcessing) {
            isBeforeDeleteProcessing = true;
            execute(new CaseBeforeDeleteTriggerHandler(), tp, TriggerParameters.TriggerEvent.beforeDelete);
            isBeforeDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
    }
    //TODO have to change the split character to ; everywhere
    public Boolean checkBypassed(){
        if (isBypassed==null){
            if (TriggerDispatcherBase.invoker.Bypass_Triggers__c!=null){
                Set<String> bypassed=new Set <String>(TriggerDispatcherBase.invoker.Bypass_Triggers__c.split(';',0));
                if (bypassed.contains('Case')){
                    isBypassed=true;
                }else{
                    isBypassed=false;
                }
            }else{
                isBypassed=false;
            }

        }
        return isBypassed;
    }
    
    /*
     * SNSW Changes START: Changes to bypass existing case trigger logic of CFM and MinCorro for user record with name as connection user
     */
    public static Boolean isRunningUserConnectionUser() {
        Boolean flag = false;
        String username = UserInfo.getName();
        System.debug(LoggingLevel.INFO, 'Current running user: ' + username);
        if(GlobalConstants.CONNECTION_USER_NAME.equalsIgnoreCase(username)) {
            flag = true;
        }
        return flag;
    }
    /*
    * SNSW Changes END: Changes to bypass existing case trigger logic of CFM and MinCorro for user record with name as connection user
    */
    
    private Boolean isQualifiedForSNSWProcessing(TriggerParameters tp) {
        Boolean flag = false;
        List<Case> cases = (List<Case>) tp.newList;
        Map<Id,Case> caseMap = (Map<Id, Case>) tp.oldMap;
        for(Case caseRecord : cases) {
            if(caseRecord.Responsible_Party__c != caseMap.get(caseRecord.Id).Responsible_Party__c && caseRecord.Responsible_Party__c == GlobalConstants.RESPONSIBLE_PARTY_SNSW) {
                return true;
            }
        }
        return flag;
    }    
}