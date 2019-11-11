/*------------------------------------------------------------
Author:        Deepak Soni
Company:       Arxxus Technology Partners
Description:   Rest API to add an attachment to a case 
Inputs:        Parameter Strings
			   "guid" - Global Unique Id to identify the case
			   "filename" - Name of attachment
			   Attachment as request body

Test Class:    CaseAttachmentMobileService_Test

History
<Date>      	<Authors Name>		<Brief Description of Change>
19/02/2016      Deepak Soni     	Implemented Rest API service
------------------------------------------------------------*/
@RestResource(urlMapping='/cfm/v1/addAttachment/*')
global class CaseAttachmentMobileService {

	public static final String PARAM_GUID = 'guid';
	public static final String PARAM_FILENAME = 'filename';
	public static final String PARAM_CREATEDDATETIME = 'createdDateTime';

	@HttpPost
	global static ResponseWrapper doPost() {
		ResponseWrapper attachmentResponse = new ResponseWrapper();
		List<ApplicationLogMessage> logMessages =new List<ApplicationLogMessage>();

		try {
			RestRequest req = RestContext.request;
			RestResponse res = RestContext.response;

			ApplicationLogMessage payloadLogMsg = new ApplicationLogMessage();
            payloadLogMsg.source = 'CaseAttachmentMobileService';
            payloadLogMsg.sourceFunction = 'doPost';
            payloadLogMsg.logMessage = 'Paramerter Strings';
            payloadLogMsg.debugLevel = 'Info';
            payloadLogMsg.payLoad = PARAM_GUID + ': ' + req.params.get(PARAM_GUID) + '  :: ' + PARAM_FILENAME + ': ' + req.params.containsKey(PARAM_FILENAME);
            logMessages.add(payloadLogMsg);

            if(!req.params.containsKey(PARAM_GUID)) {
            	attachmentResponse.errorMessage = 'No guid paramater found';
            } else if(!req.params.containsKey(PARAM_FILENAME)) {
            	attachmentResponse.errorMessage = 'No file name found';
            } else {
				String caseGuid = String.escapeSingleQuotes(req.params.get(PARAM_GUID));
				String fileName = req.params.get(PARAM_FILENAME);

				attachmentResponse.guid = caseGuid;

				Case cas = [Select Id From Case where GUID__c =:caseGuid limit 1];

				Blob picture = req.requestBody;

				Attachment att = new Attachment (ParentId = cas.Id,
				                            Body = picture,
				                            ContentType = 'image/jpg',
				                            Name = fileName);
				insert att;

				// update NotesAndAttachment record thats get created on creation of the attachment with given DateTime
				NoteOrAttachment__c customAtt = [Select Id, Attachment__c, Attachment_DateTime__c From NoteOrAttachment__c Where Attachment__c = :att.Id];

				if(req.params.containsKey(PARAM_CREATEDDATETIME) && null != req.params.get(PARAM_CREATEDDATETIME) && req.params.get(PARAM_CREATEDDATETIME).isNumeric()) {
					customAtt.Attachment_DateTime__c = Datetime.newInstance(Long.valueOf(req.params.get(PARAM_CREATEDDATETIME)));
				} else {
					customAtt.Attachment_DateTime__c = Datetime.now();
				}

				update customAtt;

				attachmentResponse.success = true;
			}

		} catch(Exception ex) {
			attachmentResponse.errorMessage = ex.getMessage();

			ApplicationLogMessage logMsg = new ApplicationLogMessage();
            logMsg.source = 'CaseAttachmentMobileService';
            logMsg.sourceFunction = 'doPost';
            logMsg.logMessage = 'An exception occurred';
            logMsg.debugLevel = 'Error';
            logMsg.logMessage = ex.getMessage();
            logMsg.ex = ex;
            logMessages.add(logMsg);
		} finally {
			ApplicationLogUtility.logMessage(logMessages);
		}

		return attachmentResponse;
	}

	global class ResponseWrapper {
		public Boolean success {get; set;}
    	public String errorMessage {get; set;}
    	public String guid {get; set;}

    	public ResponseWrapper() {
    		success = false;
    	}
	}
}