@isTest
public  class ApplicationLog_Test {
    
    static testMethod void  testSingleLog(){
        setLoggingSettings();
        TestException te;
        try{
            throw new TestException();
        }catch(TestException t){
            te=t;
        }

        ApplicationLogUtility.logMessage('Debug',
                                            'ApplicationLog_Test',
                                            'testSingleLog',
                                            'test log message',
                                            'test payload',
                                            te,
                                            1.0.longValue(),
                                            'CUSTOM_TEST_EXCEPTION',
                                            'abcdefghijklmnopqr',
                                            'reference info');
        Application_Log__c alog=[SELECT Age__c,Debug_Level__c,Id,Integration_Payload__c,Log_Code__c,Message__c,Name,OwnerId,Reference_Id__c,Reference_Info__c,Source_Function__c,Source__c,Stack_Trace__c,Timer__c FROM Application_Log__c];
        system.assert(alog!=null);
    }

    
    static testMethod void  testSingleLogMandatoryFieldMissing(){
        setLoggingSettings();
        TestException te;
        try{
            throw new TestException();
        }catch(TestException t){
            te=t;
        }
        try{
            ApplicationLogUtility.logMessage('Debug',
                                                null,
                                                null,
                                                'test log message',
                                                'test payload',
                                                te,
                                                1.0.longValue(),
                                                'CUSTOM_TEST_EXCEPTION',
                                                'abcdefghijklmnopqr',
                                                'reference info');
        }
        catch(DMLException dml){
            system.assertEquals(dml.getDmlType(0),StatusCode.REQUIRED_FIELD_MISSING);
        }
    }
    
    static testMethod void testBatchLog(){
        setLoggingSettings();
        TestException te;
        try{
            throw new TestException();
        }catch(TestException t){
            te=t;
        }
        List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

        for(integer count=0; count<100;count++){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ApplicationLog_Test';
            message.sourceFunction='testBatchLog';
            message.referenceId='abcdefghijklmnopqr';
            message.referenceInfo=''+count;
            message.logMessage='test log message';
            message.payLoad='test payload';
            message.ex=te;
            message.debugLevel='Debug';
            message.logCode='CUSTOM_TEST_EXCEPTION';
            message.timer=1.0.longValue();
            messages.add(message);
        }
        ApplicationLogUtility.logMessage(messages);
        List<Application_Log__c> alogs=[SELECT Age__c,Debug_Level__c,Id,Integration_Payload__c,Log_Code__c,Message__c,Name,OwnerId,Reference_Id__c,Reference_Info__c,Source_Function__c,Source__c,Stack_Trace__c,Timer__c FROM Application_Log__c];
        system.assertEquals(100,alogs.size());
    }
    
	@TestSetup
    public static void setLoggingSettings(){
        insert new System_Settings__c(
            Name='Test',Debug__c=true,Error__c=true,Info__c=true,Warning__c=true
        );
    }
    public class TestException extends Exception {}
}