/*---------------------------------------------------------------------------------------
Author:        Arxxus
Description:   this class will
               1. scrub the profanity words with text <profanity>
               2. scrub bad urls (determined from safe website custom metadata) with <bad_url>
               3. calculate the SecurityThreatScore__c and BusinessPriorityScore__c
Test Class:    CaseAutoTriage_Test 
-----------------------------------------------------------------------------------------*/
public class CaseAutoTriage {

    public static String originalDescription;
    private List<Case> cases = new List<Case>();
    private Set<String> profanities = new Set<string>();
    private Set<String> allowedwebLinksSet = new Set<string>();
    private Set<String> urlIdentifier = new Set<String>();
    private Map<String, Priority_Keywords__mdt> priorityKeyMap = null; // new Map<String, Priority_Keywords__mdt>();
    private Map<String, Priority_Keywords__mdt> multiWordPriorityKeyword = null;
    private Threshold_Score__mdt thresholdScores; 
    private final String powerPartnerUserType = 'PowerPartner';
    private Integer maxRowsAllowed;
    
    private Pattern MyPattern = Pattern.compile('^((https?|ftp)://)??(www[.])??([a-zA-Z0-9]|-)+?([.][a-zA-Z0-9(-|/|=|#|@|%|&|?)??]+?)+?$');
    
    private Pattern emailPattern = Pattern.compile('^[a-z0-9._%+-/!#$%&\'*=?^_`{|}~]+@[a-z0-9.-]+\\.[a-z]{2,4}$');
    
    public CaseAutoTriage(List<Case> cases) {
        profanities.addAll(getProfanityList([SELECT MasterLabel, DeveloperName FROM Profanities__mdt]));
        allowedwebLinksSet.addAll(getWebLinksList([SELECT DomainName__c FROM Safe_Website__mdt]));
        priorityKeyMap = getPriorityKeyList([SELECT MasterLabel, BusinessPriorityScore__c,SecurityThreatScore__c FROM Priority_Keywords__mdt]);
        multiWordPriorityKeyword = getMultiWordPriorityKeyword([SELECT MasterLabel, BusinessPriorityScore__c,SecurityThreatScore__c FROM Priority_Keywords__mdt WHERE Is_Multi_Word__c = true]);
        urlIdentifier.addAll(getURLIdentifierList([SELECT MasterLabel, DeveloperName FROM URL_Identifier__mdt]));
        thresholdScores = [Select MasterLabel, Business_Priority_Score__c, Security_Threat_Score__c FROM Threshold_Score__mdt limit 1];
        maxRowsAllowed = [SELECT Id, No_of_rows__c FROM Maximum_Triage_Rows__mdt LIMIT 1].No_of_rows__c.intValue(); 
        this.cases = cases;
    }   
    
    public void ProfanityFilterandHPScoreCalculator(){
        System.debug('case auto triage check.'+maxRowsAllowed);
        if(this.cases == null || UserInfo.getUserType() == powerPartnerUserType || this.cases.size() > maxRowsAllowed ) return;
        //Long exStart = DateTime.now().getTime(); // Test Variable for Execution time check
        // start and stop a clock, and report on processing time.
        // for testing / performance testing purposes.
        Id roadRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Road').getRecordTypeId();
        Id maritimeRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Maritime').getRecordTypeId();
        
        for(Case c : cases){
            
            if(c.Description == null || c.IsMinCorroCase__c || c.RecordTypeId == roadRT || c.RecordTypeId == maritimeRT || c.Original_Description__c != null) continue; 
            System.debug('case needs to be triaged.');
            originalDescription = c.Description;
            c.BusinessPriorityScore__c = 0;
            c.SecurityThreatScore__c = 0;
            
            // FIRST, take all "words" from the Description and store in a HashSet
            String lowerDescription = c.Description.toLowerCase();
            Set<String> descriptionWords = new Set<String>(lowerDescription.split('\\W+')); //Changed to Add Special Character Considerations.
            // SECOND, determine which priority words were used
            Set<String> priorityWordsAppearing = new Set<String>(priorityKeyMap.keySet());

            // TODO: need special handling for multi-words!
            priorityWordsAppearing.retainAll(descriptionWords);

            // THEN, check for profanity using a similar approach
            Set<String> profanityFound = new Set<String>(profanities);
            profanityFound.retainAll(descriptionWords);

            for (String thisWord : profanityFound) {
                // when we have a confirmed match, we then replaceAll on it
                thisWord = '(?i)\\b'+ thisWord+'\\b';
                c.Description = c.Description.replaceAll(thisWord, '[profanity]'); 
            }

            // THEN, check for profanity with spaces
            for (String thisprofaneWord : profanities) {
                if (hasAllLetters(thisprofaneWord, descriptionWords)) {
                    // If we get here, we've found that all letters appear separately as words; e.g. "t e s s t"
                    // so there's a possibility that they exist together - now we can make the more expensive 
                    // call to do a full sweep of the description field using any non-word chars as delimiters
                    // this will catch "t.e.s.s.t" or "t!e!s!s!t" or even "t!#@ e#$@ s!@# s!@$ t" 
                    // Append a regular exp for case insensitivity, joined the splited array 
                    // Took a substring(3) of the resulting join, to eliminate the preceeding nonword 
                    thisprofaneWord = '(?i)\\b' + (String.join(thisprofaneWord.split(''),'\\W+')).substring(3) + '\\b';
                    c.Description = c.Description.replaceAll(thisprofaneWord, '[profanity]');  // replaced  - Dipanjan
                }
            }
            
            for(String thisUrl : lowerDescription.split('\\s+')){ // Splited the lowerDescription Again because from descriptionWords set all special characters was removed, hence not catching urls.
                String splittedWord = thisUrl;
                thisUrl = thisUrl.replaceAll('[()><\'\";,]','');
                if(!emailPattern.matcher(thisUrl).matches() &&  MyPattern.matcher(thisUrl).matches() && isIdentifiedAsURL(thisUrl) ){ 
                    String urlHost = thisUrl;
                    if(thisUrl.startsWith('http') || thisUrl.startsWith('ftp')){
                        URL url = new URL(thisUrl);
                        urlHost = url.getHost();
                    }
                    if(!isPresentInAllowedwebLinksSet(urlHost)){
                        splittedWord = splittedWord.replaceAll('\\?', '\\\\?');
                        splittedWord = splittedWord.replaceAll('\\+', '\\\\+');
                        splittedWord = splittedWord.replaceAll('\\(', '\\\\(');
                        splittedWord = splittedWord.replaceAll('\\)', '\\\\)');
                        splittedWord = splittedWord.replaceAll('\\<', '\\\\<');
                        splittedWord = splittedWord.replaceAll('\\>', '\\\\>');
                        c.Description = c.Description.replaceAll('(?i)'+splittedWord, '[bad_url]');  
                    }                                               
                }
                                              
            }
            // NEXT, Add scores for those words
            Set<String> scoredWords = new Set<String>(); 
            for (String thisPriorityWord : lowerDescription.split('\\b')) { 
                if(!priorityKeyMap.containsKey(thisPriorityWord)) continue;
                System.debug('priority word: '+thisPriorityWord);
                Priority_Keywords__mdt priorityKeyword = priorityKeyMap.get(thisPriorityWord);
                if (priorityKeyword != null && !scoredWords.contains(thisPriorityWord)) {
                    c.SecurityThreatScore__c += (priorityKeyWord.SecurityThreatScore__c != null? priorityKeyWord.SecurityThreatScore__c:0);
                    c.BusinessPriorityScore__c += (priorityKeyWord.BusinessPriorityScore__c != null?priorityKeyWord.BusinessPriorityScore__c:0);
                    scoredWords.add(thisPriorityWord);
                }
            }
            String lowercaseDescAfterProfanity = c.Description.toLowercase();
            String descWithoutSpCharacters = lowercaseDescAfterProfanity.replaceAll('[^a-zA-Z0-9]','');
            for(String label : multiWordPriorityKeyword.keySet()) {
                if(descWithoutSpCharacters.contains(label) && !scoredWords.contains(label)) {
                    Priority_Keywords__mdt keyword = multiWordPriorityKeyword.get(label);
                    c.SecurityThreatScore__c += (keyword.SecurityThreatScore__c != null? keyword.SecurityThreatScore__c:0);
                    c.BusinessPriorityScore__c += (keyword.BusinessPriorityScore__c != null?keyword.BusinessPriorityScore__c:0);
                    scoredWords.add(label);
                }
            }
            
            if(!c.Description.equals(originalDescription)){
                c.Original_Description__c = originalDescription;
                c.CaseIsFiltered__c = true;
            }else{
                c.Original_Description__c = null;
                c.CaseIsFiltered__c = false;
            }
            
            if(thresholdScores != null && thresholdScores.Security_Threat_Score__c != null && c.SecurityThreatScore__c > 0 &&  c.SecurityThreatScore__c >= thresholdScores.Security_Threat_Score__c) {
                c.Priority = GlobalConstants.CASE_PRIORITY_HIGH;
            }
            if(thresholdScores != null && thresholdScores.Business_Priority_Score__c != null && c.BusinessPriorityScore__c > 0 && c.BusinessPriorityScore__c >= thresholdScores.Business_Priority_Score__c) {
                c.Priority = GlobalConstants.CASE_PRIORITY_HIGH;
            }
        } 
        
    }
    
    /**
     * hasAllLetters : a recursive method that returns true if all letters in a word
     * appear individually as words in the descriptionWords
     * 
     * e.g. first call with parameter "tesst" checks to see if "t" is a word in the Set
     *      if it is, calls itself with "esst" then checks to see if "e" is a word in the Set
     *      so on with "sst", "st" and eventually "t"  If the final "t" evalutes to true,
     *      recursion stops and true is returned.
     *      The first time a letter is not found as a word, false is returned and no further
     *      analysis is done.
     * 
     * Author: Arxxus
     * Date: 27/10/2016
     */
    
    public boolean hasAllLetters(String thisprofaneWordtocheck, Set<String> descriptionWords) {
        if (descriptionWords.contains(thisprofaneWordtocheck.substring(0,1))) {
            if (thisprofaneWordtocheck.length() == 1) {
                return true;
            }
            return(hasAllLetters(thisprofaneWordtocheck.substring(1), descriptionWords));
        } else {
            return(false);
        }
    }

    /**
     * Load the list of Profanity into a List of Strings.
     * Takes a parameter which is a list of profanity words.
     * Automatically adds *ed and *ing to the resulting List
     * any more documentation.
     */

    public List<String> getProfanityList(List<Profanities__mdt> profanityWords){
        List<String> profanityList = new List<String>(); 
        for(Profanities__mdt prof:profanityWords) {
            String thisWordprof = prof.MasterLabel.toLowerCase();
            profanityList.add(thisWordprof);
            profanityList.add(thisWordprof + 'ed');
            profanityList.add(thisWordprof + 'ing');
        }
        return profanityList;
    }

    /**
     * Load the list of allowed web links into a List of Strings.
     */

    public List<String> getWebLinksList(List<Safe_Website__mdt> listofwebLinks){
        List<String> webLinkList = new List<String>(); 
        for(Safe_Website__mdt web:listofwebLinks){
            webLinkList.add(web.DomainName__c);
        }    
        return webLinkList;
    }
    
    private Boolean isPresentInAllowedwebLinksSet(String urlHost) {
        for(String linkset : allowedwebLinksSet) {
            if(urlHost.contains(linkset)){
                return true;
            }
        }
        return false;
    }
    
    /**
     * Load the list of allowed url identifier.
     */

    public List<String> getURLIdentifierList(List<URL_Identifier__mdt> urlIdentifiers){
        List<String> urlIdf = new List<String>(); 
        for(URL_Identifier__mdt url:urlIdentifiers){
            urlIdf.add(url.MasterLabel);
        }    
        return urlIdf;
    }
    
    private Boolean isIdentifiedAsURL(String url){
        System.debug('identifying url.'+url);
        for(String urlIdf : urlIdentifier) {
            if(url.contains(urlIdf)) return true;
        }
        return false;
    }
    
    /**
     *  Load the list of priority words and scores into a map
     */

    public Map<String, Priority_Keywords__mdt> getPriorityKeyList(List<Priority_Keywords__mdt> listofpriorityKeys) {
        Map<String, Priority_Keywords__mdt> priorityKeyMap = new Map<String, Priority_Keywords__mdt>(); 
        for(Priority_Keywords__mdt pri:listofpriorityKeys){
            priorityKeyMap.put(pri.MasterLabel, pri);           // no need toLowerCase all since validation rule requires them to be in lower at rest
        }    
        return priorityKeyMap;
    }
    
    public Map<String, Priority_Keywords__mdt> getMultiWordPriorityKeyword(List<Priority_Keywords__mdt> listofpriorityKeys) {
        Map<String, Priority_Keywords__mdt> priorityKeyMap = new Map<String, Priority_Keywords__mdt>(); 
        for(Priority_Keywords__mdt pri:listofpriorityKeys){
            priorityKeyMap.put(pri.MasterLabel, pri);           // no need toLowerCase all since validation rule requires them to be in lower at rest
        }    
        return priorityKeyMap;
    }
    
    
}