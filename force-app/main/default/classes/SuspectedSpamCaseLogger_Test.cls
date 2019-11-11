@isTest
private class SuspectedSpamCaseLogger_Test {
    private static String ipAddress = '192.143.67.167';
    private static String source = 'SuspectedSpamCaseLogger_Test';
    private static String functionName = 'testMethod';
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try{
            SuspectedSpamCaseLogger.logSpamCase(null, source, functionName);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try{
            SuspectedSpamCaseLogger.logSpamCase(ipAddress, null, functionName);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try{
            SuspectedSpamCaseLogger.logSpamCase(ipAddress, source, null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }

    private static testMethod void testForNewSpamLog() {
        setUpTestData(true);
        System.Test.startTest();
        SuspectedSpamCaseLogger.logSpamCase(ipAddress, source, functionName);
        System.Test.stopTest();
        List<Application_Log__c> appLog = [SELECT Id, Message__c FROM Application_Log__c];
        System.assert(!appLog.isEmpty());
        System.assert(appLog[0].Message__c != null);
        System.assert(appLog[0].Message__c.endsWith(SuspectedSpamCaseLogger.NUMBER_OF_TIMES_REQ_SENT_STR + 1));
    }
    
    private static testMethod void testForSpamCheckWithoutCustomSetting() {
        setUpTestData(true);
        List<WebToCaseSpamSettings__c> settings = [SELECT ID FROM WebToCaseSpamSettings__c ];
        delete settings;
        System.Test.startTest();
        SuspectedSpamCaseLogger.logSpamCase(ipAddress, source, functionName);
        System.Test.stopTest();
        List<Application_Log__c> appLog = [SELECT Id, Message__c FROM Application_Log__c];
        System.assert(!appLog.isEmpty());
        System.assert(appLog[0].Message__c != null);
        System.assert(appLog[0].Message__c.endsWith(SuspectedSpamCaseLogger.NUMBER_OF_TIMES_REQ_SENT_STR + 1));
    }
    
    private static testMethod void testForMultipleSpam() {
        setUpTestData(false);
        System.Test.startTest();
        SuspectedSpamCaseLogger.logSpamCase(ipAddress, source, functionName);
        System.Test.stopTest();
        List<Application_Log__c> appLog = [SELECT Id, Message__c FROM Application_Log__c];
        System.assert(!appLog.isEmpty());
        System.assert(appLog[0].Message__c != null);
        System.debug(appLog[0].Message__c);
        System.assert(appLog[0].Message__c.endsWith(SuspectedSpamCaseLogger.NUMBER_OF_TIMES_REQ_SENT_STR + 2));
    }
    
    private static void setUpTestData(Boolean isNewSpam) {
        setUpCustomSetting();
        if(!isNewSpam) {
            createSpamLog();
        }       
    }
    
    private static void createSpamLog() {
        ApplicationLogMessage message = new ApplicationLogMessage();
        message.source = source;
        message.sourceFunction = functionName;
        message.logMessage = 'Suspected spam request to create case from web form. Details as below \nSource=' + source
            + '\nIp=' + ipAddress + '\n'  + SuspectedSpamCaseLogger.NUMBER_OF_TIMES_REQ_SENT_STR + 1;     
        message.debugLevel = GlobalConstants.WARNING;
        message.logCode = GlobalConstants.SUSPECTED_SPAM_CASE;
        message.referenceId = ipAddress;
        ApplicationLogUtility.logMessage(message);
    }
    
    private static void setUpCustomSetting() {
        WebToCaseSpamSettings__c spamSetting = new WebToCaseSpamSettings__c();
        //create spam setting for max 10 allowed cases within 10 mins.
        spamSetting.Within_duration_in_min__c = 10;
        spamSetting.Frequency__c = 10;
        spamSetting.Name = 'WebToCase';
        insert spamSetting;
        
        insert new System_Settings__c(
            Name='Test', Debug__c=true, Error__c=true, Info__c=true, Warning__c=true
        );
    }
}