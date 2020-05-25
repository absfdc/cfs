/*------------------------------------------------------------
Author:        Ian F
Company:       TfNSW
Description:   Custom Rest API to create Cases and Contacts and Attachments
Inputs:        
Test Class:    

History:
Mar/2/2018   Ian F, TfNSW  
Mar/28/2018  Ian F, TfNSW  Version 2.0 updates.  Comments inline.
May/9/2018  Ian F, TfNSW  Fixed bug in convertFromGMT
Jul/02/2019 Abhi I, TfNSW SFCOE-3171 Add UTC Date of Incident option to CFS API
Jan/13/2020 Abhi I, TfNSW SFCOE-3549 fixed bug in setEmptyValuesToNull method
------------------------------------------------------------*/
@RestResource(urlMapping='/v1/salesforce/case/*')
global class CaseCFSApiRestService {
    
    @HttpPost
    global static void doPost() {
        new processCaseJSON().execute();                            
    }
  
    public class processCaseJSON{
        private Contact newContact; 
        private Case newCase; 
        private Attachment newAttachment;
        private Set<String> allowedFileExtensions;
        
        public processCaseJSON() {
            //Initialise list of allowed file extensions for attachments from Custom Setting 
            Map<String, AllowableFileExtensions__c> fileExtensions = AllowableFileExtensions__c.getAll();
            allowedFileExtensions = new Set<String>();
            allowedFileExtensions.addAll(fileExtensions.keySet());
        }
    
        //Main method for executing API logic
        public void execute(){
            String result='';
            String receivedJson = '';
            RestResponse res = RestContext.response;
       
            if (RestContext.request.requestBody!=null && RestContext.request.requestBody.toString().length()>0){
                //Set any tokens that have empty strings as values to Null
                receivedJson=setEmptyValuesToNull(RestContext.request.requestBody.toString()); 
            //    return receivedJson;
                Savepoint sp = Database.setSavepoint();
                try {
                    //Validate Case, contact and Attachment object names are correct
                    result = validateObjectNames(receivedJson);
                    if (result=='Success'){
                        //Create the new records in memory
                        result = populateObjects (receivedJson);
                    }
                    if (this.newCase==null && result=='Success'){
                        result='Case not created';  
                    }
                    if (result=='Success' && this.newContact!=null){
                        //Insert new Contact
                        result=createContact();
                    }
                    if (result=='Success' && this.newCase!=null){
                        //Insert new Case
                        result=createCase();
                    }
                    if (result=='Success' && this.newAttachment!=null){
                        //Insert new Attachment
                        result=createAttachment();
                    }
        
                    if (result!='Success'){
                        Database.rollback(sp);
                        System.debug('result!=Success');
                        res.responseBody = Blob.valueOf(result);
                        res.addHeader('Content-Type', 'text/plain');
                        res.statusCode = 400;
                    }
                    else{
                        res.responseBody = Blob.valueOf('{ "Status" : "Success",  "CaseNumber" : "'+this.newCase.CaseNumber+'", "GUID" : "'+this.newCase.GUID__c+'" }');
                        result = '{ "Status" : "Success", "CaseNumber" : "'+this.newCase.CaseNumber+'", "GUID" : "'+this.newCase.GUID__c+'" }';
                        res.addHeader('Content-Type', 'application/json'); 
                        res.statusCode = 200;
                    }
                }catch (Exception e){
                    Database.rollback(sp);
                    System.debug(e);
                    System.debug('Exception thrown');
                    list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
                    ApplicationLogMessage message= new ApplicationLogMessage();
                    message.source='CaseCFSApiRestService';
                    message.sourceFunction='execute';
                    message.logMessage=e.getMessage();
                    if (receivedJson.Length() < 131072){
                        message.referenceInfo = receivedJson;
                    }
                    else{
                        message.referenceInfo = receivedJson.substring(0,131072);
                    }
                    message.ex=e;
                    message.debugLevel=GlobalConstants.ERROR;
                    messages.add(message);
                    ApplicationLogUtility.logMessage(messages);
                    messages.clear();    
                    res.responseBody = Blob.valueOf(e.getMessage());
                    res.addHeader('Content-Type', 'text/plain');
                    res.statusCode = 400;
                }
            }
            else{
                res.responseBody = Blob.valueOf('No input received');
                res.addHeader('Content-Type', 'text/plain');
                res.statusCode = 400;
            }     
        }//end execute
        
        /*********************************************************************************
        * Validate that only the objects Case, Contact and Attachment are present in the 
        * JSON and they are correcltly spelled
        **********************************************************************************/
        private String validateObjectNames (String JSONContent){
            String result = 'Success';
            String invalidObjects = '';
            Set<String> validObjects =  new Set<String>{'CASE', 'CONTACT', 'ATTACHMENT'};
            try {
                JSONParser parser = JSON.createParser(JSONContent);
                parser.nextToken();
                JSONToken currToken = parser.nextToken();
                while (currToken!=null && currToken!=JSONToken.END_OBJECT && result=='Success'){
                    String currObj = parser.getText();
                    if ( validObjects.contains(currObj.toUpperCase())==false){
                        invalidObjects = (invalidObjects=='' ? currObj : invalidObjects+', '+currObj); 
                    }
                    parser.nextToken();
                    parser.skipChildren();
                    currToken = parser.nextToken();
                }
            }
            catch(Exception e){
                System.debug(e);
                list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
                ApplicationLogMessage message= new ApplicationLogMessage();
                message.source='CaseCFSApiRestService';
                message.sourceFunction='validateObjectNames';
                message.logMessage=e.getMessage();
                if (JSONContent.Length() < 131072){
                    message.referenceInfo = JSONContent;
                }
                else{
                    message.referenceInfo = JSONContent.substring(0,131072);
                }
                message.ex=e;
                message.debugLevel=GlobalConstants.ERROR;
                messages.add(message);
                ApplicationLogUtility.logMessage(messages);
                messages.clear();    
            
                result = e.getMessage();
            }   
            
            if (invalidObjects!=''){
                result = 'Case not created. The following object(s) not detected in the system : '+invalidObjects;
            }
                
            return result;
        }
        
        /**********************************************************************************
        * Parse the JSON passed in the request and populate the Case, Contact and 
        * Attachment variables
        **********************************************************************************/
        private String populateObjects (String JSONContent){
            String result = 'Success';

            JSONParser parser = JSON.createParser(JSONContent);

            JSONToken currentToken = parser.nextToken();
            while (currentToken!=null && result == 'Success'){
                system.debug('CaseCFSApiRest:populateObjects while parser.getText() : '+parser.getText());
                if(parser.getText()!=null && parser.getText().equalsIgnoreCase('Contact')){
                    currentToken = parser.nextToken(); 
                   // this.newContact = (Contact)parser.readValueAs(Contact.class);
                    this.newContact = (Contact)parser.readValueAsStrict(Contact.class);
                    result = this.validateFields('Contact');
                }
                if(parser.getText()!=null && parser.getText().equalsIgnoreCase('Case')){
                    currentToken = parser.nextToken(); 
                    //this.newCase = (Case)parser.readValueAs(Case.class);
                    this.newCase = (Case)parser.readValueAsStrict(Case.class);
                    result = this.validateFields('Case');
                    this.newCase.GUID__c = generateGUID();
                }
                if(parser.getText()!=null && parser.getText().equalsIgnoreCase('Attachment')){
                    populateAttachment(parser);
                    result = this.validateFields('Attachment');
                    system.debug('CaseCFSApiRest:populateObjects populateAttachment parser.getText() : '+parser.getText());
                   // currentToken = parser.nextToken();
                    //parser.skipChildren();
                }
                currentToken = parser.nextToken(); 
            }
            return result;
        }
        
        /****************************************************************************************
        * Called from populateObjects.
        * Parses the Attachment JSON passed in the request and populates the Attachment variable.
        * Also cuts the Attachment Name to 80 characters if it is > 80 and checks if it is an 
        * allowed file type
        *****************************************************************************************/
        private void populateAttachment (JSONParser parser){
            this.newAttachment = new Attachment();
            JSONToken currentToken = parser.nextToken();
            while (currentToken!=JSONToken.END_OBJECT){  
                if(parser.getText()!=null && parser.getText().equalsIgnoreCase('Body'))
                {
                    currentToken = parser.nextToken();
                    this.newAttachment.Body = EncodingUtil.base64Decode(parser.getText());
                }
                else if (parser.getText()!=null && parser.getText().equalsIgnoreCase('Name')){
                    currentToken = parser.nextToken();
                    String fileName = parser.getText();
                    if(String.isNotBlank(fileName) && fileName.length() > 80){
                        // get filename extension length with '.' as last index before start of extension
                        Integer fileExtensionLength = fileName.length() - fileName.lastIndexOf('.');
                        String fileExtension = fileName.substring(fileName.lastIndexOf('.'),fileName.length());
                        // get string before '.' i.e before extension excluding '.'
                        String fileNameToBeTrimed = fileName.substring(0,fileName.lastIndexOf('.'));
                        // Set trimmed filename
                        this.newAttachment.Name = fileNameToBeTrimed.left(80 - fileExtensionLength)+fileExtension;
                    }
                    else{
                        this.newAttachment.Name = fileName;
                    }
                }
                else if (currentToken==JSONToken.FIELD_NAME){
                    String fieldName = parser.getText();
                    currentToken = parser.nextToken();
                    String fieldValue = parser.getText();
                    this.newAttachment.put(fieldName, fieldValue);
                }
                currentToken = parser.nextToken();
            }
        }
        
        /****************************************************************************************
        * Called from execute.
        * Inserts the Contact record and handles duplicates.
        *****************************************************************************************/
        private String createContact (){
            String strResult = 'Success'; 
            List<Contact> duplicateContacts;
           // Boolean highConfidenceMatch;
          //  Map<String, HighConfidenceDuplicateContactRules__c> highConfidenceRules;
            Map<String, FullMatchDuplicateContactRules__c> fullMatchConfidenceRules = FullMatchDuplicateContactRules__c.getAll(); //100% Match Rule
            boolean fullMatch = false;
            
            Database.DMLOptions dmlOption = new Database.DMLOptions();
            dmlOption.DuplicateRuleHeader.AllowSave = false;
            System.debug('contactDetails before dml: '+this.newContact);
            Database.SaveResult result = Database.insert(this.newContact, dmlOption);
            System.debug('contact insert result: '+result);
            System.debug('result.isSuccess(): '+result.isSuccess());
            if (!result.isSuccess()) {
                 for (Database.Error error : result.getErrors()) {                
                     if (error instanceof Database.DuplicateError) {
                         Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                         Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
     
                         // Return only match results of matching rules that find duplicate records
                         Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                         System.debug('Match Results are : '+matchResults);
                         System.debug('match result size: '+matchResults.size());
                         Datacloud.MatchResult firstMatchResult;
                         System.debug('fullMatchConfidenceRules: '+fullMatchConfidenceRules);
                         for(Datacloud.MatchResult mResult : matchResults) {
                             System.debug('mResult.getRule(): '+mResult.getRule());
                             if(fullMatch != true && fullMatchConfidenceRules!=null && !fullMatchConfidenceRules.isEmpty() 
                                && fullMatchConfidenceRules.containsKey(mResult.getRule())) {
                                 fullMatch=true;    //100% match
                                 firstMatchResult = mResult;
                                 System.debug('fullMatch set to TRUE ');
                             }     
                         }
                         
                         if (fullMatch==false){
                             //Insert the new record
                             Database.DMLOptions opts = new Database.DMLOptions();
                             opts.DuplicateRuleHeader.AllowSave = true;
                             Database.SaveResult newResult = Database.insert(this.newContact, opts);
                             System.debug('Full match not found. Inserting a new contact.');
                             if (!newResult.isSuccess()) {
                                 List<Database.Error> errors = newResult.getErrors();
                                 if (errors!=null && errors.size()>0){
                                     strResult = errors[0].getMessage();
                                 }
                                 else{
                                     strResult = 'Case not created. Error creating Contact';
                                 }
                             }
                         }
                         //Now update the first duplicate found with the new details 
                         if(fullMatch == true && strResult=='Success'){
                             //Merge the new record into the first match.
                             Datacloud.MatchResult matchResult = firstMatchResult;
                             Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();   
                            // Database.MergeResult res = Database.merge(this.newContact, (Contact)matchRecords[0].getRecord(), false);
                             this.newContact.Id = matchRecords[0].getRecord().Id;
                             
                             Database.DMLOptions opts = new Database.DMLOptions();
                             opts.DuplicateRuleHeader.AllowSave = true;
                             Database.SaveResult res = Database.update(this.newContact, opts);
                             if (!res.isSuccess()) {
                                for(Database.Error err : res.getErrors()) {
                                    if(strResult=='Success'){
                                        strResult=err.getMessage();
                                    }else{
                                        strResult = ' : '+ err.getMessage();
                                    }
                                }
                             }
                         } 
                     } else {
                         System.debug('Some different error than Duplicate Rules error has occurred');
                         System.debug(LoggingLevel.ERROR, error);
                         strResult = 'Case not created. ' + error.getMessage();
                     }
                 }
             } 
             return strResult;
        }
        
        /****************************************************************************************
        * Called from execute.
        * Inserts the Case record.
        *****************************************************************************************/
        private String createCase (){
            String strResult = 'Success';
            
            //SFCOE-3726 - Triage status override skipped for MO 'Pre-Registration'
            if(this.newCase.Status != GlobalConstants.DEFAULT_MIN_CORRO_WEBTOCASE_STATUS){
                this.newCase.Status = GlobalConstants.DEFAULT_WEBTOCASE_STATUS_TRIAGE;
            }
            List<CFS_API_Default_Status_Map__mdt> defaultStatusList = [select Default_Status__c from CFS_API_Default_Status_Map__mdt
                                                                   where UserId__c = :UserInfo.getUserId()];
            if (defaultStatusList!=null && defaultStatusList.size()>0)   {
                this.newCase.Status = defaultStatusList[0].Default_Status__c;
            }    
                                                            
            if (this.newContact!=null && this.newContact.Id!=null){
                populateContactDetailsOnCase();
            }
            
            if (this.newCase.RecordTypeId==null){
                String multiIssueRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE).getRecordTypeId();
                this.newCase.RecordTypeId = Id.valueOf(multiIssueRecordTypeId);
            }
            if (this.newCase.Origin==null){
                this.newCase.Origin = GlobalConstants.WEB2CASE_ORIGIN;
            }
            
            strResult = populateTaxonomyRelatedFields();

            //SFCOE-3171- Start
            //Override Date Time of Incident if Date Time of Incident is provided in the request
            if(this.newCase.Date_Time_of_Incident_gmt__c != null){
                this.newCase.Date_Time_of_Incident__c = this.newCase.Date_Time_of_Incident_gmt__c;
            }

            //SFCOE-3171 - End
            
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            List<AssignmentRule> rules = [select id from AssignmentRule where SobjectType = 'Case' and Active = true];
            if (rules!=null && rules.size()>0){
                dmlOpts.assignmentRuleHeader.assignmentRuleId= rules[0].id;
            }
            
            Database.SaveResult newResult = Database.insert(this.newCase, dmlOpts);
            if (!newResult.isSuccess()) {
                 List<Database.Error> errors = newResult.getErrors();
                 if (errors!=null && errors.size()>0){
                     strResult = errors[0].getMessage();
                 }
                 else{
                     strResult = 'Error creating Case';
                 }
            }else{
                this.newCase= [select Id, ownerId, CaseNumber, GUID__c from Case where Id = :this.newCase.Id limit 1];
            }
            
            return strResult;
        }
   
        /****************************************************************************************
        * Called from execute.
        * Inserts the Attachment record.
        *****************************************************************************************/
        private String createAttachment (){
            String strResult = 'Success';

            if (this.newCase!=null && this.newCase.Id!=null){
                RecordType attachmentRecordType = [select Id from RecordType 
                                                   where SobjectType = 'NoteOrAttachment__c' and DeveloperName = 'Attachment' limit 1];
                                                   
                NoteOrAttachment__c newNOA = new NoteOrAttachment__c(Name = this.newAttachment.Name,
                                                                     Case__c = this.newCase.Id,
                                                                     OwnerId = this.newCase.OwnerId,
                                                                     RecordTypeId = attachmentRecordType.Id);                                          

                Database.SaveResult insertCustomAttResult = Database.insert(newNOA);
                if (!insertCustomAttResult.isSuccess()) {
                    List<Database.Error> errors = insertCustomAttResult.getErrors();
                    if (errors!=null && errors.size()>0){
                        strResult = errors[0].getMessage();
                    }
                    else{
                        strResult = 'Case not created. Error creating Custom Attachment';
                    }
                } 
           
                this.newAttachment.ParentId = newNOA.Id;
                Database.SaveResult newResult = Database.insert(this.newAttachment);
                if (!newResult.isSuccess()) {
                    List<Database.Error> errors = newResult.getErrors();
                    if (errors!=null && errors.size()>0){
                        strResult = errors[0].getMessage();
                    }
                    else{
                        strResult = 'Case not created. Error creating Attachment';
                    }
                } 
                else{
                    newNOA.Attachment__c = this.newAttachment.Id;
                    Database.SaveResult newResult2 = Database.update(newNOA);
                    if (!newResult.isSuccess()) {
                        List<Database.Error> errors = newResult.getErrors();
                        if (errors!=null && errors.size()>0){
                            strResult = errors[0].getMessage();
                        }
                        else{
                            strResult = 'Case not created. Error creating Custom Attachment';
                        }
                    } 
                }                                                       
            }//Case Exists
            else{
                strResult='Error creating Case';
            }
            return strResult;
        } //End Method createAttachment 
        
        /****************************************************************************************
        * Called from createCase.
        * Prepopulates the taxonomy related Case fields based on the Taxonomy Ids passed in the
        * request.
        *****************************************************************************************/
        private String populateTaxonomyRelatedFields(){
            String strResult = 'Success';
            
            if (this.newCase.Taxonomy_Symptom_Id__c!=null || this.newCase.Taxonomy_Location_Id__c!=null){
                //Retrieve the Taxonomy
                Map<Id, Taxonomy_Metadata__c> taxonomyMap = new Map<Id, Taxonomy_Metadata__c>([SELECT Id, Customer_Value__c, Parent_Id__r.Customer_Value__c, Parent_Id__r.Parent_Id__r.Customer_Value__c, 
                                                                                        Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c, Agency__c, KPI__c, Driver__c, 
                                                                                        Status_Staff_Facing__c,  Issue_Accountability__c
                                                                                        FROM Taxonomy_Metadata__c 
                                                                                        WHERE Status_Staff_Facing__c='Active' 
                                                                                        AND (Id=:this.newCase.Taxonomy_Symptom_Id__c OR Id=:this.newCase.Taxonomy_Location_Id__c)]);
                if (taxonomyMap!=null && taxonomyMap.size()>0){
                    Taxonomy_Metadata__c issueTaxonomy = taxonomyMap.get(this.newCase.Taxonomy_Symptom_Id__c);
                    Taxonomy_Metadata__c locationTaxonomy = taxonomyMap.get(this.newCase.Taxonomy_Location_Id__c);
                    
                    if (issueTaxonomy!=null && locationTaxonomy!=null && 
                        issueTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c != locationTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c)
                    {
                        strResult = 'Error: Location and Issue passed do not belong to the same mode.' +
                          ' Location ' + locationTaxonomy.Customer_Value__c + ' belongs to Mode ' +
                          locationTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c + 
                          ' whereas Issue  ' + issueTaxonomy.Customer_Value__c + ' belongs to Mode ' + 
                          issueTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c;
                    }
                    else if (issueTaxonomy!=null || locationTaxonomy!=null){
                        if (issueTaxonomy!=null && issueTaxonomy.Issue_Accountability__c!=NULL){
                            this.newCase.Taxonomy_Accountability__c=issueTaxonomy.Issue_Accountability__c;
                        }
                        else if (locationTaxonomy!=null && locationTaxonomy.Issue_Accountability__c!=NULL){
                            this.newCase.Taxonomy_Accountability__c=locationTaxonomy.Issue_Accountability__c;
                        }
                        
                        if (issueTaxonomy!=null && issueTaxonomy.Agency__c!=NULL){
                            this.newCase.Agency__c=issueTaxonomy.Agency__c;
                        }
                        else if (locationTaxonomy!=null && locationTaxonomy.Agency__c!=NULL){
                            this.newCase.Agency__c=locationTaxonomy.Agency__c;
                        }
                        
                        if (this.newCase.modes__c==null){
                            this.newCase.modes__c= issueTaxonomy!=NULL ? issueTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c : locationTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c;
                        }
                        if (locationTaxonomy!=null){
                            this.newCase.Taxonomy_Location_Type__c=locationTaxonomy.Parent_Id__r.Parent_Id__r.Customer_Value__c;
                            this.newCase.Taxonomy_Area__c=locationTaxonomy.Parent_Id__r.Customer_Value__c;
                            this.newCase.Taxonomy_Location__c=locationTaxonomy.Customer_Value__c;
                        }
                        if (issueTaxonomy!=null){
                            this.newCase.Taxonomy_Moment__c=issueTaxonomy.Parent_Id__r.Parent_Id__r.Customer_Value__c;
                            this.newCase.Taxonomy_Transaction__c=issueTaxonomy.Parent_Id__r.Customer_Value__c;
                            this.newCase.KPI__c=issueTaxonomy.KPI__c;
                            this.newCase.Key_Driver__c=issueTaxonomy.Driver__c;
                            this.newCase.Taxonomy_Symptom__c=issueTaxonomy.Customer_Value__c;
                        }
                    }
                }  
            }
            return strResult;
        }
        
        /****************************************************************************************
        * Called from createCase.
        * Prepopulates the ContactId, SuppliedName, SuppliedEmailand Supplied_Address__c Case fields 
        * based on the Contact passed in the request.
        *****************************************************************************************/
        private void populateContactDetailsOnCase() {
            this.newCase.ContactId = this.newContact.Id;
            this.newCase.SuppliedEmail = this.newContact.Email;
            this.newCase.SuppliedName = '';
            if(!String.isBlank(this.newContact.FirstName)) {
                this.newCase.SuppliedName = this.newContact.FirstName;
            }
            if(!String.isBlank(this.newContact.LastName)) {
                this.newCase.SuppliedName = this.newCase.SuppliedName + (this.newCase.SuppliedName.length() > 0 ? ' ' : '' ) + this.newContact.LastName;
            }
            this.newCase.SuppliedPhone = this.newContact.Phone;
            this.newCase.Supplied_Address__c = '';
            if(this.newContact.MailingStreet != null) {
                this.newCase.Supplied_Address__c = this.newContact.MailingStreet + '\n';    
            }
            if(this.newContact.MailingCity != null) {
                this.newCase.Supplied_Address__c = this.newCase.Supplied_Address__c + this.newContact.MailingCity + '\n';
            }
            if(this.newContact.MailingState != null) {
                this.newCase.Supplied_Address__c = this.newCase.Supplied_Address__c + this.newContact.MailingState + ' ';
            }
            if(this.newContact.MailingPostalCode != null) {
                this.newCase.Supplied_Address__c = this.newCase.Supplied_Address__c + this.newContact.MailingPostalCode + '\n';
            }
            if(this.newContact.MailingCountry != null) {
                this.newCase.Supplied_Address__c = this.newCase.Supplied_Address__c + this.newContact.MailingCountry + '\n';
            }
            if(this.newContact.MailingCountryCode != null) {
                this.newCase.Supplied_Address__c = this.newCase.Supplied_Address__c + this.newContact.MailingCountryCode;
            }
        }
        
        /****************************************************************************************
        * Called from populateObjects.
        * Generates GUID to be stored on the Case.
        *****************************************************************************************/
        private String generateGUID() {
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

            return guid;
        }
        
        /****************************************************************************************
        * Called from populateObjects.
        * Validates that the user calling the API has access to the fields that are being updated.
        * Also checks that required fields are populated.
        *****************************************************************************************/
        private String validateFields(String objectType){
            String result = 'Success';
            String missingfields = '';
            String errorfields = '';
            List<String> requiredCasefields = new List <String>();
            
            List<CFS_API_Settings__c> settings = [select Required_Case_Fields__c from CFS_API_Settings__c];
            if (settings!=null && settings.size()>0 && settings[0].Required_Case_Fields__c!=null){
                requiredCasefields = settings[0].Required_Case_Fields__c.split(',');
            }
            
            system.debug('CaseCFSApiRestService.validateFields requiredCasefields '+requiredCasefields);
                        
            Map<String, Object> objFields;
            if (objectType=='Case'){
                objFields = this.newCase.getPopulatedFieldsAsMap();
            }
            if (objectType=='Contact'){
                objFields = this.newContact.getPopulatedFieldsAsMap();
            }

            if ((objFields!=null && objFields.size()>0) || objectType=='Attachment'){
                Map<String, Schema.SObjectField> objectFieldMap;
                if (objectType=='Case'){
                    objectFieldMap = Schema.SObjectType.Case.fields.getMap();
                } 
                if (objectType=='Contact'){
                    objectFieldMap = Schema.SObjectType.Contact.fields.getMap();
                }    
                
                if (objectType=='Contact' || objectType=='Case'){
                    system.debug('CaseCFSApiRestService.validateFields objFields '+objFields);
                    for (String fieldName : objFields.keySet()){
                       Schema.SObjectField field = objectFieldMap.get(fieldName);
                       if (field==null || field.getDescribe().isUpdateable()==false){
                          system.debug('CaseCFSApiRestService Case error field : '+fieldName);
                          errorfields = (errorfields=='' ? fieldName : errorfields+', '+fieldName);
                       }
                       //If it is a datetime field, we need to convert from GMT to local time
                       //SFCOE-3171- Skip GMT conversion for Date_Time_of_Incident_gmt__c field
                       if (field.getDescribe().getType()==Schema.DisplayType.DATETIME && fieldName != 'Date_Time_of_Incident_gmt__c'){
                           this.convertFromGMT(objectType, field);
                       }
                    }
                }
                
                if (objectType=='Case'){
                    for (String reqField : requiredCasefields){
                        if (objFields.get(reqField.trim())==null){
                            system.debug('CaseCFSApiRestService Case missing field : '+reqField);
                            missingfields = (missingfields=='' ? reqField : missingfields+', '+reqField);
                        }
                    }
                }
                if (objectType=='Contact'){
                    if (this.newContact.LastName==null){
                        missingfields = 'LastName';
                    }
                    else if (this.newContact.HomePhone==null && this.newContact.Phone==null && this.newContact.OtherPhone==null && 
                             this.newContact.MobilePhone==null && this.newContact.Email==null)
                    {
                        if (this.newContact.MailingStreet==null && this.newContact.MailingCity==null && 
                            this.newContact.MailingStateCode==null && this.newContact.MailingState==null 
                            && this.newContact.MailingPostalCode==null && this.newContact.MailingCountry==null)
                        {    
                            result = 'Case not created. You must provide a Contact Phone Number, Email Address or Mailing Address';
                        }
                        else if (this.newContact.MailingStreet==null || this.newContact.MailingCity==null 
                                 || this.newContact.MailingStateCode==null || this.newContact.MailingState==null 
                                 || this.newContact.MailingPostalCode==null || this.newContact.MailingCountry==null){
                            result = 'Case not created. The Contact Mailing Address is incomplete.  Contact Mailing Address must be completed if no Phone Number or Email is provided.';
                        }
                    }         
                }
                if (objectType=='Attachment'){
                    if (this.newAttachment.Name==null){
                        missingfields = 'Name';
                    }
                    if (this.newAttachment.ContentType==null){
                        missingfields = (missingfields=='' ? 'ContentType' : missingfields+', ContentType');
                    }
                    if (this.newAttachment.Body==null){
                        missingfields = (missingfields=='' ? 'Body' : missingfields+', Body');
                    }
                    if (missingfields=='' && isAllowableFile(this.newAttachment.Name)==false){
                        String allowedFileTypes = '';
                        for (String fileType : this.allowedFileExtensions){
                            allowedFileTypes = (allowedFileTypes=='' ? fileType : allowedFileTypes  + ', ' +fileType);
                        }
                        result = 'Case not created. Invalid Attachment File Type.  Allowable File Types are : '+allowedFileTypes;
                    }
                }
                
                if (errorfields!=''){
                   result = 'Case not created. The following '+ objectType +' field(s) do not exist or you do not have permission to update them : '+errorfields;
                }
                if (missingfields!=''){
                    result = 'Case not created. The following '+ objectType +' field(s) are required : '+missingfields; 
                }
            }
            else{
                result = 'Case not created. '+objectType+' passed with no fields.';
            }
            system.debug('CaseCFSApiRestService validateFields result : '+result);
            return result;
        }
        
        /***********************************************************
        * Called from validateFields.
        * Checks that the Attachment has a valid extension..
        ************************************************************/  
        private Boolean isAllowableFile(String filename) {
            if(!String.isBlank(filename) && filename.lastIndexOf('.') > -1) {
                String extension = filename.substring(filename.lastIndexOf('.'), filename.length());
                if(this.allowedFileExtensions.contains(extension.toLowerCase())) {
                    return true;
                }            
            }
            return false;        
        } 
        
        /*******************************************************************
        * Set any empty strings in the JSON to NULL
        *******************************************************************/
        private String setEmptyValuesToNull(String receivedJSON){
            while (receivedJSON.contains('" ')){
                receivedJSON = receivedJSON.replace('" ', '"');
            }
            while (receivedJSON.contains(': ""')){
                receivedJSON = receivedJSON.replace(': ""', ':null');
            }
            while (receivedJSON.contains(':""') ){
                receivedJSON = receivedJSON.replace(':""', ':null');
            }
            // receivedJSON = receivedJSON.replaceAll('""', 'null');
            return receivedJSON;
        }
        
        /*******************************************************************
        * Convert datetime fields from GMT to local time 
        *******************************************************************/
        private void convertFromGMT(String objectType, Schema.SObjectField field){
            if (objectType=='Case'){
                DateTime caseDateTime = (DateTime)this.newCase.get(field);
                caseDateTime = DateTime.newinstance(caseDateTime.yearGMT(),
                                                    caseDateTime.monthGMT(),
                                                    caseDateTime.dayGMT(),
                                                    caseDateTime.hourGMT(),
                                                    caseDateTime.minuteGMT(),
                                                    caseDateTime.secondGMT());

                this.newCase.put(field, caseDateTime);
            }
        }
            
    }// END class processCaseJSON
}