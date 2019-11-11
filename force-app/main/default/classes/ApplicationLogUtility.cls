/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Utility class for the Application Log

Test Class:    ApplicationLog_Test
History
23 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/
public without sharing class ApplicationLogUtility {
    /*------------------------------------------------------------
    Author:        	Dipankar Barman
    Company:       	Arxxus.com
    Description:   	Overloaded Logging method to log a message
    Inputs:        	debugLevel - Debug, Error, Info, Warning
					source - Originating trigger or utility class
                   	sourceFunction - Method in class above that caused the message
					logMessage - Message to log
                   	payLoad - Optional based on integration messages
                   	ex - the standard exception object for errors
                   	timeTaken - The time in milliseconds of the transaction
					logCode - Either the exception error code of custom org code for record
					referneceId - Process Identifier (e.g. Job Id)
					referenceInfo - Process information
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    public static void logMessage(String debugLevel,
                            String source,
                            String sourceFunction,
                            String logMessage,
                            String payLoad,
                            Exception ex,
                            Long timeTaken,
                            String logCode,
                            String referenceId,
                            String referenceInfo) {
        String stackTrace;
        if (ex!=null) stackTrace=ex.getStackTraceString();
		ApplicationLogMessage aLog= new ApplicationLogMessage();
		aLog.debugLevel=debugLevel;
		aLog.payLoad= payLoad;
		aLog.logCode= logCode;
		aLog.logMessage=logMessage ;
		aLog.referenceId= referenceId;
		aLog.referenceInfo=referenceInfo ;
		aLog.source= source;
		aLog.sourceFunction= sourceFunction;
		aLog.timer=timeTaken ;
		aLog.ex= ex;


		logMessage(aLog);



    }
	/*------------------------------------------------------------
	Author:        	Dipankar Barman
	Company:       	Arxxus.com
	Description:   	Overloaded logging  mehod to log a message
	Inputs:        	Single ApplicationLogMessage
	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
	public static void logMessage(ApplicationLogMessage singleLogMessage) {
		List<ApplicationLogMessage> logList= new 	List<ApplicationLogMessage>{singleLogMessage};

		logMessage(logList);



	}
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Utility method to log messages in bulk
    Inputs:        List of Application Log messages

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    public static void logMessage(List<ApplicationLogMessage> messages){
        List<Application_Log__c> appLogs= new List<Application_Log__c>();
        String stackTrace;
        for (ApplicationLogMessage aLog:messages){

            
			if((aLog.debugLevel == GlobalConstants.DEBUG && System_Settings__c.getInstance().Debug__c)
				||(aLog.debugLevel == GlobalConstants.ERROR && System_Settings__c.getInstance().Error__c)
				||(aLog.debugLevel == GlobalConstants.INFO && System_Settings__c.getInstance().Info__c)
				||(aLog.debugLevel == GlobalConstants.WARNING && System_Settings__c.getInstance().Warning__c)){
					if (aLog.ex!=null) stackTrace=aLog.ex.getStackTraceString();
					Application_Log__c anApplog= new Application_Log__c(Debug_Level__c=aLog.debugLevel,
		                                                        Integration_Payload__c=aLog.payLoad,
		                                                        Log_Code__c=aLog.logCode,
		                                                        Message__c=aLog.logMessage,
		                                                        Reference_Id__c=aLog.referenceId,
		                                                        Reference_Info__c=aLog.referenceInfo,
		                                                        Source__c=aLog.source,
		                                                        Source_Function__c=aLog.sourceFunction,
		                                                        Stack_Trace__c=stackTrace,
		                                                        Timer__c=aLog.timer);
		            appLogs.add(anApplog);
            }

        }

        insert appLogs;
    }
    
    
    /*------------------------------------------------------------
	Author:        	Ishu Jain
	Company:       	System Partners
	Description:   	Overloaded logging  mehod to log a message and send the email 
	Inputs:        	List of ApplicationLogMessage
	History
	<Date>          <Authors Name>     <Brief Description of Change>
	14 March 18       Ishu Jain          Created
	------------------------------------------------------------*/
    
    public static void logMessage(List<ApplicationLogMessage> messages, boolean boolSendEmail){
        List<Application_Log__c> appLogs= new List<Application_Log__c>();
        String stackTrace;
        for (ApplicationLogMessage aLog:messages){

            
			if((aLog.debugLevel == GlobalConstants.DEBUG && System_Settings__c.getInstance().Debug__c)
				||(aLog.debugLevel == GlobalConstants.ERROR && System_Settings__c.getInstance().Error__c)
				||(aLog.debugLevel == GlobalConstants.INFO && System_Settings__c.getInstance().Info__c)
				||(aLog.debugLevel == GlobalConstants.WARNING && System_Settings__c.getInstance().Warning__c)){
					if (aLog.ex!=null) stackTrace=aLog.ex.getStackTraceString();
					Application_Log__c anApplog= new Application_Log__c(Debug_Level__c=aLog.debugLevel,
		                                                        Integration_Payload__c=aLog.payLoad,
		                                                        Log_Code__c=aLog.logCode,
		                                                        Message__c=aLog.logMessage,
		                                                        Reference_Id__c=aLog.referenceId,
		                                                        Reference_Info__c=aLog.referenceInfo,
		                                                        Source__c=aLog.source,
		                                                        Source_Function__c=aLog.sourceFunction,
		                                                        Stack_Trace__c=stackTrace,
		                                                        Timer__c=aLog.timer,
		                                                        Send_Email_To_Support__c = boolSendEmail,
		                                                        Email_Id__c = Label.Exception_Email_Id);
		            appLogs.add(anApplog);
            }

        }

        insert appLogs;
    }
    
}