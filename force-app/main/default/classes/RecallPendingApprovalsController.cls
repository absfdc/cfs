public class RecallPendingApprovalsController {
  
  private List<ApplicationLogMessage> messages;
  
  public Boolean batchScheduled {get; set;}
  
  public RecallPendingApprovalsController() {
   
   messages = new List<ApplicationLogMessage>();
   batchScheduled = false;
  }
  

  public PageReference recallApprovals() {
  
    String query = 'SELECT Id, CaseNumber, Portfolio__c, OwnerId, Owned_By_MO_Staff__c'+
                  ' FROM Case'+
                  ' WHERE Case_Owner__c = \''+GlobalConstants.TRANSPORT_MO_CONTACT_REJECTED+'\' OR Case_Owner__c = \''+GlobalConstants.ROADS_MO_CONTACT_REJECTED+'\' OR Case_Owner__c = \''+GlobalConstants.WestConnex_MO_CONTACT_REJECTED+'\'';
    
                  
    System.debug('Recall pending approvals query' + query);
   
    //schedule a batch immediately to start transfer of case ownership
    String id = Database.executeBatch(new BatchExecutor(new RecallPendingApprovalsProcess(UserInfo.getUserEmail()), query, null), 10);
    
    if(id != NULL && id != '')
     batchScheduled = true;
   
   return NULL;
  }
}