@IsTest
public with sharing class CountryStatePicklistUtilityTest {
    
    private static testMethod void testForListStates(){
        System.Test.startTest();
        List<String> states = CountryStatePicklistUtility.getStatesBasedOnCountry('australia');
        System.Test.stopTest();
        System.assert(states != null, 'Test to retrive list of states failed');
    }
    
    private static testMethod void testForCountryList(){
        System.Test.startTest();
        List<String> countries = CountryStatePicklistUtility.getCountryList();
        System.Test.stopTest();
        System.assert(countries != null, 'Test to retrive list of countries failed');
    }    
}