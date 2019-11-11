/*------------------------------------------------------------
Author:        Ian F
Company:       TfNSW
Description:   Custom Rest API to add attachment to Case
Inputs:        
Test Class:    

History

------------------------------------------------------------*/
@RestResource(urlMapping='/v1/salesforce/attachment/*')
global class CaseCFSApiAttachmentRestService {

  
@HttpPost
   global static void doPost() {
       new processAttachmentJSON().execute();                      
   }
    
    public class processAttachmentJSON{
        private Case parentCase; 
        private Attachment newAttachment;
        private Set<String> allowedFileExtensions;
        
        public processAttachmentJSON() {
            Map<String, AllowableFileExtensions__c> fileExtensions = AllowableFileExtensions__c.getAll();
            allowedFileExtensions = new Set<String>();
            allowedFileExtensions.addAll(fileExtensions.keySet());
        }
    
        public void execute(){
            String result='';
            String receivedJson = '';
       
            if (RestContext.request.requestBody!=null && RestContext.request.requestBody.toString().length()>0){
                //Set any tokens that have empty strings as values to Null
                receivedJson=setEmptyValuesToNull(RestContext.request.requestBody.toString()); 
       
                Savepoint sp = Database.setSavepoint();
                try {
                    result = populateAttachmentRecord (receivedJson);
                    if (result=='Success' && this.newAttachment!=null){
                        result=createAttachment();
                    }
       
                    if (result!='Success'){
                        Database.rollback(sp);
                    }
                }catch (Exception e){
                    Database.rollback(sp);
                    System.debug(e);
                    list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
                    ApplicationLogMessage message= new ApplicationLogMessage();
                    message.source='CaseCFSApiAttachmentRestService';
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
       
                    result = e.getMessage();
                }
            }
            else{
                result='No input received';
            }    
            
            System.debug('CaseCFSApiAttachmentRestService result : '+result);
            
            RestResponse res = RestContext.response;
            if(result=='Success'){
                res.responseBody = Blob.valueOf('{"Status" : "Success"}');
                res.addHeader('Content-Type', 'application/json');
                res.statusCode = 200;
            }
            else{
                res.responseBody = Blob.valueOf(result);
                res.addHeader('Content-Type', 'text/plain');
                res.statusCode = 400;
                System.debug(result);
            }
        }
        
        /**************************************************************
        *  Parse the JSON passed in the request and create the 
        *  Attachment record.
        **************************************************************/
        private String populateAttachmentRecord (String JSONContent){
            String result = 'Success';
            String guid;
            String caseNumber;
            
            this.newAttachment = new Attachment();
            JSONParser parser = JSON.createParser(JSONContent);

            JSONToken currentToken = parser.nextToken();
            while (currentToken!=null && result=='Success'){
                if(parser.getText()!=null && parser.getText().equalsIgnoreCase('Body'))
                {
                    currentToken = parser.nextToken();
                    this.newAttachment.Body = EncodingUtil.base64Decode(parser.getText());
                }
                else if (parser.getText()!=null && parser.getText().equalsIgnoreCase('Name')){
                    currentToken = parser.nextToken();
                    String fileName = parser.getText();
                    if (isAllowableFile(fileName)==false){
                        String allowedFileTypes = '';
                        for (String fileType : this.allowedFileExtensions){
                            allowedFileTypes = (allowedFileTypes=='' ? fileType : allowedFileTypes  + ', ' +fileType);
                        }
                        result = 'Invalid File Type.  Allowable file types are : '+allowedFileTypes;
                    }
                    else{
                        if(String.isNotBlank(fileName) && fileName.length() > 80){
                            Integer fileExtensionLength = 0;
                            String fileExtension = '';
                            String fileNameToBeTrimmed = fileName;
                            Integer fileExtensionStart = fileName.lastIndexOf('.'); 
                            if (fileExtensionStart  > 0){
                                // get filename extension length with '.' as last index before start of extension
                                fileExtensionLength = fileName.length() - fileName.lastIndexOf('.');
                                fileExtension = fileName.substring(fileName.lastIndexOf('.'),fileName.length());
                                // get string before '.' i.e before extension excluding '.'
                                fileNameToBeTrimmed = fileName.substring(0,fileName.lastIndexOf('.'));
                            }
                            // Set trimmed filename
                            this.newAttachment.Name = fileNameToBeTrimmed.left(80 - fileExtensionLength)+fileExtension;
                        }
                        else{
                            this.newAttachment.Name = fileName;
                        }
                    }
                }
                else if(parser.getText()!=null && parser.getText().equalsIgnoreCase('CaseGUID'))
                {
                    currentToken = parser.nextToken();
                    guid = parser.getText();
                }
                else if (currentToken==JSONToken.FIELD_NAME){
                    String fieldName = parser.getText();
                    currentToken = parser.nextToken();
                    String fieldValue = parser.getText();
                    this.newAttachment.put(fieldName, fieldValue);
                }
                currentToken = parser.nextToken();
            }
              
            if (guid!=null){
                List<Case> cases = [select Id, ownerId from Case where GUID__c = :guid];
                if (cases!=null && cases.size()>0){
                    parentCase = cases[0];
                }
                else{
                    result = 'Invalid Case GUID';
                }
            }
            else{
                result = 'No GUID received';
            }
            return result;
        }
        
        /**********************************************************
        * Create the NoteAndAttachments record, link the Attachment 
        * to the Case and execute DML to insert the records.
        ***********************************************************/
        private String createAttachment (){
            String strResult = 'Success';
            
            strResult = this.validateAttachmentFields();

            if (strResult=='Success' && this.parentCase!=null && this.parentCase.Id!=null){
                RecordType attachmentRecordType = [select Id from RecordType 
                                                   where SobjectType = 'NoteOrAttachment__c' and DeveloperName = 'Attachment' limit 1];
                                                   
                NoteOrAttachment__c newNOA = new NoteOrAttachment__c(Name = this.newAttachment.Name,
                                                                     Case__c = this.parentCase.Id,
                                                                     OwnerId = this.parentCase.OwnerId,
                                                                     RecordTypeId = attachmentRecordType.Id);                                          

                Database.SaveResult insertCustomAttResult = Database.insert(newNOA);
                if (!insertCustomAttResult.isSuccess()) {
                    List<Database.Error> errors = insertCustomAttResult.getErrors();
                    if (errors!=null && errors.size()>0){
                        strResult = errors[0].getMessage();
                    }
                    else{
                        strResult = 'Error creating Custom Attachment';
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
                        strResult = 'Error creating Attachment';
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
                            strResult = 'Error updating Custom Attachment';
                        }
                    } 
                }                                                       
            }//Case Exists
            else{
                strResult= (strResult=='Success' ? 'Parent Case not found' : strResult);
            }
            return strResult;
        } //End Method createAttachment
        
        private Boolean isAllowableFile(String filename) {
            if(!String.isBlank(filename) && filename.lastIndexOf('.') > -1) {
                String extension = filename.substring(filename.lastIndexOf('.'), filename.length());
                if(this.allowedFileExtensions.contains(extension.toLowerCase())) {
                    return true;
                }            
            }
            return false;        
        } 
        
        /*******************************************************
        * Validate that required fields are passed.
        ********************************************************/
        private String validateAttachmentFields(){
            String result = 'Success';
            String missingfields = '';
            
            system.debug('validateAttachmentFields  Attachment : '+this.newAttachment);

            if (this.newAttachment.Name==null || this.newAttachment.Name==''){
                missingfields = 'Name';
            }
            
            if (this.newAttachment.ContentType==null || this.newAttachment.ContentType==''){
                missingfields = (missingfields=='' ? 'ContentType' : missingfields+', ContentType');
            }
            if (this.newAttachment.Body==null || this.newAttachment.Body.size()==0){
                missingfields = (missingfields=='' ? 'Body' : missingfields+', Body');
            }
            
            if (missingfields!=''){
                result = 'The following field(s) are required : '+missingfields;
            }
            return result;
        }
        
        /*******************************************************************
        * Set any empty strings in the JSON to NULL
        *******************************************************************/
        private String setEmptyValuesToNull(String receivedJSON){
            while (receivedJSON.contains('" ')){
                receivedJSON = receivedJSON.replace('" ', '"');
            }
            return receivedJSON;
        }
    }
}