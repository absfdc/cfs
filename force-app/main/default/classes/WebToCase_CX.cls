/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    Extension class for web to case custom form.
Inputs:         "controller" - standard controller for case object
Test Class:     WebToCase_Test
History:
Ian F 01/05/2018 Populate new isFeedbackAssist__c field in createCase
------------------------------------------------------------*/
global class WebToCase_CX {    
    private static final String DEFAULT_COUNTRY_AUS = 'AU';
    
    public static String sourceRmsIntranet {set; get{ return GlobalConstants.MODE_RMS_INTRANET;}}
    public static String sourceRms {set; get{ return GlobalConstants.MODE_RMS;}}
    public static String sourceSydTrains {set; get{ return GlobalConstants.MODE_SYDNEY_TRAINS;}}
    public static String sourceNswTrains {set; get{ return GlobalConstants.MODE_NSW_TRAINS;}}
    public static String sourceTfnswIntranet {set; get{ return GlobalConstants.MODE_TFNSW_INTRANET;}}
    public static String sourceTfnsw {set; get{ return GlobalConstants.MODE_TFNSW;}}
    public static String modeMaritime {set; get{ return GlobalConstants.MODE_MARITIME;}}    
    public static String modeNonModal {set; get{ return GlobalConstants.MODE_NON_MODAL;}}
    public static String feedbackForWebsite {set; get{ return GlobalConstants.FEEDBACK_FOR_WEBSITE;}}
    public static String feedbackForApp {set; get{ return GlobalConstants.FEEDBACK_FOR_APP;}}
    public Case caseRecord {get; set;}
    public Contact contactPerson {get; set;}
    public transient List<SelectOption> states;
    public String selectedState {get; set;}
    public String errorMessage {get; set;}
    public transient List<SelectOption> hours;
    public transient List<SelectOption> minutes;
    public String selectedHour {get;set;}
    public String selectedMinute {get;set;}
    public String websiteChosen{get;set;}
    
    public List<Attachment> attachments {
        get{
            return this.attachments == null ? new List<Attachment>() : this.attachments;
        } 
        set{
            this.attachments = (value == null ? new List<Attachment>() : value);
        }}
    public transient List<SelectOption> options;
    public transient List<SelectOption> rmsOptions;
    public transient List<SelectOption> routeOptions;
    public String selectedRmsOption {get; set;}
    public String location;
    public String line;
    public String trainLinesForPnr { 
        get{
            String lines = '';
            Map<String,TrainLinesForPNR__c> trainLines = TrainLinesForPNR__c.getAll();
            //$$ is used as delimiter
            for(String trainLine : trainLines.keySet()) {
                lines = lines + trainLine + '$$';
            }
            return lines.length() > 2? lines.substring(0, lines.length() - 2) : lines;
        } 
        
        set{}}
    
    public String stopNames { 
        get{
            String stops = '';
            Map<String, Lightrail_stop_location_level_1_values__c> lightRailStopsVal = Lightrail_stop_location_level_1_values__c.getAll();
            List<Taxonomy_Metadata__c> taxo = [ SELECT Id, Customer_Value__c, Customer_facing_sort_order__c 
                                               FROM Taxonomy_Metadata__c 
                                               WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION
                                               AND Status_Customer_Facing__c = 'Active'
                                               AND Parent_Id__r.Parent_Id__r.Parent_Id__r.Name = 'Light Rail'
                                               AND Parent_Id__r.Parent_Id__r.Name IN :lightRailStopsVal.keySet()
                                               ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST];
            for(Taxonomy_Metadata__c metadata : taxo) {                
                //stops = stops + String.escapeSingleQuotes(metadata.Customer_Value__c) + '$$';
                if(stops.length()>1)
                    stops = stops + metadata.Customer_Value__c + '$$';
                //stops = stops + String.escapeSingleQuotes(metadata.Customer_Value__c) + '$$';
                else stops = String.escapeSingleQuotes(metadata.Customer_Value__c) + '$$';
            }
            return stops.length() > 2? stops.substring(0, stops.length() - 2) : stops;
        }    
        set{}}
    
    @RemoteAction
    global static String getStopName(String routeName) {
        String stops = '';
        Map<String, Lightrail_route_location_level_1_values__c> lightRailLineValues = Lightrail_route_location_level_1_values__c.getAll();
        //Set<String> parentRoutename = (routeName!=null)? new Set<String>{routeName}:lightRailLineValues.keySet();
        
        Set<String> parentRoutename = new Set<String>();
        if(routeName!=null && routeName.length() > 0) parentRoutename.add(routeName);
        else parentRoutename.addAll(lightRailLineValues.keySet());
        
        List<Taxonomy_Metadata__c> taxo = [ SELECT Id, Customer_Value__c, Customer_facing_sort_order__c 
                                           FROM Taxonomy_Metadata__c 
                                           WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION
                                           AND Status_Customer_Facing__c = 'Active'
                                           AND Parent_Id__r.Parent_Id__r.Parent_Id__r.Name = 'Light Rail'
                                           AND Parent_Id__r.Name IN :parentRoutename
                                           ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST];        
        
        
        for(Taxonomy_Metadata__c metadata : taxo) {                
            stops = stops + String.escapeSingleQuotes(metadata.Customer_Value__c) + '$$';
        }
        
        stops = stops.substring(0,stops.length()-2);
        
        return stops;
    }    
    
    
    public List<SelectOption> lightRailLines {
        get{
            List<SelectOption> lines = new List<SelectOption>();
            lines.add(new SelectOption('', 'Please select'));
            Map<String, Lightrail_route_location_level_1_values__c> lightRailLineValues = Lightrail_route_location_level_1_values__c.getAll();
            List<Taxonomy_Metadata__c> taxo = [ SELECT Id, Customer_Value__c, Customer_facing_sort_order__c 
                                               FROM Taxonomy_Metadata__c 
                                               WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION
                                               AND Status_Customer_Facing__c = 'Active'
                                               AND Parent_Id__r.Parent_Id__r.Parent_Id__r.Name = 'Light Rail'
                                               AND Parent_Id__r.Parent_Id__r.Name IN :lightRailLineValues.keySet()
                                               ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST];
            for(Taxonomy_Metadata__c metadata : taxo) {
                lines.add(new SelectOption(metadata.Customer_Value__c, metadata.Customer_Value__c));
            }
            if(lines.size() == 2) {
                lines.remove(0);
            }
            return lines;
        }
        set{
            this.lightRailLines = value;
        }
    }
    
    public List<SelectOption> lightRailStops {
        get{
            List<SelectOption> stops = new List<SelectOption>();
            stops.add(new SelectOption('', 'Please select'));
            Map<String, Lightrail_stop_location_level_1_values__c> lightRailStopsVal = Lightrail_stop_location_level_1_values__c.getAll();
            List<Taxonomy_Metadata__c> taxo = [ SELECT Id, Customer_Value__c, Customer_facing_sort_order__c 
                                               FROM Taxonomy_Metadata__c 
                                               WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_LOCATION
                                               AND Status_Customer_Facing__c = 'Active'
                                               AND Parent_Id__r.Parent_Id__r.Parent_Id__r.Name = 'Light Rail'
                                               AND Parent_Id__r.Parent_Id__r.Name IN :lightRailStopsVal.keySet()
                                               ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, Customer_Value__c ASC NULLS LAST];
            for(Taxonomy_Metadata__c metadata : taxo) {
                stops.add(new SelectOption(metadata.Customer_Value__c, metadata.Customer_Value__c));
            }            
            return stops;
        }
        set{
            this.lightRailStops = value;
        }
    }
    
    public WebToCase_CX (ApexPages.StandardController controller) {           
        caseRecord = new Case();
        caseRecord.Origin =  GlobalConstants.WEB2CASE_ORIGIN;
        caseRecord.Status = GlobalConstants.DEFAULT_WEBTOCASE_STATUS_TRIAGE;
        //case categorization by webform user to be considered as -1 as its high probability of mis-categorization and would need case manager to correct the categorization
        caseRecord.categorisation_count__c = -1; 
        caseRecord.Origin_Details__c = validateString('source');
        caseRecord.Supplied_Referrer__c = validateString('refsite');
        if(!String.isBlank(caseRecord.Origin_Details__c) 
           && (caseRecord.Origin_Details__c.toLowerCase() != GlobalConstants.RMS_SOURCE_MARITIME)
           && (caseRecord.Origin_Details__c.toLowerCase() != GlobalConstants.RMS_SOURCE_RMS)               
           && (caseRecord.Origin_Details__c.toLowerCase() != GlobalConstants.RMS_SOURCE_RMS_INTRANET) ) {  
               caseRecord.Modes__c = validateString('about');            
           } else if ((caseRecord.Origin_Details__c.toLowerCase() == GlobalConstants.RMS_SOURCE_MARITIME)
                      || (caseRecord.Origin_Details__c.toLowerCase() == GlobalConstants.RMS_SOURCE_RMS)               
                      || (caseRecord.Origin_Details__c.toLowerCase() == GlobalConstants.RMS_SOURCE_RMS_INTRANET)) {
                          caseRecord.Status = GlobalConstants.ASSIGNED_TO_AGENCY_STATUS;
                      }
        if(!String.isBlank(caseRecord.Origin_Details__c) 
           && ((caseRecord.Origin_Details__c.toLowerCase() == GlobalConstants.RMS_SOURCE_MARITIME)
               || (caseRecord.Origin_Details__c.toLowerCase() == GlobalConstants.RMS_SOURCE_RMS))) {  
                   caseRecord.Origin_Details__c = GlobalConstants.CASE_ORIGIN_RMSWEBSITE;
               }
        contactPerson = new Contact();
        attachments = new List<Attachment>();
        for(Integer i = 0; i < 10; i++) {
            attachments.add(new Attachment());
        } 
        caseRecord.User_agent__c = ApexPages.currentPage().getHeaders().get('User-Agent');
        String ipAddress = null;
        if(ApexPages.currentPage().getHeaders().containsKey('True-Client-IP')) {
            ipAddress = 'True-Client-IP';
        } else if(ApexPages.currentPage().getHeaders().containsKey('X-Salesforce-SIP')){
            ipAddress = 'X-Salesforce-SIP';
        }
        if(ipAddress != null) {
            caseRecord.Users_Ip_address__c = ApexPages.currentPage().getHeaders().get(ipAddress);
        }
        for(String str : ApexPages.currentPage().getHeaders().keyset()) {
            System.debug('Key: ' + str + ' Values: ' + ApexPages.currentPage().getHeaders().get(str));
        }
    }   
    
    private String validateString(String urlParameter) {
        if(ApexPages.currentPage().getParameters().containsKey(urlParameter)) {
            return String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(urlParameter)).escapeHtml4();            
        }       
        return null;
    }
    
    /*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    Function creates new case based on value entered by user on web to case form.
Inputs:         
Returns:        "PageReference" - returns reference of thank you page if case is created successfully otherwise returns null
History:
------------------------------------------------------------*/
    public PageReference createCase() {
        System.debug('Executing createCase...');
        try {
            //Added by Ian F 01/05/2018 for new FeedbackAssist parameter
            String sFeedbackAssist = apexpages.currentpage().getparameters().get('feedbackassist');
            if (sFeedbackAssist=='true'){
                caseRecord.isFeedbackAssist__c = true;
            }
            System.debug('Checking whether User IP address did not got captured...');  
            
            if(String.isBlank(caseRecord.Users_Ip_address__c)) {
                System.debug('Id address error:');
                return returnErrorPage();
            }
            System.debug('Taxo: ' + caseRecord.Taxonomy_Transaction__c);
            System.debug('Taxo: ' + caseRecord.Taxonomy_Symptom__c);
            System.debug(LoggingLevel.INFO, 'Salutation ' + contactPerson.Salutation);
            WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker(caseRecord.Users_Ip_address__c );
            if(!spamChecker.isSuspectedSpam()) {
                System.debug('this is not a spam.');                
                if(!(String.isBlank(selectedHour) || String.isBlank(selectedMinute) || caseRecord.Date_Time_of_Incident__c == null)) {
                    caseRecord.Date_Time_of_Incident__c = DateTime.newInstance(caseRecord.Date_Time_of_Incident__c.date(), Time.newInstance(Integer.valueOf(selectedHour), Integer.valueOf(selectedMinute), 0,0));
                } else if(caseRecord.Date_Time_of_Incident__c != null) {
                    caseRecord.Date_Time_of_Incident__c = null;
                }
                if(!String.isBlank(websiteChosen)){
                    caseRecord.Taxonomy_Symptom__c = websiteChosen;
                }
                System.debug('Calling populateContactDetailsOnCase...');
                populateContactDetailsOnCase();
                WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
                System.debug('Case status before insert: ' + caseRecord.Status);
                caseRecord = caseCreator.insertCase(); 
                List<Case> caseDetails = [SELECT Id, CaseNumber, Responsible_Party__c, ContactId, OwnerId, Status, Taxonomy_Transaction__c, Created_By_Email__c,
                                          Taxonomy_Symptom__c, Date_Time_of_Incident__c, recordtypeId, Taxonomy_Accountability__c, Origin,
                                          Agency__c, Modes__c, Taxonomy_Location__c, Taxonomy_Location_Type__c, Taxonomy_Area__c, 
                                          Taxonomy_Location_Id__c,Location_Level_3__c 
                                          FROM Case WHERE Id =:caseRecord.Id];
                if(!caseDetails.isEmpty()) {
                    addAttachments(caseDetails[0]);
                    /*
* SNSW Changes START: Check if case qualifies to be shared with SNSW
*/
                    AutoShareWebCasesWithSNSW checker = new AutoShareWebCasesWithSNSW(caseDetails);
                    checker.shareQualifiedCases();
                    /*
* SNSW Changes END: Check if case qualifies to be shared with SNSW
*/
                    caseRecord = caseDetails[0];
                    System.debug('Case status after insert: ' + caseRecord.Status);
                    if(!associateContactWithCase()) {
                        update caseRecord;
                    }
                    
                    String message = GlobalConstants.WEBTOCASE_SUCCESS_MSG + caseDetails[0].CaseNumber + '.';
                    if(GlobalConstants.RESPONSIBLE_PARTY_SNSW.equalsIgnoreCase(caseDetails[0].Responsible_Party__c)) {
                        message = GlobalConstants.WEBTOCASE_SUCCESS_MSG_FOR_SNSW;
                    }
                    PageReference pgRef = Page.WebToCaseThankYouPage;
                    pgRef.getParameters().put('message', message);
                    pgRef.getParameters().put('about', caseDetails[0].Modes__c);
                    pgRef.getParameters().put('source', validateString('source'));
                    return pgRef;
                } 
            } else {
                //log suspected spam
                System.debug('logging suspected spam ');  
                SuspectedSpamCaseLogger.logSpamCase(caseRecord.Users_Ip_address__c, 'WebToCase_CX', 'createCase');
            }
        } catch(Exception e) {
            System.debug('Exception in creating the case: '+ e.getLineNumber() + e.getCause() + e.getMessage() + e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, e.getMessage());
            ExceptionLogger.logException('WebToCase_CX', 'createCase', e, null);
        }    
        
        return returnErrorPage();
    }
    
    
    private PageReference returnErrorPage() {
        System.debug('Executing returnErrorPage...');
        PageReference pgRef = Page.WebToCaseErrorPage;
        pgRef.getParameters().put('about', validateString(ApexPages.currentPage().getParameters().get('about')));
        pgRef.getParameters().put('source', validateString(ApexPages.currentPage().getParameters().get('source')));
        return pgRef;
    }
    
    /*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    Function associates contact on case based on contact details provided by user on web to case form. It either creates a new contact for non-existing contact 
or associates to pre-existing contact record which matches user input
Inputs:         
Returns:        
History:
------------------------------------------------------------*/
    private Boolean associateContactWithCase() {        
        String salesforceBaseUrl = ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To');
        Boolean caseUpdated = false;
        if(caseRecord != null && contactPerson != null && !String.isBlank(contactPerson.LastName)) {
            contactPerson.mailingStateCode = selectedState;
            if(!String.isBlank(selectedState)) {
                contactPerson.mailingCountryCode = DEFAULT_COUNTRY_AUS;
            }
            WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(caseRecord, contactPerson, salesforceBaseUrl);
            System.debug('before invoking create contact.');
            contactCreator.createContact();
            System.debug('after invoking create contact.');
            caseUpdated = true;
        }
        return caseUpdated;
    }    
    
    private void populateContactDetailsOnCase() {
        caseRecord.SuppliedEmail = contactPerson.Email;
        caseRecord.SuppliedName = '';
        if(!String.isBlank(contactPerson.FirstName)) {
            caseRecord.SuppliedName = contactPerson.FirstName;
        }
        if(!String.isBlank(contactPerson.LastName)) {
            caseRecord.SuppliedName = caseRecord.SuppliedName + (caseRecord.SuppliedName.length() > 0 ? ' ' : '' ) + contactPerson.LastName;
        }
        caseRecord.SuppliedPhone = contactPerson.Phone;
        caseRecord.Supplied_Address__c = '';
        if(contactPerson.MailingStreet != null) {
            caseRecord.Supplied_Address__c = contactPerson.MailingStreet + '\n';    
        }
        if(contactPerson.MailingCity != null) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingCity + '\n';
        }
        if(selectedState != null) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + selectedState + ' ';
        }
        if(contactPerson.MailingPostalCode != null) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingPostalCode + '\n';
        }
        if(contactPerson.MailingCountry != null) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingCountry;
        }
        if(contactPerson.MailingCountryCode != null) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingCountryCode;
        }
    }
    
    /*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    Function inserts attachments uploaded by the user on web form for the newly created case.
Inputs:         
Returns:        
History:
------------------------------------------------------------*/    
    private void addAttachments(Case caseDetails) {
        if(caseDetails != null && attachments != null && !attachments.isEmpty()) {
            WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseDetails, attachments);
            attachmentCreator.createCaseAttachment();
        }        
    }
    
    global static String retrieveLocationDetails(String mode) {
        String location = '[]';
        if(!String.isBlank(mode) ) {            
            
        }
        return location;
    }
    
    /*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    getter method, retrieves json string representation of taxonomy tree created based on Taxonomy Metadata for location
Inputs:         
Returns:        "String" - json representation of taxonomy tree to be used as data for jstree plugin on web form
History:
------------------------------------------------------------*/
    public String getLocation() {
        this.location = retrieveLocationDetails(caseRecord.Modes__c);
        return String.escapeSingleQuotes(this.location);
    }
    
    public void setLocation(String location) {
        this.location = location;
    }
    
    global static String retrieveLineDetails(String mode) {
        String line = '[]';
        if(!String.isBlank(mode)) {
            
        }
        return line;
    }
    
    /*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    getter method, retrieves json string representation of taxonomy tree created based on Taxonomy Metadata for location
Inputs:         
Returns:        "String" - json representation of taxonomy tree to be used as data for jstree plugin on web form
History:
------------------------------------------------------------*/
    public String getLine() {
        this.line = retrieveLineDetails(caseRecord.Modes__c);
        return String.escapeSingleQuotes(this.line);
    }
    
    public void setLine(String line) {
        this.line = line;
    }
    
    public void setHours(List<SelectOption> options) {
        hours = options;
    }
    
    public List<SelectOption> getHours() {
        hours = new List<SelectOption>();
        hours.add(new SelectOption('','Hour'));
        for(Integer hr = 0; hr < 24; hr++) {            
            hours.add(new SelectOption('' + hr, (hr < 10 ? '0' + hr : '' + hr)));
        }        
        return hours;
    }
    
    public void setMinutes(List<SelectOption> options) {
        minutes = options;
    }
    
    public List<SelectOption> getMinutes() {
        minutes = new List<SelectOption>();
        minutes.add(new SelectOption('','Min'));
        for(Integer min = 0; min < 60; min++) {
            minutes.add(new SelectOption('' + min, (min < 10 ? '0' + min : '' + min)));
        }        
        return minutes;
    }
    
    public void setOptions(List<SelectOption> optionValues) {
        options = optionValues;
    }
    
    public List<SelectOption> getOptions() {
        options = new List<SelectOption>();        
        Schema.DescribeFieldResult fieldResult = Case.Response_Requested__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry fieldValue : ple) {
            options.add(new SelectOption(fieldValue.getValue(), fieldValue.getLabel()));
        }       
        return options;
    }    
    
    public void setRmsOptions(List<SelectOption> optionValues) {
        rmsOptions= optionValues;
    }
    
    public List<SelectOption> getRmsOptions() {
        rmsOptions = new List<SelectOption>();        
        rmsOptions.add(new SelectOption('Road', 'Roads'));
        rmsOptions.add(new SelectOption('Maritime', 'Maritime'));
        return rmsOptions;
    }
    
    public void setRouteOptions(List<SelectOption> optionValues) {
        routeOptions= optionValues;
    }
    
    public List<SelectOption> getRouteOptions() {
        routeOptions = new List<SelectOption>();        
        routeOptions.add(new SelectOption('false', 'Regular'));
        routeOptions.add(new SelectOption('true', 'School route'));
        return routeOptions;
    }
    
    public void setDatasetId(String value) {}
    
    public String getDatasetId() {
        RMSDatasets__c rmsDataset = RMSDatasets__c.getValues('RMS Region');
        if(rmsDataset != null) {
            return rmsDataset.Dataset_Id__c;
        }
        return null;
    }
    
    public void setGmeKey(String value) {}
    
    public String getGmeKey() {
        RMSDatasets__c rmsDataset = RMSDatasets__c.getValues('RMS Region');
        if(rmsDataset != null) {
            return rmsDataset.Key__c;
        }
        return null;
    }
    
    public String getMaritimeDatasetID() {
        RMSDatasets__c maritimeDataset = RMSDatasets__c.getValues('Maritime Datasets');
        if(maritimeDataset != null) {
            return maritimeDataset.Dataset_Id__c;
        }
        return null;
    }
    
    public void setMaritimeDatasetID(String maritimeDataset) {}
    
    public void setLgaSedDatasetID(String lgaSedDataset) {}
    
    public String getLgaSedDatasetID() {        
        RMSDatasets__c maritimeDataset = RMSDatasets__c.getValues('LGA Datasets');
        if(maritimeDataset != null) {
            return maritimeDataset.Dataset_Id__c;
        }
        return null;
    }
    
    global class CaseCategorization {
        public CaseCategorization(String category, List<String> subCategory) {
            this.mode = '';
            this.category = '';
            if(!String.isBlank(category) && category.contains(':')) {
                this.mode = category.substring(0, category.indexOf(':'));
                this.category = category.replace(this.mode + ':', '');
            }
            this.subCategory = subCategory;
        }
        public String mode {get; set;}
        public String category {get; set;}
        public List<String> subCategory {get; set;}
    }
    
    public void setAllowedFileAttachments(String fileExtension){}
    
    public String getAllowedFileAttachments() {
        Map<String, AllowableFileExtensions__c> fileExtensions = AllowableFileExtensions__c.getAll();
        Set<String> allowedFileExtensions = new Set<String>();
        allowedFileExtensions.addAll(fileExtensions.keySet());
        return JSON.serialize(allowedFileExtensions);
    }
    
    @RemoteAction
    global static List<WebToCase_CX.CaseCategorization> retrieveIssueTaxonomy(String origin) {
        List<WebToCase_CX.CaseCategorization> issueCat = new List<WebToCase_CX.CaseCategorization>();
        Map<String, List<String>> catVsSubCat = TaxonomyRetriever.retrieveIssueCategoryAndSubCategory(origin);
        for(String category : catVsSubCat.keySet()) {
            List<String> subcat = new List<String>();
            subcat.addAll(catVsSubCat.get(category));
            WebToCase_CX.CaseCategorization categorization = new WebToCase_CX.CaseCategorization(category, subcat);
            issueCat.add(categorization);
        }        
        return issueCat;
    }
    
    //SFCOE-2369 - Non Modal Issue Taxonomy Changes - 13/03/2018 - Start
    @RemoteAction
    global static List<WebToCase_CX.CaseCategorization> retrieveIssueCategoryAndSubCategoryNonModal(String source, String about, String ilvl2) {
        List<WebToCase_CX.CaseCategorization> issueCat = new List<WebToCase_CX.CaseCategorization>();
        Map<String, List<String>> catVsSubCat = TaxonomyRetriever.retrieveIssueCategoryAndSubCategoryNonModal(source, about, ilvl2);
        for(String category : catVsSubCat.keySet()) {
            List<String> subcat = new List<String>();
            subcat.addAll(catVsSubCat.get(category));
            WebToCase_CX.CaseCategorization categorization = new WebToCase_CX.CaseCategorization(category, subcat);
            issueCat.add(categorization);
        }        
        return issueCat;
    }
    //SFCOE-2369 - Non Modal Issue Taxonomy Changes - 13/03/2018 - End
    
    
    @RemoteAction
    global static List<WebToCase_CX.CaseCategorization> retrieveLocTaxonomy(String origin, String modes) {
        List<WebToCase_CX.CaseCategorization> locCat = new List<WebToCase_CX.CaseCategorization>();
        Map<String, List<String>> fieldVsLocation = TaxonomyRetriever.retrieveLocationTaxonomy(origin,modes);
        for(String fieldName : fieldVsLocation.keySet()) {
            List<String> values = new List<String>();
            values.addAll(fieldVsLocation.get(fieldName));
            WebToCase_CX.CaseCategorization location = new WebToCase_CX.CaseCategorization(fieldName, values);
            locCat.add(location);
        }
        return locCat;
    }

    @RemoteAction
    global static List<String> getMatchingLocTaxonomy(String pSearchKey, String modes, Boolean pSchoolRoute) {
        return TaxonomyRetriever.retrieveMatchingLocTaxonomy(pSearchKey, modes, pSchoolRoute);
    }
}