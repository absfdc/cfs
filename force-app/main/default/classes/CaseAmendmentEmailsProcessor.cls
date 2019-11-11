/*----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class is responsible for processing the amendment related emails from the Scanner.
			   If case not found then create new case with erroneous Case record type and assign to erroneous Cases Queue.
History 
<Date>         <Authors Name>     <Brief Description of Change>
14/07/2015     Manish Damle       Created
27/09/2017     Arxxus			  create erroneous case for non mincorro cases 
-------------------------------------------------------------------------------------*/
public class CaseAmendmentEmailsProcessor extends EmailsWithScannedDocumentsProcessor{ 
    public override Messaging.InboundEmailResult process(Messaging.InboundEmail email, 
    												     Messaging.InboundEnvelope envelope, 
    												     EmailSubjectPatternConfiguration__c patternConfiguration) {
    	system.debug('---Amendment Processing---');
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        EmailMessage message;
        Case caseRecord;
        
        try {
	        String refNo = extractCaseRefNumberFromSubject(email.subject, patternConfiguration.Prefix__c, patternConfiguration.Suffix__c);
		    system.debug('---Subject---' + email.Subject + '----Extracted Ref Number----' + refNo);
	        if(refNo != null) {
	            caseRecord = fetchCaseDetails(refNo);
	            if(caseRecord == null || caseRecord.Status == GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO || caseRecord.Status == GlobalConstants.CASE_NRR_STATUS_MIN_CORRO) {//SFCOE - 59 fix - Dec '16
	            	Case erroneousCase = createNewErroneousCaseForAmendments(email, patternConfiguration);
                    message = createNewEmailMessage(email, erroneousCase.Id);
	            	reparentDocuments(email, erroneousCase, GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT);
	            } else {//Case Record Found
                    if(caseRecord.IsMinCorroCase__c == TRUE) {
                        message = createNewEmailMessage(email, caseRecord.Id);
                        reparentDocuments(email, caseRecord, GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT);
                        caseRecord.Amendment_Count__c = caseRecord.Amendment_Count__c == null ? 1 : caseRecord.Amendment_Count__c + 1;
                        caseRecord.Amendment__c = true;
                        caseRecord.Amendment_Triaged__c = false; //(WI-0001055)
                        update caseRecord;
                    } else {
                        Case erroneousCase = createNewErroneousCaseForAmendments(email, patternConfiguration);
                        message = createNewEmailMessage(email, erroneousCase.Id);
                        reparentDocuments(email, erroneousCase, GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT);
                    }	            		
	            }
	        } else {
	           Case erroneousCase = createNewErroneousCaseForAmendments(email, patternConfiguration);
               message = createNewEmailMessage(email, erroneousCase.Id);
	           reparentDocuments(email, erroneousCase, GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT);
	        }

	        result.success = true;
    	}catch(Exception e) {
    		system.debug('---Exception Amendment---' + e.getMessage() + '--LINE--' + e.getLineNumber());
    		result.success = false;
    		result.message = 'Error occured while processing the email.';
    	}
        return result;
    }
}