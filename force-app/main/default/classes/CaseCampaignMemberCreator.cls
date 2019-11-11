/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class is responsible for processing the Campaign emails. 
               This class will create a case of the type Campaign Member
History 
<Date>         <Authors Name>     <Brief Description of Change>
14/07/2015     Manish Damle       Created
-------------------------------------------------------------------------------------*/
public class CaseCampaignMemberCreator extends EmailsWithScannedDocumentsProcessor {
	public override Messaging.InboundEmailResult process(Messaging.InboundEmail email, 
    												     Messaging.InboundEnvelope envelope, 
    												     EmailSubjectPatternConfiguration__c patternConfiguration) {
    	system.debug('---Campaign Member Processing---');
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        EmailMessage message;
        Case caseRecord;
        try {
	        Case newCase = createNewCase(email, patternConfiguration);
            message = createNewEmailMessage(email, newCase.Id);
	        reparentDocuments(email, newCase, null);
	        result.success = true;
    	}catch(Exception e) {
    		system.debug('---Exception Campaign Member---' + e.getMessage() + '--LINE--' + e.getLineNumber());
    		result.success = false;
    		result.message = 'Error occured while processing the email.';
    	}
        return result;
    }
}