public class GovernmentChangeTransferOwnershipProcess implements BatchExecutor.CustomBatchable {
 
 private String loggedInUserEmail;
 
 private Integer totalCaseCount;
 private Integer successCount;
 private Integer errorCount;
 
 @TestVisible
 private List<ApplicationLogMessage> messages;
 
 public GovernmentChangeTransferOwnershipProcess(String userEmail) {
  
  loggedInUserEmail = userEmail;
  successCount = 0;
  errorCount = 0;
  totalCaseCount = 0;
  messages = new List<ApplicationLogMessage>();
 }
 
 public void execute(List<sObject> targetRecords) {
  
  List<Group> roadsManagerQueue = [Select Id From Group Where DeveloperName = 'Roads_Manager_Queue' and Type = 'Queue' Limit 1];
  List<Group> transportManagerQueue = [Select Id From Group Where DeveloperName = 'Transport_Manager_Queue' and Type = 'Queue' Limit 1];
  
  List<Case> casesToUpdate = new List<Case>();
  List<Case> casesToUnflag = new List<Case>();
  
  for(Case tempCase : (List<Case>) targetRecords) {
   
   //Transport and office of the secretary portfolio  cases routed to Transport Manager Queue
   if((tempCase.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT || tempCase.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_OOS) 
      && transportManagerQueue.size() > 0) {
   
    tempCase.OwnerID = transportManagerQueue[0].Id;
    tempCase.ChangeOfGovernmentBypass__c = TRUE;
    casesToUpdate.add(tempCase);
    totalCaseCount++;
   }
   
   //Roads portfolio cases routed to Roads Manager Queue
   if(tempCase.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_ROADS && roadsManagerQueue.size() > 0) {
   
    tempCase.OwnerID = roadsManagerQueue[0].Id;
    tempCase.ChangeOfGovernmentBypass__c = TRUE;
    casesToUpdate.add(tempCase);
    totalCaseCount++;
   }
  }
  
  if(casesToUpdate.size() > 0) {
   
   List<Database.SaveResult> strList = Database.update(casesToUpdate, false);
   
   for(Integer i=0;i<strList.size();i++) {
    
    if(strList.get(i).isSuccess()) {
    
      successCount++;
      
      //cases owner updated successfully, let now unflag the bypass flag from case
      Case caseToUnflag = new Case();
      caseToUnflag.Id = strList.get(i).getId();
      caseToUnflag.ChangeOfGovernmentBypass__c = FALSE;
      casesToUnflag.add(caseToUnflag);
    }
    else {
      
      ApplicationLogMessage message = new ApplicationLogMessage();
      message.source = 'GovernmentChangeTransferOwnershipProcess';
      message.sourceFunction = 'exceute';
      message.logMessage = 'Ownership transfer failed: ';
      message.ex = NULL;
      message.debugLevel = 'Error';
       
      for(Database.Error err : strList.get(i).getErrors()) {
         
         message.logMessage += casesToUpdate.get(i).Id+'-'+casesToUpdate.get(i).CaseNumber+'::'+err.getMessage()+',';
      }
       
      messages.add(message);
      errorCount++;
    }
   }
   
   if(casesToUnflag.size() > 0) {
    
    strList = Database.update(casesToUnflag, false);
    for(Integer i=0;i<strList.size();i++) {
    
     if(!strList.get(i).isSuccess()) {
      
      ApplicationLogMessage message = new ApplicationLogMessage();
      message.source = 'GovernmentChangeTransferOwnershipProcess';
      message.sourceFunction = 'exceute';
      message.logMessage = 'Unflagging failed: ';
      message.ex = NULL;
      message.debugLevel = 'Error';
       
      for(Database.Error err : strList.get(i).getErrors()) {
         
         message.logMessage += casesToUpdate.get(i).Id+'-'+casesToUpdate.get(i).CaseNumber+'::'+err.getMessage()+',';
      }
       
      messages.add(message);
     }
    }
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
   mail.setSubject('Change of Government: Case Ownership Transfer');
   
   String messageBody = '<html><body>Transfer of ownership to either Roads Manager Queue or Transport Manager Queue for case records has been completed successfully'+
                            ' based on the Portfolio specified on the individual Case record.'+
                            '<br/><br/><b>No. of Case records found:</b> '+totalCaseCount+
                            '<br/><br/><b>No. of Case records transferred successfully:</b> '+successCount+
                            '<br/><br/><b>No. of Case records failed to transfer:</b> '+errorCount+
                            '<br/><br/>Check Application Logs in Salesforce for more details related to errors if any.</body></html>';
                            
   mail.setHtmlBody(messageBody);
   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   
 }
 
}