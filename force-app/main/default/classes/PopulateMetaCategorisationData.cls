public class PopulateMetaCategorisationData {
    
    /* 
     * Some background and context is required to understand this code, and is in order.
     * 
     * The idea is: We have to populate 4-level hierarchical records from Location and Issue Taxonomy Data
     * Example Location Taxonomy Data Row: (Level 0 Value =>) Bus, (Level 1 Value =>) Sydney Buses, (Level 2 Value =>) Brookvale, (Level 3 Value =>) E32, (Agency =>) STA, (other attributes ...)
     * The above row will appear as "Bus, Sydney Buses, Brookvale, E32, STA, ..."
     * Other attributes: KPI, Driver, Issue Accountability, Customer Facing, Staff Facing, Customer Value.
     * The other attributes are mapped as they are, hence no separate mentioning required.
     *
     * Staging data is read one row at a time and each row relates to a leaf node.
     * There are no entries for branches.  Therefore, branches are implied and created as a result
     * of seeing a leaf that contains a newly referenced branch.  Staff Facing, Customer Facing, and
     * Customer Facing Value all relate to leaf nodes, therefore when branches are created they are
     * created using the defaultStatusStaffFacing, defaultStatusCustomerFacing and a Customer Facing
     * Value that matches the name of the level being created.
     * 
     * Let us talk about the main attributes now: Bus, Sydney Buses, Brookvale, E32, STA
     * This should get mapped to 4 level Meta Categorisation rows (this was earlier called Taxonomy Metadata)
     * Let us name the 4 levels as Child, Parent, Grand Parent and Great Grand Parent.
     * 
     * Let us start with Great Grand Parent record for the above entry. This should contain "Name = Bus, Agency = STA, Type = Location, Id = (fictitious, say) GreatGrandParent, Parent Id = <Blank>"
     * The next (Grand Parent) level should contain the values "Name = Sydney Buses, Agency = STA, Type = Location, Id = (say) GrandParent, Parent Id = GreatGrandParent (above)"
     * THe next (Parent) level will contain the values "Name = Brookvale, Agency = STA, Type = Location, Id = (say) Parent, Parent Id = GrandParent (above)"
     * The last (Child) level will contain the values "Name = E32, Agency = STA, Type = Location, Id = (say) Child, Parent Id = Parent (above)"
     * 
     *  04-MAY-2015 B.Cawrse: added customer facing status + value + staff facing status
     *  06-AUG-2015 L.Mistry: added sort order for L2 and L3 taxonomy.
     */
    
    private Map<String, Taxonomy_Metadata__c> level0Map = new Map<String, Taxonomy_Metadata__c>();
    private Map<String, Taxonomy_Metadata__c> level1Map = new Map<String, Taxonomy_Metadata__c>();
    private Map<String, Taxonomy_Metadata__c> level2Map = new Map<String, Taxonomy_Metadata__c>();
    private Map<String, List<Taxonomy_Metadata__c>> level3Map = new Map<String, List<Taxonomy_Metadata__c>>();
    
    public void populateData() {
        final String defaultStatusCustomerFacing = 'Inactive'; // Applies to level0, level1
        final String defaultStatusStaffFacing = 'Active';    // Applies to level0, level1 and level2
        
        List<Taxonomy_Staging_Data__c> stagingDataList = [SELECT Id, Agency__c, Driver__c, Issue_Accountability__c, KPI__c, Level_1__c, Level_2__c,
                                                               Status_ST_Customer_Facing__c,Status_NSWT_Customer_Facing__c, Level_3__c, Mode__c, Type__c, 
                                                               Status_Customer_Facing_L2__c,Status_Customer_Facing_L3__c, Status_Staff_Facing__c, Customer_Value_L2__c, Customer_Value_L3__c, Staff_facing_sort_order_L2__c, Staff_facing_sort_order_L3__c, Customer_facing_sort_order_L2__c, Customer_facing_sort_order_L3__c
                                                          FROM Taxonomy_Staging_Data__c                                                      
                                                          ORDER By Customer_Value_L2__c ASC NULLS LAST, Customer_Value_L3__c ASC NULLS LAST limit 10000];
        System.debug('---STAGING DATA SIZE---' + stagingDataList.size());        
        for (Taxonomy_Staging_Data__c stagingData: stagingDataList) {
            System.debug('---STAGING DATA---:T:' + stagingData.Type__c 
                                      + '-M-'  + stagingData.Mode__c 
                                      + '-CF-' + stagingData.Status_Customer_Facing_L2__c + '/'+ stagingData.Status_Customer_Facing_L3__c
                                      + '-CV-' + stagingData.Customer_Value_L2__c + '/' + stagingData.Customer_Value_L3__c);
            String statusCustomerFacingL2 = stagingData.Status_Customer_Facing_L3__c == 'Active' ? 'Active' : stagingData.Status_Customer_Facing_L2__c;
            String statusCustomerFacingL3 = stagingData.Status_Customer_Facing_L3__c;
            String statusStaffFacing = stagingData.Status_Staff_Facing__c;
            String statusSTCustomerFacing = (stagingData.Status_ST_Customer_Facing__c == null || stagingData.Status_ST_Customer_Facing__c == '') ? 'Inactive' : stagingData.Status_ST_Customer_Facing__c;
            String statusNSWTCustomerFacing = (stagingData.Status_NSWT_Customer_Facing__c == null || stagingData.Status_NSWT_Customer_Facing__c == '') ? 'Inactive' : stagingData.Status_NSWT_Customer_Facing__c;
            String statusSTCustomerFacingForChild = (statusSTCustomerFacing == 'Active') ? 'Active' : 'Inactive';
            String statusNSWTCustomerFacingForChild = (statusNSWTCustomerFacing == 'Active') ? 'Active' : 'Inactive';
            
            
            
            String customerValueL2 = stagingData.Type__c == 'Location' ? stagingData.Level_2__c : (stagingData.Customer_Value_L2__c == null ? stagingData.Level_2__c  : stagingData.Customer_Value_L2__c);
            String customerValueL3 = stagingData.Customer_Value_L3__c;
            
            
            // The Level 0 - great grand parent level key will be the unique Level 0 (Mode) values (Bus / Train / ...)
            String level0Key = stagingData.Mode__c;
            
            // The Level 1 - grand parent level key will be the unique combination of Type, Level 0, Level 1 (e.g. Location|Bus|Sydney Buses)
            String level1Key = stagingData.Type__c + '|' + stagingData.Mode__c + '|' + stagingData.Level_1__c;
 
            // The Level 2 - parent level entry will contain a unique combination of Level 0, Level 1, Level 2 (e.g. Location|Bus|Sydney Buses|Brookvale)
            String level2Key = level1Key + '|' + stagingData.Level_2__c;
 
            // The Level 3 - child level entry will contain a unique combination of Level 0, Level 1, Level 2, Level 3 (e.g. Location|Bus|Sydney Buses|Brookvale|E32)
            String level3Key = level2Key + '|' + stagingData.Level_3__c;
            
            // We will use the above key combination in unique way later, to relate any child with its corresponding parent level.
            // E.g. in the above example, if level2Key contains Bus|Sydney Buses|Brookvale, to determine its corresponding Level 1 parent record, the code will remove the last token (viz. Bus|Sydney Buses)
                        
            // System.debug('Staging data level3Key is ' + level3Key);
                
            // Let us now start checking each levels, taking necessary actions. Let's start with the great grand parent.
            if (!(level0Map.containsKey(level0Key))) {
                // This means we have a new/fresh Level 0 entry. We have to therefore create the great grand parent entry
                Taxonomy_Metadata__c level0Entry = new Taxonomy_Metadata__c(Name = stagingData.Mode__c, 
                                                                            Type__c = 'Mode', 
                                                                            Status_Customer_Facing__c = defaultStatusCustomerFacing, 
                                                                            Status_Staff_Facing__c = defaultStatusStaffFacing, 
                                                                            Customer_Value__c = stagingData.Mode__c);
                level0Map.put(level0Key, level0Entry); 
            }
            
            if (!(level1Map.containsKey(level1Key))) {
                // This means we have a new/fresh Level 1 entry. We have to therefore create the grand parent entry
                //5 May 2015 - Manish Damle:
                //Added new status fields for Sydney Trains and NSWT customer facing.
                //Copy the ST Customer Facing status and NSWT Customer Facing status values as it is from the CSV file.
                Taxonomy_Metadata__c level1Entry = new Taxonomy_Metadata__c(Name = stagingData.Level_1__c, 
                                                                            Type__c = stagingData.Type__c, 
                                                                            Status_Customer_Facing__c = defaultStatusCustomerFacing, 
                                                                            Status_Staff_Facing__c = defaultStatusStaffFacing, 
                                                                            Status_ST_Customer_Facing__c = statusSTCustomerFacing,
                                                                            Status_NSWT_Customer_Facing__c = statusNSWTCustomerFacing,
                                                                            Customer_Value__c = stagingData.Level_1__c);
                level1Map.put(level1Key, level1Entry); 
            }
            
            if (!(level2Map.containsKey(level2Key))) {
                // This means we have a new/fresh Level 2 entry. We have to therefore create the parent entry
                //5 May 2015 - Manish Damle:
                //If level 1 has ST Customer Status = active then status of the Level 2 and Level 3 should be active
                //If level 1 has NSWT Customer Status = active then status of the Level 2 and Level 3 should be active
                //1 June 2015 - Manish Damle:
                //Customer Value L2 and Customer Status L2 are now separately captured on L2
                //Customer Value L3 and Customer Status L3 are now separately captured on L3
                Taxonomy_Metadata__c level2Entry = new Taxonomy_Metadata__c(Name = stagingData.Level_2__c, 
                                                                            Type__c = stagingData.Type__c, 
                                                                            Status_Customer_Facing__c = statusCustomerFacingL2, 
                                                                            Status_Staff_Facing__c = defaultStatusStaffFacing, 
                                                                            Status_ST_Customer_Facing__c = statusSTCustomerFacingForChild,
                                                                            Status_NSWT_Customer_Facing__c = statusNSWTCustomerFacingForChild,
                                                                            Customer_Value__c = customerValueL2,
                                                                            Staff_facing_sort_order__c = stagingData.Staff_facing_sort_order_L2__c,
                                                                            Customer_facing_sort_order__c = stagingData.Customer_facing_sort_order_L2__c);
                level2Map.put(level2Key, level2Entry); 
            }

            Taxonomy_Metadata__c level3Entry = new Taxonomy_Metadata__c(Name = stagingData.Level_3__c, 
                                                                        Type__c = stagingData.Type__c, 
                                                                        Agency__c = stagingData.Agency__c, 
                                                                        KPI__c = stagingData.KPI__c, 
                                                                        Driver__c = stagingData.Driver__c, 
                                                                        Issue_Accountability__c = stagingData.Issue_Accountability__c, 
                                                                        Status_Customer_Facing__c = statusCustomerFacingL3, 
                                                                        Status_Staff_Facing__c = statusStaffFacing, 
                                                                        Status_ST_Customer_Facing__c = statusSTCustomerFacingForChild,
                                                                        Status_NSWT_Customer_Facing__c = statusNSWTCustomerFacingForChild,
                                                                        Customer_Value__c = customerValueL3,
                                                                        Staff_facing_sort_order__c = stagingData.Staff_facing_sort_order_L3__c,
                                                                        Customer_facing_sort_order__c = stagingData.Customer_facing_sort_order_L3__c);

            if (level3Map.containsKey(level3Key)) {
                // The combination of Level 0|Level 1|Level 2|Level 3 has been encountered before. Add other values.
                List<Taxonomy_Metadata__c> existingLevel3MetaDataList = level3Map.get(level3Key);
                existingLevel3MetaDataList.add(level3Entry);
            }
            else {
                // This combination of Level 0|Level 1|Level 2|Level 3 has been encountered for the first time. Create a new list
                List<Taxonomy_Metadata__c> level3MetaDataList = new List<Taxonomy_Metadata__c>();
                level3MetaDataList.add(level3Entry);
                level3Map.put(level3Key, level3MetaDataList); 
            }

        } // end for
        
        
        // When we reach here we have the whole map created.
        // Now insert all level 0 (great grand parent) entries first. 
        insert level0Map.values();

        // Time to now insert all level 1 (grand parent) entries. We have to also fetch and populate their corresponding level 0 (great grand parent) record id. Create a new list to hold this.
        List<Taxonomy_Metadata__c> finalLevel1DataList = new List<Taxonomy_Metadata__c>();
        for (String key: level1Map.keySet()) {
            
            Taxonomy_Metadata__c level1Data = level1Map.get(key);
            
            // Find and match the relevant great grand parent (Level 0) key. For example, if Level 1 key is Location|Bus|Sydney Buses, the matching great grand parent (Level 0) key is "Bus"
            Integer firstPipeIndex = key.indexOf('|');
            Integer lastPipeIndex = key.lastIndexOf('|');
            String level0Key = key.substring(firstPipeIndex + 1, lastPipeIndex);
            System.debug('Jay: level0Key is ' + level0Key);
            Taxonomy_Metadata__c level0 = level0Map.get(level0Key);
            
            level1Data.Parent_Id__c = level0.id;
            finalLevel1DataList.add(level1Data);
            
        }
         
        insert finalLevel1DataList;
        
        System.debug('Jay: Level 2 Map has ' + level2Map.size() + ' entries');
        List<Taxonomy_Metadata__c> finalLevel2DataList = new List<Taxonomy_Metadata__c>();
        for (String key: level2Map.keySet()) {
            
            // System.debug('Jay: Debug - level 2 Map current key is ' + key);
            Taxonomy_Metadata__c level2Data = level2Map.get(key);
            Integer pipeIndex = key.lastIndexOf('|');
            String level1Key = key.substring(0, pipeIndex);
            // System.debug('level1Key is ' + level1Key);
            Taxonomy_Metadata__c level1 = level1Map.get(level1Key);
            
            level2Data.Parent_Id__c = level1.id;
            finalLevel2DataList.add(level2Data);
            
        }
         
        insert finalLevel2DataList;
        
        List<Taxonomy_Metadata__c> finalLevel3DataList = new List<Taxonomy_Metadata__c>();
        for (String key: level3Map.keySet()) {
            
            List<Taxonomy_Metadata__c> level3DataList = level3Map.get(key);
            Integer pipeIndex = key.lastIndexOf('|');
            String level2Key = key.substring(0, pipeIndex);
            
            Taxonomy_Metadata__c level2 = level2Map.get(level2Key);
            
            for (Taxonomy_Metadata__c level3Data: level3DataList) {
                level3Data.Parent_Id__c = level2.id;
                finalLevel3DataList.add(level3Data);
            }
        }
        
        insert finalLevel3DataList;
        
        System.debug('Jay: level 0 Map has ' + level0Map.size() + ' entries!!!');
        System.debug('Jay: Level 1 has ' + finalLevel1DataList.size() + ' entries!!!');
        System.debug('Jay: Level 3 Map has ' + level3Map.size() + ' entries');
        updateTrainTaxonomy();
    }
    
    private static void updateTrainTaxonomy() {
        List<Taxonomy_Metadata__c> taxo = [SELECT Id FROM Taxonomy_Metadata__c WHERE Type__c = 'Mode' and Name = 'Train'];
        List<Taxonomy_Metadata__c> taxo1 = [SELECT Id FROM Taxonomy_Metadata__c WHERE Parent_Id__c IN :taxo AND Type__c = 'Issue'];
        List<Taxonomy_Metadata__c> taxo2 = [SELECT Id FROM Taxonomy_Metadata__c WHERE Parent_Id__c IN :taxo1];
        List<Taxonomy_Metadata__c> taxo3 = [SELECT Id, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Parent_Id__c, Status_Customer_Facing__c FROM Taxonomy_Metadata__c WHERE Parent_Id__c IN :taxo2];

        Set<Id> parentIssuesToUpdate = new Set<Id>();
        for(Taxonomy_Metadata__c t : taxo3) {
            if(t.Status_Customer_Facing__c == 'Active') {
                t.Status_NSWT_Customer_Facing__c = 'Active'; 
                t.Status_ST_Customer_Facing__c = 'Active';
                parentIssuesToUpdate.add(t.Parent_Id__c);
            }
        }
        
        update taxo3;

        List<Taxonomy_Metadata__c> parentIssues = [SELECT Id, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Status_Customer_Facing__c FROM Taxonomy_Metadata__c WHERE Id IN :parentIssuesToUpdate];
        for(Taxonomy_Metadata__c t: parentIssues) {
            t.Status_ST_Customer_Facing__c = 'Active';
            t.Status_NSWT_Customer_Facing__c = 'Active';    
            t.Status_Customer_Facing__c = 'Active'; 
        }
        update parentIssues;

        List<Taxonomy_Metadata__c> loctaxo1 = [SELECT Id FROM Taxonomy_Metadata__c WHERE Parent_Id__c IN :taxo AND Type__c = 'Location'];
        List<Taxonomy_Metadata__c> loctaxo2 = [SELECT Id FROM Taxonomy_Metadata__c WHERE Parent_Id__c IN :loctaxo1];
        List<Taxonomy_Metadata__c> loctaxo3 = [SELECT Id, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Parent_Id__c, Status_Customer_Facing__c FROM Taxonomy_Metadata__c WHERE Parent_Id__c IN :loctaxo2];

        List<Taxonomy_Metadata__c> tToUpdate = new List<Taxonomy_Metadata__c>();
        Set<Id> level2 = new Set<Id>();
        Set<Id> stActive = new Set<Id>();
        Set<Id> nswtActive = new Set<Id>();
        for(Taxonomy_Metadata__c t : loctaxo3) {
            if(t.Status_Customer_Facing__c == 'Active') {
                level2.add(t.Parent_Id__c);
            }
        }

        update loctaxo3;
        List<Taxonomy_Metadata__c> locParent = [SELECT Id, Status_NSWT_Customer_Facing__c, Status_ST_Customer_Facing__c, Status_Customer_Facing__c FROM Taxonomy_Metadata__c WHERE Id IN :level2];

        for(Taxonomy_Metadata__c t : locParent) {
            t.Status_ST_Customer_Facing__c = 'Active';
            t.Status_NSWT_Customer_Facing__c = 'Active';    
            t.Status_Customer_Facing__c = 'Active'; 
        }

        update locParent;
    }
}