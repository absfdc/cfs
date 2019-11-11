/*------------------------------------------------------------
Author:        Arxxus
Description:   class for Response preview
Test Class:     ResponsePreview_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
22-FEB-2016   Arxxus          Comments and cleanup
------------------------------------------------------------*/
global without sharing class ResponsePreview {
    
    @RemoteAction
    global static Map<String, String> showResponsePreviewPDF(String caseId){
        
        List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
        Map<String,String> responsedataMap = new Map<String,String>();
        try {
            
            //String caseId = caseId;
            String attachmentId = '';
            String sessionId = '';
            String attachmentName = '';
            String pdfAttachmentId = '';
            String getId = '';
            String imageURL = '';   

            List<NoteOrAttachment__c> customAttachment = [Select Id, Name, Case__c, ContentType__c, Attachment_Id__c,Case__r.Signature_Image_URL__c
                                                            FROM NoteOrAttachment__c
                                                            WHERE Case__c = : caseId
                                                            AND ContentType__c = 'application/msword'
                                                            AND Attachment_Id__c != NULL
                                                            ORDER BY CreatedDate DESC
                                                            LIMIT 1 ];
            if(customAttachment.size() > 0) {
                attachmentId = customAttachment[0].Attachment_Id__c;
                attachmentName = customAttachment[0].Name;
                imageURL = customAttachment[0].Case__r.Signature_Image_URL__c;
                sessionId = UserInfo.getSessionId();

                System.debug('Conga Parameters :: ' + caseId + '--' + attachmentId + '--' + attachmentName + '--' + sessionId);
                getId = GeneratePdfPreviewWithSignature.generate(caseId, attachmentId, attachmentName, sessionId, TRUE);

                system.debug('Get Attachment Id ::' + getId);
            }


            if(getId != '') {

                List<NoteOrAttachment__c> customAttachmentAfterConverion = [Select Id, Attachment_Id__c
                                                                                FROM NoteOrAttachment__c
                                                                                WHERE Id = : getId ];

                if(customAttachmentAfterConverion.size() > 0) {
                    pdfAttachmentId = customAttachmentAfterConverion[0].Attachment_Id__c;
                }

                String paramvalue = '';
                Blob attachmentBlob;
                String responseAttachmentName = '';

                List<Attachment> responseAttachment = [Select Id, Name, Body from Attachment where Id = : pdfAttachmentId];

                if(responseAttachment.size() > 0) {

                    attachmentBlob = responseAttachment[0].Body;
                    responseAttachmentName = responseAttachment[0].Name;
                    paramvalue = 'data:application/pdf;base64,' + EncodingUtil.base64Encode(attachmentBlob);
                    responsedataMap.put('Id', getId);
                    responsedataMap.put('data', paramvalue);
                    responsedataMap.put('name', responseAttachmentName);

                    delete responseAttachment;

                    delete customAttachmentAfterConverion;
                }

            }else{
                responsedataMap.put('Error','Failed to get the authorization');
            }

            if(imageURL != null && imageURL != ''){
                Case caseToBeUpdated = new Case();
                caseToBeUpdated.Id = caseId;
                update caseToBeUpdated;
            }   
            return responsedataMap;
        }catch(Exception e){
            //exceptionInvoked = TRUE;
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'ResponsePreview';
            message.sourceFunction = 'showResponsePreviewPDF';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();

            return responsedataMap;
        }
    }
    

}