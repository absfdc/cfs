global with sharing class ContactCaseCounter_BatchSchedule  implements Schedulable {
    private static final Integer DEFAULT_BATCH_SIZE = 100;
    
    global void execute(SchedulableContext sc) {
        ContactCaseCounter_Batch caseCounter = new ContactCaseCounter_Batch();
        Database.executeBatch(caseCounter,DEFAULT_BATCH_SIZE );
    }
}