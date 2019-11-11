/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    utility class for creating contact associated with cases created from webform.
Inputs:         "caseRecord" - instance of case which needs to be associated with contact
                "contactPerson" instance of contact record to be associated with case
                "salesforceBaseUrl" salesforce base url that can be used to access contacts directly if appended with contact id
Test Class:     WebToCaseContactCreator_Test
History:
------------------------------------------------------------*/
public class WebToCaseContactCreator {

    private Case caseRecord;
    private Contact contactPerson;
    private String salesforceBaseUrl;
    
    public WebToCaseContactCreator(Case caseRecord, Contact contactPerson, String salesforceBaseUrl) {
        if(caseRecord == null || contactPerson == null) {
            throw new InvalidParameterException('Failed to create contact. Either case or contact details missing');
        }
        this.caseRecord = caseRecord;
        this.contactPerson = contactPerson;
        //adding input phone from web to all phone fields
        this.salesforceBaseUrl = salesforceBaseUrl;
    }
    
    public WebToCaseContactCreator(){
        
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Salesforce.com
    Description:    Function creates new contact and associates with the case. 
                    If duplicate contacts are found in the org then link to those duplicate contacts are stamped on case
    Inputs:         
    Returns:        
    History:
    ------------------------------------------------------------*/
    public void createContact() {        
        ContactCreator creator = new ContactCreator(contactPerson);
        Id contactId = creator.createContact();
        if(creator.FullMatch == true){
            updateMatchedRecord(creator.duplicateContacts[0]);
        }
        resetWebContactPhoneFields(contactId);
        //returned result will be null in case contact insertion failed
        if(contactId == null) {
            //check if insertion failed due to possible duplicates.
            //System.debug('Is highconfidence: ' + creator.isHighConfidenceMatch());
            //System.debug('Duplicate contact count: ' + creator.getDuplicateContacts().size());
            //if(!creator.getDuplicateContacts().isEmpty()) {
            //    updateCaseForPossibleDuplicateContact(creator.getDuplicateContacts());                
            //}
        } else {
            caseRecord.contactid = contactId;
        }
        update caseRecord;  
    }
       
    /*private void updateCaseForPossibleDuplicateContact(List<Contact> matchingContacts) {        
        caseRecord.Potential_duplicate_contacts__c = true;
        String potentialDupContacts = '';
        if(matchingContacts.size() > Integer.valueOf(Label.MaxDuplicateContactsOnCase)) {
            for(Integer index = matchingContacts.size(); index > Integer.valueOf(Label.MaxDuplicateContactsOnCase); index--) {
                matchingContacts.remove(index - 1);
            }
        }
        
        for(Contact conRec : matchingContacts) {            
            potentialDupContacts = potentialDupContacts + conRec.Name 
                + ' https://' + salesforceBaseUrl + '/ui/support/servicedesk/ServiceDeskPage#/' + conRec.Id + ' \n';
        }
        caseRecord.Potential_duplicates__c = potentialDupContacts;        
    }
	*/    
    /*private void updateCaseForSingleMatchingContact(Contact matchingContact) {
        matchingContact.FirstName = contactPerson.FirstName;
        matchingContact.LastName = contactPerson.LastName ;
        matchingContact.Phone = contactPerson.Phone ;
        matchingContact.Email = contactPerson.Email ;
        matchingContact.MailingStreet = contactPerson.MailingStreet ;
        matchingContact.MailingPostalCode = contactPerson.MailingPostalCode;
        matchingContact.MailingCity = contactPerson.MailingCity ;
        matchingContact.MailingState = contactPerson.MailingState ;
        matchingContact.MailingCountry = contactPerson.MailingCountry ;
        
        Database.DMLOptions dmlOption = new Database.DMLOptions(); 
        dmlOption.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult result = Database.update(matchingContact, dmlOption);
        caseRecord.contactId = matchingContact.Id;
    }*/


    public void resetWebContactPhoneFields(Id conId){
        List<Contact> cons = [SELECT Id, firstName, lastName, Phone, MobilePhone, HomePhone, Other_Phone__c,Normalized_Home_Phone__c, Normalized_Mobile__c,Normalized_Other_Phone__c, Normalized_Work_Phone__c 
                                FROM Contact 
                                WHERE Id =:conId];
        for(Contact con: cons){
            if(con.Normalized_Work_Phone__c == con.Normalized_Home_Phone__c)
                con.HomePhone = '';
            if(con.Normalized_Work_Phone__c == con.Normalized_Other_Phone__c)
                con.Other_Phone__c = '';
            if(con.Normalized_Work_Phone__c == con.Normalized_Mobile__c)
                con.MobilePhone = '';
        }
        Database.DMLOptions updateDmlOption = new Database.DMLOptions();
		updateDmlOption.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] matchedContactUpdateResults = Database.update(cons, updateDmlOption);
    }

	@TestVisible
    private void updateMatchedRecord(Contact matchedContact){
        System.debug('contactPerson details = '+contactPerson);
        System.debug('matchedContact details = '+matchedContact);

        if(String.isNotEmpty(contactPerson.FirstName)) matchedContact.FirstName = contactPerson.FirstName;
        if(String.isNotEmpty(contactPerson.LastName)) matchedContact.LastName = contactPerson.LastName;
        System.debug('Email in matched Contact : '+matchedContact.Email);
        
        if(matchedContact.Email == contactPerson.Email && String.isNotBlank(contactPerson.Phone)) {
            System.debug('Email is matched');
            //workphone set
            NormalizePhoneFieldHandler obj = new NormalizePhoneFieldHandler();
            String normalizedPhoneString = obj.normalizePhone((String)contactPerson.Phone);
            if(normalizedPhoneString != matchedContact.Normalized_Home_Phone__c &&
                normalizedPhoneString != matchedContact.Normalized_Mobile__c &&
                normalizedPhoneString != matchedContact.Normalized_Work_Phone__c &&
                normalizedPhoneString != matchedContact.Normalized_Other_Phone__c){
                    matchedContact.Phone = contactPerson.Phone;
                }

            /*if(contactPerson.Phone != matchedContact.MobilePhone && 
               contactPerson.Phone != matchedContact.Other_Phone__c &&
               contactPerson.Phone != matchedContact.Phone &&
               contactPerson.Phone != matchedContact.HomePhone){
                    matchedContact.Phone = contactPerson.Phone;
                }*/

                System.debug('matchedContact mobile = '+matchedContact.MobilePhone);
                System.debug('matchedContact Work Phone = '+matchedContact.Phone);
        } else {
            System.debug('Email not matched');
            if(String.isNotEmpty(contactPerson.Email)) matchedContact.Email = contactPerson.Email;
        }
    
        if(String.isNotEmpty(contactPerson.MailingStreet)) matchedContact.MailingStreet = contactPerson.MailingStreet;
        if(String.isNotEmpty(contactPerson.MailingCity)) matchedContact.MailingCity = contactPerson.MailingCity;
        if(String.isNotEmpty(contactPerson.MailingState)) matchedContact.MailingState = contactPerson.MailingState;
        if(String.isNotEmpty(contactPerson.MailingPostalCode)) matchedContact.MailingPostalCode = contactPerson.MailingPostalCode;
        if(String.isNotEmpty(contactPerson.MailingCountry)) matchedContact.MailingCountry = contactPerson.MailingCountry;

        Database.DMLOptions updateDmlOption = new Database.DMLOptions();
        updateDmlOption.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult matchedContactUpdateResults = Database.update(matchedContact, updateDmlOption);                 
    }
        
    public class InvalidParameterException extends Exception {}
}