@isTest
private class ExceptionLogger_Test {

    private static testMethod void testForLoggingSuccess() {
    	setLoggingSettings();
       	System.Test.startTest();
       	ExceptionLogger.logException('ExceptionLogger_Test','testForLoggingSuccess', new TestException('Test Exception'), null);
       	System.Test.stopTest();
       	List<Application_Log__c> logs = [SELECT Id FROM Application_Log__c WHERE Source__c = 'ExceptionLogger_Test'];
       	System.assert(!logs.isEmpty());
    }
    
    private static testMethod void testForLoggingFailure() {
    	setLoggingSettings();
        System.Test.startTest();
        try {
        	ExceptionLogger.logException(null,'testForLoggingSuccess',new TestException('Test Exception'), null);
        	System.assert(false);
        } catch(Exception e) {
        	System.assert(true);
        }       	
       	System.Test.stopTest();
    }
    
    private static void setLoggingSettings(){
		insert new System_Settings__c(
			Name='Test',Debug__c=true,Error__c=true,Info__c=true,Warning__c=true
		);
	}
    
    public class TestException extends Exception {}
}