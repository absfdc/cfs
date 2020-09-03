/**
 * @Author: Sauce Consulting
 * @Description: controller class for address component
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   20-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class FindAddressController {
	
	@AuraEnabled
	public static List<Predictive1ServiceResponse> searchAddress(String searchKey){
		return NSWPointAddressHelper.searchAddress(searchKey);		
	}
	
	@AuraEnabled
	public static Predictive2ServiceResponse getAddressComponent(String addressId, Address_Fields_Configuration__mdt configRecord){
		return NSWPointAddressHelper.getAddressComponent(addressId, getOutputFields(configRecord));
	}

	private static String getOutputFields(Address_Fields_Configuration__mdt configRecord){
		List<String> outputFields = new List<String>();
		if(configRecord.Predictive2_Output_Field_Config__r == null)
			return JSON.serialize(outputFields);

		if(configRecord.Predictive2_Output_Field_Config__r.Include_cadastralParcels__c)
			outputFields.add('cadastralParcels');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_commElectoralName__c)
			outputFields.add('commElectoralName');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_commElectoralPid__c)
			outputFields.add('commElectoralPid');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_deliveryPointIdentifier__c)
			outputFields.add('deliveryPointIdentifier');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_lgaName__c)
			outputFields.add('lgaName');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_lgaPid__c)
			outputFields.add('lgaPid');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_lgaShortName__c)
			outputFields.add('lgaShortName');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_mbId__c)
			outputFields.add('mbId');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_sa1Id__c)
			outputFields.add('sa1Id');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_sa2Id__c)
			outputFields.add('sa2Id');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_sa3Id__c)
			outputFields.add('sa3Id');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_sa4Id__c)
			outputFields.add('sa4Id');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_stateElectoralClassCode__c)
			outputFields.add('stateElectoralClassCode');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_stateElectoralName__c)
			outputFields.add('stateElectoralName');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_stateElectoralPid__c)
			outputFields.add('stateElectoralPid');
		if(configRecord.Predictive2_Output_Field_Config__r.Include_stateElectoralType__c)
			outputFields.add('stateElectoralType');

		return JSON.serialize(outputFields);
	}
	
	@AuraEnabled
	public static Boolean isValidAddress(String address){ 
		return NSWPointAddressHelper.validateAddress(address).isValid();
	}
}