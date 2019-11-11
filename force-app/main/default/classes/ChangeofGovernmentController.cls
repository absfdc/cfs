public class ChangeofGovernmentController {
  
  private List<ApplicationLogMessage> messages;
  
  public Boolean batchScheduled {get; set;}
  
  public ChangeofGovernmentController() {
   
   messages = new List<ApplicationLogMessage>();
   batchScheduled = false;
  }
  
  public PageReference transferOwnerShip() {
  
    String roadPortfolio = GlobalConstants.MIN_CORR_PORTFOLIO_ROADS;
    String transportPortfolio = GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT;
    //String oosPortfolio = GlobalConstants.MIN_CORR_PORTFOLIO_OOS;
    

    String query = 'SELECT Id, CaseNumber, Portfolio__c, OwnerId, Owned_By_MO_Staff__c'+
                  ' FROM Case'+
                  ' WHERE Owned_By_MO_Staff__c = true'+
                  ' AND (Portfolio__c = \''+roadPortfolio+'\' OR Portfolio__c = \''+transportPortfolio+'\')';
                  
    System.debug('Case ownership transfer query' + query);
   
    //schedule a batch immediately to start transfer of case ownership
    String id = Database.executeBatch(new BatchExecutor(new GovernmentChangeTransferOwnershipProcess(UserInfo.getUserEmail()), query, null), 10);
    
    if(id != NULL && id != '')
     batchScheduled = true;
   
   return NULL;
  }
}