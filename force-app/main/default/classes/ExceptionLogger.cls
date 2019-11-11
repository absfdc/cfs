/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    utility class for logging exception message in application log.
Inputs:         
Test Class:     ExceptionLogger_Test
History:
------------------------------------------------------------*/
public class ExceptionLogger {
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Salesforce.com
    Description:    utility method for logging exception message in application log.
    Inputs:         
    Returns:        
    History:
    ------------------------------------------------------------*/
    public static void logException(String source, String functionName, Exception e, String referenceId) {
        ApplicationLogMessage message = new ApplicationLogMessage();
        message.source = source;
        message.sourceFunction = functionName;
        message.logMessage = e.getMessage();
        message.ex = e;
        message.referenceId = referenceId;
        message.debugLevel = GlobalConstants.ERROR;
        ApplicationLogUtility.logMessage(message);
    }
}