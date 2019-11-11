/*------------------------------------------------------------
Author:        Ian F
Company:       TfNSW
Description:   Custom Rest API to retrieve Taxonomy as a JSON String
Inputs:        
Test Class:    

History

------------------------------------------------------------*/
@RestResource(urlMapping='/v1/salesforce/taxonomy/*')
global class CaseCFSApiTaxonomyRestService {
   
   @HttpPost
   global static void doPost() {
        new processTaxonomyJSON().execute(); 
   }
   
   //Class used to retrieve Taxonomy and generate Json
   public class processTaxonomyJSON{
       
       public String taxonomyJSON;
       private String strType;
       private String strMode;
       private String strLevel1;
       private String strLevel2;
       private String strLevel3;
       private String strAgency;
       
       /**********************************************************************************
       *  Execute logic to retrieve the Taxonomy and generate JSON.
       ***********************************************************************************/ 
       public String execute(){
           String result='Success';
           boolean valid = true;
           RestResponse res =  RestContext.response;
           
           try{
               String receivedJson=RestContext.request.requestBody.toString();
               if (receivedJson!=null && receivedJson.length()>0){
                   result = validateParameters(receivedJson);
                   if (result=='Success'){
                       parseRequest(receivedJson);
                   }
               }
               
               if (result=='Success'){
                   result = retrieveTaxonomy();
                   res.addHeader('Content-Type', 'application/json');
                   res.statusCode = 200;
               }
               else{
               	   res.addHeader('Content-Type', 'text/plain');
                   res.statusCode = 400;
               }
               res.responseBody = Blob.valueOf(result );
           }
           catch (Exception e){
               res.responseBody = Blob.valueOf(e.getMessage());
               result = e.getMessage();
               res.addHeader('Content-Type', 'text/plain');
               res.statusCode = 400;
           }
           
           return result;
       }//method execute
       
       /**********************************************************************************
       *  Run the query to retrieve the Taxonomy and generate JSON from the results.
       ***********************************************************************************/  
       private String retrieveTaxonomy(){
           String result = '';
           
           String queryString = 'select Id, Type__c, Agency__c, Customer_Value__c, Parent_Id__r.Customer_Value__c,'+
                                'Parent_Id__r.Parent_Id__r.Customer_Value__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c from  Taxonomy_Metadata__c '+
                                'where Parent_Id__r.Parent_Id__r.Parent_Id__r.Name != null and IsMinCorro__c = false '+
                                'and Status_Staff_Facing__c = \'Active\' and Status_Customer_Facing__c = \'Active\' ';

           if (this.strType!=null && this.strType.length()>0){
                 queryString=queryString+' and Type__c = \'' +this.strType +'\'';
           }
           if (this.strMode!=null && this.strMode.length()>0){
                 queryString=queryString+' and Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c = \'' +this.strMode +'\'';
           }
           if (this.strLevel1!=null && this.strLevel1.length()>0){
                 queryString=queryString+' and Parent_Id__r.Parent_Id__r.Customer_Value__c = \'' +this.strLevel1 +'\'';
           }
           if (this.strLevel2!=null && this.strLevel2.length()>0){
                 queryString=queryString+' and Parent_Id__r.Customer_Value__c = \'' +this.strLevel2 +'\'';
           }
           if (this.strLevel3!=null && this.strLevel3.length()>0){
                 queryString=queryString+' and Customer_Value__c = \'' +this.strLevel3 +'\'';
           }
           if (this.strAgency!=null && this.strAgency.length()>0){
                 queryString=queryString+' and Agency__c = \'' +this.strAgency +'\'';
           }
           
           system.debug('retrieveTaxonomy queryString : '+queryString);                
           List<Taxonomy_Metadata__c> taxonomyList = Database.query(queryString);
           
           system.debug('retrieveTaxonomy taxonomyList : '+taxonomyList);
           
           result = generateJSONTaxonomy(taxonomyList);
           system.debug('Taxonomy result : '+result);
           return result;        
       }//method retrieveTaxonomy
   
       /**********************************************************************************
       *  Parse the JSON received via the REST API to retrieve the Type and Agency parameters
       *  to be used in the query to retrieve the Taxonomy.
       *  These parameters are not required, if blank then all taxonomy will be retrieved.
       ***********************************************************************************/    
       private void parseRequest(String JSONContent){          
           JSONParser parser = JSON.createParser(JSONContent);

           JSONToken currentToken = parser.nextToken();
           while (currentToken!=null){
               if(parser.getText()!=null && parser.getText().trim().equalsIgnoreCase('Type')){
                   currentToken = parser.nextToken(); 
                   this.strType = String.escapeSingleQuotes(parser.getText().trim());
               }
               if(parser.getText()!=null && parser.getText().trim().equalsIgnoreCase('Mode')){
                   currentToken = parser.nextToken(); 
                   this.strMode = String.escapeSingleQuotes(parser.getText().trim());
               }
               if(parser.getText()!=null && parser.getText().trim().equalsIgnoreCase('Level1')){
                   currentToken = parser.nextToken(); 
                   this.strLevel1 = String.escapeSingleQuotes(parser.getText().trim());
               }
               if(parser.getText()!=null && parser.getText().trim().equalsIgnoreCase('Level2')){
                   currentToken = parser.nextToken(); 
                   this.strLevel2 = String.escapeSingleQuotes(parser.getText().trim());
               }
               if(parser.getText()!=null && parser.getText().trim().equalsIgnoreCase('Level3')){
                   currentToken = parser.nextToken(); 
                   this.strLevel3 = String.escapeSingleQuotes(parser.getText().trim());
               }
               currentToken = parser.nextToken();
           }
       }//method parseRequest
       
                              
   /*    private String generateJSONTaxonomy(List<Taxonomy_Metadata__c> taxonomyList) {
 
           String taxonomyJSON = '{ "TaxonomyList" : [';
           // Write data to the JSON string.
           for (Taxonomy_Metadata__c taxonomyItem : taxonomyList){
               taxonomyJSON+='{';
               taxonomyJSON+='"TaxonomyId" : "'+taxonomyItem.Id+'", ';
               taxonomyJSON+='"Type" : "'+taxonomyItem.Type__c+'", ';
               
               String currMode = taxonomyItem.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c;
               currMode = currMode!=null ? currMode : 'Not Defined';
               taxonomyJSON+='"Mode" : "'+currMode.escapeHtml4()+'", ';
               
               String currLevel1 = taxonomyItem.Parent_Id__r.Parent_Id__r.Customer_Value__c;
               currLevel1 = currLevel1!=null ? currLevel1 : 'Not Defined';
               taxonomyJSON+='"Level1" : "'+currLevel1.escapeHtml4()+'", ';
               
               String currLevel2 = taxonomyItem.Parent_Id__r.Customer_Value__c!=null ? taxonomyItem.Parent_Id__r.Customer_Value__c : 'Not Defined';
               taxonomyJSON+='"Level2" : "'+currLevel2.escapeHtml4()+'", ';
               
               String currLevel3 = taxonomyItem.Customer_Value__c!=null ? taxonomyItem.Customer_Value__c : 'Not Defined';
               taxonomyJSON+='"Level3" : "'+currLevel3.escapeHtml4()+'", ';
               
               String strAgency = taxonomyItem.Agency__c!=null ? taxonomyItem.Agency__c : '';
               taxonomyJSON+='"Agency" : "'+strAgency.escapeHtml4()+'"';
               taxonomyJSON+='},';
           }
           //remove last comma
           taxonomyJSON = taxonomyJSON.removeEnd(',');
           taxonomyJSON+=']}';
           
           // Return the JSON string.
           return taxonomyJSON;
       }//method generateJSONTaxonomy*/

       /**********************************************************************************
       *  Generate JSON from the Taxonomy to return via the REST API
       ***********************************************************************************/         
       private String generateJSONTaxonomy(List<Taxonomy_Metadata__c> taxonomyList) {
 
           JSONGenerator gen = JSON.createGenerator(true);
           // Write data to the JSON string.
           gen.writeStartObject();
           gen.writeFieldName('TaxonomyList');
           gen.writeStartArray();
           for (Taxonomy_Metadata__c taxonomyItem : taxonomyList){
               gen.writeStartObject();
               gen.writeIdField('TaxonomyId', taxonomyItem.Id);
               gen.writeStringField('Type', taxonomyItem.Type__c);
               String currMode = taxonomyItem.Parent_Id__r.Parent_Id__r.Parent_Id__r.Customer_Value__c;
               gen.writeStringField('Mode', currMode!=null ? currMode : 'Not Defined');
               String currLevel1 = taxonomyItem.Parent_Id__r.Parent_Id__r.Customer_Value__c;
               gen.writeStringField('Level1', currLevel1!=null ? currLevel1 : 'Not Defined');
               String currLevel2 = taxonomyItem.Parent_Id__r.Customer_Value__c;
               gen.writeStringField('Level2', currLevel2!=null ? currLevel2 : 'Not Defined');
               gen.writeObjectField('Level3', taxonomyItem.Customer_Value__c!=null ? taxonomyItem.Customer_Value__c : 'Not Defined');
               gen.writeStringField('Agency', taxonomyItem.Agency__c!=null ? taxonomyItem.Agency__c : '');
               gen.writeEndObject();
           }
           gen.writeEndArray();
           gen.writeEndObject();
           if(gen!=null){
               system.debug('gen.getAsString() : '+gen.getAsString());
           }
           // Return the JSON string.
           return gen.getAsString();
       }//method generateJSONTaxonomy
       
       private String validateParameters (String JSONContent){
            String result = 'Success';
            String invalidFields = '';
            Set<String> validFields =  new Set<String>{'TYPE', 'MODE', 'LEVEL1', 'LEVEL2', 'LEVEL3','AGENCY'};
            try {
                JSONParser parser = JSON.createParser(JSONContent);
                parser.nextToken();
                JSONToken currToken = parser.nextToken();
                while (currToken!=null && currToken!=JSONToken.END_OBJECT){
                    String currObj = parser.getText();
                    if ( validFields.contains(currObj.toUpperCase())==false){
                        invalidFields = (invalidFields=='' ? currObj : invalidFields+', '+currObj); 
                    }
                    parser.nextToken();
                    currToken = parser.nextToken();
                }
            }
            catch(Exception e){
                System.debug(e);
                list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
                ApplicationLogMessage message= new ApplicationLogMessage();
                message.source='CaseCFSApiTaxonomyRestService';
                message.sourceFunction='validateParameters';
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
            
            if (invalidFields!=''){
                result = 'The following parameters are invalid : '+invalidFields;
            }
                
            return result;
        }
   }//class processTaxonomyJSON
}//END CaseCFSApiTaxonomyRestService