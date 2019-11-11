public with sharing class TaxonomySorter {
    private static final Integer HIGH_SORT_INT_VALUE = 99999;
    private static final String HIGH_SORT_STR_VALUE = 'ZZZZZZ';
    
    public static List<Taxonomy_Metadata__c> sort(List<Taxonomy_Metadata__c> taxonomy) {
        List<Taxonomy_Metadata__c> sortedTaxonomy = new List<Taxonomy_Metadata__c>();
        if(taxonomy == null || taxonomy.isEmpty()) {
            return sortedTaxonomy;
        }
        Set<String> taxoValues = new Set<String>();
        Map<Integer, List<Taxonomy_Metadata__c>> orderVsTaxo = new Map<Integer, List<Taxonomy_Metadata__c>>();
        for(Taxonomy_Metadata__c taxo : taxonomy) {
            if(taxo.Customer_facing_sort_order__c == null) {
                taxo.Customer_facing_sort_order__c = HIGH_SORT_INT_VALUE;
            }
            if(!orderVsTaxo.containsKey(Integer.valueOf(taxo.Customer_facing_sort_order__c))) {
                orderVsTaxo.put(Integer.valueOf(taxo.Customer_facing_sort_order__c), new List<Taxonomy_Metadata__c>());
            }
            if(!taxoValues.contains(taxo.Customer_Value__c)) {
                orderVsTaxo.get(Integer.valueOf(taxo.Customer_facing_sort_order__c)).add(taxo);
                taxoValues.add(taxo.Customer_Value__c);
            }            
        }
        
        for(Integer order : orderVsTaxo.keySet()) {
            orderVsTaxo.put(order, sortBasedOnName(orderVsTaxo.get(order)));
        }
        
        List<Integer> taxoOrder = new List<Integer>();
        taxoOrder.addAll(orderVsTaxo.keySet());
        taxoOrder.sort();
        for(Integer order : taxoOrder) {
            if(order == HIGH_SORT_INT_VALUE) {
                for(Taxonomy_Metadata__c taxo : orderVsTaxo.get(order)) {
                    taxo.Customer_facing_sort_order__c = null;
                }
            }
            sortedTaxonomy.addAll(orderVsTaxo.get(order));
        }
        
        return sortedTaxonomy;
    }
    
    private static List<Taxonomy_Metadata__c> sortBasedOnName(List<Taxonomy_Metadata__c> taxonomy) {
        List<Taxonomy_Metadata__c> sortedTaxo = new List<Taxonomy_Metadata__c>();
        Set<String> taxoValues = new Set<String>();
        Map<String, List<Taxonomy_Metadata__c>> nameVsTaxo = new Map<String, List<Taxonomy_Metadata__c>>();
        for(Taxonomy_Metadata__c taxo : taxonomy) {
            if(String.isBlank(taxo.Customer_Value__c)) {
                taxo.Customer_Value__c = HIGH_SORT_STR_VALUE;
            }
            if(!nameVsTaxo.containsKey(taxo.Customer_Value__c)) {
                nameVsTaxo.put(taxo.Customer_Value__c, new List<Taxonomy_Metadata__c>());
            }
            if(!taxoValues.contains(taxo.Customer_Value__c)) {
                nameVsTaxo.get(taxo.Customer_Value__c).add(taxo);
                taxoValues.add(taxo.Customer_Value__c);
            }            
        }
        List<String> taxoNames = new List<String>();
        taxoNames.addAll(nameVsTaxo.keySet());
        taxoNames.sort();
        for(String name : taxoNames) {
            if(name == HIGH_SORT_STR_VALUE) {
                for(Taxonomy_Metadata__c taxo : nameVsTaxo.get(name)) {
                    taxo.Customer_Value__c = '';
                }
            }
            sortedTaxo.addAll(nameVsTaxo.get(name));
        }
        return sortedTaxo;
    }
}