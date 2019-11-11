public class ContactCreator {
    
    private Contact contactDetails;
    public List<Contact> duplicateContacts;
    private Boolean highConfidenceMatch;
    private Map<String, HighConfidenceDuplicateContactRules__c> highConfidenceRules;
    private Map<String, FullMatchDuplicateContactRules__c> fullMatchConfidenceRules; //100% Match Rule
    public Boolean FullMatch = false;
    
    public ContactCreator(Contact contactDetails) {
        if(contactDetails == null) {
            throw new InvalidParameterException('Failed to instantiate ContactCreator. Contact details missing');
        }
        this.contactDetails = contactDetails;
        this.duplicateContacts = new List<Contact>();
        this.highConfidenceMatch = false;
        fullMatchConfidenceRules = FullMatchDuplicateContactRules__c.getAll();
        if(!String.isBlank(contactDetails.Phone)){
            contactDetails.HomePhone = contactDetails.Phone;
            contactDetails.MobilePhone = contactDetails.Phone;
            contactDetails.Other_Phone__c = contactDetails.Phone;
        }else if(!String.isBlank(contactDetails.MobilePhone)){
            contactDetails.HomePhone = contactDetails.MobilePhone;
            contactDetails.Phone = contactDetails.MobilePhone;
            contactDetails.Other_Phone__c = contactDetails.MobilePhone;
        }else if(!String.isBlank(contactDetails.HomePhone)){
            contactDetails.MobilePhone = contactDetails.HomePhone;
            contactDetails.Phone = contactDetails.HomePhone;
            contactDetails.Other_Phone__c = contactDetails.HomePhone;
        }else if(!String.isBlank(contactDetails.Other_Phone__c)){
            contactDetails.HomePhone = contactDetails.Other_Phone__c;
            contactDetails.Phone = contactDetails.Other_Phone__c;
            contactDetails.MobilePhone = contactDetails.Other_Phone__c;
        }
    }
    
    public Boolean isHighConfidenceMatch() {
        System.debug('Is high: ' + highConfidenceMatch);
        return this.highConfidenceMatch;
    }    
    
    public List<Contact> getDuplicateContacts() {
        return this.duplicateContacts;
    }
    
    private void checkForFullMatch(String ruleName) {
        System.debug('Rule Name to be checked for 100% Match: ' + ruleName);
        if(fullMatchConfidenceRules != null && !fullMatchConfidenceRules.isEmpty()) {
            System.debug(fullMatchConfidenceRules+' '+fullMatchConfidenceRules.size());
            if(fullMatchConfidenceRules.containsKey(ruleName)) {
                System.debug('full matchfound setting variable fullMatch to true.');
                this.FullMatch = true;
            }
        }        
    }
    
    public Id createContact() {
        System.debug('Inside contactcreator');
        Id contactId = null;
        Database.DMLOptions dmlOption = new Database.DMLOptions();
        dmlOption.DuplicateRuleHeader.AllowSave = false;
        //dmlOption.DuplicateRuleHeader.AllowSave = true;
        System.debug('contactDetails before dml: '+contactDetails);
        Database.SaveResult result = Database.insert(contactDetails, dmlOption);
        System.debug('after database dml operation.');
        if (!result.isSuccess()) {
            System.debug(':error:');
            for (Database.Error error : result.getErrors()) {
                System.debug('databaseError');                
                if (error instanceof Database.DuplicateError) {
                    Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                    Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                    System.debug('instanceof DuplicateError');
                    // Return only match results of matching rules that find duplicate records
                    Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                    System.debug('Match Results are : '+matchResults);
                    System.debug('match result size: '+matchResults.size());
                    Datacloud.MatchResult firstMatchResult;
                    for(Datacloud.MatchResult mResult : matchResults) {
                        if(this.FullMatch != true){
                            checkForFullMatch(mResult.getRule());    //100% match
                            firstMatchResult = mResult;
                        }
                    }
                    if(this.FullMatch == true){
                        //Fetch the matching contact records from the first duplicate match result.
                        Datacloud.MatchResult matchResult = firstMatchResult;
                        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                        
                        // Add matched contact to the duplicate contacts variable
                        System.debug('match results after finding matchRecord'+matchRecords);
                        for (Datacloud.MatchRecord matchRecord : matchRecords) {
                            System.debug('Matched record details == '+matchRecord);
                            this.duplicateContacts.add((Contact) matchRecord.getRecord());
                            //updateMatchedRecord((Contact) matchRecord.getRecord());
                            System.debug('Adding to Duplicates');
                            contactId = this.duplicateContacts[0].id;
                            System.debug('Found matching contact '+this.duplicateContacts[0].id);
                        }

                    } else{
                        Database.DMLOptions dmlOpt = new Database.DMLOptions();
                        dmlOpt.DuplicateRuleHeader.AllowSave = true;
                        Database.SaveResult newResult = Database.insert(contactDetails, dmlOpt);
                        contactId = newResult.getId();
                        System.debug('Full match not found. Inserting a new contact.');
                    }
                } else {
                    System.debug('Some different error than Duplicate Rules error has occured');
                    System.debug(LoggingLevel.ERROR, error);
                    throw new InvalidParameterException(error.getMessage());
                }
            }
        } else {
            System.debug('Result contact: ' + result.getId());
            contactId = result.getId();
            System.debug('contactId: ' + contactId);
        }
        System.debug('Final contactId: ' + contactId);
        return contactId;
    }
    
    public class InvalidParameterException extends Exception{}
}