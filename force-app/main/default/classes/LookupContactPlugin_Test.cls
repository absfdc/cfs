@isTest
public class LookupContactPlugin_Test {
    private static Contact contactRecord;
	static testmethod void FeedbackCallTestForExistingContact(){
        setUpTestData(true);
        FullMatchDuplicateContactRules__c fullDuplicateContactRules = new FullMatchDuplicateContactRules__c();
        fullDuplicateContactRules.Name = 'contactNormalizedMatch';
        insert fullDuplicateContactRules;
        System.Test.startTest();
        LookupContactPlugin plugin = new LookupContactPlugin();
        Map<String,Object> inputParams = new Map<String,Object>();
        
        inputParams.put('FirstName', 'John');
        inputParams.put('LastName', 'Carter');
        inputParams.put('Email', 'shrikant.hase@arxxus.com');
        inputParams.put('Phone', '8796854605');
        
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result = plugin.invoke(request);
        //System.debug('result = '+result.get().contactId);
        System.assert(!plugin.isNewContact);
        //System.assertEquals(contactRecord.id, result.contactId);
        System.Test.stopTest();
    }
    
    static testmethod void FeedbackCallTestForNewContact(){
        setUpTestData(false);
        FullMatchDuplicateContactRules__c fullDuplicateContactRules = new FullMatchDuplicateContactRules__c();
        fullDuplicateContactRules.Name = 'contactNormalizedMatch';
        insert fullDuplicateContactRules;
        System.Test.startTest();
        LookupContactPlugin plugin = new LookupContactPlugin();
        Map<String,Object> inputParams = new Map<String,Object>();
        
        inputParams.put('FirstName', 'John');
        inputParams.put('LastName', 'Carter');
        inputParams.put('Email', 'shrikant.hase@arxxus.com');
        inputParams.put('Phone', '8796854605');
        
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result = plugin.invoke(request);
        //System.debug('result = '+result.get().contactId);
        System.assert(plugin.isNewContact);
        //System.assertEquals(contactRecord.id, result.contactId);
        plugin.describe();
        System.Test.stopTest();
    }
    
    private static void setUpTestData(Boolean isDuplicate) {
        if(isDuplicate) {
            contactRecord = new Contact();
            contactRecord.FirstName = 'John';
            contactRecord.LastName = 'Carter';
            contactRecord.Email = 'shrikant.hase@arxxus.com';
            contactRecord.Phone = '8796854605';
            insert contactRecord;
        }
    }
}