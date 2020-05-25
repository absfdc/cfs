/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    utility class for retrieving taxonomy data.
Inputs:         
Test Class:     TaxonomyRetriever_Test
History:
                25/June/2018 Ian Fitzgerald  Added section for On Demand label to method retrieveLocationTaxonomy
------------------------------------------------------------*/
public class TaxonomyRetriever {
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Helper method for retrieving issue category (level2) and subcategory (level3) metadata
    Inputs:         
    Returns:        Map<String,List<String>> - returns mapping of category and subcategory where key of map is of the form mode:category
                    where mode is level0 value and category is level2 values.
    History:
    ------------------------------------------------------------*/

	static List<Metro_line_location_level_1_values__mdt> metroLineLabel = [select MasterLabel from Metro_line_location_level_1_values__mdt];
	static List<Metro_station_location_level_1_values__mdt> metroStationLabel = [select MasterLabel from Metro_station_location_level_1_values__mdt];

    static List<String> metroLineLabelList = new List<String>();
    static List<String> metroStationLabelList = new List<String>();
    
    static{
        for(Metro_line_location_level_1_values__mdt aMetroLine:metroLineLabel){
            metroLineLabelList.add((String)aMetroLine.MasterLabel);
        }

        for(Metro_station_location_level_1_values__mdt aMetroStation:metroStationLabel){
            metroStationLabelList.add((String)aMetroStation.MasterLabel);
        }
    }
    
    
    public static Map<String,List<String>> retrieveIssueCategoryAndSubCategory(String source) {
        Map<String,List<String>> catVsSubCat = new Map<String,List<String>>();
        Map<String, List<Taxonomy_Metadata__c>> level2VsLevel3 = new Map<String, List<Taxonomy_Metadata__c>>();
        
        List<Taxonomy_Metadata__c> rmsCatLevel0 = [ SELECT Id, (SELECT Id, Customer_Value__c 
                                                                FROM Child_Metadata__r 
                                                                WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_ISSUE)
                                                    FROM Taxonomy_Metadata__c
                                                    WHERE Type__c = :GlobalConstants.TAXONOMY_MODE_TYPE];
        if(!rmsCatLevel0.isEmpty()) {
            System.debug('RmsCatLevel0 size: ' + rmsCatLevel0.size());
            List<Taxonomy_Metadata__c> rmsCatLevel1 = new List<Taxonomy_Metadata__c>();
            for(Taxonomy_Metadata__c modeTaxonomy: rmsCatLevel0) {
                rmsCatLevel1.addAll(modeTaxonomy.Child_Metadata__r);
            }
            if(!rmsCatLevel1.isEmpty()) {
                List<Taxonomy_Metadata__c> rmsCatLevel2 = [ SELECT Id, Customer_Value__c, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Parent_Id__r.Parent_Id__r.Name,
                                                                    ( SELECT Id, Customer_Value__c, Name, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Customer_facing_sort_order__c
                                                                        FROM Child_Metadata__r 
                                                                        WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_ISSUE
                                                                            AND (Status_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE) 
                                                                                OR Status_NSWT_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE)
                                                                                OR Status_ST_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE))
                                                                        ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST)
                                                            FROM Taxonomy_Metadata__c
                                                            WHERE Parent_Id__c IN :rmsCatLevel1
                                                            ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST];
                System.debug('RmsCatLevel2 size: ' + rmsCatLevel2.size());  
                if(!rmsCatLevel2.isEmpty()) {
                    for(Taxonomy_Metadata__c level2 : rmsCatLevel2) {
                        List<Taxonomy_Metadata__c> rmsCatLevel3 = level2.Child_Metadata__r;
                        System.debug('rmsCatLevel3: ' + rmsCatLevel3);
                        List<Taxonomy_Metadata__c> subCategoryTaxo = new List<Taxonomy_Metadata__c>();
                        List<Taxonomy_Metadata__c> subCategoryForStTaxo = new List<Taxonomy_Metadata__c>();
                        List<Taxonomy_Metadata__c> subCategoryForNswtTaxo = new List<Taxonomy_Metadata__c>();
                        
                        for(Taxonomy_Metadata__c taxonomy : rmsCatLevel3) {
                            subCategoryTaxo.add(taxonomy);
                            if(!String.IsBlank(taxonomy.Status_NSWT_Customer_Facing__c) 
                                && taxonomy.Status_NSWT_Customer_Facing__c == GlobalConstants.TAXONOMY_STATUS_ACTIVE) {
                                subCategoryForNswtTaxo.add(taxonomy);
                            }
                            if(!String.IsBlank(taxonomy.Status_ST_Customer_Facing__c) 
                                && taxonomy.Status_ST_Customer_Facing__c == GlobalConstants.TAXONOMY_STATUS_ACTIVE) {
                                subCategoryForStTaxo.add(taxonomy);
                            }                            
                        }
                        
                        if(!rmsCatLevel3.isEmpty()) {
                            if(!String.isBlank(source) && source.toLowerCase() == GlobalConstants.WEBTOCASE_SOURCE_SYDNEY_TRAINS) {
                                subCategoryTaxo = subCategoryForStTaxo;
                                if(!String.IsBlank(level2.Status_ST_Customer_Facing__c) 
                                    && level2.Status_ST_Customer_Facing__c == GlobalConstants.TAXONOMY_STATUS_ACTIVE
                                    && !subCategoryTaxo.isEmpty()) {
                                    if(level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c))) {
                                        subCategoryTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c)));
                                    }
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c), subCategoryTaxo);
                                    
                                }
                            } else if(!String.isBlank(source) && source.toLowerCase() == GlobalConstants.WEBTOCASE_SOURCE_NSW_TRAINS) {
                                subCategoryTaxo = subCategoryForNswtTaxo;
                                if(!String.IsBlank(level2.Status_NSWT_Customer_Facing__c) 
                                    && level2.Status_NSWT_Customer_Facing__c == GlobalConstants.TAXONOMY_STATUS_ACTIVE
                                    && !subCategoryTaxo.isEmpty()) {
                                    if(level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c))) {
                                        subCategoryTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c)));
                                    }
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c), subCategoryTaxo);
                                }
                            } else {
                                if(level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c))) {
                                    subCategoryTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c)));
                                }
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c), subCategoryTaxo);
                            }
                        }                        
                    }
                }
            }
        }
        
        
        List<String> sortLevel2 = new List<String>(level2VsLevel3.keySet());
        sortLevel2.sort();
        
        
        for(String level2 : sortLevel2) {//level2VsLevel3.keySet()
            level2VsLevel3.put(level2, TaxonomySorter.sort(level2VsLevel3.get(level2)));
        }
        for(String level2 : level2VsLevel3.keySet()) {
            List<String> level3 = new List<String>();
            for(Taxonomy_Metadata__c taxo : level2VsLevel3.get(level2)) {
                level3.add(taxo.Customer_Value__c);
            }
            catVsSubCat.put(level2, level3);
        }
        return catVsSubCat;
    }    
    
    
    //SFCOE-2369 - Non Modal Issue Taxonomy Changes - 13/03/2018 - Start
        
    public static Map<String,List<String>> retrieveIssueCategoryAndSubCategoryNonModal(String source, String about, String ilvl2) {
        Map<String,List<String>> catVsSubCat = new Map<String,List<String>>();
        Map<String, List<Taxonomy_Metadata__c>> level2VsLevel3 = new Map<String, List<Taxonomy_Metadata__c>>();
        
        List<Taxonomy_Metadata__c> rmsCatLevel0 = [ SELECT Id, (SELECT Id, Customer_Value__c 
                                                                FROM Child_Metadata__r 
                                                                WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_ISSUE)
                                                    FROM Taxonomy_Metadata__c
                                                    WHERE Type__c = :GlobalConstants.TAXONOMY_MODE_TYPE];
        if(!rmsCatLevel0.isEmpty()) {
            System.debug('RmsCatLevel0 size: ' + rmsCatLevel0.size());
            List<Taxonomy_Metadata__c> rmsCatLevel1 = new List<Taxonomy_Metadata__c>();
            for(Taxonomy_Metadata__c modeTaxonomy: rmsCatLevel0) {
                rmsCatLevel1.addAll(modeTaxonomy.Child_Metadata__r);
            }
            if(!rmsCatLevel1.isEmpty()) {
                List<Taxonomy_Metadata__c> rmsCatLevel2 = [ SELECT Id, Hide_Passes__c, Hide_Non_Modal_Webform__c, Customer_Value__c, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Parent_Id__r.Parent_Id__r.Name,
                                                                    ( SELECT Id, Hide_Passes__c, Hide_Non_Modal_Webform__c, Customer_Value__c, Name, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Customer_facing_sort_order__c
                                                                        FROM Child_Metadata__r 
                                                                        WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_ISSUE
                                                                            AND (Status_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE) 
                                                                                OR Status_NSWT_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE)
                                                                                OR Status_ST_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE))
                                                                        ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST)
                                                            FROM Taxonomy_Metadata__c
                                                            WHERE Parent_Id__c IN :rmsCatLevel1
                                                            ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST];
                System.debug('RmsCatLevel2 size: ' + rmsCatLevel2.size());  
                if(!rmsCatLevel2.isEmpty()) {
                    for(Taxonomy_Metadata__c level2 : rmsCatLevel2) {
                    	
                    
                    if(about.equalsIgnoreCase('non-modal') && ilvl2.indexOf('passes')==-1 && level2.Hide_Non_Modal_Webform__c!=true ){
                    	
                        List<Taxonomy_Metadata__c> rmsCatLevel3 = level2.Child_Metadata__r;
                        System.debug('rmsCatLevel3: ' + rmsCatLevel3);
                        List<Taxonomy_Metadata__c> subCategoryTaxo = new List<Taxonomy_Metadata__c>();
                        
                        for(Taxonomy_Metadata__c taxonomy : rmsCatLevel3) {
                            if(taxonomy.Hide_Non_Modal_Webform__c!=true) subCategoryTaxo.add(taxonomy);
                        }
                        
                        if(!rmsCatLevel3.isEmpty()) {
                                if(level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c))) {
                                    subCategoryTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c)));
                                }
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c), subCategoryTaxo);
                        }                        
                    
                    }  //If - non modal condition
                    
                    else if(about.equalsIgnoreCase('non-modal') && ilvl2.contains('passes') && level2.Hide_Passes__c!=true ){

                        List<Taxonomy_Metadata__c> rmsCatLevel3 = level2.Child_Metadata__r;
                        System.debug('rmsCatLevel3: ' + rmsCatLevel3);
                        List<Taxonomy_Metadata__c> subCategoryTaxo = new List<Taxonomy_Metadata__c>();
                        
                        for(Taxonomy_Metadata__c taxonomy : rmsCatLevel3) {
                            if(taxonomy.Hide_Passes__c!=true) subCategoryTaxo.add(taxonomy);
                        }
                        
                        if(!rmsCatLevel3.isEmpty()) {
                                if(level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c))) {
                                    subCategoryTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c)));
                                }
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + level2.Customer_Value__c), subCategoryTaxo);
                        }
                    	
                    	
                    }  //End of else if
                    
                    }
                }
            }
        }
        
        
        List<String> sortLevel2 = new List<String>(level2VsLevel3.keySet());
        sortLevel2.sort();
        
        
        for(String level2 : sortLevel2) {//level2VsLevel3.keySet()
            level2VsLevel3.put(level2, TaxonomySorter.sort(level2VsLevel3.get(level2)));
        }
        for(String level2 : level2VsLevel3.keySet()) {
            List<String> level3 = new List<String>();
            for(Taxonomy_Metadata__c taxo : level2VsLevel3.get(level2)) {
                level3.add(taxo.Customer_Value__c);
            }
            catVsSubCat.put(level2, level3);
        }
        return catVsSubCat;
    }
    
  
    //SFCOE-2369 - Non Modal Issue Taxonomy Changes - 13/03/2018 - End
    
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Helper method for retrieving location taxonomy (level3)
    Inputs:         
    Returns:        Map<String,List<String>> - returns mapping of location type (usually label for field on webform) and location (level3) 
                    where key of map is of the form mode:locaiton type (e.g. Train:Train Station).
    History:      
                    25/06/2018  Ian Fitzgerald  Added section for On Demand 
                    03/06/2020 Abhi Indulkar    Performance tuning. Filter level1 taxonomies only for the required mode.
    ------------------------------------------------------------*/
    public static Map<String,List<String>> retrieveLocationTaxonomy(String source, String modes) {
        Map<String, Ferry_route_location_level1_values__c> ferryRouteLevel1 = Ferry_route_location_level1_values__c.getAll();
        Map<String, Ferry_wharf_location_level1_values__c> ferryWharfLevel1 = Ferry_wharf_location_level1_values__c.getAll();
        Map<String, Train_line_location_level1_values__c> trainLineLevel1 = Train_line_location_level1_values__c.getAll();
        Map<String, Train_station_location_level1_values__c> trainStationLevel1 = Train_station_location_level1_values__c.getAll();
        
        Map<String,List<String>> catVsSubCat = new Map<String,List<String>>();
        Map<String, List<Taxonomy_Metadata__c>> level2VsLevel3 = new Map<String, List<Taxonomy_Metadata__c>>();
        List<Taxonomy_Metadata__c> locLevel0 = [SELECT Id 
                                                    FROM Taxonomy_Metadata__c 
                                                    WHERE Type__c = :GlobalConstants.TAXONOMY_MODE_TYPE 
                                                    AND name = :modes];
        List<Taxonomy_Metadata__c> rmsLocLevel0;
        if(locLevel0.isEmpty()){
            rmsLocLevel0 = [ SELECT Id, (SELECT Id, Customer_Value__c 
                                                                FROM Child_Metadata__r 
                                                                WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION)
                                                    FROM Taxonomy_Metadata__c
                                                    WHERE Type__c = :GlobalConstants.TAXONOMY_MODE_TYPE];
        }else{
            rmsLocLevel0 = [ SELECT Id, (SELECT Id, Customer_Value__c 
                                        FROM Child_Metadata__r 
                                        WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION)
                            FROM Taxonomy_Metadata__c
                            WHERE Type__c = :GlobalConstants.TAXONOMY_MODE_TYPE
                            AND Id = :locLevel0[0].Id];
        }
        
        
        if(!rmsLocLevel0.isEmpty()) {
            System.debug('rmsLocLevel0 size: ' + rmsLocLevel0.size());
            List<Taxonomy_Metadata__c> rmsLocLevel1 = new List<Taxonomy_Metadata__c>();
            for(Taxonomy_Metadata__c modeTaxonomy: rmsLocLevel0) {
                rmsLocLevel1.addAll(modeTaxonomy.Child_Metadata__r);
            }
            if(!rmsLocLevel1.isEmpty()) {
                List<Taxonomy_Metadata__c> rmsLocLevel2 = [ SELECT Id, Customer_Value__c, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Name, Parent_Id__r.Customer_Value__c, 
                                                                    ( SELECT Id, Customer_Value__c, Name, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Customer_facing_sort_order__c
                                                                        FROM Child_Metadata__r 
                                                                        WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION   
                                                                            AND (Status_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE) 
                                                                                OR Status_NSWT_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE)
                                                                                OR Status_ST_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE))
                                                                        ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST)
                                                            FROM Taxonomy_Metadata__c
                                                            WHERE Parent_Id__c IN :rmsLocLevel1
                                                            ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST];
                System.debug('rmsLocLevel2 size: ' + rmsLocLevel2.size());  
                if(!rmsLocLevel2.isEmpty()) {
                    for(Taxonomy_Metadata__c level2 : rmsLocLevel2) {
                        List<Taxonomy_Metadata__c> rmsLocLevel3 = level2.Child_Metadata__r;                     
                        List<Taxonomy_Metadata__c> locationsTaxo = new List<Taxonomy_Metadata__c>();
                        List<Taxonomy_Metadata__c> locationsForStTaxo = new List<Taxonomy_Metadata__c>();
                        List<Taxonomy_Metadata__c> locationsForNswtTaxo = new List<Taxonomy_Metadata__c>();
                        
                        for(Taxonomy_Metadata__c taxonomy : rmsLocLevel3) {
                            if(!String.isBlank(taxonomy.Customer_Value__c)) {
                                locationsTaxo.add(taxonomy);
                            }                            
                            if(!String.IsBlank(taxonomy.Status_NSWT_Customer_Facing__c) 
                                && taxonomy.Status_NSWT_Customer_Facing__c == GlobalConstants.TAXONOMY_STATUS_ACTIVE) {
                                locationsForNswtTaxo.add(taxonomy);
                            }
                            if(!String.IsBlank(taxonomy.Status_ST_Customer_Facing__c) 
                                && taxonomy.Status_ST_Customer_Facing__c == GlobalConstants.TAXONOMY_STATUS_ACTIVE) {
                                locationsForStTaxo.add(taxonomy);
                            }                            
                        }
                        if(!String.isBlank(source) && source.toLowerCase() == GlobalConstants.WEBTOCASE_SOURCE_SYDNEY_TRAINS) {
                            locationsTaxo = locationsForStTaxo;
                            if(String.IsBlank(level2.Status_ST_Customer_Facing__c) 
                                || level2.Status_ST_Customer_Facing__c != GlobalConstants.TAXONOMY_STATUS_ACTIVE) {
                                locationsTaxo.clear();
                            }
                        } else if(!String.isBlank(source) && source.toLowerCase() == GlobalConstants.WEBTOCASE_SOURCE_NSW_TRAINS) {
                            locationsTaxo = locationsForNswtTaxo;
                            if(String.IsBlank(level2.Status_NSWT_Customer_Facing__c) 
                                || level2.Status_NSWT_Customer_Facing__c != GlobalConstants.TAXONOMY_STATUS_ACTIVE) {
                                locationsTaxo.clear();
                            }
                        }
                        if(!locationsTaxo.isEmpty()) {
                            if(level2.Parent_Id__r.Parent_Id__r.Name == 'Bus') {
                                System.debug(LoggingLevel.INFO, 'Location for bus');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Bus_Route))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Bus_Route), new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Bus_Route)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Bus_Route), locationsTaxo);
                                
                            } else if(level2.Parent_Id__r.Parent_Id__r.Name == 'On Demand') {
                                System.debug(LoggingLevel.INFO, 'Location for on demand');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.On_Demand))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.On_Demand), new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.On_Demand)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.On_Demand), locationsTaxo);
                                
                            } else if(ferryRouteLevel1.keySet().contains(level2.Parent_Id__r.Customer_Value__c)) {
                                System.debug(LoggingLevel.INFO, 'Location for ferry route');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Route ))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Route)  , new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Route)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Route)  , locationsTaxo);
                                
                            } else if(ferryWharfLevel1.keySet().contains(level2.Parent_Id__r.Customer_Value__c)) {
                                System.debug(LoggingLevel.INFO, 'Location for ferry wharf');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Wharf ))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Wharf) , new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Wharf)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Ferry_Wharf)  , locationsTaxo);
                                
                            } else if(metroLineLabelList.contains(level2.Parent_Id__r.Customer_Value__c)) {
                                System.debug(LoggingLevel.INFO, 'Location for train line');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Line ))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Line) , new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Line)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Line ) , locationsTaxo);
                                
                            } else if(trainLineLevel1.keySet().contains(level2.Parent_Id__r.Customer_Value__c)) {
                                System.debug(LoggingLevel.INFO, 'Location for train line');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Line ))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Line) , new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Line)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Line ) , locationsTaxo);
                                
                            } else if(metroStationLabelList.contains(level2.Parent_Id__r.Customer_Value__c)){
                                System.debug(LoggingLevel.INFO, 'Location for train station');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Station ))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Station ), new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Station)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Metro_Station) , locationsTaxo);
                                
                            } else if(trainStationLevel1.keySet().contains(level2.Parent_Id__r.Customer_Value__c)){
                                System.debug(LoggingLevel.INFO, 'Location for train station');
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Station ))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Station ), new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Station)));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' + Label.Train_Station) , locationsTaxo);
                                
                            } else {
                                if(!level2VsLevel3.containsKey(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':'))) {
                                    level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':' ), new List<Taxonomy_Metadata__c>());
                                }
                                
                                locationsTaxo.addAll(level2VsLevel3.get(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':')));
                                level2VsLevel3.put(String.escapeSingleQuotes(level2.Parent_Id__r.Parent_Id__r.Name + ':') , locationsTaxo);
                            }
                        }
                    }
                }
            }
        }
        for(String level2 : level2VsLevel3.keySet()) {
            level2VsLevel3.put(level2, TaxonomySorter.sort(level2VsLevel3.get(level2)));
        }
        for(String level2 : level2VsLevel3.keySet()) {
            List<String> level3 = new List<String>();
            for(Taxonomy_Metadata__c taxo : level2VsLevel3.get(level2)) {
                level3.add(taxo.Customer_Value__c);
            }
            catVsSubCat.put(level2, level3);
        }
        
        for(String x:catVsSubCat.keySet()){
            if(x.equalsIgnoreCase('Metro'))
            System.debug('level2: ' + x + '\t level3: ' + catVsSubCat.get(x));
        }
            
            
        
        System.debug('level2: Metro' + '\t level3: ' + catVsSubCat.get('Metro'));
        
        
        return catVsSubCat;
    }

    /*------------------------------------------------------------
    Author:         Abhi Indulkar
    Company:        Transport for NSW   
    Description:    Helper method for retrieving matching location taxonomy (level3)
    Inputs:         
    Returns:        List<String> - returns location (level3) taxonomy list
    History:      
    ------------------------------------------------------------*/
    public static List<String> retrieveMatchingLocTaxonomy(String pSearchKey, String modes, Boolean pSchoolRoute) {
        List<String> lMatchingLocations = new List<String>();
        pSearchKey = '%' + String.escapeSingleQuotes(pSearchKey) + '%';
        List<Taxonomy_Metadata__c> modeTaxonomy = [SELECT Id 
                                                    FROM Taxonomy_Metadata__c 
                                                    WHERE Type__c = :GlobalConstants.TAXONOMY_MODE_TYPE 
                                                    AND name = :modes];
        if(modeTaxonomy != null && !modeTaxonomy.isEmpty()){
            List<Taxonomy_Metadata__c> locations = [SELECT Id,Customer_Value__c 
                                                    FROM  Taxonomy_Metadata__c 
                                                    WHERE   Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION
                                                            AND School_Route__c = :pSchoolRoute 
                                                            AND (Status_Customer_Facing__c = :GlobalConstants.TAXONOMY_STATUS_ACTIVE 
                                                                OR Status_NSWT_Customer_Facing__c = :GlobalConstants.TAXONOMY_STATUS_ACTIVE 
                                                                OR Status_ST_Customer_Facing__c = :GlobalConstants.TAXONOMY_STATUS_ACTIVE)
                                                            AND Level__c = 'Level 3'
                                                            AND Parent_Id__r.Parent_Id__r.Parent_Id__c= :modeTaxonomy[0].Id
                                                            AND Customer_Value__c like :pSearchKey 
                                                            ORDER BY Length_of_name__c ASC, Customer_facing_sort_order__c ASC NULLS LAST,Customer_Value__c ASC NULLS LAST Limit 20];
        
            for(Taxonomy_Metadata__c taxonomy: locations){
                lMatchingLocations.add(taxonomy.Customer_Value__c);
            }
        }
                                                
        return lMatchingLocations;
    }
}