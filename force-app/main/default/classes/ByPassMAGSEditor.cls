/*------------------------------------------------------------
Author:        Arxxus
Description:   class for ByPass MAGSEditor for draft approval
Test Class:     ByPassMAGSEditor_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
12-DEC-2016   Arxxus          Comments and cleanup
------------------------------------------------------------*/
global with sharing class ByPassMAGSEditor{ 

  webService static String makeApproval(Id currentCaseId) {
    
      String caseStatus = '';     
      List<TH1__Draft__c> draftList = [Select Id, Status__c, Override_MAGS_Editor__c 
                                         FROM TH1__Draft__c 
                                         WHERE Related_Lookup_Case__c = :currentCaseId
                                         ORDER BY CreatedDate DESC LIMIT 1];
        if(draftList.size() > 0) {
            
            draftList[0].Override_MAGS_Editor__c = TRUE;
                 
            update draftList[0];
                 
            List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId ,ActorId 
                                                       FROM ProcessInstanceWorkitem 
                                                       WHERE ProcessInstance.TargetObjectId =: draftList[0].Id
                                                       AND ProcessInstance.Status = 'Pending'
                                                       Limit 1];
                                                       
             if(workItems.size() > 0 ) {   
                                                     
                 List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

                 for(ProcessInstanceWorkitem workItem : workItems) {

                     Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                     req.setWorkitemId(workItem.Id);
                     //Valid values are: Approve, Reject, or Removed. 
                     //Only system administrators can specify Removed.
    
                     req.setAction('Approve');
                     req.setComments('Approved');
                     requests.add(req);  
                 }                
           
                 Approval.ProcessResult[] processResults = Approval.process(requests);
                 system.debug('Approval ProcessResult :: ' + processResults);
    
                 if(processResults[0].isSuccess()) {
                    caseStatus = GlobalConstants.MAGS_APPROVED_MIN_CORRO; 
                 }

              }
              
          }

          return caseStatus;
          
    }
    
}