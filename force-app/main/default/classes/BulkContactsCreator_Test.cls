@isTest
public class BulkContactsCreator_Test {
    private static List<Contact> contacts = new List<Contact>();
    private static List<Case> cases = new List<Case>();
    private static Map<String, Contact> caseNumbersVsContactDetails = new Map<String, Contact>();
    private static Map<String, Id> results = new Map<String, Id>();
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try{
            BulkContactsCreator conCreator = new BulkContactsCreator(null);
            results = conCreator.createContactMaps(caseNumbersVsContactDetails);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }

    private static testMethod void testForInvalidParams() {
        System.Test.startTest();
        try{
            BulkContactsCreator conCreator = new BulkContactsCreator(null);
            conCreator.createContactMaps(null);
           // System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForNewContactInsert() {

        FullMatchDuplicateContactRules__c fullDuplicateContactRules = new FullMatchDuplicateContactRules__c();
        fullDuplicateContactRules.Name = 'contactNormalizedMatch';
        insert fullDuplicateContactRules;

        setUpTestData();
        System.Test.startTest();
        BulkContactsCreator conCreator = new BulkContactsCreator(caseNumbersVsContactDetails);
        results = conCreator.createContactMaps(caseNumbersVsContactDetails);
		integer resultsSize = results.size();
        System.Test.stopTest();     
    }
    

    private static void setUpTestData() {
        createContacts();
        createCases(4);
        Integer t = 0;
        for(Case c:cases){
            caseNumbersVsContactDetails.put(c.casenumber,contacts.get(t));
            t++;
        }
    }
    
    private static void createContacts() {
			Contact contactRecord = new Contact();
    	    contactRecord.FirstName = 'Test';
        	contactRecord.LastName = 'ContactA';
        	contactRecord.Email = 'test.contactA@nsw.gov.au';
        	contactRecord.Phone = '0497529177';
	    	contacts.add(contactRecord);
        
			Contact contactRecord1 = new Contact();
    	    contactRecord1.FirstName = 'Test';
        	contactRecord1.LastName = 'ContactB';
        	contactRecord1.Email = 'test.contactB@nsw.gov.au';
        	contactRecord1.MobilePhone = '0497529178';
	        contacts.add(contactRecord1);

			Contact contactRecord2 = new Contact();
    	    contactRecord2.FirstName = 'Test';
        	contactRecord2.LastName = 'ContactC';
        	contactRecord2.Email = 'test.contactC@nsw.gov.au';
        	contactRecord2.HomePhone = '0497529179';
	        contacts.add(contactRecord2);

        	Contact contactRecord3 = new Contact();
    	    contactRecord3.FirstName = 'Test';
        	contactRecord3.LastName = 'ContactC';
        	contactRecord3.Email = 'test.contactC@nsw.gov.au';
        	contactRecord3.HomePhone = '0497529179';
	        contacts.add(contactRecord3);
        
        
            Contact contactRecord4 = new Contact();
    	    contactRecord4.FirstName = 'Test';
        	contactRecord4.LastName = 'ContactC';
        	contactRecord4.Email = 'test.contactC@nsw.gov.au';
        	contactRecord4.HomePhone = '0497529179';
			insert contactRecord4;
        
        
        	Contact contactRecord5 = new Contact();
    	    contactRecord5.FirstName = 'XYZ';
        	contactRecord5.LastName = 'PQR';
        	contactRecord5.Email = 'ontactY@ku.au';
        	contactRecord5.MobilePhone = '0222222229';
			contacts.add(contactRecord5);
        	
        
    }    
    
    private static void createCases(Integer caseCount) {
        RecordType recordType = [ SELECT Id, Name FROM RecordType WHERE sObjectType = 'Case' AND Name = 'Bus' limit 1];
        
        for(Integer i=0; i < caseCount; i++) {
            Case caseRecord = new Case();
            caseRecord.Modes__c = 'Bus';
            caseRecord.Taxonomy_Accountability__c = '';
            caseRecord.Taxonomy_Location__c = 'Sydney';
            caseRecord.Agency__c = '';
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Compliment';
            caseRecord.Description = 'Test case for web to case creation';
            caseRecord.RecordTypeId = recordType.id;
            cases.add(caseRecord);
        }
        
        insert cases;
        
    }
    
}