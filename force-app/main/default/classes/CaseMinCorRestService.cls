/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus Technology Partners
Description:   Rest API to log Min cor cases coming from road and transport web forms
Inputs:        Json object that contains a Case to be logged with associated Contact and custom note & attachments.
Test Class:    CaseMinCorRestServiceTest

History
03/08/2016      Dipankar Barman         Implemented Rest API service
30/12/2016      Arxxus                  Updated to use 100% matching rule
15/06/2017      Ian Fitzgerald          Added list of original file names to parameters passed to WebToCaseAttachmentCreator to 
                                        keep track of file names > 80 chars
------------------------------------------------------------*/
@RestResource(urlMapping='/mincor/v1/createCase/*')
global class CaseMinCorRestService {
    public class CustomException extends Exception {}

    public static final String DEBUG_LOG_LEVEL_INFO = 'Info';
    public static final String DEBUG_LOG_LEVEL_ERROR = 'Error';
    public static final RecordType CUSTOMER = [SELECT ID FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = :GlobalConstants.CUSTOMER_CONTACT_RECTYPE_NAME];

    @HttpPost
    global static CaseResultWrapper doPost() {
      boolean bFileNamesAreTrimmed = false;
        List<String> originalFileNames = new List<String>();
        CaseResultWrapper caseResponse = new CaseResultWrapper();
        
        //Map<String, HighConfidenceDuplicateContactRules__c> highConfidenceRules = HighConfidenceDuplicateContactRules__c.getAll();
        Map<String, FullMatchDuplicateContactRules__c> fullMatchConfidenceRules = FullMatchDuplicateContactRules__c.getAll();
        
        List<ApplicationLogMessage> logMessages =new List<ApplicationLogMessage>();
        
        PublicSiteDomainName__c psdn = PublicSiteDomainName__c.getValues('Instance URL');
        String salesforceBaseUrl = psdn.Domain_Name__c;

        Savepoint caseCreationSP = Database.setSavepoint();
        try {
            

            String caseJson = RestContext.request.requestBody.tostring();

            ApplicationLogMessage payloadLogMsg = new ApplicationLogMessage();
            payloadLogMsg.source = 'CaseMinCorRestService';
            payloadLogMsg.sourceFunction = 'doPost';
            payloadLogMsg.logMessage = 'Request Body, contains all information of cases and associated contact except their attachments.';
            payloadLogMsg.debugLevel = DEBUG_LOG_LEVEL_INFO;

            payloadLogMsg.payLoad=caseJson;
            
            logMessages.add(payloadLogMsg);

            RequestWrapper reqW = (RequestWrapper) JSON.deserialize(caseJson, RequestWrapper.class);
            system.debug('request ::' + reqW  );
            String errMsg = '';
            if(reqW != null) {
                
                List<Contact> contacts = new List<Contact>();

                Map<String, Integer> contactIndexByLocalId = new Map<String, Integer>();
                Map<Integer, String> contactLocalIdByIndex = new Map<Integer, String>();
                Integer counter = 0;
                Contact con;
                
                Case newCase = new Case();
                //Contact highConfidenceMatchContact = null;
                Contact hundredPercentMatchContact = null;
                
                List<Contact> lowConfidanceMatchContacts = null;
                
                con = new Contact();
                con.FirstName = reqW.firstName; 
                con.LastName = reqW.lastName;
                con.Email = reqW.email;
                con.Phone = reqW.phone;
                con.MailingStreet = reqW.mailingStreet;
                con.MailingCity = reqW.mailingCity;
                con.MailingState = reqW.mailingState;
                con.MailingPostalCode = reqW.mailingPostalCode;
                con.MailingCountry = reqW.mailingCountry;
                con.Salutation = reqW.salutation;
                con.RecordTypeId=CUSTOMER.Id;    
                
                
                //calling web duplicate contact detector
                //ContactCreator creator = new ContactCreator(con);
                String contactId;
                
                Database.DMLOptions dmlOption = new Database.DMLOptions();
                dmlOption.DuplicateRuleHeader.AllowSave = false;
                
                dmlOption.DuplicateRuleHeader.runAsCurrentUser = false;
                
                Database.SaveResult result = Database.insert(con, dmlOption);
                
                if(!result.isSuccess()) {

                 for(Database.Error error : result.getErrors()) {
                
                  if(error instanceof Database.DuplicateError) {
                    
                    Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                    Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                    // Return only match results of matching rules that find duplicate records
                    Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                   
                    System.debug('Match Results are : '+matchResults);
                    System.debug('match result size: '+matchResults.size());
                    Datacloud.MatchResult firstMatchResult;
                    Boolean fullMatch = false;
                    
                    for(Datacloud.MatchResult mResult : matchResults) {

                        if(fullMatch != true) {
                            
                            //100% match 
                            if(fullMatchConfidenceRules != null && !fullMatchConfidenceRules.isEmpty()) {
            
                             System.debug(fullMatchConfidenceRules+' '+fullMatchConfidenceRules.size());
                             System.debug(mResult.getRule());
                             if(fullMatchConfidenceRules.containsKey(mResult.getRule())) {
                               
                               System.debug('full matchfound setting variable fullMatch to true.');
                               fullMatch = true;
                             }
                            }   
                            
                            firstMatchResult = mResult;
                        }
                     }
                    
                     if(fullMatch == true) {
                        
                        //Fetch the matching contact records from the first duplicate match result.
                        Datacloud.MatchResult matchResult = firstMatchResult;
                        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                        
                        List<Contact> duplicateContacts = new List<Contact>();
                        
                        // Add matched contact to the duplicate contacts variable
                        System.debug('match results after finding matchRecord'+matchRecords);
                        for(Datacloud.MatchRecord matchRecord : matchRecords) {
                           
                           
                            System.debug('Matched record details == '+matchRecord);
                            duplicateContacts.add((Contact) matchRecord.getRecord());
                           
                            //updateMatchedRecord((Contact) matchRecord.getRecord());
                            System.debug('Adding to Duplicates');
                            contactId = duplicateContacts[0].id;
                            System.debug('Found matching contact '+duplicateContacts[0].id);
                        }
                        
                        hundredPercentMatchContact = duplicateContacts[0];
                 
                        if(String.isNotEmpty(con.FirstName)) hundredPercentMatchContact.FirstName = con.FirstName;
                        if(String.isNotEmpty(con.LastName)) hundredPercentMatchContact.LastName = con.LastName;
                        
                        //if(String.isNotEmpty(con.Email)) hundredPercentMatchContact.Email = con.Email;
                        System.debug('Check NonEmpty :: ' + con.Phone + '::'+ String.isNotEmpty(con.Phone)+'::'+ String.isNotEmpty(con.MailingStreet));
                        if(String.isNotEmpty(con.Phone)) hundredPercentMatchContact.Phone = con.Phone;
                        
                        
                        hundredPercentMatchContact.Email = con.Email;
                        //hundredPercentMatchContact.Phone = con.Phone;
                        
                        //hundredPercentMatchContact.MailingStreet = con.MailingStreet;
                        //hundredPercentMatchContact.MailingCity = con.MailingCity;
                        //hundredPercentMatchContact.MailingPostalCode = con.MailingPostalCode;
                        
                        if(String.isNotEmpty(con.MailingStreet)) hundredPercentMatchContact.MailingStreet = con.MailingStreet;
                        if(String.isNotEmpty(con.MailingCity)) hundredPercentMatchContact.MailingCity = con.MailingCity;
                        
                        //if(String.isNotEmpty(con.MailingState)) hundredPercentMatchContact.MailingState = con.MailingState;
                        if(String.isNotEmpty(con.MailingPostalCode)) hundredPercentMatchContact.MailingPostalCode = con.MailingPostalCode;
                        
                        //if(String.isNotEmpty(con.MailingCountry)) hundredPercentMatchContact.MailingCountry = con.MailingCountry;
                        
                        
                        if(String.isEmpty(hundredPercentMatchContact.MailingState) 
                           || String.isNotEmpty(con.MailingState)) {
                           
                         hundredPercentMatchContact.MailingState = con.MailingState;
                         //hundredPercentMatchContact.MailingCountry = 'Australia';
                        }
                        
                        if(String.isEmpty(hundredPercentMatchContact.MailingCountry) 
                           || String.isNotEmpty(con.MailingCountry))
                        hundredPercentMatchContact.MailingCountry = con.MailingCountry;
                        
                        System.debug('Updated Contact :: ' + hundredPercentMatchContact );
                        //hundredPercentMatchContact.Salutation = con.Salutation;
                        if(String.isNotEmpty(con.Salutation)) hundredPercentMatchContact.Salutation = con.Salutation;
                 
                        Database.DMLOptions contactDmlOpt = new Database.DMLOptions();
                        contactDmlOpt.DuplicateRuleHeader.AllowSave = true;
                        Database.SaveResult matchedconres = Database.update(hundredPercentMatchContact, contactDmlOpt);
                        
                        System.debug('Save Result: '+matchedconres);

                      } 
                      else {
                       
                        Database.DMLOptions dmlOpt = new Database.DMLOptions();
                        dmlOpt.DuplicateRuleHeader.AllowSave = true;
                        Database.SaveResult newResult = Database.insert(con, dmlOpt);
                        
                        System.debug('Mailing Country: '+reqW.mailingCountry);
                        if(String.isEmpty(reqW.mailingCountry)) {
                        
                         con.MailingCountry = '';
                         System.debug('Mailing Country: '+reqW.mailingCountry);
                         Database.SaveResult updateResult = Database.update(con, dmlOpt);
                        }
                        
                        contactId = newResult.getId();
                        System.debug('Full match not found. Inserting a new contact.');
                      }
                   } 
                   else {
                     
                     errMsg += ' ' + error.getMessage();
                     System.debug('Some different error than Duplicate Rules error has occured');
                     System.debug(LoggingLevel.ERROR, error);
                     ApplicationLogMessage logMsg = new ApplicationLogMessage();
                     logMsg.source = 'CaseMinCorRestService';
                     logMsg.sourceFunction = 'doPost';
                     logMsg.logMessage = 'An exception occurred -'+error;
                     logMsg.debugLevel = DEBUG_LOG_LEVEL_ERROR;
                     logMessages.add(logMsg);
                   } 
                 }
                } 
                else {
            
                  System.debug('Result contact: ' + result.getId());
                  
                  System.debug('Mailing Country: '+reqW.mailingCountry);
                  if(String.isEmpty(reqW.mailingCountry)) {
                   
                   Database.DMLOptions dmlOpt = new Database.DMLOptions();
                   dmlOpt.DuplicateRuleHeader.AllowSave = true;
                   con.MailingCountry = '';
                   System.debug('Mailing Country: '+reqW.mailingCountry);
                   Database.SaveResult updateResult = Database.update(con, dmlOpt);
                  }
                        
                  contactId = result.getId();
                  System.debug('contactId: ' + contactId);
                }
                
                
                Map<String, String> minCorPortfolioDetails = new Map<String,String>();
                Map<String, String> minCorOriginDetail =  new Map<String,String>();
                Map<String,Id> minCorRecType= new Map<String,Id>();
                Map<String,Schema.RecordTypeInfo> rtMapByName =Schema.SObjectType.Case.getRecordTypeInfosByName();

                if(rtMapByName.containsKey(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_ROAD)){
                    minCorRecType.put( GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_ROAD, rtMapByName.get(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_ROAD).getRecordTypeId());
                    minCorOriginDetail.put(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_ROAD,GlobalConstants.MIN_CORR_WEBTOCASE_SOURCE_ROADS);
                    minCorPortfolioDetails.put(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_ROAD,GlobalConstants.MIN_CORR_PORTFOLIO_ROADS);
                }
                else{
                    System.debug(LoggingLevel.ERROR, 'following record type not configured- '+GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_ROAD);
                }
                
                if(rtMapByName.containsKey(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT)){
                    minCorRecType.put( GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT, rtMapByName.get(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT).getRecordTypeId());
                    minCorOriginDetail.put(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT,GlobalConstants.MIN_CORR_WEBTOCASE_SOURCE_TRANSPORT);
                    minCorPortfolioDetails.put(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT,GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT);
                }
                else{
                    System.debug(LoggingLevel.ERROR, 'following record type not configured- '+GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT);
                }

                if(rtMapByName.containsKey(GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX_1)){
                  System.debug('Inside WestConnex');
                    minCorRecType.put( GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX_1, rtMapByName.get(GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX_1).getRecordTypeId());
                    minCorOriginDetail.put(GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX_1,GlobalConstants.MIN_CORR_WEBTOCASE_SOURCE_West_Connex);
                    minCorPortfolioDetails.put(GlobalConstants.CASE_RECORD_TYPE_NAME_WESTCONNEX_1,GlobalConstants.MIN_CORR_PORTFOLIO_WestConnex);
                
                }
                else{
                    System.debug(LoggingLevel.ERROR, 'following record type not configured- '+GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT);
                }

                String caseLocalId = reqW.localId;
                String caseGuid = generateGUID();
                
                newCase.Status = GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS;
                newCase.Origin = GlobalConstants.WEB2CASE_ORIGIN;
                newCase.GUID__c = caseGuid;
                newCase.Modes__c = GlobalConstants.MIN_CORRO_MODE_NAME;//'MAGS'
                newCase.Priority= GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD;//is this same as the priority =individual standard
                newCase.Description = reqW.description;
                newCase.LocalId__c = caseLocalId;
                newCase.GPS_Incident_Location__Latitude__s = reqW.incidentLatitude;
                newCase.GPS_Incident_Location__Longitude__s = reqW.incidentLongitude;
                newCase.SuppliedEmail = reqW.email;
                //newCase.Location_of_Incident__c = reqW.location;


                if(String.isNotEmpty(reqW.originDetail)) {
                    newCase.Origin_Details__c = minCorOriginDetail.get(reqW.originDetail);
                    newCase.RecordTypeId = minCorRecType.get(reqW.originDetail);//pick the record type based on source
                    newCase.Portfolio__c=minCorPortfolioDetails.get(reqW.originDetail);

                }else{
                    System.debug(LoggingLevel.ERROR, 'originDetails is empty or is unexpected type');
                    ApplicationLogMessage caseResultLogMsg = new ApplicationLogMessage();
                    caseResultLogMsg.source = 'CaseMinCorRestService';
                    caseResultLogMsg.sourceFunction = 'doPost';
                    caseResultLogMsg.logMessage = 'originDetails is empty or is unexpected type';
                    caseResultLogMsg.debugLevel = DEBUG_LOG_LEVEL_ERROR;
                    logMessages.add(caseResultLogMsg);
                }

                newCase.Subject = reqW.subject;

                if(newCase.Subject.trim().length() > 255) {
                    newCase.Subject = newCase.Subject.trim().substring(0, 252) + '...';
                }
                newCase.Case_Category__c=reqW.category;
                
                
                String contactDetails = '';
                if (String.isNotEmpty(reqW.salutation)) contactDetails +='\nSalutation: ' + reqW.salutation;
                if(String.isNotEmpty(reqW.firstName)) contactDetails += '\nFirst Name: ' + reqW.firstName;
                if(String.isNotEmpty(reqW.lastName)) contactDetails += '\nLast Name: ' + reqW.lastName;
                if(String.isNotEmpty(reqW.email)) contactDetails += '\nEmail: ' + reqW.email;
                if(String.isNotEmpty(reqW.phone)) contactDetails += '\nphone: ' + reqW.phone;
                if(String.isNotEmpty(reqW.mailingStreet)) contactDetails += '\nMailing Street: ' + reqW.mailingStreet;
                if(String.isNotEmpty(reqW.mailingCity)) contactDetails += '\nMailing City: ' + reqW.mailingCity;
                if(String.isNotEmpty(reqW.mailingState)) contactDetails += '\nMailing State: ' + reqW.mailingState;
                if(String.isNotEmpty(reqW.mailingPostalCode)) contactDetails += '\nMailing Postal Code: ' + reqW.mailingPostalCode;
                if(String.isNotEmpty(reqW.mailingCountry)) contactDetails += '\nMailing Country: ' + reqW.mailingCountry;
                
                if(contactId != NULL && contactId != '') {
                 
                 newCase.ContactId = contactId;
                    //Added by Gary - populate Conga specific fields on the Case record «CASE_CONTACT_EMAIL»  «CONTACT_MOBILEPHONE» «CASE_CONTACT_STREET» «CASE_CONTACT_CITY» «CASE_CONTACT_STATE» «CASE_CONTACT_POST_CODE» - Start
                    if(reqW.mailingCity != null) newCase.Contact_City__c = reqW.mailingCity;
                    if(reqW.mailingPostalCode != null) newCase.Contact_Post_Code__c = reqW.mailingPostalCode;
                    if(reqW.mailingStreet != null) newCase.Contact_Street__c = reqW.mailingStreet;
                    if(reqW.mailingState != null) newCase.Contact_State__c = reqW.mailingState;
					if(reqW.email != null) newCase.Contact_Email__c = reqW.email;                    
                    //Added by Gary - populate Conga specific fields on the Case record - End
                }
                else if(newCase.contactId == NULL) {
                 
                 newCase.Potential_duplicates__c = '\n\n ***** An error occurred while creating a contact ***** \n\n Error Message: ' + errMsg;
                 newCase.Potential_duplicates__c += '\n\n Contact Details Received: ' + contactDetails;
                }
                
                
                if(reqW.toBeContacted) {
                    
                 newCase.Response_Requested__c = 'Yes';    
                } 
                else{//NRR not to be contacted
                 
                    newCase.Response_Requested__c = 'No';
                    newCase.Response_Type__c=GlobalConstants.CASE_NRR_RESPONSE_TYPE; //DB this was requested in a defect
                }
                
                List<AssignmentRule> rules = [SELECT id 
                                              FROM AssignmentRule 
                                              WHERE SobjectType = 'Case' 
                                              AND Active = true LIMIT 1];

                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.OptAllOrNone = false;

                if(!rules.isEmpty()) {                   
                    dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].id;
                    dmlOpts.assignmentRuleHeader.useDefaultRule = false;            
                }
                
                Database.SaveResult caseResult = Database.insert(newCase, dmlOpts);
               
                ApplicationLogMessage caseResultLogMsg = new ApplicationLogMessage();
                caseResultLogMsg.source = 'CaseMinCorRestService';
                caseResultLogMsg.sourceFunction = 'doPost';
                caseResultLogMsg.logMessage = 'Cases creation result';
                caseResultLogMsg.debugLevel = DEBUG_LOG_LEVEL_INFO;
                caseResultLogMsg.referenceInfo = JSON.serialize(caseResult);
                logMessages.add(caseResultLogMsg);

                
                CaseResultWrapper resW = new CaseResultWrapper();
                resW.localId = reqW.localId;
                resW.guid = newCase.Id;

                if(caseResult.isSuccess()) {
                    resW.success = true;

                    Case caseRec = newCase;
                    resW.caseNumber = newCase.CaseNumber;

                } else {
                    resW.success = false;

                    String caseErrMsg = '';
                    for(Database.Error err :caseResult.getErrors()) {
                        caseErrMsg += ' ' + err.getMessage();
                    }

                    resW.errorMessage = caseErrMsg;
                }

                Boolean isImagesTooLarge = false;
                List<String> imageNames = new List<String>();
                List<Attachment> attachments = new List<Attachment>();

                if(null != reqW.filenames && !reqW.filenames.isEmpty()) {
                    for(AttachmentWrapper attWr :reqW.filenames) {
                        // Start: Pawan Tiwrai 18/05/2017
                        //validate attachment filename against 80 characters length 
                        
                        //Ian F Jun/15/2017 keep track of original file name in case it is trimmed
                        String fileName = attWr.name;
                        String trimmedFileName = attWr.name;
                        if(String.isNotBlank(fileName) && fileName.length() > 80){
                            // get filename extension length with '.' as last index before start of extension
                            Integer fileExtensionLength = fileName.length() - fileName.lastIndexOf('.');
                            String fileExtension = fileName.substring(fileName.lastIndexOf('.'),fileName.length());
                            // get string before '.' i.e before extension excluding '.'
                            String fileNameToBeTrimed = fileName.substring(0,fileName.lastIndexOf('.'));
                            // get string after trim few characters to meet 80 characters length
                            trimmedFileName = fileNameToBeTrimed.left(80 - fileExtensionLength)+fileExtension;
                            bFileNamesAreTrimmed = true;
                        }
                        // End 
                        system.debug('Rest API fileName :: ' + fileName);
                        system.debug('Rest API trimmedFileName :: ' + trimmedFileName );
                        attachments.add(new Attachment(
                            ParentId = newCase.Id,
                            ContentType = 'image/jpg',
                            Name = trimmedFileName 
                        ));
                        //Ian F Jun/15/2017  Build list of original file names in case some are trimmed to 80 chars
                        originalFileNames.add(fileName);
                       
                    }
                }
                
                //get the case to determine the owner after assignment rules have run
                case assignedCase=[Select Id, CaseNumber, OwnerId From Case Where Id = :newCase.Id];

                // create attachments
                //Ian F Jun/15/2017  Pass list of original file names to WebToCaseAttachmentCreator
                if (attachments.size()>0){
                    System.debug('CaseMinCorRestService executing WebToCaseAttachmentCreator  originalFileNames : '+originalFileNames);
                    WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(assignedCase, attachments, originalFileNames);
                    caseResponse.customNotesAttachments= attachmentCreator.createCaseCustAttachmentOnly();
                }
                
                caseResponse.success=true;
                caseResponse.caseNumber=assignedCase.CaseNumber;
                caseResponse.localId=reqW.localId;
                caseResponse.guid=newCase.GUID__c;
            }

            
        } catch(Exception ex) {
            Database.rollback(caseCreationSP);

            caseResponse.success = false;
            caseResponse.errorMessage = ex.getMessage();
            system.debug(ex.getStackTraceString());
            ApplicationLogMessage logMsg = new ApplicationLogMessage();
            logMsg.source = 'CaseMinCorRestService';
            logMsg.sourceFunction = 'doPost';
            logMsg.logMessage = 'An exception occurred -'+ex.getStackTraceString();
            logMsg.debugLevel = DEBUG_LOG_LEVEL_ERROR;
            logMsg.ex = ex;
            logMessages.add(logMsg);
        } finally {
            ApplicationLogUtility.logMessage(logMessages);
            logMessages.clear(); 
        }
        System.debug('CaseMinCorRestService caseResponse (before) : '+caseResponse);
        //Need to update the Name value in caseResponse NotesAndAttachments to be the original file name
        //if there are trimmed filenames
        if (bFileNamesAreTrimmed==true){
          for (NoteOrAttachment__c att : caseResponse.customNotesAttachments){
            att.Name = att.File_Name__c;
          }
        }
        System.debug('CaseMinCorRestService caseResponse (final) : '+caseResponse);
        return caseResponse;
    }

    global class RequestWrapper {
        // Case Details
        public String origin {get; set;}
        public String category {get; set;}
        //public String location {get; set;}
        public Double incidentLatitude {get; set;}
        public Double incidentLongitude {get; set;}
        public String description {get; set;}
        public String originDetail {get; set;}
        public String localId {get; set;}
        public String subject{get;set;}
        // Contact details
        public Boolean toBeContacted {get; set;}
        public String firstName {get; set;}
        public String lastName {get; set;}
        public String salutation {get;set;}
        public String email {get; set;}
        public String phone {get; set;}
        public String mailingStreet {get; set;}
        public String mailingCity {get; set;}
        public String mailingState {get; set;}
        public String mailingPostalCode {get; set;}
        public String mailingCountry {get; set;}

        public List<AttachmentWrapper> filenames {get; set;}

        public RequestWrapper() {
            filenames = new List<AttachmentWrapper>();    
        }
    }

    global class AttachmentWrapper {
        public String name {get; set;}
        public Long createdDateTime {get; set;}
    }

    

    global class CaseResultWrapper {
        public Boolean success {get; set;}
        public String errorMessage {get; set;}
        public String localId {get; set;}
        public String guid {get; set;}
        public String caseNumber {get; set;}
        public List<NoteOrAttachment__c> customNotesAttachments {get;set;}
        public CaseResultWrapper() {
            success = false;
        }
    }

    // generate a global/universal unique identifier
    private static String generateGUID() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

        return guid;
    }
}