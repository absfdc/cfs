/*-----------------------------------------------------------------------------------
Author:        Arxxus
Description:   This class is responsible for processing the Ezescan emails directed to a specific roads or transport email address 
               and accordingly creating a case of record type Roads & Freight Ministerial Correspondence or Transport Ministerial Correspondence 
Test Class:    ProcessEmailsWithScannedDocuments_Test

History 
<Date>         <Authors Name>     <Brief Description of Change>
19/09/2016     Arxxus             Created
-------------------------------------------------------------------------------------*/
public class CaseRoadsTransportCreator extends EmailsWithScannedDocumentsProcessor {
  
  static List<ApplicationLogMessage> logMessages =new List<ApplicationLogMessage>();
  public static final String DEBUG_LOG_LEVEL_INFO = 'Info';
  public static final String DEBUG_LOG_LEVEL_ERROR = 'Error';
  
  public override Messaging.InboundEmailResult process(Messaging.InboundEmail email, 
                                                       Messaging.InboundEnvelope envelope, 
                                                       EmailSubjectPatternConfiguration__c patternConfiguration) {
      
      System.debug('---Roads Email Processing---');
      Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
      EmailMessage message;
      Case caseRecord;
      
      try {
      
          Case newCase = createNewCase(email, patternConfiguration);
          message = createNewEmailMessage(email, newCase.Id);
          reparentDocuments(email, newCase, GlobalConstants.INCOMING);
          result.success = true;
          
      }
      catch(Exception ex) {
      
        System.debug('---Exception Roads Email Case Creation---' + ex.getMessage() + '--LINE--' + ex.getLineNumber());
        result.success = false;
        result.message = 'Error occured while processing the email.';
        
        ApplicationLogMessage logMsg = new ApplicationLogMessage();
        logMsg.source = 'CaseRoadsCreator';
        logMsg.sourceFunction = 'process';
        logMsg.logMessage = 'An exception occurred -'+ex.getStackTraceString();
        logMsg.debugLevel = DEBUG_LOG_LEVEL_ERROR;
        logMsg.ex = ex;
        logMessages.add(logMsg);
        ApplicationLogUtility.logMessage(logMessages);
        logMessages.clear();
      }
      
      return result;
  }
}