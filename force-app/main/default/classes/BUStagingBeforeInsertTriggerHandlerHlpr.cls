/*------------------------------------------------------------
Author:        Yogiraj Sarode
Company:       Arxxus.com
Description:   BU Staging before insert handler helper
               This class is responsible for all the validations need to be performed 
               on the staging data before start processing for create Case and Contact object.
               MappingRecord class is used/refernced to get all data for validation.

History
12/06/2017       Yogiraj Sarode        Created   
------------------------------------------------------------*/
public with sharing class BUStagingBeforeInsertTriggerHandlerHlpr {
    
    //store staging picklist field name with the picklist values
    public static Map<String,Set<String>> stagingPicklistFieldNamevsValue = new Map<String,Set<String>>();
    //store column staging field api name vs csv file columnheader
    public static Map<String,String> stgingFieldVsColumnHeader = new Map<String,String>();
    Set<String> uniqueExternalCaseNumber = new Set<String>();
    /* store staging api name vs madatory fields
    *(Is Staging Field Mandatory in 'BU Staging Field Mapping Metadata') for Case object
    */
    public static Map<String,String> stagingApiNameVsCaseForMandatory = new Map<String,String>();
    /* store staging api name vs madatory fields
    *(Is Staging Field Mandatory in 'BU Staging Field Mapping Metadata') for Contact object
    */
    public static Map<String,String> stagingApiNameVsContactForMandatory = new Map<String,String>();
    //store staging apiname vs case apiname (used to map data from staging object to case object for insert/update record)
    public static Map<String,String> stagingObjectToCaseMapping = new Map<String,String>();
    //store staging apiname vs contact apiname (used to map data from staging object to contact object for insert/update record)
    public static Map<String,String> stagingObjectToContactMapping = new Map<String,String>();
     
    Set<String> cntIds = new Set<String>();
    Set<String> caseIds = new Set<String>();
    Set<String> taxonomyIds = new Set<String>();
    Set<String> mandatoryFields;
    Set<String> notMandatoryFields = new Set<String>{'Case_Manager__c','Re_assignment_Reason__c','Resolution_Detail__c'};

    //Helper constructor to reterive metadata mapping data from the MappingRecord.cls
    public BUStagingBeforeInsertTriggerHandlerHlpr(){
        System.debug('Staging class Helper');
        
        MappingRecord.getMappingMetadataList();
        stagingPicklistFieldNamevsValue = MappingRecord.stagingPicklistFieldNamevsValue;
        stgingFieldVsColumnHeader = MappingRecord.stgingFieldVsColumnHeader;
        stagingApiNameVsCaseForMandatory = MappingRecord.stagingApiNameVsCaseForMandatory;
        stagingApiNameVsContactForMandatory = MappingRecord.stagingApiNameVsContactForMandatory;
        stagingObjectToCaseMapping = MappingRecord.stagingObjectToCaseMapping;
        stagingObjectToContactMapping = MappingRecord.stagingObjectToContactMapping;

    }
    
     /*This method is used to process the staging record for below mentioned validation
    * 1. Case Id is valid or not (Only if Case Id is populated=>18 characters salesforce id)
    * 2. Contact Id is valid or not (Only if Contact Id is populated=>18 characters salesforce id)
    * 3. Taxonomy Id is valid or not (Only if Taxonomy Id is populated=>18 characters salesforce id)
    * 4. For new case: External case number uniqueness('External Case Number' column in csv file)
    * 5. For new case: Mandatory fields as specificed in 'BU Staging Field Mapping Metadata' with 
         'Is Staging Field Mandatory' checkbox checked(only if any of the case field is populated).
    * 6. For new/existing case/contact: check if picklist value exists or not
    * 7. For new contact: check if LastName and Email or any of phone fields are 
         populated (only if any of contact fields are populated).
    * 8. For new contact: Validate the date time field.
    */
    public void processStagingRecords(List<BU_Staging__c> stagingRecList){
        System.debug('Staging Record List :: ' + stagingRecList.size());
        Set<String> caseIdsInFile = new Set<String>();
        Set<String> contactIdsInFile = new Set<String>();
        Set<String> taxonomyIdsInFile = new Set<String>();
        Map<String,BU_Staging__c> stagingTrimmedRecordMap = new Map<String,BU_Staging__c>();

        Set<String> objectFields = Schema.SObjectType.BU_Staging__c.fields.getMap().keySet();
        // Iterate over the staging records to get Case Ids, Contact Ids and taxonomy Ids
        for(BU_Staging__c stagingRec : stagingRecList){
			stagingRec.Created_Date__c = System.today();            
            system.debug('Staging record :: ' + stagingRec);
            if(stagingRec.Case_Id__c != NULL) {
                caseIdsInFile.add(stagingRec.Case_Id__c);
            }
            if(stagingRec.Contact_Id__c != NULL) {
                contactIdsInFile.add(stagingRec.Contact_Id__c);
            }
            if(!String.isEmpty(stagingRec.Location_Level_3_Id__c)){
                taxonomyIdsInFile.add(stagingRec.Location_Level_3_Id__c);
            }
        }
        // create set of contact ids for valid contact ids otained from staging record
        for(Contact cnt : [SELECT ID FROM Contact WHERE Id IN : contactIdsInFile]){
            cntIds.add(cnt.Id);
        }        
        // create set of case ids for valid case ids otained from staging record
        for(Case cs : [SELECT ID FROM Case WHERE Id IN : caseIdsInFile]){
            caseIds.add(cs.Id);
        }

        // create set of taxonomy Ids for valid taxonomy ids obtained form the staging record.
        for(Taxonomy_Metadata__c taxonomyRec : [SELECT ID FROM Taxonomy_Metadata__c WHERE ID IN : taxonomyIdsInFile ]){
            taxonomyIds.add(taxonomyRec.Id);
        }

        System.debug('Get CPU Timeout processStagingRecords 1: '+Limits.getCpuTime() + '-'+ Limits.getLimitCpuTime() ); 
        
        // iterate over staging records for data validation
        for(BU_Staging__c stagingRec : stagingRecList){
            Integer count = 0;
            String mandatoryFiledError = '';
            mandatoryFields = new Set<String>();
            System.debug('Get CPU Timeout processStagingRecords ##: '+Limits.getCpuTime() + '-'+ Limits.getLimitCpuTime() ); 
            // Logic to check the external case number uniqueness
            if(!String.isBlank(stagingRec.Case_Number_Operator__c)){
                System.debug('Case_number_Operator__c :: ' + stagingRec.Case_number_Operator__c );
                if(!uniqueExternalCaseNumber.contains(stagingRec.Case_Number_Operator__c)){
                    System.debug('uniqueExternalCaseNumber not :: ' + uniqueExternalCaseNumber );
                    uniqueExternalCaseNumber.add(stagingRec.Case_Number_Operator__c);  
                }else{
                    System.debug('uniqueExternalCaseNumber out  :: ' + uniqueExternalCaseNumber +' -- '+stgingFieldVsColumnHeader.containsKey('Case_Number_Operator__c')+ '--' +stgingFieldVsColumnHeader );
                    if(stgingFieldVsColumnHeader.containsKey('Case_Number_Operator__c')){
                        // check if the Failure reason is blank
                        if(stagingRec.Failure_Reason__c == null || stagingRec.Failure_Reason__c == ''){
                            stagingRec.Failure_Reason__c = 'Please ensure '+ stgingFieldVsColumnHeader.get('Case_Number_Operator__c') +' values are unique.'+' \r\n';
                        }else{
                            stagingRec.Failure_Reason__c += 'Please ensure '+ stgingFieldVsColumnHeader.get('Case_Number_Operator__c') +' values are unique.'+' \r\n';
                        }   
                    }
                }
            }

            System.debug('Stagging Record :: ' + stagingRec +'--'+ String.isEmpty(stagingRec.Contact_Id__c));

            //UPDATE CASE: validate the case id
            if(!String.isEmpty(stagingRec.Case_Id__c)){
                System.debug('case Id Populated :: ' + caseIds + '--' + stagingRec.Case_Id__c);
                if(!caseIds.contains(stagingRec.Case_Id__c)){
                    if(stgingFieldVsColumnHeader.containsKey('Case_Id__c')){
                        if(String.isEmpty(stagingRec.Failure_Reason__c)){
                            stagingRec.Failure_Reason__c = stgingFieldVsColumnHeader.get('Case_Id__c') + ' is invalid. '+' \r\n';
                        }else{
                            stagingRec.Failure_Reason__c += stgingFieldVsColumnHeader.get('Case_Id__c') + ' is invalid. '+' \r\n';
                        }
                    }  
                }else{// update case lookup with case id populated in text field.
                    stagingRec.Case__c = stagingRec.Case_Id__c;
                }
            }

            // UPDATE CONTACT: validate the contact Id
            if(!String.isEmpty(stagingRec.Contact_Id__c)){ 
                System.debug('Contact Id Populated :: ' + cntIds + '--' + stagingRec.Contact_Id__c);
                if(!cntIds.contains(stagingRec.Contact_Id__c)){
                    if(stgingFieldVsColumnHeader.containsKey('Contact_Id__c')){
                        if(String.isEmpty(stagingRec.Failure_Reason__c)){
                            stagingRec.Failure_Reason__c = stgingFieldVsColumnHeader.get('Contact_Id__c') + ' is invalid. '+' \r\n';
                        }else{
                            stagingRec.Failure_Reason__c += stgingFieldVsColumnHeader.get('Contact_Id__c') + ' is invalid. '+' \r\n';
                        }
                    }  
                }else{// update contact lookup with case id populated in text field.
                    System.debug('Contact Id Populated after :: ' + stagingRec.Contact_Id__c);
                    stagingRec.Contact__c = stagingRec.Contact_Id__c;
                }
            }

            // validate location level 3 id is valid.
            if(!String.isEmpty(stagingRec.Location_Level_3_Id__c)){
                if(!taxonomyIds.contains(stagingRec.Location_Level_3_Id__c)){
                    if(stgingFieldVsColumnHeader.containsKey('Location_Level_3_Id__c')){
                        if(String.isEmpty(stagingRec.Failure_Reason__c)){
                            stagingRec.Failure_Reason__c = stgingFieldVsColumnHeader.get('Location_Level_3_Id__c') + ' is invalid. '+' \r\n';
                        }else{
                            stagingRec.Failure_Reason__c += stgingFieldVsColumnHeader.get('Location_Level_3_Id__c') + ' is invalid. '+' \r\n';
                        }
                    }  
                }else{// update location level lookup with case id populated in text field.
                    stagingRec.Location_Level_3__c = stagingRec.Location_Level_3_Id__c;
                }
            }

            // NEW CASE: Will validate the mandatory fields
            if(String.isEmpty(stagingRec.Case_Id__c)){

                Set<Boolean> caseBlankValueCheck = new Set<Boolean>();
                Boolean isCaseBlank = TRUE;
                caseBlankValueCheck.add(FALSE);
                for(String caseFieldName : stagingObjectToCaseMapping.keySet()){
                    if(!caseFieldName.equals('Contact_Id__c')){
                        if(!String.isEmpty(String.valueOf(stagingRec.get(caseFieldName)))){
                            isCaseBlank = FALSE;
                            break;
                        }    
                    }
                    
                }
                // Iterate over the mandatory fields to check if they have values or not
                System.debug('stagingApiNameVsCaseForMandatory :: ' + stagingApiNameVsCaseForMandatory);
                System.debug('isCaseBlank :: ' + isCaseBlank);
                if(isCaseBlank == FALSE){
                    for(String fieldName : stagingApiNameVsCaseForMandatory.keySet()){
                        System.debug('Case field value :: ' + fieldName +'--'+String.valueOf(stagingRec.get(fieldName))+'--'+String.isEmpty(String.valueOf(stagingRec.get(fieldName))) );
                        if(String.isEmpty(String.valueOf(stagingRec.get(fieldName)))){
                            String caseStatus = String.valueOf(stagingRec.Case_Status__c);
                            if(!notMandatoryFields.contains(fieldName)){
                                if(!mandatoryFields.contains(fieldName)){
                                    mandatoryFields.add(fieldName);
                                    if(String.isEmpty(mandatoryFiledError))
                                        mandatoryFiledError = stgingFieldVsColumnHeader.get(fieldName);
                                    else
                                        mandatoryFiledError += ', '+ stgingFieldVsColumnHeader.get(fieldName);
                                }else{
                                    // do nothing
                                }
                            }else if( ((fieldName.equals('Case_Manager__c') && String.isNotEmpty(caseStatus) && caseStatus.equals(GlobalConstants.CASE_IN_PROGRESS_STATUS))
                                || (fieldName.equals('Re_assignment_Reason__c') && String.isNotEmpty(caseStatus) && caseStatus.equals(GlobalConstants.CASE_STATUS_REASSIGNED))
                                || (fieldName.equals('Resolution_Detail__c') && String.isNotEmpty(caseStatus) && caseStatus.equals(GlobalConstants.CASE_SOFTCLOSED_STATUS)) ) ){
                                if(!mandatoryFields.contains(fieldName)){
                                    mandatoryFields.add(fieldName);
                                    if(String.isEmpty(mandatoryFiledError))
                                        mandatoryFiledError = stgingFieldVsColumnHeader.get(fieldName);
                                    else
                                        mandatoryFiledError += ', '+ stgingFieldVsColumnHeader.get(fieldName);
                                }else{
                                    // do nothing
                                }  
                            }
                        }
                    }
                }
            }

            // NEW CONTACT: Will validate the contact mandatory fields
            if(String.isEmpty(stagingRec.Contact_Id__c)){ 
                
                Boolean isContactBlank = TRUE;
                Set<Boolean> contactBlankValueCheck = new Set<Boolean>();
                contactBlankValueCheck.add(FALSE);

                // check if all fields for contact are blank
                for(String contactFieldName : stagingObjectToContactMapping.keySet()){
                    System.debug('Contact Field and value :: ' + contactFieldName +'::'+  String.valueOf(stagingRec.get(contactFieldName)) + '--' + String.isEmpty(String.valueOf(stagingRec.get(contactFieldName))));
                    if(!String.isEmpty(String.valueOf(stagingRec.get(contactFieldName)))){
                       isContactBlank = FALSE;
                       break;
                    }
                }
                System.debug('Check fileds check flag :: ' + contactBlankValueCheck);
                // Check for the contact mandatory fields
                if(isContactBlank == FALSE){
                    // Check for the mandatory fields specified in metadata mapping
                    for(String fieldName : stagingApiNameVsContactForMandatory.keySet()){
                      if(String.isEmpty(String.valueOf(stagingRec.get(fieldName)))){
                            if(!mandatoryFields.contains(fieldName)){
                                mandatoryFields.add(fieldName);
                                if(String.isEmpty(mandatoryFiledError))
                                    mandatoryFiledError = stgingFieldVsColumnHeader.get(fieldName);
                                else
                                    mandatoryFiledError += ', '+ stgingFieldVsColumnHeader.get(fieldName);
                            }else{
                                 // do nothing
                            }
                        }
                    }

                    // check for contact LastName, Email or Phone check
                    if(String.isEmpty(stagingRec.Contact_Second_Name__c) 
                        || (String.isEmpty(stagingRec.Contact_Email__c)
                          && String.isEmpty(stagingRec.Contact_Phone__c)
                          && String.isEmpty(stagingRec.Contact_Mobile__c)
                          && String.isEmpty(stagingRec.Contact_Work__c))){
                        System.debug('Check contact LastName,Email and Phone details');
                        if(stagingRec.Failure_Reason__c == null || stagingRec.Failure_Reason__c == ''){
                            stagingRec.Failure_Reason__c = 'Contact Second Name,Contact Email and any one from Contact Mobile,Phone and Work are Mandatory. '+' \r\n';
                        }else{
                            stagingRec.Failure_Reason__c += 'Contact Second Name,Contact Email and any one from Contact Mobile,Phone and Work are Mandatory. '+' \r\n';
                        }
                    }

                }
            }
			
            // Append error message for all the mandatory fields
            if(mandatoryFields.size() > 0 && mandatoryFields.size() ==1){
                if(stagingRec.Failure_Reason__c == null || stagingRec.Failure_Reason__c == ''){
                    stagingRec.Failure_Reason__c = mandatoryFiledError +' is Mandatory. '+' \r\n';
                }else{
                    stagingRec.Failure_Reason__c += mandatoryFiledError +' is Mandatory. '+' \r\n';
                }
            }else if(mandatoryFields.size() > 1){
                if(stagingRec.Failure_Reason__c == null || stagingRec.Failure_Reason__c == ''){
                    stagingRec.Failure_Reason__c = mandatoryFiledError +' are Mandatory. '+' \r\n';
                }else{
                    stagingRec.Failure_Reason__c += mandatoryFiledError +' are Mandatory. '+' \r\n';
                }
            }
            // Logic to evaluate the bad values for the picklist values mentioned in the csv upload template
            for(String fieldName : MappingRecord.picklistFieldApiName){
                if( stagingRec.get(fieldName) != null && stagingRec.get(fieldName) != '' ){
                    String value = String.valueOf(stagingRec.get(fieldName));
                    System.debug('Field Value :: ' + value + '--' + fieldName + '--' + stagingPicklistFieldNamevsValue);
                    // check if the field picklist value map contains the fieldname
                    if(stagingPicklistFieldNamevsValue.containsKey(fieldName)){
                        //check if picklist value doe not have the field value 
                        if(!(stagingPicklistFieldNamevsValue.get(fieldName)).contains(value)){
                            // check if the staging map has the field name and then get the field label
                            if(stgingFieldVsColumnHeader.containsKey(fieldName)){
                                // check if the Failure reason is blank
                                if(stagingRec.Failure_Reason__c == null || stagingRec.Failure_Reason__c == ''){
                                    stagingRec.Failure_Reason__c = stgingFieldVsColumnHeader.get(fieldName) + ' contains Bad Value. '+' \r\n';
                                }else{
                                    stagingRec.Failure_Reason__c += stgingFieldVsColumnHeader.get(fieldName) + ' contains Bad Value. '+' \r\n';
                                }
                            }
                        } 
                    }
                }
            }
            
            // validate and populated the date time incident on case record.
            if(String.isNotEmpty(stagingRec.Date_Time_of_Incident__c)) {
                String dateTimeOfIncident = stagingRec.Date_Time_of_Incident__c;
                try{
                    DateTime dt = Datetime.valueOf(dateTimeOfIncident);    
                    System.debug('dateTimeOfIncident: '+dateTimeOfIncident);
                }catch(Exception ex ){
                    system.debug('ex:'+ex.getMessage());
                    if(stagingRec.Failure_Reason__c == null || stagingRec.Failure_Reason__c == ''){
                        stagingRec.Failure_Reason__c = ex.getMessage() +' \r\n';
                    }else{
                        stagingRec.Failure_Reason__c += ex.getMessage() +' \r\n';
                    }
                }
            }
	
            System.debug('stagingRec.Failure_Reason__c  :: ' + stagingRec.Failure_Reason__c + '--' + stagingRec );
            if(!String.isBlank(stagingRec.Failure_Reason__c))
                stagingRec.Processing_Status__c = 'Failed';
            else
                stagingRec.Processing_Status__c = 'Success';  
       
            System.debug('stagingRec ::' + stagingRec);
        } 
        System.debug('Get CPU Timeout processStagingRecords 2#: '+Limits.getCpuTime() + '-'+ Limits.getLimitCpuTime() ); 
        
    }
    
}