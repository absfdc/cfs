/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Controller extension for Draft Approval Request Page.
               This class handles approve/reject/cancel actions.
Test Class:    DraftApprovalProcess_CX_Test
History
<Date>      <Authors Name>     <Brief Description of Change>
05/06/2015   Manish Damle        Created 
-----------------------------------------------------------------------------------------*/
public with sharing class DraftApprovalProcess_CX {
	private String processInstanceId = null;
    private String draftId = null; //TH1__Draft__c
    private Case parentCase;
    public boolean errorOnPage {get;set;} //if true do not render other stuff on the page
    public String  rejectionReason {get;set;}
    public String comments {get;set;}
    public String draftURL {get;set;}
    public TH1__Draft__c draft {get;set;}
    public boolean invokedFromPublisherAction {get;set;} //page invoked from Publisher action or not.
    
    //Default Constructor
    public DraftApprovalProcess_CX(ApexPages.StandardController controller) {
       errorOnPage  = false;
       rejectionReason = null;
       comments = '';
       invokedFromPublisherAction = false;
       TH1__Draft__c d = (TH1__Draft__c) controller.getRecord();
       draftId = d == null ? null : d.Id;
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will initialise the parameters and draft record object.
    Inputs:        
    History
    <Date>       <Authors Name>      <Brief Description of Change>
    05/06/2015   Manish Damle        Created 
    -----------------------------------------------------------------------------------------*/
    public PageReference init() {
        try {
            processInstanceId  = Apexpages.currentpage().getparameters().get('pid'); //URL param
            
            if(draftId == '' || draftId == null) {
                errorOnPage = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid url parameters.'));
                return null;
            }
            
            draftURL = 'https://' + System.URL.getSalesforceBaseUrl().getHost().remove('-api' ) + '/ui/support/servicedesk/ServiceDeskPage#/' + draftId;
            //Fetch The Case Record
            list <TH1__Draft__c> drafts = [Select Id, Name, Status__c, Related_Lookup_Case__c, OwnerId,
                                                  Related_Lookup_Case__r.CaseNumber, Related_Lookup_Case__r.status, 
                                                  Related_Lookup_Case__r.Priority, Related_Lookup_Case__r.OwnerId 
                                           From TH1__Draft__c 
                                           Where Id =: draftId limit 1]; 
            
            if(drafts.size() != 1) {
                errorOnPage = true;
                draft = new TH1__Draft__c();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Draft record not found.'));
                return null;
            } else {
                draft = drafts[0];
                parentCase = [Select Id, Reject_Reason__c, Dot_Points__c, Draft_Rejection_Count__c 
                              From Case 
                              Where Id =: draft.Related_Lookup_Case__c];
            }
            
            //if process Instance Id not available in the URL parameters then try to fetch the pending work items
            //If not found then processInstanceId will be set to null.
            if(processInstanceId == null || processInstanceId == '') {
                processInstanceId = fetchPendingApprovalRequest();
                if(processInstanceId == null) {
                    errorOnPage = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'This draft record does not have any pending approvals&nbsp;<a href=\"#\" onClick=\"closeSubTab();\">Close</a>'));
                    return null;
                } else {
                    invokedFromPublisherAction = true;    
                }
            } else {
                list <ProcessInstanceWorkitem> existingWorkItems = [Select Id From ProcessInstanceWorkitem Where Id =: processInstanceId];
                if(existingWorkItems.size() == 0) {
                    errorOnPage = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'This request is already processed.'));
                    return null;
                }
            }
            
            ProcessInstanceWorkitem workItem = [Select ActorId, OriginalActorId From ProcessInstanceWorkitem Where Id =: processInstanceId];
            User userRecord = [Select Id, Name, UserRoleId From User Where Id =: UserInfo.getUserId() limit 1];
            system.debug('----------Work Item-----' + workItem);
            set <Id> magsQueues = RetrieveNextUtils_WS.getGroupsForUser(new set <Id> { workItem.ActorId }, userRecord, null);
            system.debug('----------Mags Queues----' + magsQueues);
            
            if(magsQueues != null && magsQueues.size() ==0 ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You do not have level of access to perform this operation.'));
                errorOnPage = true;
                return null;
            }
            
        }catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured while processing the request.'));
            
        }
        return null;
    }    
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method is  getter method for Rejection Reason picklist on the VF page
    Inputs:        
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/06/2015   Manish Damle        Created 
    -----------------------------------------------------------------------------------------*/
    public list <SelectOption> getRejectionReasons() {
        list<SelectOption> options = new list<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Case.Reject_Reason__c.getDescribe();
        list<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new SelectOption('','--None--')); //Default picklist value
        for(Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;        
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will handle the approval of the draft record.
    Inputs:        
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/06/2015   Manish Damle        Created 
    -----------------------------------------------------------------------------------------*/    
    public PageReference approve() {
        
        //If rejection reason is selected then show error message
        if(rejectionReason != null && rejectionReason != '') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Rejection reason is only required when you reject the record.'));
            return null;
        }
        comments += '\nApproved by ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        Approval.ProcessWorkitemRequest approveRequest = new Approval.ProcessWorkitemRequest();
        approveRequest.setComments(comments);
        approveRequest.setAction('Approve');        
        approveRequest.setWorkitemId(processInstanceId);
        Approval.ProcessResult result =  Approval.process(approveRequest);
        
        if(!result.isSuccess()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured while processing'));
            return null;
        }
        
        /*if(!invokedFromPublisherAction) {
            return new PageReference('/' + draftId);
        }*/
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Draft record approved successfully&nbsp;<a href=\"#\" onClick=\"closeSubTab();\">Close</a>'));
        errorOnPage = true;
        return null;
    }
    
     /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will handle the rejection of the draft record. This will store the rejection count and rejection reason.
    Inputs:        
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/06/2015   Manish Damle        Created 
    -----------------------------------------------------------------------------------------*/    
    public PageReference reject() {
        Savepoint sp = Database.setSavepoint();
        try {
            
            //if rejection reason is not provided then show error
            if(rejectionReason == null || rejectionReason == '') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select rejection reason.'));
                return null;
            }
    
            comments += '\nRejected by ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '.\nReason: ' + rejectionReason;
            Approval.ProcessWorkitemRequest rejectRequest = new Approval.ProcessWorkitemRequest();
            rejectRequest.setComments(comments);
            rejectRequest.setAction('Reject');
            rejectRequest.setWorkitemId(processInstanceId);
            Approval.ProcessResult result =  Approval.process(rejectRequest);
            
            if(result.isSuccess()) {
                //Insert
                parentCase.Reject_Reason__c = rejectionReason;
                parentCase.Draft_Rejection_Count__c = parentCase.Draft_Rejection_Count__c == null ? 1 : parentCase.Draft_Rejection_Count__c + 1;
                update parentCase;                
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured while processing. Rejection reason not captured on case'));
                return null;
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured while processing'));
            Database.rollback(sp); //rollback the rejection or record creation if error occurs
            return null;
        }
        
        /*if(!invokedFromPublisherAction) {
            return new PageReference('/' + draftId);
        }*/
      
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Draft record rejected successfully&nbsp;<a href=\"#\" onClick=\"closeSubTab();\">Close</a>'));
        errorOnPage = true;
        return null;
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will redirect user to case details page.
    Inputs:        
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/06/2015   Manish Damle        Created 
    -----------------------------------------------------------------------------------------*/  
    public PageReference cancel() {
        return new PageReference('/' + draftId);
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will fetch the Pending approval request for the draft if any.
    Inputs:        
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/06/2015   Manish Damle        Created 
    -----------------------------------------------------------------------------------------*/  
    public Id fetchPendingApprovalRequest() {
      //Fetch the pending work items from the Approval History
        list <Id> newWorkItemIds = new list <Id>();
        for (list <ProcessInstance> pis : [Select (Select Id From Workitems) 
                                           From ProcessInstance p 
                                           Where p.TargetObjectId =: draft.Id 
                                              And p.Status = 'Pending']) {
            for (ProcessInstance pi : pis) {
                for (List<ProcessInstanceWorkitem> wis : pi.Workitems) {
                    for (ProcessInstanceWorkitem wi : wis ) {
                        newWorkItemIds.add(wi.Id);
                    }
                }           
            }
        }
        
        if(newWorkItemIds.size() > 0)
          return newWorkItemIds[0];
          
        return null;
    }
}