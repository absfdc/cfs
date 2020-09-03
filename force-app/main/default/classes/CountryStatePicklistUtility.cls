/**
 * Author:          Sauce Consulting
 * Description:     This is helper class for retrieving country list configured in the org
 * TestClass :      CountryStatePicklistUtilityTest
 * History
 * Date             Author                      Comments
   --------------------------------------------------------------------------------------
   13-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class CountryStatePicklistUtility {
    private static Map<String, Set<String>> countryVsStates = new Map<String, Set<String>>();
    private static final String BASE_64_CHARS = ''
            + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            + 'abcdefghijklmnopqrstuvwxyz'
            + '0123456789+/';

    private class PicklistEntryBean {
        public Boolean active {get; set;}
        public String value {get; set;}
        public String validFor {get; set;}
        public String label {get; set;}
    }

    private static Map<String, Set<Integer>> cache; 

    static{ 
        Schema.DescribeSObjectResult userDescResult = Schema.User.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = userDescResult.fields.getMap();
        if(fieldsMap.containsKey('countrycode') && fieldsMap.containsKey('statecode')){
            SObjectField countryCode = fieldsMap.get('countrycode');
            SObjectField stateCode = fieldsMap.get('statecode');
            Map<String, List<String>> results = controllingToDependentValues(countryCode, stateCode);
            for(String key : results.keySet()){
                countryVsStates.put(key, new Set<String>(results.get(key)));
            }
        }        
    }

    private static Map<String, List<String>> controllingToDependentValues(SObjectField controlling, SObjectField dependent) {

        Map<String, List<String>> results = new Map<String, List<String>>();

        if (controlling != null && dependent != null) {
            cache = new Map<String, Set<Integer>>();
            List<String> controllingValues = new List<String>();

            for (PicklistEntry pe : controlling.getDescribe().getPicklistValues()) {
                if (pe.isActive()) {
                    results.put(pe.getLabel(), new String[] {});
                    controllingValues.add(pe.getLabel());
                }
            }

            for (PicklistEntryBean pe : picklistEntryBeans(dependent.getDescribe().getPicklistValues())) {
                if (pe.active) {
                    for (Integer index : validForToIndices(pe.validFor)) {
                        results.get(controllingValues.get(index)).add(pe.label);
                    }
                }
            }
        }

        return results;
    }

    private static Set<Integer> validForToIndices(String validFor) {

        Set<Integer> indices = cache.get(validFor);
        if (indices == null) {
            indices = new Set<Integer>();

            String validForBits = base64ToBits(validFor);
            for (Integer i = validForBits.indexOf('1'); i >= 0; i = validForBits.indexOf('1', i + 1)) {
                indices.add(i);
            }

            cache.put(validFor, indices);
        }

        return indices;
    }

    private static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    private static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';

        String validForBits = '';
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = BASE_64_CHARS.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        return validForBits;
    }

    private static PicklistEntryBean[] picklistEntryBeans(List<PicklistEntry> pes) {
        return (List<PicklistEntryBean>) JSON.deserialize(JSON.serialize(pes), List<PicklistEntryBean>.class);
    }
    
    /* method to retrieve list countries available for selection */
    @AuraEnabled (cacheable=true)
    public static List<String> getCountryList(){
        return new List<String>(countryVsStates.keySet());
    }
    
    /* method to retrieve list of states associated with country */
    @AuraEnabled (cacheable=true)
    public static List<String> getStatesBasedOnCountry(String country){
        if(String.isBlank(country)) return new List<String>();
        if(!countryVsStates.containsKey(country)) return new List<String>();
        return new List<String>(countryVsStates.get(country));
    }
}