/**
 * @Author         : Sauce Consulting
 * @Description    : controller for AddressPage
 * @testClass      : AddressPageControllerTest
 * History         :
 * Date            Author                      Comments
   --------------------------------------------------------------------
   20-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class AddressPageController {

    public string sObjectName {get;set;}
    public string selectedName {get;set;}

    public AddressPageController(ApexPages.StandardController stdController) {
        sObjectName = Id.valueOf(stdController.getId()).getSObjectType().getDescribe().getName();
        getAddressNames();
    }

    public List<selectoption> getAddressNames(){
        List<selectoption> addressNames = new List<selectoption>();
        List<Address_Fields_Configuration__mdt> configRecordList =[SELECT Label,MasterLabel,SObject_Type__c,is_Default__c  
                                                                FROM Address_Fields_Configuration__mdt 
                                                                WHERE SObject_Type__c =: sObjectName] ;
        for(Address_Fields_Configuration__mdt configRecord :  configRecordList){
            if(selectedName == null && configRecord.is_Default__c){
                selectedName = configRecord.label;
            }
            addressNames.add(new selectoption(configRecord.Label,configRecord.Label));
        }
        if(String.isEmpty(selectedName) && !configRecordList.isEmpty()){
            selectedName = configRecordList[0].label;
        }
        return addressNames;
    } 
}