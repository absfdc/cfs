global class ContactCaseCounter_Batch implements Database.Batchable<sObject>{
    private static final String DEFAULT_QUERY_ON_CONTACT = 'SELECT Id FROM Contact';
    
    global Database.Querylocator start(Database.Batchablecontext bc){
        return Database.getQueryLocator(DEFAULT_QUERY_ON_CONTACT);
    }
    
     global void execute(Database.Batchablecontext bc, List<Contact> contacts) {
        if (contacts.isEmpty()) {
            return;
        }
        List<Id> contactIds = new List<Id>();
        for(Contact conRec : contacts) {
            contactIds.add(conRec.Id);
        }
        ContactCaseCounter caseCounter = new ContactCaseCounter(contactIds);
        caseCounter.countCases();
    } 
    
    global void finish(Database.Batchablecontext bc){               
        AsyncApexJob asyncJob = [SELECT Id, NumberOfErrors, TotalJobItems
                                 FROM AsyncApexJob 
                                 WHERE Id = :bc.getJobId()];
        
        //create application log entry. 
        ApplicationLogMessage message = new ApplicationLogMessage();
        message.source = 'ContactCaseCounter_Batch ';
        message.sourceFunction = 'finish';
        message.logMessage = 'Batch processing to count cases on contact completed. Details are listed below\n'
                + 'Count of processed batch: ' + asyncJob.TotalJobItems + '\n' 
                + 'Count of success batch: ' + (asyncJob.TotalJobItems - asyncJob.NumberOfErrors) + '\n'
                + 'Count of failure batch: ' + asyncJob.NumberOfErrors;
        message.referenceId = bc.getJobId();
        message.debugLevel = 'Info';
        ApplicationLogUtility.logMessage(message);  
        
    }
}