@isTest
public class ContactBeforeInsertTriggerHandler_Test {
    private static Contact contactRecord;
    private static List<Contact> conList;
    
    private static testMethod void testForSingleContactInsert(){
        Test.startTest();
        setupTestData(1, '+61 98-76543210');
        contactRecord = [SELECT ID,Normalized_Work_Phone__c FROM Contact LIMIT 1];
        System.assertEquals('09876543210', contactRecord.Normalized_Work_Phone__c);
        Test.stopTest();
    }
    
    private static testMethod void testForMultipleContactInsert(){
        Test.startTest();
        setupTestData(10, '+61 98-76543210');
        for(Contact con : [SELECT ID,Normalized_Work_Phone__c FROM Contact]){
            System.assertEquals('09876543210', con.Normalized_Work_Phone__c);
        }
        Test.stopTest();
    }
    
    private static testMethod void testForSpecialCharsInPhone(){
        Test.startTest();
        setupTestData(1, '+61 @98-765$43210');
        contactRecord = [SELECT ID,Normalized_Work_Phone__c FROM Contact LIMIT 1];
        System.assertEquals('09876543210', contactRecord.Normalized_Work_Phone__c);
        Test.stopTest();
    }
    
    private static void setupTestData(Integer noOfRecords, String phoneField) {
        conList = new List<Contact>();
        for(Integer i=0; i < noOfRecords; i++){
            contactRecord = new Contact();
            contactRecord.FirstName = 'Test'+i;
            contactRecord.LastName = 'Contact'+i;
            contactRecord.Email = 'test.contact@nsw.gov.au';
            contactRecord.Phone = phoneField;
            conList.add(contactRecord);
        }
        insert conList;
    }
}