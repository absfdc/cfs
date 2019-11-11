/*---------------------------------------------------------------------------------------
Author:        Arxxus
Description:   Before insert handler class for the Case trigger
Test Class:    CaseBeforeInsertHandlerForMO_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
10/10/2016     Arxxus             Created
17/04/2017     Arxxus             Updated. Include steps to auto-populate signatory person based 
                                  on signatory role populated and auto populate minister based 
                                  on record type of the case.
-----------------------------------------------------------------------------------------*/
public without sharing class CaseBeforeInsertHandlerForMO extends TriggerHandlerBase {

    private static List<User> signatoryUsers = new List<User>();
    private static List<User> ministerUsers = new List<User>();
    private static Boolean triggerExecuted = FALSE;

    public boolean exceptionInvoked = FALSE;

    public override void mainEntry(TriggerParameters tp) {

        process(tp);
    }

    private void process(TriggerParameters tp) {

        try {
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

            for(User tempSignatoryUser: signatoryUsers) {
                signatoryRoleVsSignatories.put(tempSignatoryUser.UserRole.Name, tempSignatoryUser.Id);
            }
            System.debug('List of signatory users :: ' + signatoryRoleVsSignatories );
            for(User tempMinisterUser: ministerUsers) {
                ministerMap.put(tempMinisterUser.Role_Dev_Name__c, tempMinisterUser.Id);
            }

            for(Case tempCase: (List<Case>) tp.newList) {
                System.debug('tempCase.Signatory__c :: ' + tempCase.Signatory__c + '--' + signatoryRoleVsSignatories.containsKey(tempCase.Signatory__c));  
                //auto-populating the signatory based on the signatory role specified on the case
                if(tempCase.Signatory__c != NULL && tempCase.Signatory__c != '') 
                  tempCase.Signatory_Person__c = signatoryRoleVsSignatories.containsKey(tempCase.Signatory__c) ? signatoryRoleVsSignatories.get(tempCase.Signatory__c) : NULL;
                System.debug('Signatory Person :: ' + tempCase.Signatory_Person__c + '--' + signatoryRoleVsSignatories.get(tempCase.Signatory__c));  
                tempCase.Road_Policy_Advisor_Owned__c = tempCase.Road_Policy_Advisor_Owned_Formula__c;
                tempCase.Transport_Policy_Advisor_Owned__c = tempCase.Transport_Policy_Advisor_Owned_Formula__c;
                tempCase.Office_of_Secretary_PA_Owned__c = tempCase.Office_of_Secretary_PA_Owned_Formula__c;
                tempCase.WestConnex_Policy_Advisor_Owned__c = tempCase.WestConnex_Policy_Advisor_Owned_Formula__c;

                //assigning minister automatically based on the case record type
                if(tempCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                    && ministerMap.containsKey(GlobalConstants.MINISTER_OF_ROAD)
                    && tempCase.Minister_User__c == NULL) 
                    tempCase.Minister_User__c = ministerMap.get(GlobalConstants.MINISTER_OF_ROAD);

                //assigning minister automatically based on the case record type
                if(tempCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                    && ministerMap.containsKey(GlobalConstants.MINISTER_OF_TRANSPORT)
                    && tempCase.Minister_User__c == NULL) 
                    tempCase.Minister_User__c = ministerMap.get(GlobalConstants.MINISTER_OF_TRANSPORT);

                //Apr 17, 2017 - assigning minister automatically based on the case record type of WestConnex
                if(tempCase.Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX 
                    && ministerMap.containsKey(GlobalConstants.MINISTER_OF_WESTCONNEX)
                    && tempCase.Minister_User__c == NULL) 
                    tempCase.Minister_User__c = ministerMap.get(GlobalConstants.MINISTER_OF_WESTCONNEX);
    

                //updating Responsible_Team__c field with team queue name
                if(GlobalConstants.TEAM_QUEUES_AND_TEAM_PICKLIST.containsKey(tempCase.Case_Owner__c)) 
                    tempCase.Responsible_Team__c = GlobalConstants.TEAM_QUEUES_AND_TEAM_PICKLIST.get(tempCase.Case_Owner__c);

            }
        }
        catch(Exception e) {

            System.debug(e);
            exceptionInvoked = TRUE;
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'CaseBeforeInsertHandlerForMO';
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