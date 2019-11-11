/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus Technology Partners
Description:   Update or insert contact based on contact id populated in the staging record.

History
16/06/2017      Pawan Tiwari         Created.
------------------------------------------------------------*/
public with sharing class UpsertContactHandler {

    List<BU_Staging__c> stagingContactDetails = new List<BU_Staging__c>();
    Map<String,Contact> contactMap;
    Map<String,String> stagingObjectToContactMapping = new Map<String,String>();
    String fieldNames = null;

    public UpsertContactHandler(List<BU_Staging__c> stagingContactDetails) {
        
        this.stagingContactDetails = stagingContactDetails;
        contactMap = new Map<String,Contact>();
        stagingObjectToContactMapping = MappingRecord.stagingObjectToContactMapping;
    
   }

    // get staging id vs contact id map with new contact and update contact
    public Map<String,String> exceute(){
        Map<String,String> getCreateContactMap = createContact();
        Map<String,String> getUpdateContactMap = updateContact();

        System.debug('getCreateContactMap :: ' + getCreateContactMap);
        System.debug('getUpdateContactMap :: ' + getUpdateContactMap);
        
        for(String tempContactId : getCreateContactMap.keySet()){
            if(!getUpdateContactMap.containsKey(tempContactId))
                getUpdateContactMap.put(tempContactId,getCreateContactMap.get(tempContactId));
        }
        System.debug('Final getUpdateContactMap :: ' + getUpdateContactMap);
        return getUpdateContactMap;
    }

    // Get existing contact details
    @TestVisible
    private Map<String,Contact> getExistingContact(){

        Set<String> contactIdSet = new Set<String>();

        for( BU_Staging__c stagingRecord : stagingContactDetails){
            if(stagingRecord.Contact_Id__c != null && stagingRecord.Processing_Status__c != GlobalConstants.FAILED_PROCESSING_STATUS){
                if(!contactIdSet.contains(stagingRecord.Contact_Id__c))
                    contactIdSet.add(stagingRecord.Contact_Id__c);
            }
        }
        System.debug('Mapping Contact :: ' + MappingRecord.contactFieldNames );
        String soqlQuery = 'select '+MappingRecord.contactFieldNames+' FROM Contact WHERE Id IN :contactIdSet';
        System.debug('soqlQuery :: ' + soqlQuery);
        List<Contact> existingContactList = Database.Query(soqlQuery);

        System.debug('existingContactList :: ' + existingContactList);
        Map<String,Contact> existingContactMap = new Map<String,Contact>();

        if(existingContactList.size() > 0){
            for(Contact tempContact : existingContactList){
                existingContactMap.put(tempContact.Id,tempContact);
            }
        }

        System.debug('existingContactMap :: ' + existingContactMap);
        return existingContactMap;

    }

    // update contact when contact id is populated in the csv upload template
    @TestVisible
    private Map<String,String> updateContact(){
       
        Map<String,Contact> existingContactDetails = getExistingContact();
        Map<String,String> contactVsStagingIdMap = new Map<String,String>();
        Map<String,Contact> contactMapToBeUpdated = new Map<String,Contact>();
        Map<String,String> stagingIdVsContactId = new Map<String,String>();
        List<BU_Staging__c> stagingRecordsToBeUpdated = new List<BU_Staging__c>();
        List<Contact> contactToBeUpdatedList = new List<Contact>();  
        Map<String,BU_Staging__c> stagingMapToBeUpdate = new Map<String,BU_Staging__c>();
        
        for( BU_Staging__c stagingRecord : stagingContactDetails){
            Boolean needToUpdate = false;  
            System.debug('existingContactDetails :: ' + existingContactDetails);
            System.debug('Staging record :: ' + stagingRecord);
            Contact existingContact = null;
            if(stagingRecord.Contact_Id__c != null && stagingRecord.Processing_Status__c != GlobalConstants.FAILED_PROCESSING_STATUS ){
                if(existingContactDetails.containsKey(stagingRecord.Contact_Id__c))
                    existingContact = existingContactDetails.get(stagingRecord.Contact_Id__c);

                system.debug('Existing Contact :: ' + existingContact);    
                if(existingContact != null){
                    for(String stagingApiName : stagingObjectToContactMapping.keySet()){
                
                        String stagingField = stagingApiName;
                        String SFField = stagingObjectToContactMapping.get(stagingApiName);
                        String fieldValue = String.valueOf(stagingRecord.get(stagingField));
                        system.debug('SFField :: ' + SFField + '--' + fieldValue );
                        if(SFField != null && SFField != ''){
                            if(String.isNotEmpty(fieldValue)){
                                needToUpdate = true;
                                existingContact.put(SFField,fieldValue);
                            }
                        }
                       System.debug('existingContact after :: ' + existingContact);
                             
                    } 
                    System.debug('needToUpdate :: ' + needToUpdate);
                    // Check if contact need to be updated (only if any field is populated apart from Contact Id)
                    if(needToUpdate == true){
                        if(!contactMapToBeUpdated.containsKey(existingContact.Id)){
                            contactToBeUpdatedList.add(existingContact);
                        }
                        System.debug('existingContact after :: ' + existingContact);
                        
                        contactMapToBeUpdated.put(existingContact.Id,existingContact);
                        contactVsStagingIdMap.put(existingContact.Id,stagingRecord.Id);
                        
                    }
                    stagingIdVsContactId.put(stagingRecord.Id,existingContact.Id);
                      
                }
            }
        }

        System.debug('contactMapToBeUpdated :: ' + contactMapToBeUpdated);
        System.debug('contactVsStagingIdMap :: ' + contactVsStagingIdMap);
        System.debug('stagingIdVsContactId :: ' + stagingIdVsContactId);
        
        
        
        if(contactMapToBeUpdated.size() > 0 ){
            Database.SaveResult[] updateResult = Database.update(contactToBeUpdatedList, false);
            
            // Iterate over the update result in sequence
            for(Integer i = 0; i < updateResult.size(); i++) {
               // Operation was successfull 
               if (updateResult.get(i).isSuccess()){
                    System.debug('Sucess Result :: ' + updateResult.get(i).getId());
                    if(contactVsStagingIdMap.containsKey(updateResult.get(i).getId())){
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = contactVsStagingIdMap.get(updateResult.get(i).getId());
                        stagingToBeUpdated.Contact__c = updateResult.get(i).getId();
                        stagingToBeUpdated.Contact_Id__c = updateResult.get(i).getId();
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                        stagingMapToBeUpdate.put(stagingToBeUpdated.Id,stagingToBeUpdated);
                       
                    }
                }else if (!updateResult.get(i).isSuccess()){ // DML operation failed
                    
                    Database.Error error = updateResult.get(i).getErrors().get(0);
                    String failedDML = error.getMessage();
                    system.debug('Failed ID :: '+contactToBeUpdatedList.get(i).Id);

                    if(contactVsStagingIdMap.containsKey(contactToBeUpdatedList.get(i).Id)){
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = contactVsStagingIdMap.get(contactToBeUpdatedList.get(i).Id);
                        stagingToBeUpdated.Contact__c = contactToBeUpdatedList.get(i).Id;
                        stagingToBeUpdated.Contact_Id__c = contactToBeUpdatedList.get(i).Id;
                        if(stagingToBeUpdated.Failure_Reason__c == null)
                            stagingToBeUpdated.Failure_Reason__c = error.getMessage()+'\r\n';
                        else
                            stagingToBeUpdated.Failure_Reason__c += error.getMessage()+'\r\n';
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.FAILED_PROCESSING_STATUS;
                        stagingMapToBeUpdate.put(stagingToBeUpdated.Id,stagingToBeUpdated);
                    }
                 } 
            }

            System.debug('stagingRecordsToBeUpdated :: ' + stagingMapToBeUpdate);
            if(stagingMapToBeUpdate.size() > 0)
                update stagingMapToBeUpdate.values();

        }
        System.debug('stagingIdVsContactId :: ' + stagingIdVsContactId);
        
        return stagingIdVsContactId;
        
    }

    /* Create a new contact if contact id is not populated
    * If contact is found with the full match i.e 100% contact matching rule the
    * get the id of the contact and update on the staging record
    */
    @TestVisible
    private Map<String,String> createContact(){

        // store final inserted contact with staging record id
        Map<String,String> stagingIdVsContactId = new Map<String,String>();
        Map<String,Contact> contactMapToBeInserted = new Map<String,Contact>();
        // store case number with contact id of the new inserted
        Map<String,String> caseNumberVsContactIdMap = new Map<String,String>();
        // used to store staging record needs to be updated for case id
        Map<String,BU_Staging__c> stagingMapToBeUpdate = new Map<String,BU_Staging__c>();
        Map<String,Contact> updatedContact = new Map<String,Contact>();
        Set<Id> uniqueContactId = new Set<Id>();
        Map<String,String> contactVsStagingId = new Map<String,String>();
        Map<String,String> contactIdVsUniqueKey = new Map<String,String>();
        Map<String,List<BU_Staging__c>> contactKeyVsStaging = new Map<String,List<BU_Staging__c>>();
        Map<String, FullMatchDuplicateContactRules__c> fullMatchConfidenceRules = FullMatchDuplicateContactRules__c.getAll();
        String errMsg = '';
              
        List<Contact> newContactList = new List<Contact>();
        List<Contact> updateContactList = new List<Contact>();
        Contact hundredPercentMatchContact = null;
        List<Contact> contactToBeInserted = new List<Contact>();
        
        Map<String,List<BU_Staging__c>> contactIdVsStagingIdMap = new Map<String,List<BU_Staging__c>>();
        
        Map<BU_Staging__c,String> stagingVsContactIdMap = new Map<BU_Staging__c,String>();

        // Iterate over the staging records
        for( BU_Staging__c stagingRecord : stagingContactDetails){
            Boolean needToCreate = false;
            Contact newContact = new Contact();
            System.debug('stagingRecord r :: ' + stagingRecord);
            // Start processing only if Processing status is not Failed.
            if(stagingRecord.Contact_Id__c == null && stagingRecord.Processing_Status__c != GlobalConstants.FAILED_PROCESSING_STATUS ){
                for(String stagingApiName : stagingObjectToContactMapping.keySet()){
                    String stagingField = stagingApiName;
                    String SFField = stagingObjectToContactMapping.get(stagingApiName);
                    String fieldValue = String.valueOf(stagingRecord.get(stagingField));

                    if(SFField != null && SFField != ''){
                        // create contact only if any contact field has value    
                        if(String.isNotEmpty(fieldValue)){
                            System.debug('Insert Contact fieldvalue ::' + fieldValue+'--'+SFField+'--'+stagingField);
                            needToCreate = true;
                            newContact.put(SFField,fieldValue);
                        }//end if
                    
                    }//end if
                }//end for
                System.debug('Contact needToCreate :: ' + needToCreate);
                // check if contact need to be created (only if fields are not blank)
                if(needToCreate == true){
                    newContact.put('RecordTypeId',MappingRecord.CUSTOMER.Id);
                    System.debug('** New Contact ** ' +'--'+newContact);
                    String uniqueKey = newContact.LastName+'-'+newContact.Email+'-'+newContact.Phone+'-'+newContact.HomePhone+'-'+newContact.MobilePhone;
                  
                    // store contact mapping with unique key. will be used to get the contact after the 100% matching rule                  
                    if(contactKeyVsStaging.containskey(uniqueKey.toUpperCase())){
                        contactKeyVsStaging.get(uniqueKey.toUpperCase()).add(stagingRecord);
                    } else {
                        newContactList.add(newContact);
                        contactKeyVsStaging.put(uniqueKey.toUpperCase(),new List<BU_Staging__c>{stagingRecord} );
                    }
                    

                }//end if
            }
        }

        System.debug('contactKeyVsStaging :: ' + contactKeyVsStaging);
        String contactId;
       
        // create contact only if newContactList size is greater than 0.
        if(newContactList.size() > 0){
            // Allow duplicate records to be saved (Not the hundread percent matching rule)
            Database.DMLOptions dmlOption = new Database.DMLOptions();
            dmlOption.DuplicateRuleHeader.AllowSave = true;
            dmlOption.DuplicateRuleHeader.runAsCurrentUser = false;

            // DML to insert the contact 
            Database.SaveResult[] insertResult = Database.insert(newContactList, dmlOption);
            System.debug('Contact List after insert :: ' + newContactList);

            
            // Iterate over the insert new contact result list
            for(Integer i = 0; i < insertResult.size(); i++) {

                if (insertResult.get(i).isSuccess()){ // NEW Contact : created and staging record need to be updated
                    System.debug('New Contact Success Result :: ' + insertResult.get(i).getId());
                    String matchContactUniqueKey = newContactList.get(i).LastName+'-'+newContactList.get(i).Email+'-'+newContactList.get(i).Phone+'-'+newContactList.get(i).HomePhone+'-'+newContactList.get(i).MobilePhone;
                    System.debug('matchContactUniqueKey :: ' + matchContactUniqueKey);
                    for(BU_Staging__c stagingRecord : contactKeyVsStaging.get(matchContactUniqueKey.toUpperCase())){
                        stagingIdVsContactId.put(stagingRecord.Id,insertResult.get(i).getId());
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = stagingRecord.Id;
                        stagingToBeUpdated.Contact_Id__c = insertResult.get(i).getId();
                        stagingToBeUpdated.Contact__c = insertResult.get(i).getId();
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                        
                        stagingMapToBeUpdate.put(stagingToBeUpdated.Id, stagingToBeUpdated);
                    }//end if
                }else if(!insertResult.get(i).isSuccess()){ // DML Failed : Contact not inserted
                    Database.Error error = insertResult.get(i).getErrors().get(0);
                    String failedDML = error.getMessage();
                    system.debug('New Failed Contact :: '+newContactList.get(i));

                    String matchContactUniqueKey = newContactList.get(i).LastName+'-'+newContactList.get(i).Email+'-'+newContactList.get(i).Phone+'-'+newContactList.get(i).HomePhone+'-'+newContactList.get(i).MobilePhone;
                    
                    if(error instanceof Database.DuplicateError) { // check if error is of duplicate record
                        Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                        // Return only match results of matching rules that find duplicate records
                        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                            
                        System.debug('Match Results are : '+matchResults);
                        System.debug('match result size: '+matchResults.size());
                        Datacloud.MatchResult firstMatchResult;
                        Boolean fullMatch = false;

                        for(Datacloud.MatchResult mResult : matchResults) {
                            if(fullMatch != true) {
                                //100% match 
                                if(fullMatchConfidenceRules != null && !fullMatchConfidenceRules.isEmpty()) {
            
                                    System.debug(fullMatchConfidenceRules+' '+fullMatchConfidenceRules.size());
                                    System.debug('Rule Name :: ' + mResult.getRule());
                                    if(fullMatchConfidenceRules.containsKey(mResult.getRule())) { // contact matching rule is 100% matching rule
                                        System.debug('full matchfound setting variable fullMatch to true.');
                                        fullMatch = true;
                                    }
                                }  
                                firstMatchResult = mResult; 
                            }
                        }// end for

                        //100% matching Contact
                        if(fullMatch == true) {
                            //Fetch the matching contact records from the first duplicate match result.
                            Datacloud.MatchResult matchResult = firstMatchResult;
                            Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                        
                            Map<String,Contact> duplicateContactMap = new Map<String,Contact>();
                            List<Contact> duplicateContacts = new List<Contact>();
                        
                            // Add matched contact to the duplicate contacts variable
                            System.debug('match results after finding matchRecord'+matchRecords);

                            for(Datacloud.MatchRecord matchRecord : matchRecords) {
                       
                                System.debug('Matched record details == '+matchRecord);
                                duplicateContacts.add((Contact) matchRecord.getRecord());
                           
                                System.debug('Adding to Duplicates');

                            }//end for

                            if(duplicateContacts.size() > 0){ // duplicate contact exist
                                hundredPercentMatchContact = duplicateContacts[0];
                                System.debug('Matched Contact details :: ' + hundredPercentMatchContact);
                                System.debug(' contactKeyVsStaging :: matchContactUniqueKey ' + contactKeyVsStaging +'--'+matchContactUniqueKey.toUpperCase() );
                                if(contactKeyVsStaging.containsKey(matchContactUniqueKey.toUpperCase())){
                                    //uniqueContactId.add(hundredPercentMatchContact.Id);
                                   if(contactIdVsStagingIdMap.containsKey(hundredPercentMatchContact.Id)) {
                                       contactIdVsStagingIdMap.get(hundredPercentMatchContact.Id).addAll(contactKeyVsStaging.get(matchContactUniqueKey.toUpperCase()));
                                   } else {
                                       if(contactKeyVsStaging.containsKey(matchContactUniqueKey.toUpperCase()) && contactKeyVsStaging.get(matchContactUniqueKey.toUpperCase()) != NULL &&
                                         contactKeyVsStaging.get(matchContactUniqueKey.toUpperCase()).size() > 0){
                                         System.debug('in Else : ' + contactKeyVsStaging );
                                            for(BU_Staging__c stagingRec : contactKeyVsStaging.get(matchContactUniqueKey.toUpperCase())){
                                                System.debug('In for :: ' + stagingRec);
                                                if(contactIdVsStagingIdMap.containsKey(hundredPercentMatchContact.Id))
                                                    contactIdVsStagingIdMap.get(hundredPercentMatchContact.Id).add(stagingRec);
                                                else
                                                    contactIdVsStagingIdMap.put(hundredPercentMatchContact.Id, new List<BU_Staging__c>{stagingRec}); 
 
                                            }
                                       }
                                         
                                   }
                               }

                            }//end if

                        }else { // not 100% contact match logic
                            // do nothing, contact will be inserted because of not 100% matching rule.
                        }// end if else

                    }else {// not duplicate error logic
                        System.debug('Not Duplicate Error :: ' + failedDML);
                        
                        //String matchContactUniqueness = newContactList.get(i).LastName+'-'+newContactList.get(i).Email+'-'+newContactList.get(i).Phone+'-'+newContactList.get(i).HomePhone+'-'+newContactList.get(i).MobilePhone;
                        //System.debug('matchContactUniqueness :: ' + matchContactUniqueness.toUpperCase() + contactKeyVsStaging +'--' + contactKeyVsStaging.containsKey(matchContactUniqueness.toUpperCase())  );
                       
                        for(BU_Staging__c stagingRecord : contactKeyVsStaging.get(matchContactUniqueKey.toUpperCase())){
                            BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                            stagingToBeUpdated.Id = stagingRecord.Id;
                            if(stagingToBeUpdated.Failure_Reason__c == null)
                                stagingToBeUpdated.Failure_Reason__c = error.getMessage()+'\r\n';
                            else
                                stagingToBeUpdated.Failure_Reason__c += error.getMessage()+'\r\n';
                            stagingToBeUpdated.Processing_Status__c = GlobalConstants.FAILED_PROCESSING_STATUS;
                            stagingMapToBeUpdate.put(stagingToBeUpdated.Id, stagingToBeUpdated);
                        }
                    
                    }
                }
            }//end for

        }

        System.debug('contactIdVsStagingIdMap :: ' + contactIdVsStagingIdMap);
		
        for(Contact con : [Select Id,Formal_Salutation__c,FirstName,LastName,HomePhone,MobilePhone,Phone,
                              Email,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry 
                              FROM Contact
                              WHERE Id IN: contactIdVsStagingIdMap.keyset() ]){
            Boolean needToBeUpdated = false;
            System.debug('Conact update after match :: ' + con);

            String matchContactUniqueKey = con.LastName+'-'+con.Email+'-'+con.Phone+'-'+con.HomePhone+'-'+con.MobilePhone;
            System.debug('After matchContactUniqueKey :: ' + contactIdVsStagingIdMap.containsKey(con.Id));

            if(contactIdVsStagingIdMap.containsKey(con.Id)){
                //stagingRecord = contactIdVsStagingIdMap.get(con.Id);
                for(BU_Staging__c stagingRecord : contactIdVsStagingIdMap.get(con.Id)){
                    System.debug('Staging record :: ' + stagingRecord);
                    System.debug('stagingObjectToContactMapping :: ' + stagingObjectToContactMapping);  
                    for(String stagingApiName : stagingObjectToContactMapping.keySet()){
                        
                        String stagingField = stagingApiName;
                        String SFField = stagingObjectToContactMapping.get(stagingApiName);
                        String fieldValue = String.valueOf(stagingRecord.get(stagingField));
                        String contactFieldValue = String.valueOf(con.get(SFField));
                        
                        System.debug('Field Value :: ' + fieldValue + '--' + contactFieldValue);
                        if(String.isNotEmpty(fieldValue) && (fieldValue != contactFieldValue)){
                            needToBeUpdated = true;  
                            con.put(SFField,fieldValue);
                        }
                    } 
                }
                

                if(needToBeUpdated == true){
                    
                    System.debug('Updated Contact :: ' + con );
                    if(!updatedContact.containsKey(con.Id)){
                        updatedContact.put(con.Id,con);
                        updateContactList.add(con);
                    }
              
                }else{// update staging record with existing contact with the full match contact id
                    for(BU_Staging__c stagingRecord : contactIdVsStagingIdMap.get(con.Id)){
                        stagingIdVsContactId.put(stagingRecord.Id,con.Id);
                        
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = stagingRecord.Id;
                        stagingToBeUpdated.Contact_Id__c = con.Id;
                        stagingToBeUpdated.Contact__c = con.Id;
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                        
                        stagingMapToBeUpdate.put(stagingToBeUpdated.Id, stagingToBeUpdated);
                    }
                }
            }
        }

        System.debug('Updated Contact list :: ' + updateContactList );  

        if(updateContactList.size() > 0){

            Database.DMLOptions contactDmlOption = new Database.DMLOptions();
            contactDmlOption.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult[] matchedContacts = Database.update(updateContactList, contactDmlOption);
    
            for(Integer i=0;i<matchedContacts.size();i++){
                if (matchedContacts.get(i).isSuccess()){
                    system.debug('Success matchedContacts :: ' + matchedContacts.get(i).getId());
                    for(BU_Staging__c stagingRecord : contactIdVsStagingIdMap.get(matchedContacts.get(i).getId())){
                        stagingIdVsContactId.put(stagingRecord.Id,matchedContacts.get(i).getId());
                        
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = stagingRecord.Id;
                        stagingToBeUpdated.Contact_Id__c = matchedContacts.get(i).getId();
                        stagingToBeUpdated.Contact__c = matchedContacts.get(i).getId();
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                        
                        stagingMapToBeUpdate.put(stagingToBeUpdated.Id, stagingToBeUpdated);
                    }
                  
                }else if (!matchedContacts.get(i).isSuccess()){
                    // DML operation failed
                    Database.Error error = matchedContacts.get(i).getErrors().get(0);
                    String failedDML = error.getMessage();
                    system.debug('Failed ID'+updateContactList.get(i).Id);
                    for(BU_Staging__c stagingRecord : contactIdVsStagingIdMap.get(updateContactList.get(i).Id)){
                        stagingIdVsContactId.put(stagingRecord.Id,updateContactList.get(i).Id);
                        
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = stagingRecord.Id;                        
                        stagingToBeUpdated.Contact_Id__c = updateContactList.get(i).Id;
                        stagingToBeUpdated.Contact__c = updateContactList.get(i).Id;
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.FAILED_PROCESSING_STATUS;
                        
                        stagingMapToBeUpdate.put(stagingToBeUpdated.Id, stagingToBeUpdated);
                    }
                }
            }
            System.debug('matchedContacts :: ' + matchedContacts);
        }

        if(stagingMapToBeUpdate.size() > 0)
            update stagingMapToBeUpdate.values();

        System.debug('stagingMapToBeUpdate :: ' + stagingMapToBeUpdate);  
        System.debug('stagingIdVsContactId :: ' + stagingIdVsContactId);    

        return stagingIdVsContactId;    
        
    }
    
}