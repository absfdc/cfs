public with sharing class SuspectedSpamCaseLogger {

    public static final String NUMBER_OF_TIMES_REQ_SENT_STR = 'Number of times request sent:';

    public static void logSpamCase(String ipAddress, String source, String functionName) {
        if(String.isBlank(ipAddress) || String.isBlank(source) || String.isBlank(functionName)) {
            throw new InvalidParameterException('Failed to instantiate SuspectedSpamCaseLogger. Either ip address or source details missing');
        }
        Application_Log__c log = getAlreadyLoggedMsg(ipAddress);
        if(log == null) {
            logSuspectedSpam(ipAddress, source, functionName);
        } else {
            updateLogMessage(log);
        }
    }
    
    private static Application_Log__c getAlreadyLoggedMsg(String ipAddress) {
        WebToCaseSpamSettings__c spamSettings = WebToCaseSpamSettings__c.getValues('WebToCase');
        if(spamSettings == null) {
            return null;
        }
        
        DateTime since = System.now().addMinutes(-1 * Integer.valueOf(spamSettings.Within_duration_in_min__c));
        
        List<Application_Log__c> log = [SELECT Id, Message__c 
                                        FROM Application_Log__c 
                                        WHERE Reference_Id__c = :ipAddress 
                                          AND CreatedDate > :since];
        if(!log.isEmpty()) {
            return log[0];
        } 
        return null;
    }
    
    private static void logSuspectedSpam(String ipAddress, String source, String functionName) {
        ApplicationLogMessage message = new ApplicationLogMessage();
        message.source = source;
        message.sourceFunction = functionName;
        message.logMessage = 'Suspected spam request to create case from web form. Details as below \nSource=' + source 
            + '\nIp=' + ipAddress + '\n'  + NUMBER_OF_TIMES_REQ_SENT_STR + 1;     
        message.debugLevel = GlobalConstants.WARNING;
        message.logCode = GlobalConstants.SUSPECTED_SPAM_CASE;
        message.referenceId = ipAddress;
        ApplicationLogUtility.logMessage(message);
    }
    
    private static void updateLogMessage(Application_Log__c message) {
        if(message.Message__c.contains(NUMBER_OF_TIMES_REQ_SENT_STR )) {
            String strMessage = message.Message__c;
            Integer freqCount = Integer.valueOf(strMessage.subString(strMessage.lastIndexOf(':') + 1)) + 1;
            message.Message__c = strMessage.subString(0, strMessage.lastIndexOf(':') + 1) + freqCount;
            
            update message;
        }
    }
    
    public class InvalidParameterException extends Exception {}
}