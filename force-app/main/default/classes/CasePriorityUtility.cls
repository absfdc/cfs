/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   it checks the Input Text and body for key words that are configured as high priority
                returns the ministreal correspondance record type for cases

Test Class:    CaseTriggerDispatcher_Test
History
30 Mar 2015      Dipankar Barman     created
------------------------------------------------------------*/
public with sharing class CasePriorityUtility {
    static Pattern highPriority;
    static Set<Id> scannedRecTypeIds= new Set<Id> ();
    static Set<String> scannedOrigins=new Set<String>();
    static{
        //fetch the MinCorro case recordTypes to check against reprioritising them
        CaseFilterSetting__c caseFilterSetting=CaseFilterSetting__c.getValues(GlobalConstants.CASE_FILTER_SETTING_NAME);
        if(caseFilterSetting!=null){
            String origins=caseFilterSetting.origin__c.normalizeSpace();
            String scannedRecTypes=caseFilterSetting.RecordType__c.normalizeSpace();
            List<String> scannedRecordTypeDeveloperNames=scannedRecTypes.split(',',0);
            Map<Id,RecordType> caseTypes=new Map<Id,RecordType> ([SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName in :scannedRecordTypeDeveloperNames]);
            scannedOrigins.addAll(origins.split(',',0));
            scannedRecTypeIds=caseTypes.keySet();
        }
        

        //fetch the configured words from custom settings
        Set<Keywords__c> highPriorityKeywords = new Set<Keywords__c>();
        Map<String, Keywords__c> mapOfKeyWordsSettings = Keywords__c.getAll();
        for(Keywords__c keyword : mapOfKeyWordsSettings.values()) {
            if(keyword.Priority__c == GlobalConstants.CASE_PRIORITY_HIGH) {
                highPriorityKeywords.add(keyword);
            }
        }        
        String regexPre='(?i).*(\\s';
        String regexPost='\\s).*';
        String regexMid;
        for (Keywords__c aKey:highPriorityKeywords){
            regexMid=regexMid==null?aKey.Name:regexMid+'\\s|\\s'+aKey.Name;
        }
        //prepare pre compiled pattern
        String highPriorityRegex=regexPre+regexMid+regexPost;
        highPriority=Pattern.compile(highPriorityRegex);

    }
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Returns the configured case record type ids for which keywords are to be scanned
            except Ministreal Correspondance case type if configured on case else returns null

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    public static Set<ID> getScannedRecTypeIds(){
        return scannedRecTypeIds;
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Returns the configured case record origins for which keywords are to be scanned
            except Ministreal Correspondance case type if configured on case else returns null

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    public static Set<String> getScannedOrigins(){
        return scannedOrigins;
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   it checks the Input Text and body for key words that are configured as high priority
    Inputs:         The string to check
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    public static Boolean checkMatchesKeyword(String textIn){
        Boolean result=false;
        if (textIn!=null){
            String cleanText= ' ' + textIn.replaceAll('[^a-zA-Z]', ' ').normalizeSpace() + ' ';
            Matcher textMatcher= highPriority.matcher(cleanText);
            if (textMatcher.matches()){
                result= true;

            }else{
                result= false;
            }

        }
        return result;
    }
}