@isTest
private class PopulateMetaCategorisationData_Test {

    private static testMethod void testForErrorMsg() {
        List<SObject> records = Test.loadData(Taxonomy_Staging_Data__c.SObjectType, 'stagingRecords');
        System.assert(records.size() == 3);
        System.Test.startTest();
        PopulateMetaCategorisationData taxoLoader = new PopulateMetaCategorisationData();
        taxoLoader.populateData();
        System.Test.stopTest();
        List<Taxonomy_Metadata__c> taxoMetadata = [SELECT Id FROM Taxonomy_Metadata__c];
        System.assert(taxoMetadata.size() == 6);
    }
}