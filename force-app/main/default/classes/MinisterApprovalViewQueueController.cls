/*------------------------------------------------------------
Author:        Arxxus
Description:   class used to get all cases in approval queue for intermediate or final approval.
               and navigate to case mo view after click on review now link. 
Test Class:     MinisterApprovalViewQueueController_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
12-DEC-2016   Arxxus          Comments and cleanup
------------------------------------------------------------*/

global with sharing class MinisterApprovalViewQueueController {

    public MinisterApprovalViewQueueController() {

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   get case list present in approval queue
    Inputs:        string to filter the results i.e case number or case subject
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    12-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    @RemoteAction
    global Static List<Case> getCaseQueue(String filterStr,String isErrorPage) {

        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        List<Case> caseQueue = new List<Case>();
     
        Set<Id> targetCaseRecordIds = new Set<Id>();

        for(ProcessInstanceWorkItem workItem: [SELECT ProcessInstance.TargetObjectId
                                                FROM ProcessInstanceWorkItem
                                                WHERE ProcessInstance.Status = 'Pending'
                                                AND ActorId = : UserInfo.getUserId() ]) {

            targetCaseRecordIds.add(workItem.ProcessInstance.TargetObjectId);
        }

        if(filterStr != NULL && filterStr != '') {

            filterStr = '%' + filterStr + '%';

            caseQueue = [SELECT Id, CaseNumber, Subject, Due_date__c, Contact.Name, Signatory_Person__r.Name, Desktop_Editing__c, Status
                          FROM Case
                          WHERE Id IN: targetCaseRecordIds
                          AND(Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                              OR Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX
                              OR Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                              OR Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS 
                              OR Record_Type_Dev_Name__c = : GlobalConstants.MIN_CORRO_RECTYPE_API_NAME)
                          AND(Subject LIKE: filterStr OR CaseNumber Like: filterStr)
                          ORDER BY Due_date__c ASC, CaseNumber ASC ];

            return caseQueue;
        }else if(isErrorPage == 'true'){
          return caseQueue;
        }else {

            caseQueue = [SELECT Id, CaseNumber, Subject, Due_date__c, ContactId, Contact.Name, Signatory_Person__c, Signatory_Person__r.Name, Desktop_Editing__c, Status
                          FROM Case
                          WHERE Id IN: targetCaseRecordIds
                          AND(Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD 
                              OR Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT 
                              OR Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_OOS 
                              OR Record_Type_Dev_Name__c = : GlobalConstants.MIN_CORRO_RECTYPE_API_NAME
                              OR Record_Type_Dev_Name__c = : GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX)
                          ORDER BY Due_date__c ASC, CaseNumber ASC ];

            return caseQueue;
        }
        return caseQueue;
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   navigate to case (MO View UI) where review now is clicked, 
    Inputs:        NA
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    12-DEC-2016   Arxxus          Comments and cleanup
    ------------------------------------------------------------*/
    public PageReference reviewNow() {

        String caseId = ApexPages.currentPage().getParameters().get('queueCaseId');
        String caseIndex = ApexPages.currentPage().getParameters().get('queueCaseIndex');
        String sortColIndex = ApexPages.currentPage().getParameters().get('queueSortColIndex');
        String sortColOrder = ApexPages.currentPage().getParameters().get('queueSortColOrder');
        String searchName = ApexPages.currentPage().getParameters().get('searchBy');

        System.debug('Got Case Id: ' + caseId);
        System.debug('Got Case Index: ' + caseIndex);
        System.debug('Got Col Index: ' + sortColIndex);
        System.debug('Got Sort Col Order: ' + sortColOrder);

        PageReference approvalViewReference;

        if (caseId != NULL && caseId != '') {

            approvalViewReference = new Pagereference(Page.MinisterApprovalView.getUrl());
            approvalViewReference.getParameters().put('caseId', caseId);
            approvalViewReference.getParameters().put('caseIndex', caseIndex);
            approvalViewReference.getParameters().put('sortColIndex', sortColIndex);
            approvalViewReference.getParameters().put('sortColOrder', sortColOrder);
            approvalViewReference.getParameters().put('searchBy', searchName);
            approvalViewReference = approvalViewReference.setRedirect(true);

            return approvalViewReference;
        }

        return NULL;
    }
}