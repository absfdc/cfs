@isTest
private class TaxonomySorter_Test {
    
    private static List<Taxonomy_Metadata__c> taxoList;
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        List<Taxonomy_Metadata__c> sortedTaxo = TaxonomySorter.sort(taxoList);
        System.Test.stopTest();
        System.assert(sortedTaxo.isEmpty());
    }
    
    private static testMethod void testForSortingBasedOnName() {
        setUpTestData();
        for(Taxonomy_Metadata__c taxo: taxoList) {
            taxo.Customer_facing_sort_order__c = null;
            taxo.Staff_facing_sort_order__c = null;
        }
        System.Test.startTest();
        List<Taxonomy_Metadata__c> sortedTaxo = TaxonomySorter.sort(taxoList);
        System.Test.stopTest();
        for(Integer i = 0; i < 10; i++) {
            System.debug('Actual: ' + sortedTaxo[i].Customer_Value__c);
            System.debug('Expected: ' + 'Test' + i);
            System.assert(sortedTaxo[i].Customer_Value__c == 'Test' + i);
        }
    }
    
    private static testMethod void testForSortingBasedOnCustomSort() {
        setUpTestData();
        for(Taxonomy_Metadata__c taxo: taxoList) {
            taxo.Customer_Value__c = null;
        }
        System.Test.startTest();
        List<Taxonomy_Metadata__c> sortedTaxo = TaxonomySorter.sort(taxoList);
        System.Test.stopTest();
        System.assert(!sortedTaxo.isEmpty());
        for(Integer i = 0; i < sortedTaxo.size(); i++) {
            System.assert(sortedTaxo[i].Customer_facing_sort_order__c == i);
        }
    }
    
    private static void setUpTestData() {
        taxoList = new List<Taxonomy_Metadata__c>();
        for(Integer i = 0; i < 10; i++) {
            Taxonomy_Metadata__c taxo = new Taxonomy_Metadata__c();
            taxo.Agency__c = 'RMS';
            taxo.Customer_facing_sort_order__c = i;
            taxo.Customer_Value__c = 'Test' + i;
            taxo.Driver__c = 'Driver';
            taxo.Issue_Accountability__c = 'Accountability';
            taxo.KPI__c = 'KPI';
            taxo.IsMinCorro__c = false;
            taxo.Staff_facing_sort_order__c = i;
            taxo.Status_Customer_Facing__c = 'Active';
            taxo.Status_NSWT_Customer_Facing__c = 'Active';
            taxo.Status_Staff_Facing__c = 'Active';
            taxo.Status_ST_Customer_Facing__c = 'Active';
            taxo.Type__c = 'Location';
            
            taxoList.add(taxo);
        }
    }
}