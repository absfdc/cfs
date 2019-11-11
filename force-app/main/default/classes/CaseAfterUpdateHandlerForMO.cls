/*---------------------------------------------------------------------------------------
Author:        Arxxus
Description:   After Update handler class for the Case trigger
Test Class:    CaseAfterUpdateHandlerForMO_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
10/10/2016     Arxxus             Created
07/04/2017     Arxxus             Updated.Send email on Signature Review Completed checkbox
03/05/3017     Ian Fitzgerald     Moved call to ReassignSignatoryApproval.reassignRequest out of for-loop
17/04/2017     Arxxus             Updated. Send email to customer/staff and additional corro recipients 
                                  only when case stauts is 'Review' and Signature Review Completed checkbox is checked.
                                  Check the email communication prefernce as 'Email' before sending and email.
16/05/2017     Arxxus             Updated.Merge the MOI Change with health org changes.
-----------------------------------------------------------------------------------------*/
public without sharing class CaseAfterUpdateHandlerForMO extends TriggerHandlerBase {

    public boolean exceptionInvoked = FALSE;

    public override void mainEntry(TriggerParameters tp) {

        process(tp);
        precedentCaseUnShare(tp);
        precedentCaseShare(tp);

    }

    private void process(TriggerParameters tp) {

        try {
            Map<Id,Case> caseRecordsToReassign = new Map<Id,Case>();
            
            Boolean isTrue;
            Map<String,Digital_Process_Send_Email__c> checkSendEmailProcess = Digital_Process_Send_Email__c.getAll();
            isTrue = checkSendEmailProcess != NULL && checkSendEmailProcess.size() > 0 && checkSendEmailProcess.get(GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL) != NULL ?checkSendEmailProcess.get(GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL).On__c:FALSE;
                
            for(Case tempCase: (List<Case>) tp.newList) {

                Case newCase = (Case) tp.newMap.get(tempCase.Id);
                Case oldCase = (Case) tp.oldMap.get(tempCase.Id);

                // 17/04/2017 Pawan Tiwari: check if 'Digital Process Send Email' custom setting has record for 'On' as checked
                if(isTrue == FALSE){

                    // check if user has checked 'Signature Review Completed' checkbox checked for email to customer/staff/additional corro
                    if(newCase.Status == GlobalConstants.CASE_REVIEW_STATUS 
                        && newCase.Review_Completed__c == true 
                        && oldCase.Review_Completed__c == false ){

                        // check if communication prefernce is 'Email' before sending the email.
                        if(newCase.Minister_Communication_Preference__c == GlobalConstants.MINISTER_COMM_PREFERENCE_EMAIL)
                            EmailCustomer.prepareAndSendEmail(newCase.Id);
                        
                    }
                }
                
                //reassigning approval from signatory to signatory OBO when case status is Awaiting MO Signatory Approval
                if (newCase.Signatory_Person_OBO__c != NULL 
                    && newCase.Signatory_Person_OBO__c != oldCase.Signatory_Person_OBO__c 
                    && newCase.Status == GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO) {
                    caseRecordsToReassign.put(newCase.Id, newCase);
                }

                //reassigning approval from OBO signatory to signatory when case status is Awaiting MO Signatory Approval
                Map<Id,Case> oboCaseRecordsToReassign = new Map<Id,Case>();
                if (newCase.Signatory__c != NULL 
                    && newCase.Signatory_Person_OBO__c != oldCase.Signatory_Person_OBO__c 
                    && newCase.Signatory_Person_OBO__c == NULL 
                    && newCase.Status == GlobalConstants.AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO) {
                    caseRecordsToReassign.put(newCase.Id, newCase);
                }
            }
            
            //03/05/3017 Ian Fitzgerald Moved the below if-statement out of for-loop
            if(caseRecordsToReassign.size() > 0){
                ReassignSignatoryApproval.reassignRequest(caseRecordsToReassign);
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
    }

    /*---------------------------------------------------------------------------------------
    Author:        Arxxus
    Description:   used to share a case with MO Contact and Signatory Person on change
    Input:         trigger parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    10/10/2016     Arxxus             Created
    -----------------------------------------------------------------------------------------*/
    private void precedentCaseShare(TriggerParameters tp) {

        try {

            Set<Id>relatedCaseIds = new Set<Id>();

            Set<Id> precedentCaseIds = new Set<Id>();
            Map<Id,Case> precedentCaseMap = new Map<Id,Case>();

            for(Case tempCase: (List<Case>) tp.newList) {

                Case newCase = (Case) tp.newMap.get(tempCase.Id);
                Case oldCase = (Case) tp.oldMap.get(tempCase.Id);

                System.debug('New Case Status: ' + newCase.Status);
                System.debug('Old Case Status: ' + oldCase.Status);

                if((newCase.MO_User__c != oldCase.MO_User__c) 
                   || (newCase.Signatory_Person__c != oldCase.Signatory_Person__c) 
                   && newCase.Precedent_Cases_Count__c > 0) {

                    relatedCaseIds.add(tempCase.Id);

                }

            }

            Map<Id,Case> newMap = (Map<Id,Case>) tp.newMap;

            Map<Id,Case> relatedCaseMap = new Map<Id,Case>();

            Map<Id,Precedent__c> precedentValuesMap = new Map<Id,Precedent__c>();

            if (relatedCaseIds.size() > 0) {

                for(Precedent__c getPrecedentRecord: [Select Id, Related_Case__c, Precedent_Case__c FROM Precedent__c
                                                        WHERE Related_Case__c IN: relatedCaseIds]) {
                    precedentValuesMap.put(getPrecedentRecord.Id, getPrecedentRecord);
                    precedentCaseIds.add(getPrecedentRecord.Precedent_Case__c);
                }

                if(precedentCaseIds.size() > 0) {
                    // create a map of caseId and case to get MO_User__c and Signatory_Person__c 
                    for(Case getCase: [Select Id, OwnerId FROM Case
                                            WHERE Id IN: precedentCaseIds]) {
                        precedentCaseMap.put(getCase.Id, getCase);
                    }
                }

                // create a map of caseId and case to get MO_User__c and Signatory_Person__c 
                for(Case getCase: newMap.values()) {

                    if(relatedCaseIds.contains(getCase.Id)) 
                        relatedCaseMap.put(getCase.Id, getCase);

                }

                Map<Id,List<Precedent__c>> relatedCaseVsPrecedentCaseMap = new Map<Id,List<Precedent__c>>();

                // create a Map of related Case id with List of precdent
                for(Precedent__c getPrecedent: precedentValuesMap.values()) {

                    if(!relatedCaseVsPrecedentCaseMap.containsKey(getPrecedent.Related_Case__c)) 
                        relatedCaseVsPrecedentCaseMap.put(getPrecedent.Related_Case__c, new List < Precedent__c > {getPrecedent});
                    else 
                        relatedCaseVsPrecedentCaseMap.get(getPrecedent.Related_Case__c).add(getPrecedent);

                }

                System.debug('After Insert relatedCaseVsPrecedentCaseMap :: ' + relatedCaseVsPrecedentCaseMap);

                List<CaseShare> csShareList = new List<CaseShare>();

                for(List<Precedent__c> getPrecedentList: relatedCaseVsPrecedentCaseMap.values()) {

                    for(Precedent__c getPrecedent: getPrecedentList) {

                        String moContact = NULL;
                        String signatoryPerson = NULL;

                        if(relatedCaseMap.containsKey(getPrecedent.Related_Case__c)) {

                            moContact = relatedCaseMap.get(getPrecedent.Related_Case__c).MO_User__c;
                            signatoryPerson = relatedCaseMap.get(getPrecedent.Related_Case__c).Signatory_Person__c;

                        }

                        if(getPrecedent.Precedent_Case__c != NULL) {

                            // block to check if MO User or Signatory are owner of precedent case then not share case
                            if(precedentCaseMap.containsKey(getPrecedent.Precedent_Case__c)) {

                                if(moContact != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != moContact) {

                                    CaseShare csShare = new CaseShare();
                                    // Give Read write access to that user for this particular case record.
                                    csShare.CaseAccessLevel = 'Edit';
                                    // Assign case Id of case record.
                                    csShare.CaseId = getPrecedent.Precedent_Case__c;
                                    // Assign user id to grant read write access to this particular case record.
                                    csShare.UserOrGroupId = moContact;
                                    csShareList.add(csShare);
                                }

                                if(signatoryPerson != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != moContact) {

                                    CaseShare csShare = new CaseShare();
                                    // Give Read write access to that user for this particular case record.
                                    csShare.CaseAccessLevel = 'Edit';
                                    // Assign case Id of case record.
                                    csShare.CaseId = getPrecedent.Precedent_Case__c;
                                    // Assign user id to grant read write access to this particular case record.
                                    csShare.UserOrGroupId = signatoryPerson;
                                    csShareList.add(csShare);
                                }
                            }
                        }
                    }
                }

                System.debug('After Insert csShareList :: ' + csShareList);

                if(csShareList != null && csShareList.size() > 0) 
                    insert csShareList;

            }

        } catch(Exception e) {
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'CaseAfterUpdateHandlerForMO';
            message.sourceFunction = 'precedentCaseShare';
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
    }

    /*---------------------------------------------------------------------------------------
    Author:        Arxxus
    Description:   used to unshare a case with MO Contact and Signatory Person who is no longer on that case
    Input:         trigger parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    10/10/2016     Arxxus             Created
    -----------------------------------------------------------------------------------------*/
    private void precedentCaseUnShare(TriggerParameters tp) {

        try {

            Set<Id> relatedCaseIds = new Set<Id>();
            Set<Id> precedentCaseIds = new Set<Id>();
            Map<Id,Case> precedentCaseMap = new Map<Id,Case>();

            for (Case tempCase: (List<Case>) tp.newList) {

                Case newCase = (Case) tp.newMap.get(tempCase.Id);
                Case oldCase = (Case) tp.oldMap.get(tempCase.Id);

                System.debug('New Case MO_User__c: ' + newCase.MO_User__c + '--' + newCase.Signatory_Person__c);
                System.debug('Old Case MO_User__c: ' + oldCase.MO_User__c + '--' + oldCase.Signatory_Person__c);

                if((newCase.MO_User__c != oldCase.MO_User__c) 
                    || (newCase.Signatory_Person__c != oldCase.Signatory_Person__c) 
                    && newCase.Precedent_Cases_Count__c > 0) {

                    relatedCaseIds.add(tempCase.Id);

                }
            }

            Map<Id,Case> oldMap = (Map<Id,Case>) tp.oldMap;
            Map<Id,Case> relatedCaseMap = new Map<Id,Case>();
            Map<Id,Precedent__c> precedentValuesMap = new Map<Id,Precedent__c>();

            if(relatedCaseIds.size() > 0) {

                for(Precedent__c getPrecedentRecord: [Select Id, Related_Case__c, Precedent_Case__c FROM Precedent__c
                                                        WHERE Related_Case__c IN: relatedCaseIds]) {

                    precedentValuesMap.put(getPrecedentRecord.Id, getPrecedentRecord);
                    precedentCaseIds.add(getPrecedentRecord.Precedent_Case__c);
                }

                if(precedentCaseIds.size() > 0) {
                    // create a map of caseId and case to get MO_User__c and Signatory_Person__c 
                    for (Case getCase: [Select Id, OwnerId FROM Case
                                        WHERE Id IN: precedentCaseIds]) {
                        precedentCaseMap.put(getCase.Id, getCase);
                    }
                }

                if(oldMap.size() > 0) {
                    // create a map of caseId and case to get MO_User__c and Signatory_Person__c 
                    for(Case getCase: oldMap.values()) {
                        if(relatedCaseIds.contains(getCase.Id)) 
                            relatedCaseMap.put(getCase.Id, getCase);
                    }

                    system.debug('Before Delete relatedCaseMap ::' + relatedCaseMap);

                }

                Map<Id,List<Precedent__c>> relatedCaseVsPrecedentCaseMap = new Map<Id,List<Precedent__c>>();

                if(precedentValuesMap.size() > 0) {
                    // create a Map of related Case id with List of precdent
                    for(Precedent__c getPrecedent: precedentValuesMap.values()) {

                        if(!relatedCaseVsPrecedentCaseMap.containsKey(getPrecedent.Related_Case__c)) 
                            relatedCaseVsPrecedentCaseMap.put(getPrecedent.Related_Case__c, new List<Precedent__c> {getPrecedent});
                        else 
                            relatedCaseVsPrecedentCaseMap.get(getPrecedent.Related_Case__c).add(getPrecedent);

                    }

                    system.debug('Before Delete relatedCaseVsPrecedentCaseMap ::' + relatedCaseVsPrecedentCaseMap);

                }

                List<CaseShare> csShareList = new List<CaseShare>();

                // map used to create case vs user (MO Contact or Signatory Person)
                Map<Id,Set<Id>> caseVsUserIdMap = new Map<Id,Set<Id>> ();

                if(relatedCaseVsPrecedentCaseMap.size() > 0) {

                    for(List<Precedent__c> getPrecedentList : relatedCaseVsPrecedentCaseMap.values()) {

                        for(Precedent__c getPrecedent: getPrecedentList) {

                            String moContact = NULL;
                            String signatoryPerson = NULL;

                            if(relatedCaseMap.containsKey(getPrecedent.Related_Case__c)) {
                                moContact = relatedCaseMap.get(getPrecedent.Related_Case__c).MO_User__c;
                                signatoryPerson = relatedCaseMap.get(getPrecedent.Related_Case__c).Signatory_Person__c;
                            }
                            
                            if(getPrecedent.Precedent_Case__c != NULL) {

                                // block to check if MO User or Signatory are owner of precedent case then not share case
                                if(precedentCaseMap.containsKey(getPrecedent.Precedent_Case__c)) {

                                    if(moContact != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != moContact) {

                                        if(!caseVsUserIdMap.containsKey(getPrecedent.Precedent_Case__c)) {
                                            caseVsUserIdMap.put(getPrecedent.Precedent_Case__c, new Set<Id>{(Id)moContact});
                                        } else {
                                            caseVsUserIdMap.get(getPrecedent.Precedent_Case__c).add((Id) moContact);
                                        }

                                    }

                                    if(signatoryPerson != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != moContact) {

                                        if(!caseVsUserIdMap.containsKey(getPrecedent.Precedent_Case__c)) {
                                            caseVsUserIdMap.put(getPrecedent.Precedent_Case__c, new Set <Id> { (Id) signatoryPerson });
                                        } else {
                                            caseVsUserIdMap.get(getPrecedent.Precedent_Case__c).add((Id) signatoryPerson);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // set of user id with whom unshare case.
                Set<Id> userIds = new Set<Id>();
                for(Set<Id> getIdSet: caseVsUserIdMap.values()) {
                    for(Id getId: getIdSet) {
                        userIds.add(getId);
                    }
                }

                if(caseVsUserIdMap.size() > 0 && userIds.size() > 0) {
                    List<CaseShare> caseShareToDelete = [Select Id, CaseId, CaseAccessLevel, UserOrGroupId, RowCause FROM CaseShare
                                                            WHERE CaseAccessLevel = 'Edit'
                                                            AND CaseId IN: caseVsUserIdMap.keySet()
                                                            AND RowCause = 'Manual'
                                                            AND UserOrGroupId IN: userIds];

                    system.debug('caseShareToDelete ::' + caseShareToDelete);
                    if(caseShareToDelete.size() > 0) 
                        delete caseShareToDelete;
                }
            }
        }
        catch(Exception e) {

            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'CaseAfterUpdateHandlerForMO';
            message.sourceFunction = 'precedentCaseUnShare';
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
    }

}