public class BatchExecutor implements Database.Batchable<sObject>, Database.Stateful {
    
    private String query;
    private CustomBatchable contextObject;
    private set<id> idSet;
    
    List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
    
    public interface CustomBatchable {
     
     void execute(list<sObject> scope);
     void finish();
    }
    
    public BatchExecutor(CustomBatchable contextObject, String query, Set<id> ids) {

        this.contextObject = contextObject;
        this.query = query;
        this.idSet = ids;

        if(ids == null) {
         
         this.query = query;
        }
        else {
         
         this.query = query+' idSet';
        } 
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        System.debug('Query is ====================== '+query);
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        
     system.debug('Query scope is ====================== '+scope);   
     contextObject.execute(scope);
    }
    
    public void finish(Database.BatchableContext BC) {
       
       contextObject.finish();
    }  
}