public class RecallPendingApprovalsProcess implements BatchExecutor.CustomBatchable {
 
 private String loggedInUserEmail;
 
 private Integer totalCaseCount;
 private Integer successCount;
 private Integer errorCount;
 
 private List<ApplicationLogMessage> messages;
 
 public RecallPendingApprovalsProcess(String userEmail) {
  
  loggedInUserEmail = userEmail;
  successCount = 0;
  errorCount = 0;
  totalCaseCount = 0;
  messages = new List<ApplicationLogMessage>();
 }
 
 public void execute(List<Case> targetRecords) {
  
  Set<Id> targetCaseIds = new Set<Id>();
  
  List<Approval.ProcessWorkitemRequest> approvalWorkItemRequests = new List<Approval.ProcessWorkitemRequest>();
  
  for(Case tempCase : targetRecords)
    targetCaseIds.add(tempCase.Id);
  
  for(ProcessInstanceWorkItem workItem : [Select ProcessInstance.Status, ProcessInstance.TargetObjectId, ProcessInstanceId, OriginalActorId,
                                               Id, ActorId
                                               From ProcessInstanceWorkitem 
                                               WHERE ProcessInstance.TargetObjectId IN :targetCaseIds
                                               AND ProcessInstance.Status = 'Pending']) {
    
     totalCaseCount++;
     
     //recall pending approval requests
     Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
     pwr.SetComments('Recalled by '+UserInfo.getName()+ ' as part of change of government process');
     pwr.setWorkItemId(workItem.id);
     pwr.setAction('Removed'); 
     approvalWorkItemRequests.add(pwr);                                           
  }
  
  if(approvalWorkItemRequests.size() > 0) {
   
   List<Approval.ProcessResult> prList = Approval.process(approvalWorkItemRequests, FALSE);
   
   for(Approval.ProcessResult tempPR : prList) {
     
     if(!tempPR.isSuccess()) {
       
      ApplicationLogMessage message = new ApplicationLogMessage();
      message.source = 'RecallPendingApprovalsProcess';
      message.sourceFunction = 'execute';
      message.logMessage = 'Recall Failed for '+tempPR.getEntityId()+': '+tempPR.getErrors()[0];
      message.debugLevel = GlobalConstants.ERROR;
      messages.add(message);
      
      errorCount++;
     }
     else
      successCount++;  
   }
         
  }
  
 }
 
 public void finish() {
  
   if(messages.size() > 0) {
   
    ApplicationLogUtility.logMessage(messages);
    messages.clear(); 
   }
   
   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
   
   mail.setToAddresses(new String[] {loggedInUserEmail});
   //mail.setBCCAddresses(new String[] {'mincorro2@arxxus.com'});
   mail.setSenderDisplayName('Ministerial Correspondence Admin User');
   mail.setSubject('Change of Government: Recall Penging Approvals');
   
   String messageBody = '<html><body>Recalling pending approvals for case records has been completed successfully'+
                            '<br/><br/><b>No. of Case records found:</b> '+totalCaseCount+
                            '<br/><br/><b>No. of Case records recalled successfully:</b> '+successCount+
                            '<br/><br/><b>No. of Case records failed to recall:</b> '+errorCount+
                            '<br/><br/>Check Application Logs in Salesforce for more details related to errors if any.</body></html>';
                            
   mail.setHtmlBody(messageBody);
   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   
 }
}