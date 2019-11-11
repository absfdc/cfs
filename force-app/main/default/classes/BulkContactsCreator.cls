/*------------------------------------------------------------
Author:         Gary Bakshi
Company:        Salesforce Practice, Transport for NSW
Description:    Bulkified version of Contact Creator class, 
primarily intended  by Feedback Assist Project
Inputs:         This bulkified class expects a Map of Case 
records and their corresponding Contact records (that needs to 
be inserted or updated). Contact records in the input map are
expected to have name, phone and email values set on them.
Test Class:     BulkContactsCreator_Test
History:
------------------------------------------------------------*/
public class BulkContactsCreator {
    
    private Map<String, Contact> updatedContactDetails;
    private Map<String, HighConfidenceDuplicateContactRules__c> highConfidenceRules;
    private static Map<String, FullMatchDuplicateContactRules__c> fullMatchConfidenceRules; //100% Match Rule
    private Map<String, List<String>> intermediateContactsMap;
    
    public BulkContactsCreator(){}
    
    public BulkContactsCreator(Map<String, Contact> caseNumbersVsContactDetails){}
    
    public Map<String, Id> createContactMaps(Map<String, Contact> caseNumbersVsContactDetails) {
        String newKey = '';
        String normalizedPhoneString = '';
        String numberNormalised = '';
        NormalizePhoneFieldHandler obj = new NormalizePhoneFieldHandler();
        
        if(caseNumbersVsContactDetails.size() <1) {
            throw new InvalidParameterException('Failed to instantiate BulkContactsCreator. Contact details missing');
        }
        
        fullMatchConfidenceRules = FullMatchDuplicateContactRules__c.getAll();
        
        //As we are Bulk inserting Contacts, we need a mechanism to be able to map back to the original CaseNumbers
        intermediateContactsMap = new Map<String, List<String>>();
        
        for(String caseNumber : caseNumbersVsContactDetails.keySet()){
            Contact contactDetail = new Contact();
            contactDetail = caseNumbersVsContactDetails.get(caseNumber);
            
            if(!String.isBlank(contactDetail.Phone)){
                normalizedPhoneString = obj.normalizePhone((String)contactDetail.Phone);
                contactDetail.HomePhone = normalizedPhoneString;
                contactDetail.MobilePhone = normalizedPhoneString;
                contactDetail.Other_Phone__c = normalizedPhoneString;
            }else if(!String.isBlank(contactDetail.MobilePhone)){
                normalizedPhoneString = obj.normalizePhone((String)contactDetail.MobilePhone);
                contactDetail.HomePhone = normalizedPhoneString;
                contactDetail.Phone = normalizedPhoneString;
                contactDetail.Other_Phone__c = normalizedPhoneString;
            }else if(!String.isBlank(contactDetail.HomePhone)){
                normalizedPhoneString = obj.normalizePhone((String)contactDetail.HomePhone);
                contactDetail.MobilePhone = normalizedPhoneString;
                contactDetail.Phone = normalizedPhoneString;
                contactDetail.Other_Phone__c = normalizedPhoneString;
            }else if(!String.isBlank(contactDetail.Other_Phone__c)){
                normalizedPhoneString = obj.normalizePhone((String)contactDetail.Other_Phone__c);
                contactDetail.HomePhone = normalizedPhoneString;
                contactDetail.Phone = normalizedPhoneString;
                contactDetail.MobilePhone = normalizedPhoneString;
            }
            caseNumbersVsContactDetails.put(caseNumber, contactDetail);
            System.debug('contactDetail: ' + contactDetail);
        }//end of for loop
        
        Contact aContact = new Contact();
        String contactFirstName = '';
        String contactEmail = '';
        String contactPhone = '';
        
        System.debug('Constructing the intermediate map...');
        for(String acaseNumber : caseNumbersVsContactDetails.keySet()){
            aContact = caseNumbersVsContactDetails.get(acaseNumber);
            
            if(aContact.Phone!=null)
                contactPhone = aContact.Phone;
            
            if(contactPhone.length() > 1)
                contactPhone = contactPhone.substring(contactPhone.length()-3,contactPhone.length());
            contactFirstName = aContact.FirstName!=null?aContact.FirstName:'';
            contactEmail = aContact.Email!=null?aContact.Email:'';
            
            newKey = contactFirstName + '-' + aContact.LastName + '-' + contactEmail + '-' + contactPhone;
            
            System.debug('newKey: ' + newKey + ' acaseNumber: ' + acaseNumber);
            if(!intermediateContactsMap.containsKey(newKey)){
                List<String> newKeyCases = new List<String>();
                newKeyCases.add(acaseNumber);
                intermediateContactsMap.put(newKey, newKeyCases);
            } else {
                List<String> caseNumbersForNewKey = intermediateContactsMap.get(newKey);
                caseNumbersForNewKey.add(acaseNumber);
                intermediateContactsMap.put(newKey, caseNumbersForNewKey);
            }
            
            
            
        }
        System.debug('Done constructing the intermediate map...');
        
        return createContact(caseNumbersVsContactDetails);
    }
    
    private boolean checkForFullMatch(String ruleName) {
        System.debug('Rule Name to be checked for 100% Match: ' + ruleName);
        if(fullMatchConfidenceRules != null && !fullMatchConfidenceRules.isEmpty()) {
            System.debug(fullMatchConfidenceRules+' '+fullMatchConfidenceRules.size());
            if(fullMatchConfidenceRules.containsKey(ruleName)) {
                System.debug('Full match found. Setting variable fullMatch to true...');
                return true;
            }
        }
        return false;
    }
    
    public Map<String, Id> createContact(Map<String, Contact> updatedContactDetails) {
        System.debug('Inside contactcreator');
        List<Contact> duplicateContacts;
        Boolean highConfidenceMatch;
        Boolean FullMatch = false;
        String newKey = '';
        Map<String, Id> contactsToBeReturnedMap = new Map<String, Id>();
        List<Id> contactsToBeReturned = new List<Id>();
        List<Contact> noMatchContactsToBeInserted = new List<Contact>();   //No matches found, insert this record
        Map<Integer, Contact> noMatchContactsToBeInsertedMap = new Map<Integer, Contact>();
        Id contactId = null;
        Contact contactToBeInserted = new Contact();
        List<Contact> contactsToBeUpdated = new List<Contact>();
        NormalizePhoneFieldHandler obj = new NormalizePhoneFieldHandler();
        
        Database.DMLOptions dmlOption = new Database.DMLOptions();
        dmlOption.DuplicateRuleHeader.AllowSave = false;
        
        List<Contact> contactsToBeInsertedInBulk = updatedContactDetails.values();
        Map<Contact, Contact> contactsToBeInsertedVsDupeContact = new Map<Contact, Contact>();
        Integer trackCount = 0;
        
        Database.SaveResult[] results = Database.insert(contactsToBeInsertedInBulk, dmlOption);
        System.debug('after database dml operation.');
        
        Map<String, Id> keyVsContactIdInDB = new Map<String, Id>();
        
        
        for (Database.SaveResult result:results){
            
            if (!result.isSuccess()) {
                System.debug(':error:');
                for (Database.Error error : result.getErrors()) {
                    System.debug('databaseError');                
                    
                    if (error instanceof Database.DuplicateError) {
                        duplicateContacts = new List<Contact>();
                        highConfidenceMatch = false;
                        
                        Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                        System.debug('instanceof DuplicateError');
                        // Return only match results of matching rules that find duplicate records
                        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                        System.debug('Match Results are : ' + matchResults);
                        System.debug('Match Result size: ' + matchResults.size());
                        
                        Datacloud.MatchResult firstMatchResult;
                        for(Datacloud.MatchResult mResult:matchResults) {
                            FullMatch = checkForFullMatch(mResult.getRule());    //100% match
                            if(FullMatch) firstMatchResult = mResult;
                        }
                        
                        if(FullMatch){
                            Datacloud.MatchResult matchResult = firstMatchResult;
                            Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();                        
                            for (Datacloud.MatchRecord matchRecord : matchRecords) {
                                System.debug('Matched record details == '+matchRecord);
                                duplicateContacts.add((Contact) matchRecord.getRecord());
                                System.debug('Adding to Duplicates');
                                //Fetch the matching contact records from the first duplicate match result
                                contactId = duplicateContacts[0].id;
                                System.debug('Found matching contact '+duplicateContacts[0].id);
                                contactToBeInserted = duplicateContacts[0];
                                
                                contactsToBeInsertedVsDupeContact.put(contactsToBeInsertedInBulk.get(trackCount), contactToBeInserted);
                                
                                Contact nonDBIncomingContact = contactsToBeInsertedInBulk.get(trackCount);
                                
                                String contactFirstName = nonDBIncomingContact.FirstName!=null?nonDBIncomingContact.FirstName:'';
                                String contactEmail = nonDBIncomingContact.Email!=null?nonDBIncomingContact.Email:'';
                                String contactPhone = nonDBIncomingContact.Phone!=null?nonDBIncomingContact.Phone:'';
                                if(contactPhone.length()>1) contactPhone = contactPhone.substring(contactPhone.length()-3,contactPhone.length());
                                String newKeyVsContactIdInDB = contactFirstName + '-' + nonDBIncomingContact.LastName + '-' + contactEmail + '-' + contactPhone;
                                keyVsContactIdInDB.put(newKeyVsContactIdInDB, contactToBeInserted.Id);
                                
                            }
                            System.debug('match results after finding matchRecord'+matchRecords);                            
                            contactsToBeReturned.add(contactId);
                            
                        } else if(!FullMatch){
                            noMatchContactsToBeInserted.add(contactsToBeInsertedInBulk.get(trackCount));
                            noMatchContactsToBeInsertedMap.put(trackCount, contactsToBeInsertedInBulk.get(trackCount));
                        }
                        
                    } else {
                        System.debug('Some error than Duplicate Matching Rules has error has occured during Contact creation');
                        System.debug(LoggingLevel.ERROR, error);
                        throw new InvalidParameterException(error.getMessage());
                    }
                } //end of for loop
            } else {
                contactId = result.getId();
                System.debug('Inserted Contact ID: ' + contactId);
                
                Contact nonDBIncomingContact = contactsToBeInsertedInBulk.get(trackCount);
                
                String contactFirstName = nonDBIncomingContact.FirstName!=null?nonDBIncomingContact.FirstName:'';
                String contactEmail = nonDBIncomingContact.Email!=null?nonDBIncomingContact.Email:'';
                String contactPhone = nonDBIncomingContact.Phone!=null?nonDBIncomingContact.Phone:'';
                if(contactPhone.length()>1) contactPhone = contactPhone.substring(contactPhone.length()-3,contactPhone.length());
                String newKeykeyVsContactIdInDB = contactFirstName + '-' + nonDBIncomingContact.LastName + '-' + contactEmail + '-' + contactPhone;
                keyVsContactIdInDB.put(newKeykeyVsContactIdInDB, nonDBIncomingContact.Id);
                
                //if insert is a success - put it in the map of contacts to be returned                
                contactsToBeReturned.add(contactId);
            }
            
            trackCount++;
            
        }  //End of master for loop - Now we can do insert DML again because it will be outside for loop
        
        //Start:: Bulk insert Contacts that were not 100% match
        
        Map<Contact, ID> allNewlyInsertedContactsVSOriginal = new Map<Contact, ID>();
        Integer y = 0;
        
        if((noMatchContactsToBeInserted!=null) && (noMatchContactsToBeInserted.size() > 0)){
            Database.DMLOptions dmlOpt = new Database.DMLOptions();
            dmlOpt.DuplicateRuleHeader.AllowSave = true;
            try{
                Database.SaveResult[] newResults = Database.insert(noMatchContactsToBeInserted, dmlOpt);
                for(Database.SaveResult newResult:newResults){
                    contactId = newResult.getId();
                    System.debug('100% Contact Match not found. Inserted a new contact: ' + contactId);
                    
                    contactsToBeReturned.add(contactId);
                    allNewlyInsertedContactsVSOriginal.put(noMatchContactsToBeInserted.get(y),contactId);
                    y++; 
                }
                
                for (Contact anoMatchContactsToBeInserted:allNewlyInsertedContactsVSOriginal.keySet()){
                    //Add newly inserted Contacts to hashmap                    
                    String contactFirstName = anoMatchContactsToBeInserted.FirstName!=null?anoMatchContactsToBeInserted.FirstName:'';
                    String contactEmail = anoMatchContactsToBeInserted.Email!=null?anoMatchContactsToBeInserted.Email:'';
                    String contactPhone = anoMatchContactsToBeInserted.Phone!=null?anoMatchContactsToBeInserted.Phone:'';
                    if(contactPhone.length()>1) contactPhone = contactPhone.substring(contactPhone.length()-3,contactPhone.length());
                    String newKeykeyVsContactIdInDBForNewContacts = contactFirstName + '-' + anoMatchContactsToBeInserted.LastName + '-' + contactEmail + '-' + contactPhone;
                    keyVsContactIdInDB.put(newKeykeyVsContactIdInDBForNewContacts, allNewlyInsertedContactsVSOriginal.get(anoMatchContactsToBeInserted));
                    
                }
                
            }catch(Exception ne){
                System.debug('Some error other than Duplicate Matching Rules has error has occured during Contact insertion for Contact that didnt matched 100% matching rule');
                System.debug(LoggingLevel.ERROR, ne);
                throw new InvalidParameterException(ne.getMessage());
            }
        }
        
        //End:: Bulk insert Contacts that were not 100% match
        
        String contactFirstName = '';
        String contactEmail = '';
        String contactPhone = '';
        
        for(String keyForNewIncomingContactsData:keyVsContactIdInDB.keySet()){
            List<String> caseNumbers = new List<String>();
            system.debug('Searching Map for newKey: ' + keyForNewIncomingContactsData);
            //Find this key in the intermediate map to get the value to create a 
            //final map of Case numbers VS Contact Id values and return it back
            caseNumbers = intermediateContactsMap.get(keyForNewIncomingContactsData);
            if (caseNumbers!=null && !caseNumbers.isEmpty()){
                for (String aCaseNum: caseNumbers){
                    contactsToBeReturnedMap.put(aCaseNum,keyVsContactIdInDB.get(keyForNewIncomingContactsData));
                    system.debug('Added in contactsToBeReturnedMap Map:: newKey: ' + keyForNewIncomingContactsData + ' Case Number: ' 
                                 + aCaseNum + ' ContactId: ' + keyVsContactIdInDB.get(keyForNewIncomingContactsData));
                }
            }
        }//for
        
        
        //UPDATE EXISTING DUPE CONTACTS WITH THE NEW CONTACT DETAILS
        set<Contact> existingContactEmailPhonesToBeUpdated = new set<Contact>();
        list<Contact> lstexistingContactEmailPhonesToBeUpdated = new list<Contact>();
        for (Contact newContact: contactsToBeInsertedVsDupeContact.keySet())
        {
            Contact origContactInDB = contactsToBeInsertedVsDupeContact.get(newContact);
            if(newContact.Email!=null) origContactInDB.Email = newContact.Email;
            if(newContact.Phone!=null) {
                origContactInDB.Phone = obj.normalizePhone((String)newContact.Phone);
                origContactInDB.Normalized_Work_Phone__c = obj.normalizePhone((String)newContact.Phone);
            //}
            //if(newContact.MobilePhone!=null) {
                origContactInDB.MobilePhone = obj.normalizePhone((String)newContact.MobilePhone);
                origContactInDB.Normalized_Mobile__c = obj.normalizePhone((String)newContact.MobilePhone);
            //}
            //if(newContact.HomePhone!=null) {
                origContactInDB.HomePhone = obj.normalizePhone((String)newContact.HomePhone);
                origContactInDB.Normalized_Home_Phone__c = obj.normalizePhone((String)newContact.HomePhone);
            //}
            System.debug('newContact.OtherPhone: ' + origContactInDB.OtherPhone);
            //if(newContact.OtherPhone!=null) {
                origContactInDB.Other_Phone__c = obj.normalizePhone((String)newContact.Phone);
                origContactInDB.Normalized_Other_Phone__c = obj.normalizePhone((String)newContact.Phone);
                System.debug('origContactInDB.Other_Phone__c: ' + origContactInDB.Other_Phone__c + ' origContactInDB.Normalized_Other_Phone__c: ' + origContactInDB.Normalized_Other_Phone__c);
            }
            existingContactEmailPhonesToBeUpdated.add(origContactInDB);
        }
        
        if(existingContactEmailPhonesToBeUpdated!=null && existingContactEmailPhonesToBeUpdated.size()>0){
            lstexistingContactEmailPhonesToBeUpdated.addall(existingContactEmailPhonesToBeUpdated);
            
            Database.DMLOptions dmlContactReUpdateOption = new Database.DMLOptions();
            dmlOption.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult[] result = Database.update(lstexistingContactEmailPhonesToBeUpdated, dmlContactReUpdateOption);
            //            update lstexistingContactEmailPhonesToBeUpdated;
            for (Database.SaveResult sr : results) {
                if(!sr.isSuccess()){
                    ApplicationLogMessage message= new ApplicationLogMessage();
                    message.source='BulkContactsCreator';
                    message.sourceFunction='createContact';
                    message.referenceInfo=JSON.serialize(sr.getErrors());
                    message.debugLevel='Error';
                    ApplicationLogUtility.logMessage(message);
                }
            }            
            
            
        }
        
        return contactsToBeReturnedMap;
    }
    
    public class InvalidParameterException extends Exception{}
}






/*

Test Data: 
fxyx-dxyz-kxyz@wu.com-223 Case Number: 00461525 ContactId: 0035D00000DDDDkQAP
fxyx-dxyz-kxyz@wu.com-223 Case Number: 00461526 ContactId: 0035D00000DDDDkQAP
rpqr-qlmn-qrfw@lmno.com-723 Case Number: 00461527 ContactId: 0035D00000DDDDlQAP
ABC-DEF-a@b.com-777 Case Number: 00461528 ContactId: 0035D00000DCYPmQAP
PQR-LMN--955 Case Number: 00461529 ContactId: 0035D000009BCPuQAO
yieyuey-dadasda-cane@e.com-055 Case Number: 00461530 ContactId: 0035D000009CRKRQA4



Execute Anonymous Script::

Contact a1 = new Contact (firstname='fxyx', lastname='dxyz', Phone = '0129932223', email = 'kxyz@wu.com');//repeat new contact
Contact a2 = new Contact (firstname='fxyx', lastname='dxyz', Phone = '0129932223', email = 'kxyz@wu.com');//repeat new contact
Contact a3 = new Contact (firstname='rpqr', lastname='qlmn', Phone = '0137222723', email = 'qrfw@lmno.com');//new contact
Contact a4 = new Contact (firstname='ABC', lastname='DEF', Phone = '0177777777', email = 'a@b.com');//update existing number with new no
Contact a5 = new Contact (firstname='PQR', lastname='LMN', Phone = '0156273955');//, email = 'd@e.com' //find existing contact without giving email
Contact a6 = new Contact (firstname='yieyuey', lastname='dadasda', Phone = '0156361055', email = 'cane@e.com'); //existing contact

Map<String, Contact> caseNumbersVsContactmap = new Map<String, Contact>();
caseNumbersVsContactmap.put('00461525',a1);
caseNumbersVsContactmap.put('00461526',a2);
caseNumbersVsContactmap.put('00461527',a3);
caseNumbersVsContactmap.put('00461528',a4);
caseNumbersVsContactmap.put('00461529',a5);
caseNumbersVsContactmap.put('00461530',a6);


BulkContactsCreator c = new BulkContactsCreator();
Map<String, Id> results = c.createContactMaps(caseNumbersVsContactmap);

System.debug('Printing the Final Map');
for(String caseNumber : results.keySet()){
System.debug('Case Number: ' + caseNumber + ' - ' + results.get(caseNumber) + ' - original value: ' + caseNumbersVsContactmap.get(caseNumber));
}





*/