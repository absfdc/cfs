public class InflightMOCasesBatchProcessor implements BatchExecutor.CustomBatchable {
 
 private String loggedInUserEmail;
 
 @TestVisible
 private Integer totalMinisterCaseCount;
 private Integer totalMOCaseCount;
 private Integer obsoleteSignatoryCaseCount;
 
 private Integer successMinisterCount;
 private Integer successMOCount;
 private Integer successSignatoryCount;
 
 private Integer errorMinisterCount;
 private Integer errorMOCount;
 private Integer errorCount;
 
 private Map<String, String> roadSignatoryRoles;
 private Map<String, String> transportSignatoryRoles;
 private Map<String, String> oosSignatoryRoles;
 
 @TestVisible
 private List<ApplicationLogMessage> messages; 
 
 public InflightMOCasesBatchProcessor(String userEmail) {
  
  loggedInUserEmail = userEmail;
  successMinisterCount = 0;
  successMOCount = 0;
  successSignatoryCount = 0;
  errorMinisterCount = 0;
  errorMOCount = 0;
  errorCount = 0;
  totalMinisterCaseCount = 0;
  totalMOCaseCount = 0;
  obsoleteSignatoryCaseCount = 0;
  messages = new List<ApplicationLogMessage>();
  
  roadSignatoryRoles = new Map<String, String>();
  roadSignatoryRoles.put('Minister','Minister for Roads, Maritime and Freight');
  roadSignatoryRoles.put('Parliamentary Secretary','Parliamentary Secretary for Transport and Infrastructure');
  roadSignatoryRoles.put('Parliamentary Secretary Transport and Roads','Parliamentary Secretary for Transport and Infrastructure');
  roadSignatoryRoles.put('Parliamentary Secretary Regional Roads','Parliamentary Secretary for Regional Roads and Transport');
  roadSignatoryRoles.put('Parliamentary Secretary Regional Roads and Rail','Parliamentary Secretary for Regional Roads and Transport');
  roadSignatoryRoles.put('Chief of Staff','Chief of Staff Roads');
  roadSignatoryRoles.put('RMS Chief Executive','Chief Executive, Roads and Maritime Services');
  roadSignatoryRoles.put('Secretary, TfNSW','Secretary');
  roadSignatoryRoles.put('MAGS Manager','Manager, Ministerial & Government Services - Roads, Maritime and Freight');
  roadSignatoryRoles.put('Executive Director','Executive Director, Customer Relations & Government Services');
  roadSignatoryRoles.put('Principal Manager','Principal Manager, Ministerial & Government Services');
  
  transportSignatoryRoles = new Map<String, String>();
  transportSignatoryRoles.put('Minister','Minister for Transport and Infrastructure');
  transportSignatoryRoles.put('Parliamentary Secretary','Parliamentary Secretary for Transport and Infrastructure');
  transportSignatoryRoles.put('Parliamentary Secretary Transport and Roads','Parliamentary Secretary for Transport and Infrastructure');
  transportSignatoryRoles.put('Parliamentary Secretary Regional Roads','Parliamentary Secretary for Regional Roads and Transport');
  transportSignatoryRoles.put('Parliamentary Secretary Regional Roads and Rail','Parliamentary Secretary for Regional Roads and Transport');
  transportSignatoryRoles.put('Chief of Staff','Chief of Staff Transport');
  transportSignatoryRoles.put('RMS Chief Executive','Chief Executive, Roads and Maritime Services');
  transportSignatoryRoles.put('Secretary, TfNSW','Secretary');
  transportSignatoryRoles.put('MAGS Manager','Manager, Ministerial & Government Services - Roads, Maritime and Freight');
  transportSignatoryRoles.put('Executive Director','Executive Director, Customer Relations & Government Services');
  transportSignatoryRoles.put('Principal Manager','Principal Manager, Ministerial & Government Services');
  
  oosSignatoryRoles = new Map<String, String>();
  oosSignatoryRoles.put('Secretary, TfNSW','Secretary');
  oosSignatoryRoles.put('MAGS Manager','Manager, Ministerial & Government Services - Roads, Maritime and Freight');
  oosSignatoryRoles.put('Executive Director','Executive Director, Customer Relations & Government Services');
  oosSignatoryRoles.put('Principal Manager','Principal Manager, Ministerial & Government Services');
 }
 
 public void execute(List<Case> targetRecords) {
 
  Map<String, String> orgInternalUsers = new Map<String, String>();
  
  Map<String, Case> casesToUpdate = new Map<String, Case>();
  
  List<Case> casesToUnflag = new List<Case>();
  
  List<Action_Plan__c> actionPlansToUpdate = new List<Action_Plan__c>();
  
  for(User tempInternalUser : [SELECT Id, FirstName, LastName 
                               FROM User
                               WHERE UserType = 'Standard'
                               AND (Role_Dev_Name__c IN :GlobalConstants.MO_DLO_AND_PA_ROLE_NAMES
                               OR Role_Dev_Name__c IN :GlobalConstants.MO_SIGNATORY_ROLE_NAMES)
                               ORDER BY CreatedDate ASC]) {
   
    String mapKey = tempInternalUser.FirstName+'-'+tempInternalUser.LastName;
    mapKey = mapKey.toLowerCase();
    orgInternalUsers.put(mapKey, tempInternalUser.Id);                            
  }
  
  for(Case tempCase : targetRecords) {
   
   if(tempCase.Minister__c != NULL && tempCase.Minister_User__c == NULL) {
     
     totalMinisterCaseCount++;
     
     String key = tempCase.Minister__r.FirstName+'-'+tempCase.Minister__r.LastName;
     key = key.toLowerCase();
     if(orgInternalUsers.containsKey(key)) {
    
      tempCase.Minister_User__c = orgInternalUsers.get(key);
      successMinisterCount++;
      casesToUpdate.put(tempCase.Id, tempCase);
     }
     else{
     
      errorMinisterCount++;
      System.debug('Map does not contain Minister');
     }
   }
   
   if(tempCase.MO_Contact__c != NULL 
      && tempCase.MO_Contact__r.Account.Name == 'MO Contacts'
      && tempCase.MO_User__c == NULL) {
     
     totalMOCaseCount++;
     
     String key = tempCase.MO_Contact__r.FirstName+'-'+tempCase.MO_Contact__r.LastName;
     key = key.toLowerCase();
     if(orgInternalUsers.containsKey(key)) {
    
      tempCase.MO_User__c = orgInternalUsers.get(key);
      successMOCount++;
      casesToUpdate.put(tempCase.Id, tempCase);
     }
     else
      errorMOCount++;
   }
   
   if(tempCase.Signatory__c != NULL 
      && tempCase.Signatory__c != '' 
      && tempCase.Signatory__c != 'Commissioner'
      && roadSignatoryRoles.keySet().contains(tempCase.Signatory__c)
      && tempCase.Portfolio__c != NULL
      && tempCase.Portfolio__c != '') {
    
     obsoleteSignatoryCaseCount++;
     
     System.debug('Obsolete Signatory Case: '+tempCase.Id);
     
     if(tempCase.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_ROADS) {
      
      if(roadSignatoryRoles.containsKey(tempCase.Signatory__c)) {
      
       tempCase.Signatory__c = roadSignatoryRoles.get(tempCase.Signatory__c);
       successSignatoryCount++;
       casesToUpdate.put(tempCase.Id, tempCase);
      }
     }
     
     if(tempCase.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT) {
      
      if(transportSignatoryRoles.containsKey(tempCase.Signatory__c)) {
      
       tempCase.Signatory__c = transportSignatoryRoles.get(tempCase.Signatory__c);
       successSignatoryCount++;
       casesToUpdate.put(tempCase.Id, tempCase);
      }
     }
     
     if(tempCase.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_OOS) {
      
      if(oosSignatoryRoles.containsKey(tempCase.Signatory__c)) {
      
       tempCase.Signatory__c = oosSignatoryRoles.get(tempCase.Signatory__c);
       successSignatoryCount++;
       casesToUpdate.put(tempCase.Id, tempCase);
      }
     }
   }
   
   tempCase.Minister_Communication_Preference__c = GlobalConstants.MINISTER_COMM_PREFERENCE_EMAIL;
   tempCase.ChangeOfGovernmentBypass__c = TRUE;
   casesToUpdate.put(tempCase.Id, tempCase);
   
   if(tempCase.Action_Plans__r != NULL && tempCase.Action_Plans__r.size() > 0) {
    
    for(Action_Plan__c tempAP : tempCase.Action_Plans__r) {
     
     if(tempAP.Parent_Case__r.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_ROADS
         && tempAP.Signatory__c != '' && roadSignatoryRoles.containsKey(tempAP.Signatory__c)) {
      
      tempAP.Signatory__c = roadSignatoryRoles.get(tempAP.Signatory__c);
      actionPlansToUpdate.add(tempAP);
     }
     
     if(tempAP.Parent_Case__r.Portfolio__c == GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT
        && tempAP.Signatory__c != '' && transportSignatoryRoles.containsKey(tempAP.Signatory__c)) {
      
      tempAP.Signatory__c = transportSignatoryRoles.get(tempAP.Signatory__c);
      actionPlansToUpdate.add(tempAP);
     }
    }
   }
  }
  
  if(casesToUpdate.size() > 0) {
   
   List<Case> casesToUpdateList = casesToUpdate.values();
   List<Database.SaveResult> strList = Database.update(casesToUpdateList, false);
   
   for(Integer i=0;i<strList.size();i++) {
    
    if(!strList.get(i).isSuccess()) {
     
     ApplicationLogMessage message = new ApplicationLogMessage();
     message.source = 'InflightMOCasesBatchProcessor';
     message.sourceFunction = 'exceute';
     message.logMessage = 'Case Updation Failed: ';
     message.ex = NULL;
     message.debugLevel = 'Error';
     
     for(Database.Error err : strList.get(i).getErrors()) {
         
      message.logMessage += casesToUpdateList.get(i).Id+'-'+casesToUpdateList.get(i).CaseNumber+':'+err.getMessage()+',';
     }
     
     messages.add(message);
     errorCount++;
    }
    else {
     
     Case caseToUnflag = new Case();
     caseToUnflag.Id = strList.get(i).getId();
     caseToUnflag.ChangeOfGovernmentBypass__c = FALSE;
     casesToUnflag.add(caseToUnflag);
    }
   }
   
   if(casesToUnflag.size() > 0) {
    
    strList = Database.update(casesToUnflag, false);
    for(Integer i=0;i<strList.size();i++) {
    
     if(!strList.get(i).isSuccess()) {
      
      ApplicationLogMessage message = new ApplicationLogMessage();
      message.source = 'InflightMOCasesBatchProcessor';
      message.sourceFunction = 'exceute';
      message.logMessage = 'Unflagging failed: ';
      message.ex = NULL;
      message.debugLevel = 'Error';
       
      for(Database.Error err : strList.get(i).getErrors()) {
         
         message.logMessage += casesToUpdateList.get(i).Id+'-'+casesToUpdateList.get(i).CaseNumber+':'+err.getMessage()+',';
      }
       
      messages.add(message);
     }
    }
   } 
  }
  
  if(actionPlansToUpdate.size() > 0) {
  
   List<Database.SaveResult> strAPList = Database.update(actionPlansToUpdate, false);
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
  mail.setSubject('Inflight MO Cases Updation');
   
  String messageBody = '<html><body>Inflight MO cases updation process completed.'+
                            '<br/><br/><b>Minister Lookup:</b><br/>No. of Case records found with data in Minister field: '+totalMinisterCaseCount+
                            '<br/>No. of Case records successfully processed with corresponding matching Minister user: '+successMinisterCount+
                            '<br/>No. of Case records failed to process because of no matching Minister user: '+errorMinisterCount+
                            '<br/><br/><b>MO Contact Lookup:</b><br/>No. of Case records found with data in MO Contact field: '+totalMOCaseCount+
                            '<br/>No. of Case records successfully processed with corresponding matching MO Contact user: '+successMOCount+
                            '<br/>No. of Case records failed to process because of no matching MO Contact user: '+errorMOCount+
                            '<br/><br/><b>Signatory Values Updation:</b><br/>No. of Case records found with obsolete signatory values: '+obsoleteSignatoryCaseCount+
                            '<br/>No. of Case records successfully updated with new signatory values: '+successSignatoryCount+
                            '<br/><br/>No. of Case records failed due to other errors: '+errorCount+
                            '<br/><br/>To report on case records with no matching Minister or MO Contact user records found, kindly use following'+
                            ' two reports located in Unfiled public report folder - Inflight Cases Minister Lookup Miss, Inflight Cases MO Contact Lookup Miss and Inflight Cases Obsolete Signatory Miss'+
                            '<br/><br/>Check Application Logs in Salesforce for more details related to errors if any.</body></html>';
                            
  mail.setHtmlBody(messageBody);
  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
 }
}