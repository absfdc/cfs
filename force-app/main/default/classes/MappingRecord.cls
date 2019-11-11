/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus.com
Description:   Mapping record data from 'BU Staging Field Mapping Metadata'
                This class is used to have the information about the contact and case 
                mapping field api name with the staging objecy api name.
                Reterive 'Customer' record type for the contact object
                Reterive record type for 'Bus' and 'Light Rail' cases

History
15/06/2017       Yogiraj Sarode        Created   
------------------------------------------------------------*/
// used to get the mapping records and record types
public with sharing class MappingRecord {
	
	public static String contactFieldNames = null;

	public static String caseFieldNames = null;

	public static String stagingApiName = null;

	// staging field vs column header  
	public static Map<String,String> stgingFieldVsColumnHeader = new Map<String,String>();

	public static Map<String,String> stagingObjectToCaseMapping = new Map<String,String>();

	// store field name vs picklist values for staging object
	public static Map<String,Set<String>> stagingPicklistFieldNamevsValue = new Map<String,Set<String>>();
	public static Set<String> picklistFieldApiName = new Set<String>();
	public static Map<String,String> stagingApiNameVsCaseForMandatory = new Map<String,String>();
	public static Map<String,String> stagingApiNameVsContactForMandatory = new Map<String,String>();

	// staging object field api name with contact object field api name map
	public static Map<String,String> stagingObjectToContactMapping = new Map<String,String>();
	
    public static Map<String,Id> modeVsRecordTypeId = new Map<String,Id>();
    
    // Customer record type for the new contact
	public static final RecordType CUSTOMER = [SELECT ID FROM RecordType 
												WHERE sObjectType = 'Contact' 
												AND DeveloperName = :GlobalConstants.CUSTOMER_CONTACT_RECTYPE_NAME];
    
    public static void setRecordTypeMap() {
        for(RecordType rt : [SELECT ID, DeveloperName FROM RecordType 
                             WHERE sObjectType = 'Case' 
                             AND (DeveloperName = :GlobalConstants.PRIVATE_OPERATOR_RECORD_TYPE OR DeveloperName = :GlobalConstants.LIGHT_RAIL_RECORD_TYPE)]){
                                 if(rt.DeveloperName == GlobalConstants.PRIVATE_OPERATOR_RECORD_TYPE){
                                     modeVsRecordTypeId.put('Bus', rt.Id);    
                                 }
                                 if(rt.DeveloperName == GlobalConstants.LIGHT_RAIL_RECORD_TYPE){
                                     modeVsRecordTypeId.put('Light Rail', rt.Id);    
                                 }
        }
    }
	
	// return the staging mapping records from metadata 
    public static void getMappingMetadataList(){

    	Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjSchema = schemaMap.get('BU_Staging__c');
        Map<String, Schema.SObjectField> fieldMap = sObjSchema.getDescribe().fields.getMap();
        Schema.DescribeSObjectResult objResult = sObjSchema.getDescribe();
        Set<String> pickValuesSet = new Set<String>();

        stagingApiName = null;
        contactFieldNames = null;
        caseFieldNames = null;

    	List<BU_Staging_Field_Mapping_Metadata__mdt> mappingMetaDataList = [SELECT Column_Header__c,Is_Staging_Field_Mandatory__c,	
																		Staging_Field_API_Name__c,Object_Name__c,Sobject_Field_API_Name__c
                               											FROM BU_Staging_Field_Mapping_Metadata__mdt ];
		if(mappingMetaDataList.size() > 0){

			for(BU_Staging_Field_Mapping_Metadata__mdt mappingMetaDataRec : mappingMetaDataList){
                // staging api name vs csv column header
				if(stagingApiName == null){
	                if(mappingMetadataRec.Staging_Field_API_Name__c != null)
	                    stagingApiName = mappingMetadataRec.Staging_Field_API_Name__c;
	            }else{
	                if(mappingMetadataRec.Staging_Field_API_Name__c != null)
	                    stagingApiName = stagingApiName+', '+mappingMetadataRec.Staging_Field_API_Name__c;
	            }

				stgingFieldVsColumnHeader.put(mappingMetaDataRec.Staging_Field_API_Name__c, mappingMetaDataRec.Column_Header__c);
                
            	System.debug('Staging_Field_API_Name__c :: ' + mappingMetaDataRec.Staging_Field_API_Name__c);
            	Schema.DisplayType fielddataType = fieldMap.get(mappingMetaDataRec.Staging_Field_API_Name__c).getDescribe().getType();
            	System.debug('fielddataType :: ' + fielddataType);
            	if(fielddataType == Schema.DisplayType.Picklist && mappingMetaDataRec.Staging_Field_API_Name__c != 'Country__c'){
            		picklistFieldApiName.add(mappingMetaDataRec.Staging_Field_API_Name__c);
            		Schema.DescribeFieldResult fieldResult = objResult.fields.getMap().get(mappingMetaDataRec.Staging_Field_API_Name__c).getDescribe();
                    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                    for(Schema.PicklistEntry s:ple){
                    	
                    	if(!stagingPicklistFieldNamevsValue.containsKey(mappingMetaDataRec.Staging_Field_API_Name__c))
                    		stagingPicklistFieldNamevsValue.put(mappingMetaDataRec.Staging_Field_API_Name__c,new Set<String>{s.getValue()});
                		else if(stagingPicklistFieldNamevsValue.containsKey(mappingMetaDataRec.Staging_Field_API_Name__c))
                			stagingPicklistFieldNamevsValue.get(mappingMetaDataRec.Staging_Field_API_Name__c).add(s.getValue());
                        
                    } 
                    
            	}

                // Field name list and staging object api vs case object field api name
                if(mappingMetaDataRec.Object_Name__c == 'Contact'){

                	// staging api vs column header map for mandatory fields
					if(mappingMetaDataRec.Is_Staging_Field_Mandatory__c == TRUE)
						stagingApiNameVsContactForMandatory.put(mappingMetaDataRec.Staging_Field_API_Name__c, mappingMetaDataRec.Column_Header__c);

                	if(contactFieldNames == null){
		                if(mappingMetadataRec.Sobject_Field_API_Name__c != null)
		                    contactFieldNames = mappingMetadataRec.Sobject_Field_API_Name__c;
		            }else{
		                if(mappingMetadataRec.Sobject_Field_API_Name__c != null)
		                    contactFieldNames = contactFieldNames+', '+mappingMetadataRec.Sobject_Field_API_Name__c;
		            }
                	stagingObjectToContactMapping.put(mappingMetadataRec.Staging_Field_API_Name__c, mappingMetadataRec.Sobject_Field_API_Name__c);
            	}	
            	
            	// Field name list and staging object api vs contact object field api name
                if(mappingMetaDataRec.Object_Name__c == 'Case'){
                	System.debug('In Case ==> Mandatory :: ' + mappingMetaDataRec.Is_Staging_Field_Mandatory__c );
                	// staging api vs column header map for mandatory fields
					if(mappingMetaDataRec.Is_Staging_Field_Mandatory__c == TRUE)
						stagingApiNameVsCaseForMandatory.put(mappingMetaDataRec.Staging_Field_API_Name__c, mappingMetaDataRec.Column_Header__c);

            		if(caseFieldNames == null){
		            	if(mappingMetadataRec.Sobject_Field_API_Name__c != null)
		            		caseFieldNames = mappingMetadataRec.Sobject_Field_API_Name__c;
		            }else{
		            	if(mappingMetadataRec.Sobject_Field_API_Name__c != null)
		            		caseFieldNames = caseFieldNames+', '+mappingMetadataRec.Sobject_Field_API_Name__c;
		            }	
                	stagingObjectToCaseMapping.put(mappingMetadataRec.Staging_Field_API_Name__c, mappingMetadataRec.Sobject_Field_API_Name__c);
        		}
        	} 

        	System.debug('Picklist values map :: ' + stagingPicklistFieldNamevsValue );
    	}

    }
	
}