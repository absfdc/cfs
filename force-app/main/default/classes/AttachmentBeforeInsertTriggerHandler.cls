/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus.com
Description:   A utility class for the Attachment Trigger

Test Class:    AttachmentBeforeInsertTriggerHandler_Test
History
19/05/2017     Pawan Tiwari      Created.
------------------------------------------------------------*/
public without sharing class AttachmentBeforeInsertTriggerHandler extends TriggerHandlerBase{
    
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    
    public override void mainEntry(TriggerParameters tp) {
        System.debug('AttachmentBeforeInsertTriggerHandler :: mainEntry');
        process(tp);        
    }

    private void process(TriggerParameters tp) {
        System.debug('***AttachmentBeforeInsertTriggerHandler called****');
        try{
            for(Attachment attach : (List<Attachment>)tp.newList){
                // Start: Pawan Tiwrai 18/05/2017
                //validate attachment filename against 80 characters length 
                System.debug('AttachmentBeforeInsertTriggerHandler attachment :: ' + attach);
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
                System.debug('AttachmentBeforeInsertTriggerHandler fileName :: ' + fileName);
                attach.Name = fileName;
            }
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='AttachmentBeforeInsertTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.newMap!=null)  message.referenceInfo=JSON.serialize(tp.newMap.keySet());
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