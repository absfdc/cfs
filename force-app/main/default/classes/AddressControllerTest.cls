/**
 * Author :         Sauce Consulting
 * Description:     This is test class responsible to test AddressController 
 * TestClass :      AddressControllerTest
 * History :
 * Date             Author                      Comments
   --------------------------------------------------------------------------------------
   19-11-2019       Sauce Consulting            Initial Release
 */
@isTest
public with sharing class AddressControllerTest {
    
    @isTest
    private static void test_getfieldConfig(){
         Address_Fields_Configuration__mdt configRecord = [Select label,SObject_Type__c,Show_Validation_Flag__c,Address_Validation_Flag_Field__c,City_Field__c,Country_Field__c,Postcode_Field__c,
                                                          State_Field__c,Street_Field__c
                                                          FROM Address_Fields_Configuration__mdt LIMIT 1];
        test.startTest();
            Address_Fields_Configuration__mdt record = AddressController.getfieldConfig(configRecord.label,configRecord.SObject_Type__c);
            System.assertEquals(configRecord.label , record.label, 'getfieldConfig method is not returning correct config record');
        test.stopTest();
    }

    @isTest
    private static void test_getExistingAddress(){

        Address_Fields_Configuration__mdt configRecord = [Select label,SObject_Type__c,Show_Validation_Flag__c,Address_Validation_Flag_Field__c,City_Field__c,Country_Field__c,Postcode_Field__c,
                                                          State_Field__c,Street_Field__c
                                                          FROM Address_Fields_Configuration__mdt
                                                          WHERE SObject_Type__c = 'Contact' LIMIT 1];
        sObject sObj = Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).newSObject() ;
        sObj.put(configRecord.Street_Field__c, '411 Pitt Street');
        sObj.put(configRecord.City_Field__c, 'Sydney');
        sObj.put(configRecord.Postcode_Field__c, '2000'); 
        sObj.put(configRecord.Country_Field__c, 'Australia');
        sObj.put('LastName', 'Test Contact');
        insert sObj;

        test.startTest(); 
            String fields =  configRecord.Street_Field__c + ',' + configRecord.City_Field__c + ',' + configRecord.Postcode_Field__c + ',' + configRecord.State_Field__c + ',' + configRecord.Country_Field__c;
            sObject record = database.query('Select ' + fields + ' FROM ' + configRecord.SObject_Type__c);
            AddressController.existingAddressWrapper wrapper = AddressController.getExistingAddress(configRecord.label , record.id);
            system.assertEquals(wrapper.street , record.get(configRecord.Street_Field__c), 'Street value is not featching correctly');
            system.assertEquals(wrapper.city , record.get(configRecord.City_Field__c), 'City value is not featching correctly');
            system.assertEquals(wrapper.postCode , record.get(configRecord.Postcode_Field__c), 'Postcode value is not featching correctly');
            system.assertEquals(wrapper.country , record.get(configRecord.Country_Field__c), 'Country value is not featching correctly');
        test.stopTest();
    } 

    @isTest
    private static void test_getExistingAddressForSingleField(){

        Address_Fields_Configuration__mdt configRecord = [Select label,SObject_Type__c,Show_Validation_Flag__c,Address_Validation_Flag_Field__c,City_Field__c,Country_Field__c,Postcode_Field__c,
                                                          State_Field__c,Street_Field__c
                                                          FROM Address_Fields_Configuration__mdt
                                                          WHERE SObject_Type__c = 'Contact' 
                                                          LIMIT 1];
        sObject sObj = Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).newSObject() ;
        sObj.put(configRecord.Street_Field__c, '241 George Street, Sydney New South Wales 2000');
        sObj.put('LastName', 'Test Contact'); 
        insert sObj;

        test.startTest(); 
            String fields =  configRecord.Street_Field__c ;
            sObject record = database.query('Select ' + fields + ' FROM ' + configRecord.SObject_Type__c);
            configRecord.City_Field__c = configRecord.Street_Field__c;
            AddressController.existingAddressWrapper wrapper = AddressController.getExistingAddress(configRecord.label , record.id);
            system.assertEquals(wrapper.street , record.get(configRecord.Street_Field__c), 'Street value is not featching correctly');
            system.assertEquals(wrapper.city , '', 'City value is not featching correctly');
            system.assertEquals(wrapper.postCode ,'', 'Postcode value is not featching correctly');
        test.stopTest();
    } 


    @isTest
    private static void test_saveRecord(){
         Address_Fields_Configuration__mdt configRecord = [Select label,SObject_Type__c,Show_Validation_Flag__c,Address_Validation_Flag_Field__c,City_Field__c,Country_Field__c,Postcode_Field__c,
                                                          State_Field__c,Street_Field__c,State_Code_Mapping__r.NSW__c,State_Code_Mapping__r.VIC__c,
                                                          State_Code_Mapping__r.QLD__c,State_Code_Mapping__r.SA__c,State_Code_Mapping__r.WA__c,
                                                          State_Code_Mapping__r.TAS__c, State_Code_Mapping__r.ACT__c,State_Code_Mapping__r.NT__c,
                                                          State_Code_Mapping__r.Other__c, State_Code_Mapping__c
                                                          FROM Address_Fields_Configuration__mdt
                                                          WHERE SObject_Type__c = 'Contact'
                                                          LIMIT 1];
        sObject sObj = Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).newSObject() ;
        sObj.put(configRecord.Street_Field__c, '411 Pitt Street');
        sObj.put(configRecord.City_Field__c, 'Sydney');
        sObj.put(configRecord.Postcode_Field__c, '2000'); 
        sObj.put(configRecord.Country_Field__c, 'Australia');
        sObj.put('LastName', 'Test Contact');
        insert sObj;
  
        test.startTest(); 
            String fields =  configRecord.Street_Field__c + ',' + configRecord.City_Field__c + ',' + configRecord.Postcode_Field__c + ',' + configRecord.State_Field__c + ',' + configRecord.Country_Field__c;
            //save record with new assress
            AddressController.saveRecord(sObj.id, configRecord , '241 George Street','Sydney', '2000', 'New South Wales','Australia',null);
            //fetch updated record
            sObject record = database.query('Select ' + fields + ' FROM ' + configRecord.SObject_Type__c + ' WHERE Id = \'' + sObj.id + '\'');
            //assert 
            system.assertEquals('Sydney' , record.get(configRecord.City_Field__c), 'City value is not updating correctly');
            system.assertEquals('2000' , record.get(configRecord.Postcode_Field__c), 'Postcode value is not updating correctly');
            system.assertEquals('New South Wales' , record.get(configRecord.State_Field__c), 'State value is not updating correctly');
            system.assertEquals('Australia' , record.get(configRecord.Country_Field__c), 'Country value is not updating correctly');

            
        test.stopTest();
    }

    // Test Address store in single field
    @isTest
    private static void test_saveRecordSingleField(){
         Address_Fields_Configuration__mdt configRecord = [Select label,SObject_Type__c,Show_Validation_Flag__c,Address_Validation_Flag_Field__c,City_Field__c,Country_Field__c,Postcode_Field__c,
                                                          State_Field__c,Street_Field__c,State_Code_Mapping__r.NSW__c,State_Code_Mapping__r.VIC__c,
                                                          State_Code_Mapping__r.QLD__c,State_Code_Mapping__r.SA__c,State_Code_Mapping__r.WA__c,
                                                          State_Code_Mapping__r.TAS__c, State_Code_Mapping__r.ACT__c,State_Code_Mapping__r.NT__c,
                                                          State_Code_Mapping__r.Other__c, State_Code_Mapping__c
                                                          FROM Address_Fields_Configuration__mdt
                                                          WHERE SObject_Type__c = 'Contact'
                                                          LIMIT 1];
        
        sObject sObj = Schema.getGlobalDescribe().get(configRecord.SObject_Type__c).newSObject() ;
        sObj.put(configRecord.Street_Field__c, '411 Pitt Street');
        sObj.put(configRecord.City_Field__c, 'Sydney');
        sObj.put(configRecord.Postcode_Field__c, '2000'); 
        sObj.put(configRecord.Country_Field__c, 'Australia');
        sObj.put('LastName', 'Test Contact');
        insert sObj;
        
        test.startTest(); 
            String fields =  configRecord.Street_Field__c + ',' + configRecord.City_Field__c + ',' + configRecord.Postcode_Field__c + ',' + configRecord.State_Field__c + ',' + configRecord.Country_Field__c;
            //save record with new assress
             configRecord.City_Field__c = configRecord.Street_Field__c;
            AddressController.saveRecord(sObj.id, configRecord , '241 George Street','Sydney', '2000', 'New South Wales','Australia',null);
            //fetch updated record
            sObject record = database.query('Select ' + fields + ' FROM ' + configRecord.SObject_Type__c + ' WHERE Id = \'' + sObj.id + '\'');
            //assert 
            System.debug (LoggingLevel.INFO,'record.Street_Field__c :' +  String.valueOf(record.get(configRecord.Street_Field__c)));
            system.assertEquals('241 George Street, Sydney New South Wales 2000' , record.get(configRecord.Street_Field__c), 'Address value is not updating correctly in single field');

            //Check if end "," is removed from street field 
            AddressController.saveRecord(sObj.id, configRecord , '241 George Street, Sydney New South Wales 2000',null, null, null,null,null);
            sObject record1 = database.query('Select ' + fields + ' FROM ' + configRecord.SObject_Type__c + ' WHERE Id = \'' + sObj.id + '\'');
            //assert 
            system.assertEquals('241 George Street, Sydney New South Wales 2000' , record1.get(configRecord.Street_Field__c), 'Street value is not updating correctly');
           
        test.stopTest();
    }
}