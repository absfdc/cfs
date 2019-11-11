global class LookupContactPlugin implements Process.Plugin { 
    private Contact contactRecord;
    public Boolean isNewContact;
    private String phoneType;
    global Process.PluginResult invoke(Process.PluginRequest request) { 
        isNewContact = true;
        String firstName = (String) request.inputParameters.get('FirstName');
        String lastName = (String) request.inputParameters.get('LastName');
        String email = (String) request.inputParameters.get('Email');
        String phone = (String) request.inputParameters.get('Phone');
        phoneType = (String) request.inputParameters.get('PhoneType');
        //String homePhone = (String) request.inputParameters.get('HomePhone');
        //String mobilePhone = (String) request.inputParameters.get('MobilePhone');
        System.debug('firstName is =='+firstName);
        System.debug('PhoneType is =='+phoneType);
        
        contactRecord = new Contact();
        contactRecord.FirstName = firstName;
        contactRecord.LastName = lastName;
        contactRecord.email = email;
        if(phoneType == 'homePhone'){ 
            contactRecord.HomePhone = phone;   
        }else if(phoneType == 'mobilePhone'){
            contactRecord.MobilePhone = phone;   
        }else if(phoneType == 'otherPhone'){
            contactRecord.Other_Phone__c = phone; 
        }else if(phoneType == 'workPhone'){
            contactRecord.Phone = phone;
        }
        
        Id contactRecordId = createContact(contactRecord);
        System.debug('contactrecord id in LU plugin: '+contactRecordId);
        Map<String,Object> result = new Map<String,Object>();
        
        if(contactRecordId != null) {
            Contact customer = [SELECT Id, FirstName, LastName, Email, Phone, HomePhone, MobilePhone, UCC_Flag__c
                                FROM Contact 
                                WHERE Id =: contactRecordId];
            System.debug('customer: '+customer);
            result.put('contactId', customer.Id);
            result.put('firstName', customer.FirstName);
            result.put('lastName', customer.LastName);
            result.put('email', customer.Email);
            result.put('phone', customer.Phone);
            result.put('homePhone', customer.HomePhone);
            result.put('mobilePhone', customer.MobilePhone);
            result.put('uccFlag', customer.UCC_Flag__c);
            result.put('isNewContact', isNewContact);
        }
        System.debug('result: '+result);
        return new Process.PluginResult(result);
    }
    
    global Process.PluginDescribeResult describe() { 
        Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
        result.Name = 'Look Up Contact By Email, Phone';
        result.Tag = 'Contact Classes';
        result.inputParameters = new 
            List<Process.PluginDescribeResult.InputParameter>{ 
                new Process.PluginDescribeResult.InputParameter('FirstName', 
                                                                Process.PluginDescribeResult.ParameterType.STRING, true),
                    
                    new Process.PluginDescribeResult.InputParameter('LastName', 
                                                                    Process.PluginDescribeResult.ParameterType.STRING, true),
                    
                    new Process.PluginDescribeResult.InputParameter('Email', 
                                                                    Process.PluginDescribeResult.ParameterType.STRING, true),
                    
                    new Process.PluginDescribeResult.InputParameter('Phone', 
                                                                    Process.PluginDescribeResult.ParameterType.STRING, true),
                    
                    new Process.PluginDescribeResult.InputParameter('HomePhone', 
                                                                    Process.PluginDescribeResult.ParameterType.STRING, true), 
                    
                    new Process.PluginDescribeResult.InputParameter('MobilePhone', 
                                                                    Process.PluginDescribeResult.ParameterType.STRING, true),
                    
                    new Process.PluginDescribeResult.InputParameter('PhoneType', 
                                                                    Process.PluginDescribeResult.ParameterType.STRING, true)
                    }; 
                        result.outputParameters = new 
                        List<Process.PluginDescribeResult.OutputParameter>{              
                            new Process.PluginDescribeResult.OutputParameter('contactId', 
                                                                             Process.PluginDescribeResult.ParameterType.STRING),
                                new Process.PluginDescribeResult.OutputParameter('firstName', 
                                                                                 Process.PluginDescribeResult.ParameterType.STRING),
                                new Process.PluginDescribeResult.OutputParameter('lastName', 
                                                                                 Process.PluginDescribeResult.ParameterType.STRING),
                                new Process.PluginDescribeResult.OutputParameter('email', 
                                                                                 Process.PluginDescribeResult.ParameterType.STRING),
                                new Process.PluginDescribeResult.OutputParameter('phone', 
                                                                                 Process.PluginDescribeResult.ParameterType.STRING),
                                new Process.PluginDescribeResult.OutputParameter('homePhone', 
                                                                                 Process.PluginDescribeResult.ParameterType.STRING),
                                new Process.PluginDescribeResult.OutputParameter('mobilePhone', 
                                                                                 Process.PluginDescribeResult.ParameterType.STRING),
                                new Process.PluginDescribeResult.OutputParameter('uccFlag', 
                                                                                 Process.PluginDescribeResult.ParameterType.Boolean),
                                new Process.PluginDescribeResult.OutputParameter('isNewContact', 
                                                                                 Process.PluginDescribeResult.ParameterType.Boolean)
                                }; 
                                    return result; 
    }
    
    public Id createContact(Contact contactRecord) {        
        System.debug(':createContact:');
        ContactCreator creator = new ContactCreator(contactRecord);
        Id existingMatchingContact = null;
        Boolean matchingContactIdStamped = false;
        Id contactId = creator.createContact();
        System.debug('contactId in create contact LU plugin '+contactId);
        if(creator.FullMatch == true){
            updateMatchedRecord(creator.duplicateContacts[0]);
            isNewContact = false;
        }
        if(contactId != null){
            resetFlowContactPhoneFields(contactId);
            return contactId;
        }
        return null;
        
        /*
if(creator.FullMatch) {
System.debug('Is 100%Match, trying to update Contact: ');
return creator.getDuplicateContacts()[0].Id;
} else {

try{

//Cross Check Phone Fields
if(contactRecord != null) {
String cphone = '';  //input example (+61) 123 455 555
cphone = contactRecord.Phone;
cphone = cphone.replaceall(' ', '');
cphone = cphone.replace('(', '');
cphone = cphone.replace(')', '');
cphone = cphone.replace('+', '');
if (cphone.startswith('61')) cphone = cphone.substring(2, cphone.length());
if (cphone.startswith('0')) cphone = cphone.substring(1, cphone.length());
cphone = '%' + cphone;
System.debug('Trimmed phone: ' + cphone.replaceall(' ', ''));
//Now Cross Match with other fields

String contactFirstName = contactRecord.FirstName;
String contactLastName = contactRecord.LastName;
String contactEmail = contactRecord.Email;

SearchContacts s = new searchContacts();
existingMatchingContact = s.searchContact(contactFirstName,contactLastName,cphone,contactEmail);

if (existingMatchingContact != null){
System.debug('ID for Matching Existing Contact: ' + existingMatchingContact);
matchingContactIdStamped = true;
return existingMatchingContact;
}
System.debug('Scanning Complete for Contact Phone against Cross Check Phone Fields...');
}   

} catch(Exception e) {
system.debug('createContact::Exception - ' + e.getMessage() + e.getLineNumber() + e.getStackTraceString());
return null;
}
}



if(!creator.getDuplicateContacts().isEmpty()) {

if(!matchingContactIdStamped) {
Database.DMLOptions dmlOption = new Database.DMLOptions();
dmlOption.DuplicateRuleHeader.AllowSave = true;
system.debug('Not a 100% Match so Trying to insert the Contact');
Database.SaveResult result = Database.insert(contactRecord, dmlOption);
system.debug('Not a 100% Match so inserted the Contact with id: ' + result.id);
return result.id;             
}
return null;
}
return null;        
*/
    }
    
    public void updateMatchedRecord(Contact matchedContact){
        
        if(String.isNotEmpty(contactRecord.FirstName)) matchedContact.FirstName = contactRecord.FirstName;
        if(String.isNotEmpty(contactRecord.LastName)) matchedContact.LastName = contactRecord.LastName;
        System.debug('Email in matched Contact : '+matchedContact.Email);
        
        if(matchedContact.Email == contactRecord.Email) {
            //workphone set
            if(phoneType == 'mobilePhone') 
                matchedContact.mobilephone = contactRecord.MobilePhone;
            if(phoneType == 'homePhone') 
                matchedContact.HomePhone = contactRecord.HomePhone;
            if(phoneType == 'workPhone') 
                matchedContact.Phone = contactRecord.Phone;
            if(phoneType == 'otherPhone') 
                matchedContact.Other_Phone__c = contactRecord.Other_Phone__c;
        } else {
            if(String.isNotEmpty(contactRecord.Email))
                matchedContact.Email = contactRecord.Email;
        }
        
        if(String.isNotEmpty(contactRecord.MailingStreet)) matchedContact.MailingStreet = contactRecord.MailingStreet;
        if(String.isNotEmpty(contactRecord.MailingCity)) matchedContact.MailingCity = contactRecord.MailingCity;
        if(String.isNotEmpty(contactRecord.MailingState)) matchedContact.MailingState = contactRecord.MailingState;
        if(String.isNotEmpty(contactRecord.MailingPostalCode)) matchedContact.MailingPostalCode = contactRecord.MailingPostalCode;
        if(String.isNotEmpty(contactRecord.MailingCountry)) matchedContact.MailingCountry = contactRecord.MailingCountry;
        
        Database.DMLOptions updateDmlOption = new Database.DMLOptions();
        updateDmlOption.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult matchedContactUpdateResults = Database.update(matchedContact, updateDmlOption);
        System.debug('result = '+matchedContactUpdateResults.isSuccess());
        System.debug('Error is :'+matchedContactUpdateResults.getErrors());                 
    }
    
    public void resetFlowContactPhoneFields(Id conId){
        List<Contact> cons = [SELECT Id, firstName, lastName, Phone, MobilePhone, HomePhone, Other_Phone__c,Normalized_Home_Phone__c, Normalized_Mobile__c,Normalized_Other_Phone__c, Normalized_Work_Phone__c 
                                FROM Contact 
                                WHERE Id =:conId];
        for(Contact con: cons){
            if(isNewContact == true){
                if(phoneType == 'homePhone'){
                    con.Phone = '';
                    con.Other_Phone__c = '';
                    con.MobilePhone = '';
                }
                if(phoneType == 'otherPhone'){
                    con.Phone = '';
                    con.HomePhone = '';
                    con.MobilePhone = '';
                }
                if(phoneType == 'mobilePhone'){
                    con.HomePhone = '';
                    con.Phone = '';
                    con.Other_Phone__c = '';
                }
                if(phoneType == 'workPhone'){
                    con.HomePhone = '';
                    con.Other_Phone__c = '';
                    con.MobilePhone = '';
                }
            }
        }
        Database.DMLOptions updateDmlOption = new Database.DMLOptions();
		updateDmlOption.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] matchedContactUpdateResults = Database.update(cons, updateDmlOption);
        
    }
    
}