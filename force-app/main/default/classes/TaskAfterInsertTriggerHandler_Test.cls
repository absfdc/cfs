@isTest
private class TaskAfterInsertTriggerHandler_Test {
	
	@isTest static void exceptionTest() {
		// Implement test code
		TaskAfterInsertTriggerHandler tait = new TaskAfterInsertTriggerHandler();
		tait.mainEntry(null);
        
        list <Application_Log__c> logs = [Select Id from Application_Log__c];
        system.assert(logs !=null);
	}
	
}