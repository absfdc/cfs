/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class is responsible for processing the Signed Response related emails from the Scanner.
               ------------------------------------------------------------				   
                Pattern Matched | Case Found | Create New Case | Case Type 
			   ------------------------------------------------------------
			    Yes             | Yes        | No              | -
			    Yes             | No         | Yes             | Erroneous Case
			    No              | Yes        | Yes             | Min Corro Case
History 
<Date>         <Authors Name>     <Brief Description of Change>
14/07/2015     Manish Damle       Created
12/09/2017     Yogiraj Sarode - status for a CFM case will not change and new case will be created which create new case erroroneous case 
							  - status for a Min Corro case will change (existing behaviour no change made)
--------------------------------------------------------------------------------------*/
public class CaseSignedResponseProcessor  extends EmailsWithScannedDocumentsProcessor {
    
    // 12/09/2017: Yogiraj Sarode for Req-102 Oct Release
    public static List<Group> erroneousCasesQueueList = null;

    public override Messaging.InboundEmailResult process(Messaging.InboundEmail email, 
    												     Messaging.InboundEnvelope envelope, 
    												     EmailSubjectPatternConfiguration__c patternConfiguration) {
    	system.debug('---Signed Response/Regular Case Processing---');
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        EmailMessage message;
        Case caseRecord;
        
    	
        
        try {
	        String refNo = extractCaseRefNumberFromSubject(email.subject, patternConfiguration.Prefix__c, patternConfiguration.Suffix__c);
	        // 12/09/2017: Yogiraj Sarode for Req-102 Oct Release, Starts Here
	        if(erroneousCasesQueueList == NULL){
	        	erroneousCasesQueueList = [SELECT Id 
	        							   FROM Group WHERE Type = 'Queue' AND DeveloperNAME =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO LIMIT 1];
	        }
	        // 12/09/2017: Yogiraj Sarode for Req-102 Oct Release, Ends Here
		    system.debug('---Subject---' + email.Subject + '----Extracted Ref Number----' + refNo);
	        if(refNo != null) {
	            caseRecord = fetchCaseDetails(refNo);
	            if(caseRecord == null || caseRecord.Status == GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO || caseRecord.Status == GlobalConstants.CASE_NRR_STATUS_MIN_CORRO) {//SFCOE - 59 fix - Dec '16
	            	Case erroneousCase = createNewErroneousCase(email, patternConfiguration);
                    message = createNewEmailMessage(email, erroneousCase.Id);
	            	reparentDocuments(email, erroneousCase, GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE);
	            } else {//Case Record Found
	            	
	            	// 12/09/2017: Yogiraj Sarode for Req-102 Oct Release, Starts Here
	            	if(caseRecord.IsMinCorroCase__c == TRUE) {
                        message = createNewEmailMessage(email, caseRecord.Id);
                        Id caseAttachmentId = createCaseAttachmentFromEmailAttachments(email, caseRecord);
                        System.debug('-----Signed Response/Regular---' + caseAttachmentId);
                        if(caseAttachmentId != null) {
                            list <NoteOrAttachment__c> customNoteOrAttachments = [Select Category__c 
                                                                                  From NoteOrAttachment__c 
                                                                                  Where Attachment__c =: caseAttachmentId limit 1];
                            if(customNoteOrAttachments.size() > 0) {
                                customNoteOrAttachments[0].Category__c = GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE;
                                customNoteOrAttachments[0].Requires_Printing__c = true; 
                                update customNoteOrAttachments[0];
                                System.debug('-----Signed Response/Regular---Attachment Updated--');
                            }
                        }
                        caseRecord.Status = GlobalConstants.CASE_SIGNED_STATUS_MIN_CORRO;
                        update caseRecord;
                    } else {
                        Case erroneousCase = createNewErroneousCase(email, patternConfiguration);
                        message = createNewEmailMessage(email, erroneousCase.Id);
                        reparentDocuments(email, erroneousCase, GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE);
                    }
                    // 12/09/2017: Yogiraj Sarode for Req-102 Oct Release, Ends Here
	            }
	        } else {
	           Case newCase = createNewCase(email, patternConfiguration);
               message = createNewEmailMessage(email, newCase.Id);
	           reparentDocuments(email, newCase, null);
	        }
	        result.success = true;
    	}catch(Exception e) {
    		system.debug('---Exception Signed Response/Regular Case---' + e.getMessage() + '--LINE--' + e.getLineNumber());
    		result.success = false;
    		result.message = 'Error occured while processing the email.';
    	}
        return result;
    }
}