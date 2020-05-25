@isTest
private class TaxonomyRetriever_Test {
    private static String mode;
    private static String category;
    private static String subcategory;
    private static String level1LocValue;
    private static String level2LocValue;
    private static String level3LocValue;
    
    private static testMethod void testForRetrievingCategory() {
        mode = 'Road';
        category = 'Road rules';
        subcategory = 'Parking rules';
        level1LocValue = 'Region';
        level2LocValue = 'Sydney';
        level3LocValue = 'Sydney';
        setUpTestData(false, false);
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveIssueCategoryAndSubCategory('');
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get('Road:Road rules'));
        System.assert(subCat.contains(subcategory));
    }
    
    private static testMethod void testForRetrievingCategoryForSydneyTrains() {
        mode = 'Train';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Region';
        level2LocValue = 'Sydney';
        level3LocValue = 'Sydney';
        setUpTestData(false, true);
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveIssueCategoryAndSubCategory(GlobalConstants.WEBTOCASE_SOURCE_SYDNEY_TRAINS);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get('Train:Air Pollution'));
        System.assert(subCat.contains(subcategory));
    }
    
    private static testMethod void testForRetrievingCategoryForPassesAndFares() {
        mode = 'non-modal';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Region';
        level2LocValue = 'Sydney';
        level3LocValue = 'Sydney';
        setUpTestData(false, true);
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveIssueCategoryAndSubCategoryNonModal('tfnsw','non-modal','Tickets%2C%20Passes%20and%20Schemes');
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get('non-modal:Air Pollution'));
        System.assert(subCat.contains(subcategory));
    }    
    
    private static testMethod void testForRetrievingCategoryForNswTrains() {
        mode = 'Train';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Region';
        level2LocValue = 'Sydney';
        level3LocValue = 'Sydney';
        setUpTestData(true, false);
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveIssueCategoryAndSubCategory(GlobalConstants.WEBTOCASE_SOURCE_NSW_TRAINS);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get('Train:Air Pollution'));
        System.assert(subCat.contains(subcategory));
    }
    
    private static testMethod void testForRetrievingStationForSydneyTrains() {
        mode = 'Train';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Sydney Trains Stations';
        level2LocValue = 'CBD Inner West';
        level3LocValue = 'Bondi Junction';
        setUpTestData(false, true);
        Train_station_location_level1_values__c trainStation = new Train_station_location_level1_values__c(Name=level1LocValue);
        insert trainStation;
        
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveLocationTaxonomy(GlobalConstants.WEBTOCASE_SOURCE_SYDNEY_TRAINS,mode);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get(mode+ ':' + Label.Train_Station));
        System.assert(subCat.contains(level3LocValue));
    }
    
    private static testMethod void testForRetrievingLineForNswTrains() {
        mode = 'Train';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'NSW TrainLink Intercity Train Lines';
        level2LocValue = 'Train Line';
        level3LocValue = 'Blue Mountains Line';
        setUpTestData(true, false);
        Train_line_location_level1_values__c trainLine = new Train_line_location_level1_values__c(Name=level1LocValue);
        insert trainLine;
        
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveLocationTaxonomy(GlobalConstants.WEBTOCASE_SOURCE_NSW_TRAINS,mode);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get(mode+ ':' + Label.Train_Line));
        System.assert(subCat.contains(level3LocValue));
    }
        
    private static testMethod void testForRetrievingFerryRoute() {
        mode = 'Ferry';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Sydney Ferries - Ferry';
        level2LocValue = 'Manly';
        level3LocValue = 'F1 - Manly Ferry';
        setUpTestData(false, false);
        Ferry_route_location_level1_values__c ferryRoute = new Ferry_route_location_level1_values__c(Name=level1LocValue);
        insert ferryRoute;
        
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveLocationTaxonomy('',mode);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get(mode+ ':' + Label.Ferry_Route));
        System.assert(subCat.contains(level3LocValue));
    }
    
    private static testMethod void testForRetrievingFerryWharf() {
        mode = 'Ferry';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Sydney Ferries - Wharf';
        level2LocValue = 'Manly';
        level3LocValue = 'Manly';       
        setUpTestData(false, false);
        Ferry_wharf_location_level1_values__c ferryWharf = new Ferry_wharf_location_level1_values__c(Name=level1LocValue);
        insert ferryWharf;
        
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveLocationTaxonomy('',mode);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get(mode+ ':' + Label.Ferry_Wharf));
        System.assert(subCat.contains(level3LocValue));
    }
    
    private static testMethod void testForRetrievingBusRoute() {
        mode = 'Bus';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Busways Blacktown';
        level2LocValue = 'SMBSC 1';
        level3LocValue = '673';
        setUpTestData(false, false);
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveLocationTaxonomy('',mode);
        List<String> matchingBusTaxo = WebToCase_CX.getMatchingLocTaxonomy('6', mode, false);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get(mode+ ':' + Label.Bus_Route));
        System.assert(subCat.contains(level3LocValue));
        System.assert(matchingBusTaxo.contains(level3LocValue));
        
    }
    
    private static testMethod void testForRetrievingLocationForLightRail() {
        mode = 'Light Rail';
        category = 'Air Pollution';
        subcategory = 'Air';
        level1LocValue = 'Light Rail';
        level2LocValue = 'Light Rail';
        level3LocValue = 'Dulwich Hill Line';
        setUpTestData(false, false);
        System.Test.startTest();
        Map<String,List<String>> taxonomyData = TaxonomyRetriever.retrieveLocationTaxonomy('',mode);
        System.Test.stopTest();
        System.assert(!taxonomyData.isEmpty());
        Set<String> subCat = new Set<String>();
        subCat.addAll(taxonomyData.get(mode+ ':'));
        System.assert(subCat.contains(level3LocValue));
    }
    
    private static void setUpTestData(Boolean isNswTrains, Boolean isSydneyTrains) {
        createTaxonomy(isNswTrains, isSydneyTrains);
    }   
        
    private static void createTaxonomy(Boolean isNswTrains, Boolean isSydneyTrains) {      
        Taxonomy_Metadata__c modeTaxonomy = new Taxonomy_Metadata__c();
        modeTaxonomy.Type__c = 'Mode';
        modeTaxonomy.Status_Customer_Facing__c = 'Active';
        modeTaxonomy.Status_Staff_Facing__c = 'Active';
        modeTaxonomy.Customer_Value__c = mode;
        modeTaxonomy.Name = mode;
        modeTaxonomy.Status_NSWT_Customer_Facing__c = (isNswTrains? 'Active' : 'Inactive');
        modeTaxonomy.Status_ST_Customer_Facing__c = (isSydneyTrains? 'Active' : 'Inactive');
        
        insert modeTaxonomy;
        
        List<Taxonomy_Metadata__c> level1Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c level1Loc = new Taxonomy_Metadata__c();
        level1Loc.Type__c = 'Location';
        level1Loc.Status_Customer_Facing__c = 'Active';
        level1Loc.Status_Staff_Facing__c = 'Active';
        level1Loc.Customer_Value__c = level1LocValue;
        level1Loc.Name = level1LocValue;
        level1Loc.Parent_Id__c = modeTaxonomy.Id;
        level1Loc.Status_NSWT_Customer_Facing__c = (isNswTrains? 'Active' : 'Inactive');
        level1Loc.Status_ST_Customer_Facing__c = (isSydneyTrains? 'Active' : 'Inactive');
        level1Taxonomies.add(level1Loc);
        
        Taxonomy_Metadata__c level1Issue = new Taxonomy_Metadata__c();
        level1Issue.Type__c = 'Issue';
        level1Issue.Status_Customer_Facing__c = 'Active';
        level1Issue.Status_Staff_Facing__c = 'Active';
        level1Issue.Customer_Value__c = 'Road';
        level1Issue.Name = 'Road';
        level1Issue.Parent_Id__c = modeTaxonomy.Id;
        level1Issue.Status_NSWT_Customer_Facing__c = (isNswTrains? 'Active' : 'Inactive');
        level1Issue.Status_ST_Customer_Facing__c = (isSydneyTrains? 'Active' : 'Inactive');
        level1Taxonomies.add(level1Issue);
        
        insert level1Taxonomies;
        
        List<Taxonomy_Metadata__c> level2Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c level2Loc = new Taxonomy_Metadata__c();
        level2Loc.Type__c = 'Location';
        level2Loc.Status_Customer_Facing__c = 'Active';
        level2Loc.Status_Staff_Facing__c = 'Active';
        level2Loc.Customer_Value__c = level2LocValue;
        level2Loc.Name = level2LocValue;
        level2Loc.Parent_Id__c = level1Loc.Id;
        level2Loc.Status_NSWT_Customer_Facing__c = (isNswTrains? 'Active' : 'Inactive');
        level2Loc.Status_ST_Customer_Facing__c = (isSydneyTrains? 'Active' : 'Inactive');
        level2Taxonomies.add(level2Loc);
        
        Taxonomy_Metadata__c level2Issue = new Taxonomy_Metadata__c();
        level2Issue.Type__c = 'Issue';
        level2Issue.Status_Customer_Facing__c = 'Active';
        level2Issue.Status_Staff_Facing__c = 'Active';
        level2Issue.Customer_Value__c = category;
        level2Issue.Name = category;
        level2Issue.Parent_Id__c = level1Issue.Id;
        level2Issue.Status_NSWT_Customer_Facing__c = (isNswTrains? 'Active' : 'Inactive');
        level2Issue.Status_ST_Customer_Facing__c = (isSydneyTrains? 'Active' : 'Inactive');
        level2Taxonomies.add(level2Issue);
        
        insert level2Taxonomies;
        
        List<Taxonomy_Metadata__c> level3Taxonomies = new List<Taxonomy_Metadata__c>();
        Taxonomy_Metadata__c taxonomyLoc = new Taxonomy_Metadata__c();
        taxonomyLoc.Agency__c = 'RMS';
        taxonomyLoc.Customer_Value__c = level3LocValue;
        taxonomyLoc.Name = level3LocValue;
        taxonomyLoc.Issue_Accountability__c = 'Test Location Taxonomy';
        taxonomyLoc.Driver__c = '';
        taxonomyLoc.KPI__c = '';
        taxonomyLoc.Parent_Id__c = level2Loc.Id;
        taxonomyLoc.Status_Customer_Facing__c = 'Active';
        taxonomyLoc.Status_Staff_Facing__c = 'Active';
        taxonomyLoc.Status_NSWT_Customer_Facing__c = (isNswTrains? 'Active' : 'Inactive');
        taxonomyLoc.Status_ST_Customer_Facing__c = (isSydneyTrains? 'Active' : 'Inactive');
        taxonomyLoc.Type__c = 'Location'; 

        Taxonomy_Metadata__c taxonomyIssue = new Taxonomy_Metadata__c();
        taxonomyIssue.Agency__c = 'RMS';
        taxonomyIssue.Customer_Value__c = subcategory;
        taxonomyIssue.Name = subcategory;
        taxonomyIssue.Issue_Accountability__c = 'Test Location Taxonomy';
        taxonomyIssue.Driver__c = '';
        taxonomyIssue.KPI__c = '';
        taxonomyIssue.Parent_Id__c = level2Issue.Id;
        taxonomyIssue.Status_Customer_Facing__c = 'Active';
        taxonomyIssue.Status_Staff_Facing__c = 'Active';
        taxonomyIssue.Status_NSWT_Customer_Facing__c = (isNswTrains? 'Active' : 'Inactive');
        taxonomyIssue.Status_ST_Customer_Facing__c = (isSydneyTrains? 'Active' : 'Inactive');
        taxonomyIssue.Type__c = 'Issue';        
        level3Taxonomies.add(taxonomyIssue);
        level3Taxonomies.add(taxonomyLoc);
        insert level3Taxonomies;
    }
}