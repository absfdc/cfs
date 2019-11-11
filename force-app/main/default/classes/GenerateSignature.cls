/*------------------------------------------------------------
Author:        Arxxus
Description:   WebService call to get Document located in Salesforce and return image as a response.
Test Class:     GenerateSignature_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
12-DEC-2016   Arxxus          Comments and cleanup
07-Apr-2017   Arxxus          Updated.Implementation for Review status logic
11-Apr-2017   Arxxus          Updated. Check if signature location is populated or not on user record
------------------------------------------------------------*/
@RestResource(urlMapping='/mincor/v1/GenerateSignature/*')
global class GenerateSignature {

    //http get request call
    @HttpGet
    global static void validateForSignature() {
        
        List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
        try{
            String userId = RestContext.request.params.get('userId');
            String caseId = RestContext.request.params.get('caseId');
            String documentId = RestContext.request.params.get('documentId');
            String customAttachementId = '';
            String signaturedDocumentId = '';
            String imageURL;

            Boolean isTrue;
            Map<String,Digital_Process_Send_Email__c> checkSendEmailProcess = Digital_Process_Send_Email__c.getAll();
            isTrue = checkSendEmailProcess != NULL && checkSendEmailProcess.size() > 0 && checkSendEmailProcess.get(GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL) != NULL ?checkSendEmailProcess.get(GlobalConstants.DIGITAL_PROCESS_SEND_EMAIL).On__c:FALSE;

            Boolean checkAuthorizationRecords = false;
            List<User> userList = [SELECT Id, Signature_Location__c FROM User WHERE Id =: userId ]   ;

            if(userList.size() > 0){

                if(userList[0].Signature_Location__c != null && userList[0].Signature_Location__c != ''){
                    
                    signaturedDocumentId = (userList[0].Signature_Location__c).split('=')[1];

                }else{

                    ApplicationLogMessage message = new ApplicationLogMessage();
                    message.source='GenerateSignature';
                    message.sourceFunction='validateForSignature';
                    message.logMessage='Signature location is not populated on user record.';
                    message.debugLevel='Error';
                    messages.add(message);
                    ApplicationLogUtility.logMessage(messages);
                    messages.clear();
                } 
            }
       
       
            // get request and response parameters from RestContext
            RestResponse res = RestContext.response;    
        
            // get image body from Document
            List<Document> getAttachmentList  = [Select Id,Body from Document where Id =: signaturedDocumentId ];

            for(Signature_Authorisation__c getSignatureAuthorisation : [Select Id, Case_Id__c, Document_Id__c,CreatedDate, User_Id__c 
                                                                        FROM Signature_Authorisation__c 
                                                                        WHERE User_Id__c =: userId
                                                                        AND Case_Id__c =: caseId
                                                                        AND Document_Id__c =: documentId
                                                                        ORDER BY CreatedDate desc limit 1]) {
                
                checkAuthorizationRecords = true;
                
                // set response for this request
                if(getAttachmentList.size() > 0) {
                    
                    RestContext.response.addHeader('Content-Type', 'image/png');
                    RestContext.response.responseBody = getAttachmentList[0].Body;
                
                }else{
                     
                    ApplicationLogMessage message = new ApplicationLogMessage();
                    message.source='GenerateSignature';
                    message.sourceFunction='validateForSignature';
                    message.logMessage='No signature found after getting validation record.';
                    message.debugLevel='Error';
                    messages.add(message);
                    ApplicationLogUtility.logMessage(messages);
                    messages.clear();
                } 
               
            }

            if(checkAuthorizationRecords == false) {
                
                ApplicationLogMessage message = new ApplicationLogMessage();
                message.source='GenerateSignature';
                message.sourceFunction='validateForSignature';
                message.logMessage='No validation record found for signature authorisation.';
                message.debugLevel='Error';
                messages.add(message);
                ApplicationLogUtility.logMessage(messages);
                messages.clear();

            }

        }catch(Exception e) {
          
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source='GenerateSignature';
            message.sourceFunction='validateForSignature';
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel='Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
        }
    }
}