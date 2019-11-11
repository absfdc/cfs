/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus.com
Description:   Handler class to truncate the filename when it exceeds the 80 characters limit
Test Class:    NoteOrAttBeforeInsertTriggerHandler_Test.cls 
History
19/05/2017     Pawan Tiwari       Created 
------------------------------------------------------------*/
public without sharing class NoteOrAttBeforeInsertTriggerHandler extends TriggerHandlerBase{
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    public boolean exceptionInvoked = FALSE;

    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Pawan Tiwari
    Company:       Arxxus.com
    Description:   Handler function to truncate the filename when it exceeds the 80 characters limit
    
    History
    19/05/2017     Pawan Tiwari       Created 
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        System.debug('NoteOrAttBeforeInsertTriggerHandler :: process');
        try {
            
            for(NoteOrAttachment__c attach : (list <NoteOrAttachment__c>) tp.newList) {
              
                // Start: Pawan Tiwrai 18/05/2017
                //validate attachment filename against 80 characters length 
                String fileName = attach.name;
                if(String.isNotBlank(fileName) && fileName.length() > 80){
                    // get filename extesnion length with '.' as last index before start of extension
                    Integer fileExtensionLength = fileName.length() - fileName.lastIndexOf('.');
                    String fileExtension = fileName.substring(fileName.lastIndexOf('.'),fileName.length());
                    // get string before '.' i.e before extension excluding '.'
                    String fileNameToBeTrimed = fileName.substring(0,fileName.lastIndexOf('.'));
                    // get string after trim few characters to meet 80 characters length
                    fileName = fileNameToBeTrimed.left(80 - fileExtensionLength)+fileExtension;
                }
                attach.Name = fileName;
               
            }
            
           
        }
        catch(Exception e) {
            
            exceptionInvoked = TRUE;
            
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='NoteOrAttBeforeInsertTriggerHandler';
            message.sourceFunction='process';
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel='Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear(); 
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
}