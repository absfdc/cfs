/*---------------------------------------------------------------------------------------
Author:        Arxxus
Description:   Before Update handler class for the Case trigger
Test Class:    CaseBeforeUpdateHandlerForMO_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
10/10/2016     Arxxus             Created
17/04/2017     Arxxus             Updated. Include steps to auto-populate signatory person based 
                                  on signatory role populated and auto populate minister based 
                                  on record type of the case.
10/05/2017     Arxxus             Updated. Changes for inactive responsible MAGS officer user  
04/05/2017     Ian Fitzgerald     Merged three SOQL queries to Group object into one to
                                  reduce query count 
06/06/2017    Pawan Tiwari       Updated. Do no update the owner with MAGS Signatory if case record type is WestConnex. 
08/09/2017    Pawan Tiwari       Oct Release: Commented code to update the case owner as MAGS Signatory 
                                 or MO User when case status is 'MAGS Approved'.   
18/05/2018    Gary Bakshi        Updated this condition: If case is assigned to a Queue, and current user Role contains 
                                 'DLO','Policy_Advisor','Senior_Executive_Coordinator' and case status is Pre-Registration
                                 Then make the currently logged in user as the case owner.

-----------------------------------------------------------------------------------------*/
public without sharing class CaseBeforeUpdateHandlerForMO extends TriggerHandlerBase {

    private static List<User> signatoryUsers = new List<User>();
    private static List<User> ministerUsers = new List<User>();
    private static List<Group> RoadMAGSManagerQueue = new List<Group>();
    private static List<Group> TransportMAGSManagerQueue = new List<Group>();
    private static List<Group> WestConnexMAGSManagerQueue = new List<Group>();
    private static List<Group> CRGSAdminQueue = new List<Group>();
    private static Map<Id,User> ativeUserList;
    private static User loggedInUser = NULL;
    private static set<String> bypassTakeOwnershipRoleContains = new Set<String>{'DLO','Policy_Advisor','Senior_Executive_Coordinator'};

    public boolean exceptionInvoked = FALSE;
    private static Boolean triggerExecuted = FALSE;

    static{
        if(ativeUserList == null)
            ativeUserList = new Map<Id,User>([Select Id,Name FROM User where isActive = TRUE]);
    }

    public override void mainEntry(TriggerParameters tp) {

        process(tp);
    }

    private void process(TriggerParameters tp) {

        try {
            //Added corresponding to Process Builder - Update Ownership
            //Check whether user role is allowed to bypass take ownership option
            Boolean userRoleAllowedtoBypassTakeOwnership = false;
            
            Map<String,String> signatoryRoleVsSignatories = new Map<String,String>();
            Map<String,String> ministerMap = new Map<String,String>();
            Set<String> ministersRole = new Set<String>();

            ministersRole.add(GlobalConstants.MINISTER_OF_ROAD);
            ministersRole.add(GlobalConstants.MINISTER_OF_TRANSPORT);
            // include westconnex minister 
            ministersRole.add(GlobalConstants.MINISTER_OF_WESTCONNEX);
            //include Regional Transport and Roads Minister
            ministersRole.add(GlobalConstants.MINISTER_OF_REGIONAL_TRANSPORT_AND_ROADS);

            if(signatoryUsers.isEmpty() && !triggerExecuted) {

                signatoryUsers = [SELECT Id, UserRole.Name, Role_Dev_Name__c
                                    FROM User
                                    WHERE (Role_Dev_Name__c IN: GlobalConstants.MO_SIGNATORY_ROLE_NAMES
                                    OR Role_Dev_Name__c =: GlobalConstants.MINISTER_OF_WESTCONNEX)
                                    AND IsActive = TRUE
                                    ORDER BY CreatedDate ASC ];
            }

            if(ministerUsers.isEmpty() && !triggerExecuted) {

                ministerUsers = [SELECT Id, Role_Dev_Name__c
                                    FROM User
                                    WHERE Role_Dev_Name__c IN: ministersRole
                                    AND IsActive = TRUE
                                    ORDER BY CreatedDate ASC ];
            }

            //START: May/4/2017  Ian Fitzgerald, Merged three SOQL queries to Group object into one
            if(RoadMAGSManagerQueue.isEmpty() || TransportMAGSManagerQueue.isEmpty() || CRGSAdminQueue.isEmpty()){
                List<Group> MAGSManagerQueues = [Select Id, DeveloperName From Group Where Type = 'Queue'
                                         and DeveloperName in ('Roads_Manager_Queue', 'Transport_Manager_Queue', 'CRGS_Admins_MC', 'WestConnex_Manager_Queue')];
                
                for (Group g : MAGSManagerQueues){
                    if (g.DeveloperName=='Roads_Manager_Queue')
                        RoadMAGSManagerQueue.add(g);
                    if (g.DeveloperName=='Transport_Manager_Queue')
                        TransportMAGSManagerQueue.add(g);
                    if (g.DeveloperName=='CRGS_Admins_MC')
                        CRGSAdminQueue.add(g);    
                    if(g.DeveloperName=='WestConnex_Manager_Queue')
                       WestConnexMAGSManagerQueue.add(g);
                }
            }
            System.debug('Queue List Size: ' + RoadMAGSManagerQueue.size());
           //END: May/4/2017  Ian Fitzgerald, Merged three SOQL queries to Group object into one
                                  
            if(loggedInUser == NULL) 
                loggedInUser = [SELECT Role_Dev_Name__c, Id FROM User WHERE Id = :UserInfo.getUserId()];

            
            for (String s:bypassTakeOwnershipRoleContains){
                if (loggedInUser.Role_Dev_Name__c.contains(s))
                    userRoleAllowedtoBypassTakeOwnership = true;
            }
            
            for(User tempMinisterUser: ministerUsers) {
                ministerMap.put(tempMinisterUser.Role_Dev_Name__c, tempMinisterUser.Id);
            }

            for(User tempSignatoryUser: signatoryUsers) {
                signatoryRoleVsSignatories.put(tempSignatoryUser.UserRole.Name, tempSignatoryUser.Id);
            }

            System.debug('Map Role: ' + signatoryRoleVsSignatories.KeySet());

            Map<String,String> magsRejectionCases = new Map<String,String>();

            Set<Id> lockedApprovalCaseIds = new Set<Id>();
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

            for (Case tempCase: (List<Case>) tp.newList) {

                Case newCase = (Case) tp.newMap.get(tempCase.Id);
                Case oldCase = (Case) tp.oldMap.get(tempCase.Id);
                
                //auto-populating the signatory based on the signatory role specified on the case
                if((newCase.Signatory__c != NULL && tempCase.Signatory__c != '' && newCase.Signatory__c != oldCase.Signatory__c) || newCase.Signatory_Person__c == null)
                 tempCase.Signatory_Person__c = signatoryRoleVsSignatories.containsKey(tempCase.Signatory__c) ? signatoryRoleVsSignatories.get(tempCase.Signatory__c) : NULL;

                //copying data from formula fields into normal checkbox fields so as to use them in sharing rules. Currently formula fields are not supported for use in sharing rules
                newCase.Road_Policy_Advisor_Owned__c = newCase.Road_Policy_Advisor_Owned_Formula__c;
                newCase.Transport_Policy_Advisor_Owned__c = newCase.Transport_Policy_Advisor_Owned_Formula__c;
                tempCase.Office_of_Secretary_PA_Owned__c = tempCase.Office_of_Secretary_PA_Owned_Formula__c;
                newCase.WestConnex_Policy_Advisor_Owned__c = newCase.WestConnex_Policy_Advisor_Owned_Formula__c;

                //assigning minister automatically based on the case record type
                if(tempCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                   && ministerMap.containsKey(GlobalConstants.MINISTER_OF_ROAD)
                   && newCase.Minister_User__c == NULL
                   && newCase.Minister__c == NULL) 
                   tempCase.Minister_User__c = ministerMap.get(GlobalConstants.MINISTER_OF_ROAD);

                //assigning minister automatically based on the case record type
                if(tempCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                  && ministerMap.containsKey(GlobalConstants.MINISTER_OF_TRANSPORT)
                  && newCase.Minister_User__c == NULL
                  && newCase.Minister__c == NULL) 
                  tempCase.Minister_User__c = ministerMap.get(GlobalConstants.MINISTER_OF_TRANSPORT);

                //assigning minister automatically based on the case record type for westconnex
                if(tempCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX 
                  && ministerMap.containsKey(GlobalConstants.MINISTER_OF_WESTCONNEX)
                  && newCase.Minister_User__c == NULL
                  && newCase.Minister__c == NULL) 
                  tempCase.Minister_User__c = ministerMap.get(GlobalConstants.MINISTER_OF_WESTCONNEX);  

                //blank out the signatory if signatory role is cleared
                if(newCase.Signatory__c == NULL || newCase.Signatory__c == '') 
                  tempCase.Signatory_Person__c = NULL;

                //case has completed Thunderhead MAGS approval
                if(newCase.Status == GlobalConstants.MAGS_APPROVED_MIN_CORRO && newCase.Status != oldCase.Status) {

                    if(newCase.Case_Owner_Role_Name__c == GlobalConstants.MAGS_ROLE_MANAGER_LABEL 
                       || newCase.Case_Owner_Role_Name__c == GlobalConstants.MAGS_ROLE_EDITOR_LABEL 
                       || newCase.Case_Owner_Role_Name__c == GlobalConstants.MAGS_ROLE_SR_OFFICER_LABEL 
                       || newCase.Case_Owner_Role_Name__c == GlobalConstants.MAGS_ROLE_EXECUTIVE_DIRECTOR_LABEL 
                       || newCase.Case_Owner_Role_Name__c == GlobalConstants.MAGS_ROLE_PRINCIPAL_MANAGER_LABEL
                      || newCase.Case_Owner_Role_Name__c == GlobalConstants.MAGS_ROLE_EXECUTIVE_DIRECTOR_LABEL
                      ) {

                        //stamping down the earlier case owner from the MAGS hierarchy
                        newCase.Rejection_User__c = newCase.OwnerId;
                    }

                    if((loggedInUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_MANAGER 
                        || loggedInUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_EDITOR 
                        || loggedInUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_SR_OFFICER 
                        || loggedInUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_EXECUTIVE_DIRECTOR 
                        || loggedInUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_PRINCIPAL_MANAGER)) {

                        //stamping down the earlier case owner from the MAGS hierarchy
                        newCase.Rejection_User__c = loggedInUser.Id;
                    }
                    /* Updated : 08/09/2017 Added by Pawan Tiwari
                    // commented for RQ-100(qTest-CFS)
                    //if the signatory role is MAGS Manager, Executive Director, CRGS or Principal MAGS Manager then no intermediate approver
                    // 06/06/2017: Do not update owner with MAGS signatory if record type is WestConnex.
                    if((newCase.Signatory__c == GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE 
                       || newCase.Signatory__c == GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE 
                       || newCase.Signatory__c == GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) 
                       && newCase.Signatory_Person__c != NULL && newCase.Record_Type_Dev_Name__c != GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX) {

                        newCase.OwnerId = newCase.Signatory_Person__c;
                    }
                    else if(newCase.Signatory__c != '' && newCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE 
                            && newCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE 
                            && newCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE 
                            && newCase.MO_User__c != NULL) {

                        newCase.OwnerId = newCase.MO_User__c;
                    }*/ 
                }

                //case has been rejected by MO User (Intermediate approval by DLO/PA), transfer case ownership to initial submitter (MAGS Manager)
                if(((newCase.Status == GlobalConstants.MO_AMEND_MIN_CORRO 
                     && oldCase.Status == GlobalConstants.AWAITING_MO_CONTACT_APPROVAL_MIN_CORRO) 
                    || (newCase.Status == GlobalConstants.SIGNATORY_REJECTED_MIN_CORRO 
                    && oldCase.Status == GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO 
                    && (newCase.Signatory__c == GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE 
                        || newCase.Signatory__c == GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE 
                        || newCase.Signatory__c == GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE)) 
                    || (newCase.Status == GlobalConstants.MO_AMEND_MIN_CORRO 
                        && oldCase.Status == GlobalConstants.SIGNATORY_REJECTED_MIN_CORRO) 
                    || (newCase.Status == GlobalConstants.MO_AMEND_MIN_CORRO 
                        && oldCase.Status == GlobalConstants.MAGS_APPROVED_MIN_CORRO)) 
                   && newCase.Status != oldCase.Status && newCase.Rejection_User__c != NULL) {

                    newCase.OwnerId = newCase.Rejection_User__c;
                    magsRejectionCases.put(newCase.Rejection_User__c, newCase.Id);
                }

                //updating Responsible_Team__c field with team queue name
                if(GlobalConstants.TEAM_QUEUES_AND_TEAM_PICKLIST.containsKey(newCase.Case_Owner__c)) 
                  newCase.Responsible_Team__c = GlobalConstants.TEAM_QUEUES_AND_TEAM_PICKLIST.get(newCase.Case_Owner__c);

                //updating case ownership to Responsible_MAGS_Officer__c for Roads and Transport cases after status is updated as signed and emailed
                if(newCase.Status == GlobalConstants.MO_SIGNED_AND_EMAILED_MIN_CORRO 
                    && newCase.Minister_Communication_Preference__c == GlobalConstants.MINISTER_COMM_PREFERENCE_EMAIL 
                    && newCase.Responsible_MAGS_Officer__c != NULL 
                    && (newCase.Record_Type_Dev_Name__c == GlobalConstants.MIN_CORRO_RECTYPE_API_NAME 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX)) {
                 
                    // validate if responsible mags officer is an active user
                    if(ativeUserList.containsKey(newCase.Responsible_MAGS_Officer__c))    
                        newCase.OwnerId = newCase.Responsible_MAGS_Officer__c;
                    else{   // user is inactive, get responsible mags officer user id from custom setting
                        Map<String,Active_user_for_responsible_MAGS_officer__c> activeResponsibleMAGSOfficer =  Active_user_for_responsible_MAGS_officer__c.getAll();   
                        if(activeResponsibleMAGSOfficer.containsKey(GlobalConstants.RESPONSIBLE_MAGS_OFFICER_USER_ID)){
                            newCase.OwnerId = activeResponsibleMAGSOfficer.get(GlobalConstants.RESPONSIBLE_MAGS_OFFICER_USER_ID).User_Id__c;
                        }
                    }
                } 
                
                //updating case ownership to Responsible_MAGS_Officer__c after status is updated as signed and is marked for wet signature
                // and minister comm. pref. is Email
                if(newCase.Wet_Signature__c && newCase.Status == GlobalConstants.CASE_SIGNED_STATUS_MIN_CORRO 
                    && oldCase.Status == GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO
                    && newCase.Minister_Communication_Preference__c == GlobalConstants.MINISTER_COMM_PREFERENCE_EMAIL 
                    && newCase.Responsible_MAGS_Officer__c != NULL 
                    && (newCase.Record_Type_Dev_Name__c == GlobalConstants.MIN_CORRO_RECTYPE_API_NAME 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX)) {
                    
                    // validate if responsible mags officer is an active user
                    if(ativeUserList.containsKey(newCase.Responsible_MAGS_Officer__c))    
                        newCase.OwnerId = newCase.Responsible_MAGS_Officer__c;
                    else{   // user is inactive, get responsible mags officer user id from custom setting 
                        Map<String,Active_user_for_responsible_MAGS_officer__c> activeResponsibleMAGSOfficer =  Active_user_for_responsible_MAGS_officer__c.getAll();   
                        if(activeResponsibleMAGSOfficer.containsKey(GlobalConstants.RESPONSIBLE_MAGS_OFFICER_USER_ID)){
                            newCase.OwnerId = activeResponsibleMAGSOfficer.get(GlobalConstants.RESPONSIBLE_MAGS_OFFICER_USER_ID).User_Id__c;
                        }
                    }
                }  
                    
                
                //updating case ownership to CRGS Admin queue after status is updated as signed and is marked for wet signature
                // and minister comm. pref. is Letter
                if(newCase.Wet_Signature__c && newCase.Status == GlobalConstants.CASE_SIGNED_STATUS_MIN_CORRO 
                    && oldCase.Status == GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO
                    && newCase.Minister_Communication_Preference__c == GlobalConstants.EZESCAN_CASE_ORIGIN 
                    && CRGSAdminQueue != NULL && CRGSAdminQueue.size() > 0 
                    && (newCase.Record_Type_Dev_Name__c == GlobalConstants.MIN_CORRO_RECTYPE_API_NAME 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT
                        || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX)) 
                    newCase.OwnerId = CRGSAdminQueue[0].Id;

                System.debug('Record Lock Status: ' + Approval.isLocked(newCase.Id));

                System.debug('Owner Profile Name: ' + newCase.Case_Owner_Profile__c);
                System.debug('Owner Substring Id: ' + newCase.Case_Owner__c.substring(0, 4));

                //generating incoming PDF for new roads, transport and OOS case created via email and webform
                //checking session Id as Conga call requires a valid session id. 
                //This session id can be null sometimes when in context of some automated process 
                if((newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                    || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                    || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX
                    || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS) 
                   && (newCase.Origin == GlobalConstants.WEB2CASE_ORIGIN 
                       || newCase.Origin == GlobalConstants.EZESCAN_CASE_ORIGIN
                       || newCase.Origin == GlobalConstants.EZESCAN_EMAIL_CASE_ORIGIN) 
                   && newCase.Incoming_PDF_Generated__c == FALSE && UserInfo.getSessionId() != NULL 
                   && ((newCase.Status == GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS 
                        || oldCase.Status == GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS)
                       || (newCase.Status == GlobalConstants.DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS 
                        || oldCase.Status == GlobalConstants.DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS)) 
                  // && newCase.Case_Owner_Profile__c != NULL 
                   && newCase.Case_Owner_Profile__c != GlobalConstants.MIN_COR_API_INTEGRATION_USERNAME) {

                    String caseOwner = newCase.OwnerId;
                    
                    System.debug('Case Owner: '+caseOwner);

                    //if(caseOwner.substring(0, 4) != '005') {
                      
                        System.debug('Got session Id: ' + UserInfo.getSessionId());
                        GenerateIncomingPDF.generate(newCase.Id, UserInfo.getSessionId());
                        newCase.Incoming_PDF_Generated__c = TRUE;
                  //  }
                }
                
                //generating incoming PDF for new general ministerial case created via email and webform
                //checking session Id as Conga call requires a valid session id. 
                //This session id can be null sometimes when in context of some automated process 
                if(newCase.Record_Type_Dev_Name__c == GlobalConstants.MIN_CORRO_RECTYPE_API_NAME
                   && newCase.Origin == GlobalConstants.EZESCAN_EMAIL_CASE_ORIGIN
                   && newCase.Incoming_PDF_Generated__c == FALSE && UserInfo.getSessionId() != NULL
                   && (newCase.Status == GlobalConstants.DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS 
                        || oldCase.Status == GlobalConstants.DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS)
                   //&& newCase.Case_Owner_Profile__c != NULL 
                   && newCase.Case_Owner_Profile__c != GlobalConstants.MIN_COR_API_INTEGRATION_USERNAME
                   && newCase.ContactId != NULL) {
                   
                        
                        System.debug('Got session Id: ' + UserInfo.getSessionId());
                        GenerateIncomingPDF.generate(newCase.Id, UserInfo.getSessionId());
                        newCase.Incoming_PDF_Generated__c = TRUE;       
                }
                
                /*
                if(userRoleAllowedtoBypassTakeOwnership){
                    if (newCase.status == GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS && newCase.OwnerId == oldCase.OwnerId){
                            newCase.OwnerId = loggedInUser.id;
                    }
                }
                */
                

                //unlocking locked case - happens because of approval process
                if(Approval.isLocked(newCase.Id)) 
                 lockedApprovalCaseIds.add(newCase.Id);

            }

            //unocking records locked by MO view approval process
            if(lockedApprovalCaseIds.size() > 0) {

                // Unlock the cases
                Approval.UnlockResult[] lrList = Approval.unlock(new List <Id> (lockedApprovalCaseIds), false);

                // Iterate through each returned result
                for(Approval.UnlockResult lr: lrList) {

                    if(!lr.isSuccess()) {

                        // Operation failed, so get all errors                
                        for(Database.Error err: lr.getErrors()) {

                            ApplicationLogMessage message = new ApplicationLogMessage();
                            message.source = 'CaseBeforeUpdateHandlerForMO';
                            message.sourceFunction = 'process';
                            message.logMessage = 'Approval auto-unlock failed: ' + err.getMessage();
                            message.debugLevel = GlobalConstants.ERROR;
                            messages.add(message);
                        }
                    }
                }

            }

            if(magsRejectionCases.size() > 0){

                for(User tempUser: [SELECT Id, Name, Role_Dev_Name__c
                                        FROM User WHERE Id IN: magsRejectionCases.keySet()]) {
    
                    System.debug('Role Dev Name: ' + tempUser.Role_Dev_Name__c);
    
                    if(tempUser.Role_Dev_Name__c != '' 
                       && (tempUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_EDITOR 
                           || tempUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_MANAGER 
                           || tempUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_SR_OFFICER 
                           || tempUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_EXECUTIVE_DIRECTOR 
                           || tempUser.Role_Dev_Name__c == GlobalConstants.MAGS_ROLE_PRINCIPAL_MANAGER)) {
    
                        Case newCase = (Case) tp.newMap.get(magsRejectionCases.get(tempUser.Id));
    
                        if(newCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE 
                           && newCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE 
                           && newCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) {
    
                            System.debug('Dev Name Case: ' + newCase.Record_Type_Dev_Name__c);
    
                            if(newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD) 
                                newCase.OwnerId = RoadMAGSManagerQueue.size() > 0 ? RoadMAGSManagerQueue[0].Id: newCase.Rejection_User__c;
    
                            if(newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                               || newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS) 
                                newCase.OwnerId = TransportMAGSManagerQueue.size() > 0 ? TransportMAGSManagerQueue[0].Id: newCase.Rejection_User__c;


                            if(newCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX) 
                                newCase.OwnerId = WestConnexMAGSManagerQueue.size() > 0 ? WestConnexMAGSManagerQueue[0].Id: newCase.Rejection_User__c;    
    
                            System.debug('Case Owner: ' + newCase.OwnerId);
                        }
                        else if(newCase.Responsible_MAGS_Officer__c != NULL) {
    
                            //upon rejection updating case ownership to Responsible MAGS Officer when signatory is non MO
                            newCase.OwnerId = newCase.Responsible_MAGS_Officer__c;
                        }
                    }
                }
            }
        }
        catch(Exception e) {
        
            exceptionInvoked = TRUE;
            System.debug(e);
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'CaseBeforeUpdateHandlerForMO';
            message.sourceFunction = 'process';

            if(tp != null && tp.newMap != null) 
                message.referenceInfo = JSON.serialize(tp.newMap.keySet());

            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
         
        triggerExecuted = TRUE;
    }
}