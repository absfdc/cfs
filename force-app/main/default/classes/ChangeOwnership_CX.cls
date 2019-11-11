public with sharing class ChangeOwnership_CX {

  public Boolean sendEmailNotification {get; set;}
  
  public SObject updationRecord {get; set;}
  
  public String recordName {get; set;}
  public String recordId {get; set;}
  public String objectLabel {get; set;}
  
  public ChangeOwnership_CX() {
   
   sendEmailNotification = false;
   recordName = ApexPages.currentPage().getParameters().get('recordName') == NULL?'':ApexPages.currentPage().getParameters().get('recordName');
   recordId = ApexPages.currentPage().getParameters().get('id');
   objectLabel = ApexPages.currentPage().getParameters().get('recordLabel') == NULL?'Account':ApexPages.currentPage().getParameters().get('recordLabel');
   
   updationRecord = Schema.getGlobalDescribe().get(objectLabel).newSObject();
   updationRecord.Id = recordId;
  }
  
  public PageReference Cancel() {
   
   return NULL;
  }
    
  public PageReference save() {
   
   if(recordId != NULL && recordId != '') {
    
    Database.DMLOptions dlo = new Database.DMLOptions();
    dlo.EmailHeader.triggerAutoResponseEmail = sendEmailNotification;

    Database.SaveResult sr = Database.update(updationRecord, dlo);
    
    if(!sr.isSuccess()) {
     
     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ''+sr.getErrors()[0].getMessage())); 
     return NULL;
    }
    else {
     
     String assignedTo;
     String tabLabel = recordName;
     
     String ownerId = (String)updationRecord.get('ownerId');
     // check that owner is a user (not a queue)
     if(ownerId.substring(0,3) != '00G' ){
      
      User recordOwner = [SELECT Name FROM User WHERE Id = :ownerId];   
      assignedTo =  recordOwner.Name;            
     }
     else {
      
      Group recordOwner = [SELECT Name FROM GROUP WHERE Id = :ownerId AND Type = 'Queue'];   
      assignedTo =  recordOwner.Name;
     }    
     
     
     Pagereference checkRecordAccessPageRef = new Pagereference(Page.checkRecordAccess.getUrl());
     checkRecordAccessPageRef.getParameters().put('id', updationRecord.Id);
     checkRecordAccessPageRef.getParameters().put('assignedTo', assignedTo);
     checkRecordAccessPageRef.getParameters().put('tabLabel', tabLabel);
     checkRecordAccessPageRef = checkRecordAccessPageRef.setRedirect(true);
     
     return checkRecordAccessPageRef;
     
    }
   }
   
   return NULL;
  }
}