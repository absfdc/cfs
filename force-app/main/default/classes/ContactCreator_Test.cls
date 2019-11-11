@isTest
private class ContactCreator_Test {

    private static Contact contactRecord;
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try{
            ContactCreator conCreator = new ContactCreator(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForNewContactInsert() {
        setUpTestData(false);
        System.Test.startTest();
        ContactCreator conCreator = new ContactCreator(contactRecord);
        Id contactID = conCreator.createContact();
        System.assert(!String.isBlank(contactID));
        //System.assert(!conCreator.hasDuplicateResult());
        System.assert(conCreator.getDuplicateContacts().isEmpty());
        System.Test.stopTest();     
    }
    
    private static testMethod void testForDuplicateContactInsert() {
        setUpTestData(true);
        FullMatchDuplicateContactRules__c fullDuplicateContactRules = new FullMatchDuplicateContactRules__c();
        fullDuplicateContactRules.Name = 'contactNormalizedMatch';
        insert fullDuplicateContactRules;
        System.Test.startTest();
        ContactCreator conCreator = new ContactCreator(contactRecord);
        Id contactID = conCreator.createContact();
        System.assert(!String.isBlank(contactID));
        //System.assert(conCreator.hasDuplicateResult());
        System.assert(conCreator.FullMatch);
        System.Test.stopTest();     
    }
      
    private static void setUpTestData(Boolean isDuplicate) {
        if(isDuplicate) {
            createContact();
            insert contactRecord;
        }
        createContact();
    }
    
    private static void createContact() {
        contactRecord = new Contact();
        contactRecord.FirstName = 'Test';
        contactRecord.LastName = 'Contact';
        contactRecord.Email = 'test.contact@nsw.gov.au';
        contactRecord.Phone = '123123123';
    }
}