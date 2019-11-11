/*------------------------------------------------------------
Author:        Arxxus
Description:   class for all action needed for MO view UI.
Test Class:     MinisterApprovalViewController_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
07-DEC-2016   Arxxus             Comments and cleanup
15-Aug-2017   Pawan Tiwari       Updated.
26-Jun-2018  Ian Fitzgerald     Added Smart Corro dynamic signature insert.
                                      Added method generateSignedCorroPdf
                                      Replaced method createAuthorisationRecordAndUpdateSignatureURL
------------------------------------------------------------*/
global with sharing class MinisterApprovalViewController {

    public static String caseSubject { get; set; }
    public static String CaseNumber { get; set; }
    public static String contactName { get; set; }
    public static String dueDate { get; set; }
    public static String createdDate { get; set; }
    public static List <Case> getCaseList { get; set; }
    public static String currentCaseId { get; set; }
    public static List <Case> caseListForApproval { get; set; }
    public static Integer caseIndexNumber { get; set; }
    public static Integer sortColIndexNumber { get; set; }
    public static Integer sortColOrderNumber { get; set; }
    public static Integer totalCaseCountInQueue { get; set; }
    public static String loggedInUserId { get; set; }
    public static String filterStr { get; set; }

    public static List<String> approvalQueueColumnsHeader = new List<String>{'Due_date__c', 'CaseNumber', 'CaseNumber', 'CaseStatus__c', 'Contact.Name', 'Signatory_Person__r.Name', 'Desktop_Editing__c', 'Subject'};
    public static List<String> approvalQueueSorting = new List<String>{'ASC', 'DESC'};

    public static String instructionsSentTo { get; set; }

    public static boolean exceptionInvoked = FALSE;

    public MinisterApprovalViewController() {

    }

    public void caseDeatils() {

        loggedInUserId = UserInfo.getUserId();
        currentCaseId = ApexPages.currentPage().getParameters().get('caseId');
        caseIndexNumber = Integer.valueOf(ApexPages.currentPage().getParameters().get('caseIndex'));
        sortColIndexNumber = Integer.valueOf(ApexPages.currentPage().getParameters().get('sortColIndex'));
        sortColOrderNumber = Integer.valueOf(ApexPages.currentPage().getParameters().get('sortColOrder'));
        filterStr = ApexPages.currentPage().getParameters().get('searchBy');

        caseListForApproval = getCaseListQueue(sortColIndexNumber, sortColOrderNumber,filterStr);
        totalCaseCountInQueue = caseListForApproval.size();
        setCaseParameters(caseIndexNumber, sortColIndexNumber, sortColOrderNumber,filterStr);
        getUserOrQueueToSendInstructions(getCurrentCaseNumberForId(currentCaseId));
    
    }

    private static string getCurrentCaseNumberForId(String caseId){
        List<Case> getCaseNumber = [Select Id,CaseNumber from case where Id =: currentCaseId limit 1];
        if(getCaseNumber.size() > 0){
            return getCaseNumber[0].CaseNumber;
        }

        return '';
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get case list present in approval queue
    Inputs:        sort by column index, sorting order i.e ASC or DESC => 0 means ASC, 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @TestVisible
    private static List <Case> getCaseListQueue(Integer sortColIndex, Integer sortColOrder, String getFilterStr) {
        
        List<String> caseList = new List<String>();
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        List<Case> caseQueue = new List<Case>();

        try {

            Integer checkSortOrder = sortColOrder;
            String caseNumberSort = 'ASC';

            // toggle sorting order for 'Desktop Editing' due to inverse order in jsSorter at Approval Queue UI maintain CaseNumber ASC sortOrder for chekbox due to UI
            if(sortColIndex == 6) {
                if(checkSortOrder == 0) {
                    checkSortOrder = 1;
                }else if(checkSortOrder == 1) {
                    checkSortOrder = 0;
                }
            }

            String nullOrder = '';

            String orderByColumn = approvalQueueColumnsHeader.get(sortColIndex);
            String sortOrder = approvalQueueSorting.get(checkSortOrder);

            if(sortOrder == 'ASC')
                nullOrder = 'FIRST';
            else if(sortOrder == 'DESC')
                nullOrder = 'LAST';


            Set<Id> targetCaseRecordIds = new Set<Id>();

            for(ProcessInstanceWorkItem workItem: [SELECT ProcessInstance.TargetObjectId
                                                    FROM ProcessInstanceWorkItem
                                                    WHERE ProcessInstance.Status = 'Pending'
                                                    AND ActorId = : UserInfo.getUserId()
                                                    ORDER BY ElapsedTimeInMinutes ]) {

                targetCaseRecordIds.add(workItem.ProcessInstance.TargetObjectId);
            }
            List<Id> targetCaseRecordIdsList = new List<Id>(targetCaseRecordIds);
            targetCaseRecordIdsList.sort();

            String query = '';
            if(getFilterStr != NULL && getFilterStr != '') {

                getFilterStr = '%' + getFilterStr + '%';

                query = 'SELECT Id, CaseNumber, CaseStatus__c, Subject, Due_date__c, Signatory_Person__r.Name, Desktop_Editing__c FROM Case WHERE Id IN :targetCaseRecordIdsList AND (Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.MIN_CORRO_RECTYPE_API_NAME 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX 
                                + '\' ) AND(Subject LIKE: getFilterStr OR CaseNumber LIKE: getFilterStr) ORDER BY ' + orderByColumn + ' ' + sortOrder + ' NULLS ' + nullOrder + ', CaseNumber ' + caseNumberSort;
            }else{
                query = 'SELECT Id, CaseNumber, CaseStatus__c, Subject, Due_date__c, Signatory_Person__r.Name, Desktop_Editing__c FROM Case WHERE Id IN :targetCaseRecordIdsList AND (Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.MIN_CORRO_RECTYPE_API_NAME 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                                + '\' OR Record_Type_Dev_Name__c = \'' 
                                + GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX 
                                + '\' ) ORDER BY ' + orderByColumn + ' ' + sortOrder + ' NULLS ' + nullOrder + ', CaseNumber ' + caseNumberSort;
            }                    
            system.debug('-query- ' + orderByColumn + '--' + sortOrder + '--' + query);
            caseQueue = Database.query(query);
            system.debug('Controller case queue :: ' + caseQueue);

            if(caseQueue.size() > 0)
                return caseQueue;

            return caseQueue;
        } catch (Exception e) {
            exceptionInvoked = TRUE;
            /*ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getCaseListQueue';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();*/
            return caseQueue;
        }

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   check if user is authorised to create an amendment. Only DLO/PA are authorised to create Amendment.
    Inputs:        NA
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static Boolean getUserRoleToCreateAmendment() {

        Boolean createAmendment = false;

        List<User> getUserRoleList = [Select Id FROM User
                                          WHERE Id = : UserInfo.getUserId()
                                          AND(Role_Dev_Name__c IN: GlobalConstants.MO_DLO_AND_PA_ROLE_NAMES 
                                          OR Role_Dev_Name__c IN : GlobalConstants.MO_MANAGER_ROLES_FOR_REJECTION) ];

        if(getUserRoleList.size() > 0) {
            createAmendment = true;
        }

        return createAmendment;

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   determine user is authorised for final approval or intermediate approval.
    Inputs:        NA
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static String validateUserForApproval() {

        List<User> getDLOAndPARoleUser = [Select Id FROM User
                                              WHERE Id = : UserInfo.getUserId()
                                              AND Role_Dev_Name__c IN: GlobalConstants.MO_DLO_AND_PA_ROLE_NAMES ];

        if(getDLOAndPARoleUser.size() > 0) {
            return 'Intermediate';
        }else {
            List<User> getSignatoryUser = [Select Id FROM User
                                              WHERE Id = : UserInfo.getUserId()
                                              AND Role_Dev_Name__c IN: GlobalConstants.MO_SIGNATORY_ROLE_NAMES ];

            if(getSignatoryUser.size() > 0)
                return 'Signatory';

            else
                return '';
        }

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   determine user or queue to which the case would be assigned after rejection is made
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC, 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static String getUserOrQueueToSendInstructions(String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        try {
            currentCaseWithNumber = String.escapeSingleQuotes(currentCaseWithNumber);
            String getApproverRole = '';

            List<User> userList = [Select Id, Role_Dev_Name__c from User where Id = : UserInfo.getUserId()];

            if(userList.size() > 0) {
                getApproverRole = userList[0].Role_Dev_Name__c;
            }

            if(currentCaseWithNumber != null && currentCaseWithNumber != '' ) {

                currentCaseId = getCurrentCaseId(currentCaseWithNumber);

                List <Case> getCaseListWithRecordType = [ Select Id, Record_Type_Dev_Name__c, MO_User__c, MO_User__r.Name, Rejection_User__c, Rejection_User__r.Name,Responsible_MAGS_Officer__r.Name 
                                                            FROM Case WHERE Id = : currentCaseId 
                                                            AND Record_Type_Dev_Name__c != NULL ];

                
                instructionsSentTo = getApproverRole;
                if(getCaseListWithRecordType.size() > 0) {

                    if((GlobalConstants.MO_DLO_AND_PA_ROLE_NAMES).contains(getApproverRole)) {   // check if rejection user is DLO/PA

                        if(getCaseListWithRecordType[0].Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD) {

                            instructionsSentTo = GlobalConstants.ROADS_MO_CONTACT_REJECTED;

                        }else if(getCaseListWithRecordType[0].Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                                  || getCaseListWithRecordType[0].Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS) {

                            system.debug('getApproverRole :: ' + getApproverRole);
                            instructionsSentTo = GlobalConstants.TRANSPORT_MO_CONTACT_REJECTED;

                        }else if(getCaseListWithRecordType[0].Record_Type_Dev_Name__c == GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX) {

                            system.debug('getApproverRole :: ' + getApproverRole);
                            instructionsSentTo = GlobalConstants.WestConnex_MO_CONTACT_REJECTED;
                        }

                    }else if((GlobalConstants.MO_SIGNATORY_ROLES_FOR_REJECTION).contains(getApproverRole)) {  // check if rejection user is MO Signatory 
             
                        if(getCaseListWithRecordType[0].MO_User__c != NULL) {

                            instructionsSentTo = getCaseListWithRecordType[0].MO_User__r.Name;

                        }
                    
                    }else if((GlobalConstants.MO_MANAGER_ROLES_FOR_REJECTION).contains(getApproverRole)) {  // check if rejection user is Non MO Signatory
                        
                        if(getCaseListWithRecordType[0].Responsible_MAGS_Officer__r.Name != NULL){
                        
                            instructionsSentTo = getCaseListWithRecordType[0].Responsible_MAGS_Officer__r.Name;
                        
                        }else if(getCaseListWithRecordType[0].Rejection_User__r.Name != NULL) {

                            instructionsSentTo = getCaseListWithRecordType[0].Rejection_User__r.Name;

                        }

                    }
                }
            }
            return instructionsSentTo;
        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getUserOrQueueToSendInstructions';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return '';
        }
    }


    private static String getCurrentCaseId(String caseNumberValue){

        List<Case> getCaseNumber = [Select Id from Case where CaseNumber = :caseNumberValue limit 1 ];
        if(getCaseNumber.size() > 0){
          return getCaseNumber[0].Id;  
        }
        return '';   

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   submit request for approval or rejection
    Inputs:        case index in approval queue, approval is intermediate or signatory,approve or reject, sort by column index, sorting order i.e ASC or DESC => 0 means ASC, 1 means DESC, rejection comment
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static String submitApprovalRequest(String approverRole, String approveOrReject, String preference, String rejectionComment, String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        try {
         
            currentCaseId = getCurrentCaseId(currentCaseWithNumber);
            User currentUser = [select Signature_Template_Id__c from User where Id = :UserInfo.getUserId() limit 1 ];
            
            Id signatureDraftId;
            if(approverRole == 'Signatory' && approveOrReject != 'Reject') {   
                signatureDraftId = TH1.GLOBAL_API_V1.generateDraft(currentUser.Signature_Template_Id__c, currentCaseId);
            }
            
            String communicationPreference = preference;

            List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ActorId
                                                          FROM ProcessInstanceWorkitem
                                                          WHERE ProcessInstance.TargetObjectId = : currentCaseId
                                                          AND ActorId = : UserInfo.getUserId() limit 1 ];

            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

            for(ProcessInstanceWorkitem workItem: workItems) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                //Valid values are: Approve, Reject, or Removed. 
                //Only system administrators can specify Removed.
                // check if request if for 'Approve'
                if(approveOrReject == 'Approve') {
                    req.setAction('Approve');
                    if(approverRole == 'Signatory') {   // check if request is made by Signatory
                        req.setComments('Approved');
                    }else if (approverRole == 'Intermediate') // check if request is made by Intermediate approver i.e DLO/PA
                        req.setComments('Approved and sent to signatory for further approval.');
                        
                }else if (approveOrReject == 'Reject') {   // check if request if for 'Rejection'
                    req.setAction('Reject');
                    req.setComments(rejectionComment);
                    
                }
                requests.add(req);
                
            }
            Approval.ProcessResult[] processResults = Approval.process(requests);
            if(processResults[0].isSuccess()) {
                // check if approver is 'Signatory' and request is for 'Approve', intiate Signed document generation process
                if(approverRole == 'Signatory' && approveOrReject == 'Approve') {
                    createAuthorisationRecordAndUpdateSignatureURL(communicationPreference, currentCaseId, signatureDraftId);
                }

                // check if approver is 'Intermediate' and request is for 'Reject' , create Amendment with rejection comments.
                if(approverRole == 'Intermediate' && approveOrReject == 'Reject') {
                    
                    AmendmentComments__c amendmentCommentToCreate = new AmendmentComments__c();
                    amendmentCommentToCreate.RelatedCase__c = currentCaseId;
                    amendmentCommentToCreate.Amendment_Comment__c = rejectionComment;

                    UserRecordAccess useraccess = [select HasReadAccess, RecordId, HasEditAccess FROM UserRecordAccess where RecordId =:currentCaseId and 
                                                  UserId =: UserInfo.getUserId()];
                    System.debug('currentCaseId: '+currentCaseId);
                    System.debug('useraccess: '+useraccess);
                    insert amendmentCommentToCreate;
                    System.debug('currentCaseId after insert: '+currentCaseId);
                    
                }
 
                return 'Approved';
            } else
                return '';


        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'submitApprovalRequest';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return '';
        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   set case field values for UI
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @TestVisible
    private static void setCaseParameters(Integer caseIndex, Integer sortColIndex, Integer sortColOrder, String getFilterStr) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        try {

            getCaseList = getCaseInformation(caseIndex, sortColIndex, sortColOrder,filterStr,false,new List<String>{});
            if(getCaseList.size() > 0) {
                if(getCaseList[0].Subject != '' & getCaseList[0].Subject != null)
                    caseSubject = getCaseList[0].Subject;
                else
                    caseSubject = '(No Subject)';
                CaseNumber = getCaseList[0].CaseNumber;
                contactName = getCaseList[0].Contact.Name;
                if(getCaseList[0].Due_date__c != null)
                    dueDate = (getCaseList[0].Due_date__c).format();
                else
                    dueDate = '';

                createdDate = (Date.newInstance((getCaseList[0].CreatedDate).year(), (getCaseList[0].CreatedDate).month(), (getCaseList[0].CreatedDate).day())).format();
            }
        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'setCaseParameters';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get case information when 'Skip to next' is made on UI
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static List <Case> getCaseInformation(Integer caseIndex, Integer sortColIndex, Integer sortColOrder, String getFilterStr,Boolean isMarkedForDesktopEditing,List<String> casesToBeRemovedFromList) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

        try {
            
            caseListForApproval = getCaseListQueue(sortColIndex, sortColOrder, getFilterStr);
            system.debug('CaseIndex :: ' + caseIndex + '::' + caseListForApproval + ' ' + casesToBeRemovedFromList + '::' + isMarkedForDesktopEditing);
            if(caseIndex >= 0){
                if(isMarkedForDesktopEditing == true){
                    for(Integer i = 0 ; i < caseListForApproval.size(); i++){
                        for(String caseToRemove : casesToBeRemovedFromList){
                            system.debug('CaseNumber match :: ' + caseListForApproval[i].CaseNumber + ' ' + caseToRemove);
                            if(caseListForApproval[i].CaseNumber == caseToRemove){
                                caseListForApproval.remove(i);
                            }
                        }
                    }
                    
                }
                system.debug('caseListForApproval :: ' + caseListForApproval);
                currentCaseId = caseListForApproval.get(caseIndex).Id;
            }

            system.debug('Current Case Id :: ' + currentCaseId);
            List<Case> caseList = [Select Id, Subject, Priority, Status, CaseNumber, Contact.Name, Due_date__c, CreatedDate
                                      FROM Case
                                      WHERE Id = : currentCaseId
                                      LIMIT 1 ];
            if(caseList.size() > 0) {
                return caseList;
            }
            return new List <Case> ();
        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getCaseInformation';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            return new List<Case>{};
        }

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get body of unsigned response to render in 'Response' section of MO view UI
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static Map<String,String> getResponseDocumentBody(Integer caseIndex, Integer sortColIndex, Integer sortColOrder, String getFilterStr,Boolean isMarkedForDesktopEditing,List<String> casesToBeRemovedFromList) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        Map<String,String> attachmentDetailMap = new Map<String,String>();
        try {

            system.debug('sortOrder :: orderByColumn ' + sortColIndex + '--' + sortColOrder + ':::' + isMarkedForDesktopEditing + ':::' + caseIndex);
            caseListForApproval = getCaseListQueue(sortColIndex, sortColOrder, getFilterStr);
            system.debug('getResponseDocumentBody :: ' + caseListForApproval);

            if(caseIndex >= 0){
                if(isMarkedForDesktopEditing == true){
                    for(Integer i = 0 ; i < caseListForApproval.size(); i++){
                        for(String caseToRemove : casesToBeRemovedFromList){
                            if(caseListForApproval[i].CaseNumber == caseToRemove){
                                caseListForApproval.remove(i);
                            }
                        }
                    }
                }
                currentCaseId = caseListForApproval.get(caseIndex).Id;
            }

            String paramvalue;
            Blob attachmentBlob;

            List<NoteOrAttachment__c> customAttachment = [Select Id, Case__c, Desktop_Editing__c, ContentType__c, Category__c, Attachment_Id__c
                                                              FROM NoteOrAttachment__c
                                                              WHERE Case__c = : currentCaseId
                                                              AND ContentType__c =: GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF
                                                              AND Category__c = : GlobalConstants.UNSIGNED_RESPONSE
                                                              AND Attachment_Id__c != NULL
                                                              ORDER BY CreatedDate DESC
                                                              LIMIT 1 ];

            if(customAttachment.size() > 0) {
                List<Attachment> responseAttachment = [Select Id, Body from Attachment where Id = : customAttachment[0].Attachment_Id__c];

                //Updated(Start): Aug 15,2017-Pawan Tiwari=> set attachment body data only when attachment has body otherwise do not set the 'data' key
                if(responseAttachment.size() > 0) {
                    attachmentBlob = responseAttachment[0].Body;
                    paramvalue = EncodingUtil.base64Encode(attachmentBlob);
                    paramvalue = 'data:application/pdf;base64,' + paramvalue;
                }
                
                System.debug('Base64 Data: ' + paramvalue);
                if(String.isNotEmpty(paramvalue))
                    attachmentDetailMap.put('data', paramvalue);
                //End
                if(customAttachment[0].Desktop_Editing__c == TRUE)
                    attachmentDetailMap.put('desktopEditing', 'true');
                else
                    attachmentDetailMap.put('desktopEditing', 'false');
            }
            return attachmentDetailMap;

        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getResponseDocumentBody';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new Map<String,String>{};
        }
    }


    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   update case and custom attachment(Unsigned Response category ) with rejection comment
    Inputs:        rejection comment, case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC, if true then create amendment otherwise not 
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static String getUpdateCaseWithRejectionComment(String caseRejectionComment, Boolean createAmendment, String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        String caseUpdateResult = '';
        try {

            currentCaseId = String.escapeSingleQuotes(currentCaseWithNumber);
            currentCaseId = getCurrentCaseId(currentCaseWithNumber);

            List<User> getUser = [Select Id, Name from User Where Id = : UserInfo.getUserId()];

            Integer fieldLength = SObjectType.Case.Fields.Rejection_Comment__c.Length;

            NoteOrAttachment__c updateAttachment = new NoteOrAttachment__c();

            List<NoteOrAttachment__c> customAttachment = [Select Id, Case__c, Case__r.Rejection_Comment__c, ContentType__c, Category__c, Attachment_Id__c, Rejection_Comment__c
                                                              FROM NoteOrAttachment__c
                                                              WHERE Case__c = : currentCaseId
                                                              AND ContentType__c =: GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF
                                                              AND Category__c = : GlobalConstants.UNSIGNED_RESPONSE
                                                              AND Attachment_Id__c != NULL
                                                              ORDER BY CreatedDate DESC
                                                              LIMIT 1 ];
            if(customAttachment.size() > 0) {
                updateAttachment.Id = customAttachment[0].Id;

                Case updateCaseInfo = new Case();
                updateCaseInfo.Id = currentCaseId;
                if(caseRejectionComment == '')
                    return caseUpdateResult;

                String caseRejectionComments = customAttachment[0].Case__r.Rejection_Comment__c;
                String noteOrAttachmentRejectionComment = customAttachment[0].Rejection_Comment__c;
                system.debug('caseRejectionComments :: ' + caseRejectionComments + '--' + noteOrAttachmentRejectionComment);

                if(caseRejectionComments != null && caseRejectionComments.length() > 0) {

                    if(getUser.size() > 0)
                        caseRejectionComments += '\n' + '------------------------' + '\n' + 'Commented By: ' + getUser[0].Name + ' ' + 'on ' + System.today().format() + '\n\n' + caseRejectionComment;

                }else{

                    if(getUser.size() > 0) {
                        caseRejectionComments = 'Commented By: ' + getUser[0].Name + ' ' + 'on ' + System.today().format() + '\n\n' + caseRejectionComment;
                    }

                }

                if(noteOrAttachmentRejectionComment != null && noteOrAttachmentRejectionComment.length() > 0) {

                    if(getUser.size() > 0)
                        noteOrAttachmentRejectionComment += '\n' + '------------------------' + '\n' + 'Commented By: ' + getUser[0].Name + ' ' + 'on ' + System.today().format() + '\n\n' + caseRejectionComment;

                }else{

                    if(getUser.size() > 0) {
                        noteOrAttachmentRejectionComment = 'Commented By: ' + getUser[0].Name + ' ' + 'on ' + System.today().format() + '\n\n' + caseRejectionComment;
                    }

                }

                if(caseRejectionComments.length() >= fieldLength)
                    updateCaseInfo.Rejection_Comment__c = caseRejectionComments.substring(caseRejectionComment.length(), caseRejectionComments.length());
                else
                    updateCaseInfo.Rejection_Comment__c = caseRejectionComments;

                if(noteOrAttachmentRejectionComment.length() >= fieldLength)
                    updateAttachment.Rejection_Comment__c = noteOrAttachmentRejectionComment.substring(caseRejectionComment.length(), noteOrAttachmentRejectionComment.length());
                else
                    updateAttachment.Rejection_Comment__c = noteOrAttachmentRejectionComment;

                update updateCaseInfo;

                if(createAmendment == TRUE)
                    updateAttachment.Category__c = GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT;

                update updateAttachment;

                caseUpdateResult = 'Success';

            }
            return caseUpdateResult;

        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getUpdateCaseWithRejectionComment';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return caseUpdateResult = '';
        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   update case and custom attachment(Unsigned Response category) with 'Desktop Editing = true'
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static String caseUpdateWithDesktopEditing(String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        String caseUpdateResult = '';

        try {
           
            currentCaseId = getCurrentCaseId(currentCaseWithNumber);

            Case updateCase = new Case();
            updateCase.Id = currentCaseId;

            List<NoteOrAttachment__c> getCaseAttachment = [Select Id, Case__c, ContentType__c, Category__c, Attachment_Id__c, Desktop_Editing__c
                                                              FROM NoteOrAttachment__c
                                                              WHERE Case__c = : currentCaseId
                                                              AND ContentType__c =: GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF
                                                              AND Category__c = : GlobalConstants.UNSIGNED_RESPONSE
                                                              AND Response_PDF__c = TRUE
                                                              AND Attachment_Id__c != NULL
                                                              ORDER BY CreatedDate DESC
                                                              LIMIT 1 ];

            if(getCaseAttachment.size() > 0) {
                getCaseAttachment[0].Desktop_Editing__c = true;
                updateCase.Desktop_Editing__c = true;
            }
            update updateCase;
            update getCaseAttachment[0];

            caseUpdateResult = 'Marked for desktop editing successfully';
            return caseUpdateResult;
        }catch(Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'caseUpdateWithDesktopEditing';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return caseUpdateResult = '';
        }

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get user detail for display User Name and Signatory signature on Approve and confirm screen UI.
    Inputs:        NA
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static User getUserDetail() {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

        List<User> userList = [SELECT Id, Name, Signature_Location__c FROM User WHERE Id = : UserInfo.getUserId() limit 1];

            if(userList.size() > 0) {
                return userList[0];
            }
            return new User();
       
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   update case with signature url
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static String updateCaseSingnatureURL(String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        try {
           
            currentCaseId = getCurrentCaseId(currentCaseWithNumber);
                        
            List<User> userList = [SELECT Id, Signature_Location__c FROM User WHERE Id = : UserInfo.getUserId()];
            Database.SaveResult srList;
            if(userList.size() > 0) {
                Case updateCase = new Case();
                updateCase.Id = currentCaseId;
                updateCase.Signature_Image_URL__c = userList[0].Signature_Location__c;

                srList = Database.update(updateCase, true);

            }
            if(srList.isSuccess())
                return 'Updated';
            else
                return '';
        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'updateCaseSingnatureURL';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return '';
        }

    }
    
    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get case with communication preference and contact email address present on case
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static Case getCommunicationPreferences(String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        String communicationPrefernce = '';
        try {
            currentCaseId = String.escapeSingleQuotes(currentCaseWithNumber);
            currentCaseId = getCurrentCaseId(currentCaseWithNumber);

            List<Case> caseList = [SELECT Id, Contact_Email__c, Minister_Communication_Preference__c FROM Case
                                      WHERE Id = : currentCaseId ];

            if(caseList.size() > 0) {
                return caseList[0];
            }
            return new Case();
        }catch(Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getCommunicationPreferences';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new Case();
        }

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   generate signed document , used to see preview with siganture on UI
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static Map <String, String> getDocumentPreviewWithSignature(String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        Map<String,String> responsedataMap = new Map<String,String>();
        try {
            System.debug('currentCaseWithNumber :: ' + currentCaseWithNumber );
            currentCaseId = getCurrentCaseId(currentCaseWithNumber);

            String caseId = currentCaseId;
            String attachmentId = '';
            String sessionId = '';
            String attachmentName = '';
            String pdfAttachmentId = '';
            String getId = '';

            List<NoteOrAttachment__c> customAttachment = [Select Id, Name, Case__c, ContentType__c, Attachment_Id__c
                                                            FROM NoteOrAttachment__c
                                                            WHERE Case__c = : currentCaseId
                                                            AND ContentType__c = 'application/msword'
                                                            AND Attachment_Id__c != NULL
                                                            ORDER BY CreatedDate DESC
                                                            LIMIT 1 ];
            if(customAttachment.size() > 0) {
                attachmentId = customAttachment[0].Attachment_Id__c;
                attachmentName = customAttachment[0].Name;

                sessionId = UserInfo.getSessionId();

                System.debug('Conga Parameters :: ' + caseId + '--' + attachmentId + '--' + attachmentName + '--' + sessionId);
                getId = GeneratePdfPreviewWithSignature.generate(caseId, attachmentId, attachmentName, sessionId, TRUE);

                system.debug('Get Attachment Id ::' + getId);
            }


            if(getId != '') {

                List<NoteOrAttachment__c> customAttachmentAfterConverion = [Select Id, Attachment_Id__c
                                                                                FROM NoteOrAttachment__c
                                                                                WHERE Id = : getId ];

                if(customAttachmentAfterConverion.size() > 0) {
                    pdfAttachmentId = customAttachmentAfterConverion[0].Attachment_Id__c;
                }

                String paramvalue = '';
                Blob attachmentBlob;
                String responseAttachmentName = '';

                List<Attachment> responseAttachment = [Select Id, Name, Body from Attachment where Id = : pdfAttachmentId];

                if(responseAttachment.size() > 0) {

                    attachmentBlob = responseAttachment[0].Body;
                    responseAttachmentName = responseAttachment[0].Name;
                    paramvalue = 'data:application/pdf;base64,' + EncodingUtil.base64Encode(attachmentBlob);
                    responsedataMap.put('Id', getId);
                    responsedataMap.put('data', paramvalue);
                    responsedataMap.put('name', responseAttachmentName);

                    delete responseAttachment;

                    delete customAttachmentAfterConverion;

                    Case caseToBeUpdated = new Case();    
                    caseToBeUpdated.Id = currentCaseId;
                    caseToBeUpdated.Signature_Image_URL__c = '';
                    update caseToBeUpdated;
                }

            }
            return responsedataMap;
        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getDocumentPreviewWithSignature';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return responsedataMap;
        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   create authorisation record , update case with signature url and then call conga to generate signed response
    Inputs:        communication prefrence selected on UI , current case id
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
  /* @RemoteAction
    global static Map<String,String> createAuthorisationRecordAndUpdateSignatureURL(String preference, String getCurrentCaseId) {
        
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        Map<String,String> congaParameterMap = new Map<String,String>();

        try {

            String userId = UserInfo.getUserId();
            String caseId = getCurrentCaseId;
            String documentId = '';
            String documentName = '';
            String sessionId = UserInfo.getSessionId();
            String getId = '';

            List<NoteOrAttachment__c> customAttachment = [Select Id, Name, Case__c, ContentType__c, Attachment_Id__c
                                                            FROM NoteOrAttachment__c
                                                            WHERE Case__c = : caseId
                                                            AND ContentType__c = 'application/msword'
                                                            AND Attachment_Id__c != NULL
                                                            ORDER BY CreatedDate DESC
                                                            LIMIT 1 ];
            if(customAttachment.size() > 0) {
                documentId = customAttachment[0].Attachment_Id__c;
                documentName = customAttachment[0].Name;
            }

            Signature_Authorisation__c signatureData = new Signature_Authorisation__c();
            signatureData.Case_Id__c = caseId;
            signatureData.Document_Id__c = documentId;
            signatureData.User_Id__c = userId;

            insert signatureData;

            Map<String, PublicSiteDomainName__c> publicSiteDomainNameMap = PublicSiteDomainName__c.getAll();
            String getSiteURL;

            if(publicSiteDomainNameMap.containsKey('Site URL'))
                getSiteURL = publicSiteDomainNameMap.get('Site URL').Domain_Name__c;

            Case updateCase = new Case();
            updateCase.Id = caseId;
            updateCase.Signature_Image_URL__c = getSiteURL + GlobalConstants.CASE_SIGNATURE_IMAGE_URI + 'userId=' + userId + '&caseId=' + caseId + '&documentId=' + documentId;
            updateCase.Minister_Communication_Preference__c = preference;

            system.debug('Signature Image getUrl:: ' + updateCase.Signature_Image_URL__c);
            update updateCase;

            congaParameterMap.put('caseId', caseId);
            congaParameterMap.put('documentId', documentId);
            congaParameterMap.put('documentName', documentName);
            congaParameterMap.put('sessionId', sessionId);


            /*List<NoteOrAttachment__c> attachmentsToDelete = [Select Id, Name, Case__c, ContentType__c, Attachment_Id__c
                                                                FROM NoteOrAttachment__c
                                                                WHERE Case__c = : caseId
                                                                AND ContentType__c =: GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF
                                                                AND Category__c = : GlobalConstants.SIGNED_RESPONSE
                                                                AND Attachment_Id__c != NULL ];
            if(attachmentsToDelete.size() > 0) {
                delete attachmentsToDelete;
            }*/
            
     /*       system.debug('getGeneratedSignedPDF parameters :: ' + caseId + '-' + documentId + '-' + documentName + '-' + preference);
            getGeneratedSignedPDF(caseId, documentId, documentName, preference);

            return congaParameterMap;
        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'createAuthorisationRecordAndUpdateSignatureURL';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new Map <String, String> {};
        }
    }*/
    
    @RemoteAction
    global static Map<String,String> createAuthorisationRecordAndUpdateSignatureURL(String preference, String getCurrentCaseId, Id signatureDraftId) {
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

        try {
            Map<String,String> ret = new Map<String,String>();
            List<String> mList = new List<String> {'','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
            Date sigDate = Date.Today();
            String sigDateStr = sigDate.day()+'-'+mList[sigDate.month()]+'-'+sigDate.year();
            String sigExtract = '';

            System.debug('createAuthorisationRecordAndUpdateSignatureURL start');
        
            List<TH1__Draft__c> draftList = [select Id, TH1__Draft_XML_Attachment_Id__c, Related_Lookup_Case__c, Related_Lookup_Case__r.Signatory_Person_OBO__c from TH1__Draft__c
                                             where Related_Lookup_Case__c = :getCurrentCaseId
                                             and Id != :signatureDraftId
                                             ORDER BY CreatedDate DESC
                                             LIMIT 1 ];
        
            //Retrieve the draft containing the Signature for the current Signatory
            TH1__Draft__c signatureDraft = [select Id, TH1__Draft_XML_Attachment_Id__c from TH1__Draft__c where Id = :signatureDraftId LIMIT 1];
                                         
            Attachment sigDraftXML = [select Id, Body from Attachment where Id = :signatureDraft.TH1__Draft_XML_Attachment_Id__c LIMIT 1];

            String sig = sigDraftXML.Body.toString(); 
        
            //Extract the Signature XML to be inserted into the Corro
            Integer start = sig.indexOf('<imagelink');
            Integer endPos = sig.indexOf('/>',start)+2;

            //Add today's date
//            sigExtract = sig.substring(start, endPos)+ '<tab/><tab/>'+ sigDateStr;
            
            DateTime signingDateMo = Datetime.now();
            String dateOutput = signingDateMo.format('dd/MM/yyyy');
            System.debug('Debug: '+dateOutput);            
            
            sigExtract = sig.substring(start, endPos)+ '<tab/><tab/>'+ dateOutput;
        
            System.debug('createAuthorisationRecordAndUpdateSignatureURL sigExtract : '+sigExtract);
            
            String originalSigExtract = sigExtract;
            

            try{
                Integer startAdjustImageWidthHt = sigExtract.indexOf('width="');
                Integer endPosAdjustImageWidthHt = sigExtract.indexOf('"',startAdjustImageWidthHt+7)+1;
                String widthSigExtract = sigExtract.substring(startAdjustImageWidthHt+7, endPosAdjustImageWidthHt);
                System.debug(widthSigExtract);
                
                String replacedWidthFirstExtract = sigExtract.substring(0, startAdjustImageWidthHt+7) + '7.9375cm"' + sigExtract.substring(endPosAdjustImageWidthHt, sigExtract.length());
                System.debug(replacedWidthFirstExtract);
                
                Integer startAdjustImageHeightHt = replacedWidthFirstExtract.indexOf('height="');
                Integer endPosAdjustImageHeightHt = replacedWidthFirstExtract.indexOf('"',startAdjustImageHeightHt+8)+1;
                String HeightSigExtract = replacedWidthFirstExtract.substring(startAdjustImageHeightHt+6, endPosAdjustImageHeightHt);
                System.debug(HeightSigExtract);
                
                String replacedHeightExtract = replacedWidthFirstExtract.substring(0, startAdjustImageHeightHt+7) + '"2.645833333cm"' + replacedWidthFirstExtract.substring(endPosAdjustImageHeightHt, replacedWidthFirstExtract.length());
                System.debug(replacedHeightExtract);            
                sigExtract = replacedHeightExtract;
            }catch(Exception xonvexp){
                System.debug('Some erorr occured while trying to set image height and width');
                sigExtract = originalSigExtract;
            }
            
            
        
            //Signature Draft can be cleaned up
            delete signatureDraft;
        
                                         
            if (draftList!=null && draftList.size()>0){
                Attachment att = [select Id, ContentType, Body from Attachment where Id = :draftList[0].TH1__Draft_XML_Attachment_Id__c limit 1];
                //Backup xml with Signature tag
                Attachment backupXML = new Attachment(ContentType=att.ContentType, Body=att.Body, ParentId = draftList[0].Related_Lookup_Case__c, Name = 'Draft_XML_Backup_@098765ABCDEFGH_DoNotCreateNOA');
                insert backupXML;
                
                String draftXMLAsString =  att.body.toString();      
            
                /********************************************************************************************************************
                 The logic below finds the Signature tag in the XML, it then inserts the Signature XML in the same location that was occupied by the tag.
                 Note that all templates where a Signature needs to be inserted will need to use the same tag but currently all signature tags
                 are in the same Smart Corro shared content called Combined_Signature_Block which is then included in the template
                 ***********************************************************************************************************************/
                String SignatureTag = '{{IMAGE:CASE_SIGNATURE_IMAGE_URL:W=300:H=100}}';
                Integer startPos = draftXMLAsString.indexOf(SignatureTag);
                Integer endingPos = startPos + SignatureTag.length();
                
System.debug('PARSING THE STRING');
System.debug('draftXMLAsString.substring(0,startPos): ' + draftXMLAsString.substring(0,startPos));
System.debug('sigExtract: ' + sigExtract);
System.debug('draftXMLAsString.substring(endingPos+1,draftXMLAsString.length(): ' + draftXMLAsString.substring(endingPos+1,draftXMLAsString.length()));
System.debug('draftXMLAsString.substring(endingPos,draftXMLAsString.length(): ' + draftXMLAsString.substring(endingPos,draftXMLAsString.length()));
              
                /* we do not want to add pp word for now
                try{
                    String relatedSignatoryPP = draftList[0].Related_Lookup_Case__r.Signatory_Person_OBO__c;
                    if(relatedSignatoryPP != null){
                        System.debug('Adding word pp as SignatoryPP is Not null');
                        sigExtract = sigExtract + '<br /><b>pp</b><br />';
                        System.debug('After Adding the word pp as SignatoryPP is Not null: ' + sigExtract);
                    }
                }catch(Exception expp){
                    System.debug('Some error occured while trying to add the word pp as SignatoryPP is Not null: ' + expp.getMessage() + expp.getStackTraceString());
                }
                */
                
                
                String signedDraftXMLAsString = draftXMLAsString.substring(0,startPos) + sigExtract+draftXMLAsString.substring(endingPos,draftXMLAsString.length());
               
                System.debug('createAuthorisationRecordAndUpdateSignatureURL draftXMLAsString**** : '+signedDraftXMLAsString);
                             
                att.body = Blob.valueOf(signedDraftXMLAsString);
                update att;
            
                if(!System.isFuture() && !System.isBatch()){  
                    System.debug('createAuthorisationRecordAndUpdateSignatureURL finaliseDraft');  
                    generateSignedCorroPdf(preference, draftList[0].Id, getCurrentCaseId, backupXML.Id, draftList[0].TH1__Draft_XML_Attachment_Id__c);
                }
            
            }
            return ret;
        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'createAuthorisationRecordAndUpdateSignatureURL';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages, true);
            messages.clear();
            
            if (getCurrentCaseId!=null && getCurrentCaseId.length()>0){
                Case caseToBeUpdated = new Case(Id=getCurrentCaseId, 
                                                SignedPDFGenerationFailed__c = TRUE, 
                                                Status = GlobalConstants.CASE_REVIEW_STATUS);
                update caseToBeUpdated;
            }

            return new Map <String, String> {};
        }    
    }
         
    @future(callout=true)
    private static void generateSignedCorroPdf(String communicationPreference, Id draftId, Id caseId, Id backupXMLId, Id draftXMLId){
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        System.debug('generateSignedCorroPdf draftId : '+draftId);
        try{
            DateTime createdAfter = Datetime.Now();
            TH1.GLOBAL_API_V1.finaliseDraft(draftId);
            
            //finding out auto-generated related custom NoteOrAttachment__c record
            List<NoteOrAttachment__c> relatedNoteOrAttachmentRecord = [SELECT Name, Category__c, Attachment_Id__c, Attachment__c
                                                                       FROM NoteOrAttachment__c
                                                                       WHERE Name like 'Response_%'
                                                                       AND Case__c = :caseId
                                                                       AND CreatedDate > :createdAfter];
              
            //Set the NoteOrAttachment__c record Category__c field value to "Signed Response"   
            if(relatedNoteOrAttachmentRecord!=null && relatedNoteOrAttachmentRecord.size() > 0) {
                relatedNoteOrAttachmentRecord[0].Category__c = GlobalConstants.SIGNED_RESPONSE;
                relatedNoteOrAttachmentRecord[0].Response_PDF__c = TRUE;
                update relatedNoteOrAttachmentRecord[0];
            }   
            
            Attachment backedUpXML = [select Id, Body from Attachment where Id = :backupXMLId limit 1];
            
            Attachment draftXml = new Attachment(Id=draftXMLId, Body = backedUpXML.Body);
            update draftXml;
            
            delete backedUpXML;
            
            List<Digital_Process_Send_Email__c> checkSendEmailProcessList =  [Select Id,Name,On__c FROM Digital_Process_Send_Email__c 
                                                                              WHERE Name =: GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL];
            Boolean digProcessIsOn = checkSendEmailProcessList != NULL && checkSendEmailProcessList.size() > 0 ? checkSendEmailProcessList[0].On__c:FALSE;
            
            Case updateCase = new Case(Id=caseId);
            
            if (digProcessIsOn == FALSE && communicationPreference != GlobalConstants.EZESCAN_CASE_ORIGIN) {                                    
                updateCase.Status = GlobalConstants.CASE_REVIEW_STATUS;
            }
            
            updateCase.Minister_Communication_Preference__c = communicationPreference;
            //updateCase.SignedPDFGenerationFailed__c = FALSE;

            if (communicationPreference == GlobalConstants.EZESCAN_CASE_ORIGIN) {
                List<Group> queueListForCaseOwner = [Select Id, Name from Group where Name = : GlobalConstants.CRGS_PROFILE_NAME];
                if(queueListForCaseOwner.size() > 0) {
                    updateCase.OwnerId = queueListForCaseOwner[0].Id;
                    updateCase.Status = GlobalConstants.CASE_READY_FOR_PRINTING_STATUS_MIN_CORRO;
                    update updateCase;
                }
            }

            updateCase.Signature_Authorisation_Failure__c = false;  
            update updateCase;                                                 
        
        }
        catch(Exception e){
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'generateSignedCorroPdf';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages, true);
            messages.clear();
            
            //Set Signature failed checkbox on Case
            if (caseId!=null){
                Case caseToBeUpdated = new Case(Id=caseId, 
                                                SignedPDFGenerationFailed__c = TRUE, 
                                                Status = GlobalConstants.CASE_REVIEW_STATUS);
                update caseToBeUpdated;
            }
            
            //Make sure XML with Signature tag is back on the Draft
            List<Attachment> backedUpXML = [select Id, Body from Attachment where Id = :backupXMLId];
            if (backedUpXML!=null && backedUpXML.size()>0)
            {
                Attachment draftXml = new Attachment(Id=draftXMLId, Body = backedUpXML[0].Body);
                update draftXml;
                delete backedUpXML;
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   Generate signed response using conga
    Inputs:        current case Id, document Id , document name , communication preference
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static void getGeneratedSignedPDF(String caseId, String documentId, String documentName, String communicationPrefernce) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

        try {

            String sessionId = UserInfo.getSessionId();
            GeneratePdfPreviewWithSignature.generateSignedPDF(caseId, documentId, documentName, sessionId, FALSE, communicationPrefernce,UserInfo.getUserId());

        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getGeneratedSignedPDF';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

        }

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get all enclosures for UI, Enclosures would be in Chronological (Ascending) order
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static List<Attachment> getEnclosuresList(String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage> ();
        List<Attachment> attachmentDetailList = new List<Attachment> ();

        try {
            
            currentCaseId = String.escapeSingleQuotes(currentCaseWithNumber);
            currentCaseId = getCurrentCaseId(currentCaseWithNumber);
            System.debug('** Current Case Id ** ' + currentCaseId + '--' + currentCaseWithNumber);

            Set<String> attchmentId = new Set<String> ();

            for(NoteOrAttachment__c customAttachment: [Select Id, Name, Case__c, ContentType__c, Category__c, Attachment_Id__c
                                                        FROM NoteOrAttachment__c
                                                        WHERE Case__c = : currentCaseId
                                                        AND Category__c = : GlobalConstants.ENCLOUSER
                                                        AND Attachment_Id__c != NULL ]) {

                attchmentId.add(customAttachment.Attachment_Id__c);
            }

            for(Attachment getAttachments: [Select Id, ContentType, Name, BodyLength, CreatedBy.Name 
                                              FROM Attachment 
                                              WHERE Id IN: attchmentId 
                                              ORDER BY CreatedDate ASC ]) {
                attachmentDetailList.add(getAttachments);
            }
            return attachmentDetailList;
        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getEnclosuresList';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new List <Attachment> {};
        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get all precedents signed response for UI, Enclosures would be in Chronological (Ascending) order
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static Map<Id,AttachmentInfo> getPrecedentsDetail(String currentCaseWithNumber) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        Map<Id,AttachmentInfo> attachmentInformationMap = new Map<Id,AttachmentInfo>();

        try {
            Set<String> precedentCaseIdSet = new Set<String>();
            Set<String> attachmentIdSet = new Set<String>();
            String caseId;
            caseId = String.escapeSingleQuotes(currentCaseWithNumber);
            
            caseId = getCurrentCaseId(currentCaseWithNumber);
            attachmentInformationMap = AttachmentInformation.getPrecedentAttachment(caseId);
            return attachmentInformationMap;
        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getPrecedentsDetail';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new Map<Id,AttachmentInfo>{};
        }
    }


    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get all custom attachments having Category as 'Incoming', Incoming would be in Chronological (Ascending) order
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static Map<Id,AttachmentInfo> getIncomingAttachments(String currentCaseWithNumber){
        
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        
        Map<Id,AttachmentInfo> attachmentInformationMap = new Map<Id,AttachmentInfo>();

        try {

            currentCaseWithNumber = String.escapeSingleQuotes(currentCaseWithNumber);
            String caseId = getCurrentCaseId(currentCaseWithNumber);
            attachmentInformationMap = AttachmentInformation.getIncomingAttachment(caseId,GlobalConstants.INCOMING);
            return attachmentInformationMap;

        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getIncomingAttachments';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new Map<Id,AttachmentInfo>{};
        }
    
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   Get all signed response where contact is OBO or case Contact,Preference would be given to OBO ,Order to show would be reverse chronological(descending) order
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    public static Map<Id,AttachmentInfo> getPreviousCorroRelatedToContact(String currentCaseWithNumber) {

        Map<Id,AttachmentInfo> attachmentInformationMap = new Map<Id,AttachmentInfo>();
        List <ApplicationLogMessage> messages = new List <ApplicationLogMessage> ();
        try {

            String caseId ;
            caseId = String.escapeSingleQuotes(currentCaseWithNumber);

            caseId = getCurrentCaseId(currentCaseWithNumber);
            attachmentInformationMap = AttachmentInformation.getPreviousCorroAttachment(caseId);
            return attachmentInformationMap;

        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getPreviousCorroRelatedToContact';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new Map<Id,AttachmentInfo>{};
        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   Get all signed response where contact is OBO or case Contact,Preference would be given to OBO ,Order to show would be reverse chronological(descending) order
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    public static Map <Id, AttachmentInfo> getConsolidatedAdviceList(String currentCaseWithNumber) {
        
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        try {
            String caseId;
            caseId = String.escapeSingleQuotes(currentCaseWithNumber);
            Map<Id,AttachmentInfo> attachmentInformationMap = new Map<Id,AttachmentInfo>();
            caseId = getCurrentCaseId(currentCaseWithNumber);
            attachmentInformationMap = AttachmentInformation.getAdviceAttachment(caseId);
            return attachmentInformationMap;

        } catch (Exception e) {
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getConsolidatedAdviceList';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new Map<Id,AttachmentInfo>{};

        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get thunderhead draft url
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    public static String getThunderHeadDraftURL(String currentCaseWithNumber) {
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        try {
            String caseId;
            caseId = String.escapeSingleQuotes(currentCaseWithNumber);
            caseId = getCurrentCaseId(currentCaseWithNumber);
            String draftURL = '';
            List<TH1__Draft__c> getDraftId = [Select Id, CreatedDate FROM TH1__Draft__c
                                                WHERE Related_Lookup_Case__c = : caseId
                                                AND Status__c = : GlobalConstants.MAGS_APPROVED_MIN_CORRO
                                                ORDER BY CreatedDate DESC
                                                LIMIT 1 ];


            String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
            Map<String,PublicSiteDomainName__c> publicSiteDomainNameMap = PublicSiteDomainName__c.getAll();
            String getSiteURL;

            if(publicSiteDomainNameMap.containsKey('Draft Base Domain'))
                getSiteURL = publicSiteDomainNameMap.get('Draft Base Domain').Domain_Name__c;
                
            system.debug('BaseUrl :: ' + baseUrl);
            if(getDraftId.size() > 0) {
                draftURL = getSiteURL + 'id=' + getDraftId[0].Id + '&retURL=' + caseId + GlobalConstants.DRAFT_THUNDERHEAD_URL_END_STRING + '#dr' + getDraftId[0].Id;
            }
            system.debug('draftURL :: ' + draftURL);
            return draftURL;
        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getThunderHeadDraftURL';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return NULL;
        }
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get recent amendment i.e custom attachment with category as 'Amendment'
    Inputs:        case index in approval queue, sort by column index, sorting order i.e ASC or DESC => 0 means ASC and 1 means DESC
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    public static AttachmentInfo getAmendmentsList(String currentCaseWithNumber) {
        List <ApplicationLogMessage> messages = new List <ApplicationLogMessage> ();

        try{
            String caseId;
            caseId = String.escapeSingleQuotes(currentCaseWithNumber);
            Map<Id,String> sfAttachmentMap = new Map<Id,String>();
            Map<Id,NoteOrAttachment__c> getNotesAndAttachmentWithRejectionComment = new Map<Id,NoteOrAttachment__c>();
            
            caseId = getCurrentCaseId(currentCaseWithNumber);
            system.debug('Get current case Id :: ' + caseId);

            for(NoteOrAttachment__c getNotesAndAttachment: [Select Id, Case__c, Case__r.CaseNumber, Category__c, ContentType__c, Attachment_Id__c, Rejection_Comment__c, CreatedDate, LastModifiedDate, LastModifiedBy.Name
                                                            FROM NoteOrAttachment__c
                                                            Where Case__c = : caseId
                                                            AND(ContentType__c =: GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF
                                                                OR ContentType__c = 'binary/octet-stream')
                                                            AND Attachment_Id__c != NULL
                                                            AND Category__c = : GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT
                                                            ORDER BY CreatedDate DESC
                                                            LIMIT 1 ]) {
                getNotesAndAttachmentWithRejectionComment.put(getNotesAndAttachment.Attachment_Id__c, getNotesAndAttachment);
            }

            system.debug('Get amendment map :: ' + getNotesAndAttachmentWithRejectionComment);

            List<Attachment> attachmentList = [Select Id, Name, Body, CreatedDate, CreatedBy.Name
                                                FROM Attachment
                                                WHERE Id IN: getNotesAndAttachmentWithRejectionComment.keySet()
                                                ORDER BY CreatedDate DESC
                                                LIMIT 1 ];

            if(attachmentList.size() > 0) {
                AttachmentInfo newAttachmentInfo = new AttachmentInfo();
                newAttachmentInfo.body = 'data:application/pdf;base64,' + EncodingUtil.base64Encode(attachmentList[0].Body);
                if(getNotesAndAttachmentWithRejectionComment.containsKey(attachmentList[0].Id)) {
                
                    newAttachmentInfo.currentCaseNumber = getNotesAndAttachmentWithRejectionComment.get(attachmentList[0].Id).Case__r.CaseNumber;

                    newAttachmentInfo.rejectionComment = getNotesAndAttachmentWithRejectionComment.get(attachmentList[0].Id).Rejection_Comment__c;

                    newAttachmentInfo.createdBy = getNotesAndAttachmentWithRejectionComment.get(attachmentList[0].Id).LastModifiedBy.Name;

                    newAttachmentInfo.createdDate = Date.newInstance(
                        (getNotesAndAttachmentWithRejectionComment.get(attachmentList[0].Id).LastModifiedDate).year(),
                        (getNotesAndAttachmentWithRejectionComment.get(attachmentList[0].Id).LastModifiedDate).month(),
                        (getNotesAndAttachmentWithRejectionComment.get(attachmentList[0].Id).LastModifiedDate.day()));
                }
                system.debug('Get newAttachment :: ' + newAttachmentInfo);
                return newAttachmentInfo;
            }

            return new AttachmentInfo();


        }catch(Exception e){
            exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'MinisterApprovalViewController';
            message.sourceFunction = 'getAmendmentsList';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return new AttachmentInfo();
        }

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   return back to MinisterApprovalViewQueue page
    Inputs:        NA
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    public PageReference approvalQueueHome() {

        System.debug('Redirecting to home');
        PageReference approvalQueueViewReference;
        approvalQueueViewReference = new Pagereference(Page.MinisterApprovalViewQueue.getUrl());
        approvalQueueViewReference.getParameters().put('sortColIndex', Apexpages.currentPage().getParameters().get('sortColIndex'));
        approvalQueueViewReference.getParameters().put('sortColOrder', Apexpages.currentPage().getParameters().get('sortColOrder'));
        approvalQueueViewReference = approvalQueueViewReference.setRedirect(true);

        return approvalQueueViewReference;
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   return back to MinisterApprovalViewQueue page, this is called when there are no any case in approval queue
    Inputs:        NA
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    07-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global static PageReference approvalQueueHomePage() {
        PageReference approvalQueueViewReference;
        approvalQueueViewReference = new Pagereference(Page.MinisterApprovalViewQueue.getUrl());
        approvalQueueViewReference.getParameters().put('showErrorPage', 'true');
        approvalQueueViewReference = approvalQueueViewReference.setRedirect(true);
        system.debug('approvalQueueViewReference :: ' + approvalQueueViewReference);
        system.debug('Get PageReference :: ' + approvalQueueViewReference );
        return approvalQueueViewReference;
    }

}