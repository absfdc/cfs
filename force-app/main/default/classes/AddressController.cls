/**
 * Author :         Sauce Consulting
 * Description:     This class is responsible to handle all the operations related to address component
 * TestClass :      AddressControllerTest
 * History :
 * Date             Author                      Comments
   --------------------------------------------------------------------------------------
   04-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class AddressController {
    
    private static Address_Fields_Configuration__mdt configRecord = null;
    /**
    * @description : get list of all the Address_Fields_Configuration__mdt records 
    * system.debug(AddressController.getfieldConfig('Billing Address','undefined'));
    */
    @AuraEnabled(cacheable = true)
    public static Address_Fields_Configuration__mdt getfieldConfig(String recordName,String obejctName){
        String queryString ='SELECT Show_Validation_Flag__c,Display_Form_Save_Button__c,Use_Country_State_Picklist__c,Address_Validation_Flag_Field__c,Label,' 
            + 'Address_Label__c,Is_Default__c,Input_Style_Class__c,City_Field__c,City_Label__c,Country_Field__c,Country_Label__c,DeveloperName,Display_Save_Button__c,'
            + 'Field_Label_Style_Class__c,Id,Is_City_Required__c,Is_Postcode_Required__c,Is_State_Required__c,Is_Street_Required__c,' 
            + 'Placeholder_Text_City__c,Placeholder_Text_Country__c,Placeholder_Text_Postcode__c,Street_Field_To_Use__c,'
            + 'Placeholder_Text_State__c,Placeholder_Text_Street__c,Postcode_Field__c,Postcode_Label__c,QualifiedApiName,SObject_Type__c,' 
            + 'State_Code_Mapping__r.NSW__c,State_Code_Mapping__r.VIC__c,State_Code_Mapping__r.QLD__c,State_Code_Mapping__r.SA__c,State_Code_Mapping__r.WA__c,' 
            + 'State_Code_Mapping__r.TAS__c, State_Code_Mapping__r.ACT__c,State_Code_Mapping__r.NT__c,State_Code_Mapping__r.Other__c,' 
            + 'State_Code_Mapping__c,State_Field__c,State_Label__c,Street_Field__c,Street_Label__c, Predictive2_Output_Field_Config__r.Include_cadastralParcels__c, ' 
            + 'Predictive2_Output_Field_Config__r.Include_commElectoralName__c, Predictive2_Output_Field_Config__r.Include_commElectoralPid__c, ' 
            + 'Predictive2_Output_Field_Config__r.Include_deliveryPointIdentifier__c, Predictive2_Output_Field_Config__r.Include_lgaName__c, ' 
            + 'Predictive2_Output_Field_Config__r.Include_lgaPid__c, Predictive2_Output_Field_Config__r.Include_lgaShortName__c, ' 
            + 'Predictive2_Output_Field_Config__r.Include_mbId__c, Predictive2_Output_Field_Config__r.Include_sa1Id__c, Predictive2_Output_Field_Config__r.Include_sa2Id__c, ' 
            + 'Predictive2_Output_Field_Config__r.Include_sa3Id__c, Predictive2_Output_Field_Config__r.Include_sa4Id__c, Predictive2_Output_Field_Config__r.Include_stateElectoralClassCode__c, ' 
            + 'Predictive2_Output_Field_Config__r.Include_stateElectoralName__c, Predictive2_Output_Field_Config__r.Include_stateElectoralPid__c, ' 
            + 'Predictive2_Output_Field_Config__r.Include_stateElectoralType__c FROM Address_Fields_Configuration__mdt';
        String filterString = '';
        filterString = ' WHERE label = ' +'\'' + recordName +'\''; 
        queryString = queryString + filterString + ' LIMIT 1';
        system.debug('==queryString=' + queryString);
        configRecord = Database.query(queryString);
        return configRecord;
    }

    /**
    * @description : get existing address on the record  
    */
    @AuraEnabled(cacheable = true)
    public static existingAddressWrapper getExistingAddress(String recordName , String recordId){
        
        Address_Fields_Configuration__mdt configRecord = [SELECT City_Field__c,Show_Validation_Flag__c,Address_Validation_Flag_Field__c,Country_Field__c,Postcode_Field__c,SObject_Type__c,
                State_Field__c,Street_Field__c
        FROM Address_Fields_Configuration__mdt
        WHERE Label =: recordName];
        
        String queryString;
        if(configRecord.Street_Field__c != configRecord.City_Field__c){
            queryString = 'SELECT Id,' + configRecord.Street_Field__c + ','
                                          + configRecord.City_Field__c + ','
                                          + configRecord.Postcode_Field__c + ','
                                          + configRecord.State_Field__c + ','
                                          + configRecord.Country_Field__c + 
                            ' FROM ' + configRecord.SObject_Type__c + 
                            ' WHERE Id = ' + '\''+ recordId +'\''; 
            List<SObject> records = database.query(queryString);
            if(records.isEmpty()){
                return new existingAddressWrapper('', '','','','');    
            }
            return new existingAddressWrapper(String.valueOf(records[0].get(configRecord.Street_Field__c)),
                                            String.valueOf(records[0].get(configRecord.City_Field__c)),
                                            String.valueOf(records[0].get(configRecord.Postcode_Field__c)),
                                            String.valueOf(records[0].get(configRecord.State_Field__c)),
                                            String.valueOf(records[0].get(configRecord.Country_Field__c)));
        } else{
            queryString = 'SELECT Id,' + configRecord.Street_Field__c + 
                            ' FROM ' + configRecord.SObject_Type__c + 
                            ' WHERE Id = ' + '\''+ recordId +'\''; 
            System.debug(LoggingLevel.INFO, 'queryString : ' + queryString);
            List<SObject> records = database.query(queryString);
            if(records.isEmpty()){
                return new existingAddressWrapper('', '','','','');    
            }
            return new existingAddressWrapper(String.valueOf(records[0].get(configRecord.Street_Field__c)),'','','','');                    
        }
    }

    /**
    * @description : handle save operation 
    */
    @AuraEnabled
    public static void saveRecord(String recordId, Address_Fields_Configuration__mdt configRecord,
                                    String  selectedStreet, String selectedCity, String selectedPostcode,
                                    String selectedState, String selectedCountry, Boolean isValidAddress){
        try{
            sObject sObj = Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).newSObject() ;
            sObj.id = recordId;

            if(configRecord.Street_Field__c != configRecord.City_Field__c){
                sObj.put(configRecord.Street_Field__c,  selectedStreet == 'null' ? '' :selectedStreet);
                sObj.put(configRecord.City_Field__c, (selectedCity == 'null' ? '' : selectedCity));
                sObj.put(configRecord.Postcode_Field__c, (selectedPostcode == 'null' ? '' : selectedPostcode)); 
                sObj.put(configRecord.State_Field__c, selectedState == configRecord.State_Code_Mapping__r.Other__c ? '' : selectedState);
                sObj.put(configRecord.Country_Field__c, selectedCountry == 'null' ? '' : selectedCountry);
                if(!String.isBlank(configRecord.Address_Validation_Flag_Field__c)){
                    sObj.put(configRecord.Address_Validation_Flag_Field__c, isValidAddress);
                }
            }else{   
                String streetAddress =  (selectedStreet == null ? '' :selectedStreet + ', ')  + 
                                        (selectedCity == null ? '' : selectedCity) + ' ' + 
                                        ((selectedState == configRecord.State_Code_Mapping__r.Other__c || selectedState == null) ? '' : selectedState) + ' ' + 
                                        (selectedPostcode == null ? '' : selectedPostcode);
                System.debug(LoggingLevel.INFO, 'streetAddress result: ' + streetAddress);
                streetAddress = streetAddress.trim();
                if(streetAddress != null && streetAddress.endsWith(',')){
                    streetAddress = streetAddress.substring(0, streetAddress.length() - 1);
                } 
                sObj.put(configRecord.Street_Field__c , streetAddress);
                if(!String.isBlank(configRecord.Address_Validation_Flag_Field__c)){
                    sObj.put(configRecord.Address_Validation_Flag_Field__c, isValidAddress);
                }
            }
            visiblityWrapper visibilityCheck = checkFieldVisiblity(configRecord.label);
            System.debug(LoggingLevel.INFO, 'Visibility check result: ' + visibilityCheck.isReadOnly);
            if(!visibilityCheck.isReadOnly) update sObj;    
        } catch(exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @AuraEnabled(cacheable=true)
    public static visiblityWrapper checkFieldVisiblity(String recordName){
        configRecord = [Select SObject_Type__c,Street_Field__c FROM Address_Fields_Configuration__mdt WHERE label = : recordName ];
        
        if(configRecord != null ){
            //checking only for one address field accessibility with assumption that if one address field is accessible 
            //then rest other address fields should also be accessible
            try{ 
                return new visiblityWrapper(
                    Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).getDescribe().fields.getMap().get(configRecord.Street_Field__c).getDescribe().isUpdateable()
                    || Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).getDescribe().fields.getMap().get(configRecord.Street_Field__c).getDescribe().isCreateable(),
                    Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).getDescribe().fields.getMap().get(configRecord.Street_Field__c).getDescribe().isAccessible()
                );                
            }catch (exception e){
                system.debug('Exception : === ' + e);
                return  new visiblityWrapper(false,false);        
            }  
        }
        return  new visiblityWrapper(false,false);
    }

    /**
    * @description : This is wrapper class for state picklist 
    */
     public class stateWrapper{
        @AuraEnabled
        public string label {get;set;}
        @AuraEnabled
        public string value {get;set;}
        public stateWrapper(string label,string value){
            this.label = label;
            this.value = value;
        }
     }

     /**
    * @description : This is wrapper class for field visiblity 
    */
     public class visiblityWrapper{
        @AuraEnabled
        public Boolean isVisible {get;set;}
        @AuraEnabled
        public Boolean isReadOnly {get;set;}
        
        public visiblityWrapper(Boolean isEditable,Boolean isVisible){
            this.isVisible = isVisible;
            this.isReadOnly = !isEditable;
        }
     }

     /**
    * @description : This is wrapper class for state picklist 
    */
     public class existingAddressWrapper{
        @AuraEnabled
        public string street {get;set;}
        @AuraEnabled
        public string city {get;set;}
        @AuraEnabled
        public string postcode {get;set;}
        @AuraEnabled
        public string state {get;set;}
        @AuraEnabled
        public string country {get;set;}

        public existingAddressWrapper(string street,string city,string postcode,string state,string country){
            this.street = street == null? '': street;
            this.city = city == null? '': city;
            this.postcode = postcode == null ? '' : postcode;
            this.state = state == null ? '' : state;
            this.country = country == null ? '' : country;
        }
     }

}