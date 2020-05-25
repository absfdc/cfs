/*------------------------------------------------------------
Author: Sauce Consulting
Description: Controller class for concessions application form
------------------------------------------------------------*/
global class WebToCaseConcession_CX {    
    private static final String NON_MODAL_MODE = 'non-modal';
    private static final String DEFAULT_COUNTRY_AUS = 'AU';
    
    // Type Of application
    public static List<SelectOption> typeOfApplicationOptions {set;get;}
    
    public static String sourceTfnsw {set; get{ return GlobalConstants.MODE_TFNSW;}}
    public Case caseRecord {get; set;}
    public Contact contactPerson {get; set;}
    public String selectedState {get; set;}
    public String errorMessage {get; set;}
    
    static {
        typeOfApplicationOptions = new List<SelectOption>{new SelectOption('','--None--')};
        
        Schema.DescribeFieldResult fieldResult = Case.Type_of_Application__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple) {
            typeOfApplicationOptions.add(new SelectOption(f.getValue(), f.getLabel()));
        }       
    }
    
    public List<Attachment> attachments {
        get{return this.attachments == null ? new List<Attachment>() : this.attachments;} 
        set{this.attachments = (value == null ? new List<Attachment>() : value);}
    }
    
    public WebToCaseConcession_CX (ApexPages.StandardController controller) {
        caseRecord = new Case();
        caseRecord.Origin =  GlobalConstants.WEB2CASE_ORIGIN;
        caseRecord.Type = Label.DefaultCaseTypeForConcession;
        caseRecord.Status = GlobalConstants.DEFAULT_WEBTOCASE_STATUS_TRIAGE;
        //case categorization by webform user to be considered as -1 as its high probability of mis-categorization and would need case manager to correct the categorization
        caseRecord.categorisation_count__c = -1; 
        caseRecord.Origin_Details__c = validateString('source');
        caseRecord.Supplied_Referrer__c = validateString('refsite');
        if(!String.isBlank(caseRecord.Origin_Details__c)) {  
           caseRecord.Modes__c = validateString('about');            
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
        //state defaulted to NSW for concession application
        this.selectedState = 'NSW';        
    }   
    
    private String validateString(String urlParameter) {
        if(ApexPages.currentPage().getParameters().containsKey(urlParameter)) {
            return String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(urlParameter)).escapeHtml4();            
        }       
        return null;
    }
    
    public PageReference createCase() {
        System.debug('Executing createCase...');
        try {
            if(String.isBlank(caseRecord.Users_Ip_address__c)) {
                System.debug('Ip address error:');
                return returnErrorPage();
            }
            WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker(caseRecord.Users_Ip_address__c );
            if(!spamChecker.isSuspectedSpam()) {
                populateContactDetailsOnCase();
                caseRecord.Subject = 'Concessions form: ' + caseRecord.Type_of_Application__c;
                WebToCaseCreator caseCreator = new WebToCaseCreator(caseRecord);
                System.debug('Case status before insert: ' + caseRecord.Status);
                caseRecord = caseCreator.insertCase(); 
                List<Case> caseDetails = [SELECT Id, CaseNumber, ContactId, OwnerId, Status
                                          FROM Case WHERE Id =:caseRecord.Id];
                if(!caseDetails.isEmpty()) {
                    addAttachments(caseDetails[0]);

                    caseRecord = caseDetails[0];
                    System.debug('Case status after insert: ' + caseRecord.Status);
                    if(!associateContactWithCase()) {
                        update caseRecord;
                    }
                    
                    PageReference pgRef = Page.ConcessionApplicationThankYouPage;
                    pgRef.getParameters().put('caseNumber', caseDetails[0].CaseNumber);
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
        pgRef.getParameters().put('source', 'concessions-application');
        return pgRef;
    }
    
    private Boolean associateContactWithCase() {        
        String salesforceBaseUrl = ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To');
        Boolean caseUpdated = false;
        if(caseRecord != null && contactPerson != null && !String.isBlank(contactPerson.LastName)) {
            contactPerson.mailingStateCode = selectedState;
            if(!String.isBlank(selectedState)) {
                contactPerson.mailingCountryCode = DEFAULT_COUNTRY_AUS;
            }
            WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(caseRecord, contactPerson, salesforceBaseUrl);
            contactCreator.createContact();
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
        if(!String.isBlank(contactPerson.MailingStreet)) {
            caseRecord.Supplied_Address__c = contactPerson.MailingStreet + '\n';    
        }
        if(!String.isBlank(contactPerson.MailingCity)) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingCity + '\n';
        }
        if(!String.isBlank(selectedState)) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + selectedState + ' ';
        }
        if(!String.isBlank(contactPerson.MailingPostalCode)) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingPostalCode + '\n';
        }
        if(!String.isBlank(contactPerson.MailingCountry)) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingCountry;
        }
        if(!String.isBlank(contactPerson.MailingCountryCode)) {
            caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contactPerson.MailingCountryCode;
        }
    }
    
    @RemoteAction
    global static List<WebToCase_CX.CaseCategorization> retrieveConcessionTaxonomy() {
        List<WebToCase_CX.CaseCategorization> concessionTaxonomies = new List<WebToCase_CX.CaseCategorization>();
        
        List<Taxonomy_Metadata__c> level3Taxonomy = [SELECT Id, Customer_Value__c, Parent_Id__r.Name, Parent_Id__r.Customer_Value__c
                                                    FROM Taxonomy_Metadata__c
                                                    WHERE Type__c = :GlobalConstants.TAXONOMY_TYPE_ISSUE
                                                        AND Status_Customer_Facing__c = :String.escapeSingleQuotes(GlobalConstants.TAXONOMY_STATUS_ACTIVE) 
                                                        AND Display_on_Concession_Form__c = true
                                                        AND Level__c = 'Level 3'
                                                    ORDER BY Customer_facing_sort_order__c ASC NULLS LAST, 
                                                    Customer_Value__c ASC NULLS LAST];
        
        Map<String, List<String>> level2VsLevel3 = new Map<String, List<String>>();
        for(Taxonomy_Metadata__c level3 : level3Taxonomy){
            String level2Value;
            if(level3.Parent_Id__r != null && level3.Parent_Id__r.Customer_Value__c != null){
                level2Value = level3.Parent_Id__r.Customer_Value__c;
            }
            
            if(level2Value != null && !level2VsLevel3.containsKey(level2Value)){
                level2VsLevel3.put(level2Value, new List<String>());
            }
            level2VsLevel3.get(level2Value).add(level3.Customer_Value__c);
        }
        
        for(String category : level2VsLevel3.keySet()) {
            List<String> subcat = new List<String>();
            subcat.addAll(level2VsLevel3.get(category));
            WebToCase_CX.CaseCategorization categorization = new WebToCase_CX.CaseCategorization(NON_MODAL_MODE + ':' + category, subcat);
            concessionTaxonomies.add(categorization);
        }        
        return concessionTaxonomies;
    }  
    
    private void addAttachments(Case caseDetails) {
        if(caseDetails != null && attachments != null && !attachments.isEmpty()) {
            WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseDetails, attachments);
            attachmentCreator.createCaseAttachment();
        }
    }
       
    public void setAllowedFileAttachments(String fileExtension){}
    
    public String getAllowedFileAttachments() {
        Map<String, AllowableFileExtensions__c> fileExtensions = AllowableFileExtensions__c.getAll();
        Set<String> allowedFileExtensions = new Set<String>();
        allowedFileExtensions.addAll(fileExtensions.keySet());
        return JSON.serialize(allowedFileExtensions);
    }
}