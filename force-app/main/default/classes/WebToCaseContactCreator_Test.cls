@isTest
private class WebToCaseContactCreator_Test {

    private static Case caseRecord;
    private static Contact contactPerson;
    
    private static testMethod void testForInvalidData() {
        setUpTestData(0);
        System.Test.startTest();
        try {
            WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(null, contactPerson, '');
			
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(caseRecord, null, '');
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.debug('Label: ' + Label.MaxDuplicateContactsOnCase);
        System.Test.stopTest();
    }
    
    private static testMethod void testForNewContact() {
        setUpTestData(0);
        System.Test.startTest();
        WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(caseRecord, contactPerson, '');
        contactCreator.createContact();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, ContactId FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        Contact matchedCon = new Contact();
            matchedCon.FirstName = 'Test';
            matchedCon.LastName = 'Contact';
            matchedCon.Phone = '123456789';
            matchedCon.Email = 'test@contact.com';
            matchedCon.MailingStreet = 'Castlereagh St.';
            matchedCon.MailingCity = 'Sydney';
            matchedCon.MailingPostalCode = '2000';
            matchedCon.MailingCountry = 'Australia';    
            contactCreator.updateMatchedRecord(matchedCon);
        System.assert(cases[0].ContactId != null);
        System.assert(cases[0].ContactId == contactPerson.Id);
    }
    
    private static testMethod void testForSingleDuplicateContact() {
        setUpTestData(1);
        createCustomSettings();
        System.Test.startTest();
        WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(caseRecord, contactPerson, '');
        contactCreator.createContact();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, ContactId FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        //System.assert(cases[0].ContactId != null);
    }
  
    private static testMethod void testForMultipleDuplicateContact() {
        setUpTestData(6);
        createCustomSettings();
        System.Test.startTest();
        WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(caseRecord, contactPerson, '');
        contactCreator.createContact();
        System.Test.stopTest();
        List<Case> cases = [SELECT Id, ContactId, SuppliedEmail, SuppliedPhone, SuppliedName FROM Case WHERE Id = :caseRecord.Id];
        System.assert(!cases.isEmpty());
        System.assert(cases[0].ContactId != null);
    }
    
    private static void setUpTestData(Integer duplicateContactContact) {
        createCase();
        createDuplicateContacts(duplicateContactContact);
    }
    
    private static void createCustomSettings() {
        FullMatchDuplicateContactRules__c fullDuplicateContactRules = new FullMatchDuplicateContactRules__c();
        fullDuplicateContactRules.Name = 'contactNormalizedMatch';
        insert fullDuplicateContactRules;       
    }
    
    private static void createDuplicateContacts(Integer contactCount) {
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < contactCount; i++) {
            contacts.add(createContact());
        }       
        if(!contacts.isEmpty()) {
            Database.DMLOptions dmlOption = new Database.DMLOptions(); 
            dmlOption.DuplicateRuleHeader.AllowSave = true;
            List<Database.SaveResult> result = Database.insert(contacts, dmlOption);
        }       
        contactPerson = createContact();
    }
    
    private static Contact createContact() {
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Contact';
        con.Phone = '123456789';
        con.Email = 'test@contact.com';
        con.MailingStreet = 'Castlereagh St.';
        con.MailingCity = 'Sydney';
        con.MailingPostalCode = '2000';
        con.MailingCountry = 'Australia';
        return con;
    }
    private static void createCase() {
        caseRecord = new Case();
        caseRecord.Origin = 'Web';
        caseRecord.Priority = 'Normal';
        caseRecord.Type = 'Compliment';
        caseRecord.Description = 'Test case for spam check';    
        insert caseRecord;
    }
}