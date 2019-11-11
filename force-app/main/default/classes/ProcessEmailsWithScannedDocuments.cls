/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class  will process the Emails with scanned  documents to attach them 
               to appropriate case if not found then it will create new case record.

Test Class:    ProcessEmailsWithScannedDocuments_Test
History
10/04/2015     Manish Damle       Created
-----------------------------------------------------------------------------------*/
public with sharing class ProcessEmailsWithScannedDocuments {
	
	
	/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will filter out the EmailMessages with 
                   Subject having words "Scanned Email" (<- Configurable in custom settings). 
                   which will be sent by Saff members. 
                   This will extract the case ref. number from the subject and 
                   check for an existing case; if found then attach that message to existing case.
                   If not found then E2C processing will create new case and attach
                   the message to that case except for the amendments
    Inputs:        InboundEmail, InboundEnvelope
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    10/04/2015     Manish Damle       Created
    11/06/2015     Brett Cawrse       Changes to reference CanNumber rather than custom Case #
    13/07/2015     Manish Damle       Amendment  Amendment_Triaged__c and Amendment_Count__c added
                                      For Amendment if no case found send error message to sender
    -----------------------------------------------------------------------------------*/
	public Messaging.InboundEmailResult processEmails(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		SavePoint sp = Database.setSavepoint();
		try {
			//Get the pattern from the custom settings 
	        EmailSubjectPatternConfiguration__c patternConfiguration = getEmailSubjectPatternConfiguration(email); 
            if(patternConfiguration.HandlerClass__c == null || patternConfiguration.HandlerClass__c == '')  {
                result.success = false;
                result.message = 'Configuration Error.';
                return result;
            }
            
            Type t = Type.forName(patternConfiguration.HandlerClass__c);
            EmailsWithScannedDocumentsProcessor processor = (EmailsWithScannedDocumentsProcessor) t.newInstance();
			result = processor.process(email, envelope, patternConfiguration);                
		}catch(Exception e) {
			system.debug('----Exception---Inbound Email Service--' + e.getMessage() + '--Line--' + e.getLineNumber());
            result.success = false;
    		result.message = 'Error occured while processing the email.';
		}
		return result;
	}
    
    /*-----------------------------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   This Method will return custom setting depending upon the email toAddress.
    Inputs:        Email
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    11/05/2015     Vishnu Belkone       Created
    -------------------------------------------------------------------------------------*/
    private EmailSubjectPatternConfiguration__c getEmailSubjectPatternConfiguration(Messaging.InboundEmail email){
        EmailSubjectPatternConfiguration__c pattern;
        List<EmailSubjectPatternConfiguration__c> emailSubjectPatterns  =EmailSubjectPatternConfiguration__c.getall().values();
     	Set <String> toAddressSet;
        for(EmailSubjectPatternConfiguration__c subPattern : emailSubjectPatterns){
            toAddressSet = new Set<String>(subPattern.ToAddress__c.split(','));
            system.debug('-----Patten Matching Email To Address-------' + toAddressSet);
            if(toAddressSet.contains(email.toAddresses[0])){
                pattern = subPattern; 
                system.debug('---To Address From Email---' + email.toAddresses + '--Email To From Custom settings--' + subPattern.ToAddress__c + '--Configured Pattern--' + pattern);
            }           
        }        
        return pattern;        
    }
}