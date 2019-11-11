public without sharing class ValuePopulatorIncomingSNSWCases {
    private List<Case> cases;
    private static Map<String, Id> recordTypeMap;
    private static Map<String, Id> queueNameMap;
    private static Map<String, Default_value_setup_SNSW_to_RMS__c> settings;
    
    public ValuePopulatorIncomingSNSWCases(List<Case> cases) {
        if(cases == null || cases.isEmpty()) {
            throw new InvalidDataException('Failed to populate default values. Case details missing');
        }
        this.cases = cases;
        if(recordTypeMap == null || queueNameMap == null) {
            readDefaultSetting();
        }       
    }
    
    public void populateValues() {
        List<Entitlement> entitlementsForRMS = [SELECT Name, Id FROM Entitlement WHERE Name = :GlobalConstants.RMS_AGENCY];        
        for(Case caseRecord : cases) {
            System.debug(LoggingLevel.INFO, 'Mode received from SNSW is ' + caseRecord.Modes__c);           
            String mode = '';
            for(String key : settings.keySet()) {
                if(caseRecord.Modes__c != null && caseRecord.Modes__c.contains(key)) {
                    mode = key;
                    break;
                }
            }
            if(settings.get(mode) == null) {
                System.debug(LoggingLevel.INFO, 'Custom setting entry not available for ' + caseRecord.Modes__c);
                continue;
            }
            caseRecord.Status = GlobalConstants.DEFAULT_CASE_STATUS_FROM_SNSW;
            caseRecord.Type = GlobalConstants.DEFAULT_CASE_TYPE_FROM_SNSW;
            caseRecord.RecordTypeId = recordTypeMap.get(settings.get(mode).Record_Type_Name__c);
            caseRecord.OwnerId = queueNameMap.get(settings.get(mode).Queue__c);
            caseRecord.Taxonomy_Moment__c = settings.get(mode).Issue_Level_1__c;         
            caseRecord.Agency__c = GlobalConstants.RMS_AGENCY;
            caseRecord.OwnerAgency__c = GlobalConstants.RMS_AGENCY;
            if(!entitlementsForRMS.isEmpty()) {
                caseRecord.EntitlementId = entitlementsForRMS[0].Id;
            }
        }
    }
    
    private static void readDefaultSetting() {
        Set<String> queueNames = new Set<String>();
        Set<String> recordTypeNames = new Set<String>();
        settings = Default_value_setup_SNSW_to_RMS__c.getAll();
        recordTypeMap = new Map<String, Id>();
        queueNameMap = new Map<String, Id>();
        for(Default_value_setup_SNSW_to_RMS__c setting : settings.values()) {
            recordTypeNames.add(setting.Record_Type_Name__c);
            queueNames.add(setting.Queue__c);
        }
        
        for(RecordType rt:[ SELECT Id, Name 
                            FROM RecordType 
                            WHERE sObjectType = 'Case' 
                                AND Name IN :recordTypeNames]) {
            recordTypeMap.put(rt.Name, rt.Id);
        }
        
        for(Group grp :[SELECT Id, Name 
                        FROM Group 
                        WHERE Name IN : queueNames
                            AND Type = 'Queue']) {
            queueNameMap.put(grp.Name, grp.Id);
        }
    }
    
    public class InvalidDataException extends Exception {}
}