/*------------------------------------------------------------
Author:        Ian F
Company:       TfNSW
Description:   Custom Rest API to retrieve Case as a JSON String
Inputs:        
Test Class:    

History

------------------------------------------------------------*/
@RestResource(urlMapping='/v1/salesforce/retrievecase/*')
global class CaseCFSApiRetrieveCaseRestService {
   
   @HttpPost
   global static void doPost() {
       new processCaseJSON().execute();                        
   }
   
   //Class used to retrieve Case and generate Json
   public class processCaseJSON{
       private String caseGUID = '';
       private Set<String> fieldNames = new Set<String>();
       private String errorString = '';
       private String caseJSON = '';
       Set<String> allowedCasefields;
       Map<String,String> statusMap;
       
       public processCaseJSON() {
            this.allowedCasefields = new Set <String>();
            this.statusMap = new Map<String,String>();
            
            //Retrieve the list of fields that can be returned from a Custom Setting
            List<CFS_API_Settings__c> settings = [select Viewable_Case_Fields__c from CFS_API_Settings__c];
            if (settings!=null && settings.size()>0 && settings[0].Viewable_Case_Fields__c!=null){
           	    this.allowedCasefields.addAll(settings[0].Viewable_Case_Fields__c.split(','));
            }
            
            //We don't return the actual Status, we return a mapped Status which is read from a Custom Setting
            for(CaseStatusForMobileApp__c caseStatus :CaseStatusForMobileApp__c.getall().values()) {
                if(caseStatus.Responsible_Party__c=='NA') {
	        		this.statusMap.put(caseStatus.Name.toLowerCase(), caseStatus.Case_Status_on_Mobile_App__c);
	        	}
            }
        }
       
           
       /**********************************************************************************
       *  Execute logic to retrieve the Cases and generate JSON.
       ***********************************************************************************/ 
       public void execute(){
           RestResponse res =  RestContext.response;
           String receivedJson = '';
           String jsonStart = '{ "Cases" : [';
           String jsonReturn = jsonStart;
           
           try {

               if (RestContext.request.requestBody!=null && RestContext.request.requestBody.toString().length()>0){
                   receivedJson=RestContext.request.requestBody.toString();
                   caseJSONArray caseArray = (caseJSONArray)JSON.deserialize(receivedJson, caseJSONArray.class); 
                   
                   if (caseArray!=null && caseArray.cases!=null && caseArray.cases.size()<=100){
                       for (caseJSON cse : caseArray.cases){
                           if (validateFields(cse)==true){
                                cse = retrieveCase(cse);
                           }
                           if (jsonReturn!=jsonStart){
                               jsonReturn+=',';
                           }
                           jsonReturn = jsonReturn + cse.generateCaseJSON();
                       }
                       jsonReturn+=']}';
                   }
                   else{
                       list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
                       ApplicationLogMessage message= new ApplicationLogMessage();
                       message.source='CaseCFSApiRetrieveCaseRestService';
                       message.sourceFunction='execute';
                       if (caseArray==null || caseArray.cases==null){
                           message.logMessage='Invalid JSON.';
                       }
                       else{
                           message.logMessage='Maximum number of Cases allowed is 100.';
                       }
                       if (receivedJson.Length() < 131072){
                           message.referenceInfo = receivedJson;
                       }
                       else{
                           message.referenceInfo = receivedJson.substring(0,131072);
                       } 
                       message.debugLevel=GlobalConstants.ERROR;
                       messages.add(message);
                       ApplicationLogUtility.logMessage(messages);
                       messages.clear();    
                       res.responseBody = Blob.valueOf(message.logMessage);
                       jsonReturn = message.logMessage;
                       res.addHeader('Content-Type', 'text/plain');
                       res.statusCode = 400;
                       return;
                   }
               }
               res.responseBody = Blob.valueOf(jsonReturn);
               res.addHeader('Content-Type', 'application/json');
               res.statusCode = 200;
           }catch(Exception e){
                System.debug('CaseCFSApiRetrieveCaseRestService : Exception thrown');
                System.debug(e);
                
                list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
                ApplicationLogMessage message= new ApplicationLogMessage();
                message.source='CaseCFSApiRetrieveCaseRestService';
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
       }//method execute
       
       /****************************************************************
       * Execute SOQL query to retrieve Case and return serialized JSON
       *****************************************************************/
       private caseJSON retrieveCase(caseJSON cse){
           set<String> fieldsQueried = new set<String>();
           fieldsQueried.addAll(cse.CaseFields.split(','));
           
           String query='SELECT CaseNumber';
           for (String fieldName : fieldsQueried){
           	   if (fieldName.trim().equalsIgnoreCase('CaseNumber')==false && fieldName.trim().equalsIgnoreCase('GUID__c')==false){
                   query+=',';
                   query+=fieldName.trim();
           	   }
           }
           query+=' from Case WHERE GUID__c = \''+String.escapeSingleQuotes(cse.caseGUID.trim()) +'\'';
           
           system.debug('CaseCFSApiRetrieveCaseRestService.retrieveCase query : '+query);
           
           List<Case> caseList=Database.query(query);
           System.debug('CaseCFSApiRetrieveCaseRestService.retrieveCase caseList : '+caseList);
           if (caseList!=null && caseList.size()>0){
               Case c = caseList[0];
               cse.CaseNumber = c.CaseNumber;
               cse.jsonString = convertCaseToJSON(c); 
           }
           else{
               cse.errorMessage = 'Invalid GUID';
           }
           System.debug('CaseCFSApiRetrieveCaseRestService.retrieveCase cse : '+cse);
           return cse;
       }
       
       /*****************************************************************
       * Validate that the fields passed in exist and that the user has
       * access to them
       ******************************************************************/
       private Boolean validateFields(caseJSON cse){
           boolean isValid = true;
           String errorfields = '';
            
           Map<String, Schema.SObjectField> caseFieldMap = Schema.SObjectType.Case.fields.getMap();
           
           system.debug ('RetrieveCase validateFields caseFieldMap : '+caseFieldMap);
           
           if (cse.caseGUID==null || cse.caseGUID==''){
               cse.errorMessage = 'No GUID received';
               isValid = false;
           }
           else if (cse.CaseFields!=null && cse.CaseFields.length()>0){
               set<String> fieldsQueried = new set<String>();
               fieldsQueried.addAll(cse.CaseFields.split(','));
               for (String fieldName : fieldsQueried){
                   Schema.SObjectField field = caseFieldMap.get(fieldName.trim());
                   
                   system.debug ('RetrieveCase validateFields fieldName : '+fieldName);
                   system.debug ('RetrieveCase validateFields field : '+field);
                   
                   if (fieldName.trim().equalsIgnoreCase('CaseNumber')==false && fieldName.trim().equalsIgnoreCase('GUID__c')==false){
                       if (field==null || field.getDescribe().isAccessible()==false || 
                           (this.allowedCasefields.size()>0 && this.allowedCasefields.contains(fieldName.trim())==false))
                       {
                          errorfields = (errorfields=='' ? fieldName : errorfields+', '+fieldName);
                       }
                   }
               }
               if (errorfields!=''){
                   cse.errorMessage = 'The following field(s) do not exist or you do not have permission to view them : '+errorfields;
                   isValid = false;
               }
           }
           else{
               cse.errorMessage = 'No field names were entered for this GUID';
               isValid = false;
           }
           return isValid;
       }
       
       /**************************************************************************
       *  Generate JSON to be returned containing the Case field values requested.
       *  Case is serialized as JSON and then the details we need are parsed and
       *  converted to JSON in our response format.
       ***************************************************************************/
       private String convertCaseToJSON(Case c){
            String jsonStr = '';
            
            JSONParser parser = JSON.createParser(JSON.serialize(c, true));

            JSONToken currentToken = parser.nextToken();
            currentToken = parser.nextValue();
            while (currentToken!=null){
                if (parser.getCurrentName()=='attributes' || parser.getCurrentName()=='Id' || 
                    parser.getCurrentName()=='CaseNumber' || parser.getCurrentName()=='GUID__c')
                {
                    parser.skipChildren();
                }
                else if (parser.getCurrentName()=='Status'){
                	String caseStatus = parser.getText();
                	String mappedStatus = this.statusMap.get(caseStatus.toLowerCase());
                    caseStatus = (mappedStatus!=null ? mappedStatus : caseStatus);
                    jsonStr = jsonStr + '"Status" : "'+caseStatus+'"';
                }
                else if (currentToken!=JSONToken.END_OBJECT && currentToken!=JSONToken.START_OBJECT
                       && currentToken!=JSONToken.END_ARRAY && currentToken!=JSONToken.START_ARRAY){
                    if (jsonStr!='') {
                        jsonStr+=',';
                    }   
                    jsonStr = jsonStr + '"'+parser.getCurrentName()+'" : "'+parser.getText()+'"';
                }
                currentToken = parser.nextValue();
            }
            return jsonStr;
       }
   }
   
   /***************************************************************************
   * Class to contain array of classes containing JSON returned for each class
   ****************************************************************************/
   public class caseJSONArray
   {
       public List <caseJSON> cases;
   }

   /*****************************************************
   * This class manages the JSON returned for each Case
   *****************************************************/
   public class caseJSON
   {
       public String caseGUID;
       public String CaseNumber;
       public String CaseFields;
       public String jsonString = '';
       public String errorMessage;
       
       public String generateCaseJSON(){
           String finalJSON;
           if (this.errorMessage!=null){
                finalJSON = '{ "CaseGUID" : "'+caseGUID+'", "Error" : "'+this.errorMessage+'"}';
           }
           else {
               finalJSON = '{ "CaseGUID" : "'+caseGUID+'", "CaseNumber" : "'+CaseNumber+'", '+jsonString +'}';
           }
           return finalJSON;
       }
   }
    
}