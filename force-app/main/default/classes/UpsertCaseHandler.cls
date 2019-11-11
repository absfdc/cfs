/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus Technology Partners
Description:   insert/update a case based on the case id populated on the staging record

History
16/06/2017      Pawan Tiwari         Created.
------------------------------------------------------------*/
public with sharing class UpsertCaseHandler {
    
    List<BU_Staging__c> stagingDetails = new List<BU_Staging__c>();
    Map<String,Case> caseMap;
    Map<String,String> stagingObjectToCaseMapping = new Map<String,String>();
    String fieldNames = null;

    public UpsertCaseHandler(List<BU_Staging__c> stagingDetails) {
        this.stagingDetails = stagingDetails;
        caseMap = new map<String,Case>();

        stagingObjectToCaseMapping = MappingRecord.stagingObjectToCaseMapping;
		MappingRecord.setRecordTypeMap();
            
    }

    /* This method is invoked in BUStagingAfterInsertTriggerHandler.cls
    * This method is responsible to craete or update a new case based on Case Id populated in the staging record
    */
    public Map<String,String> exceute(Map<String,String> stagingWithContactIdMap){
        // get a map of staging Id vs new contact Id
        Map<String,String> getCreateCaseMap = createCase(stagingWithContactIdMap);
        System.debug('getCreateCaseMap :: ' + getCreateCaseMap);

        // get a map of staging Id vs existing case Id
        Map<String,String> getUpdateCaseMap = updateCase(stagingWithContactIdMap);
        System.debug('getUpdateCaseMap :: ' + getUpdateCaseMap);
        
        if(getCreateCaseMap != null){
            for(String tempStaging : getCreateCaseMap.keySet()){
                if(!getUpdateCaseMap.containsKey(tempStaging))
                    getUpdateCaseMap.put(tempStaging,getCreateCaseMap.get(tempStaging));
            }
        }
        System.debug('Final getUpdateCaseMap :: ' + getUpdateCaseMap);
        return getUpdateCaseMap;
    }
    

    /* get exiting case details for the case ids populated on the staging record 
        where staging record has processing status as 'Success'. 
    */
    @TestVisible
    private Map<String,Case> getExistingCase(){

        Set<String> caseIdSet = new Set<String>();

        for( BU_Staging__c stagingRecord : stagingDetails){
            if(stagingRecord.Case_Id__c != null && stagingRecord.Processing_Status__c != GlobalConstants.FAILED_PROCESSING_STATUS){
                if(!caseIdSet.contains(stagingRecord.Case_Id__c))
                    caseIdSet.add(stagingRecord.Case_Id__c);
            }
        }

        String soqlQuery = 'select '+MappingRecord.caseFieldNames+' FROM Case WHERE Id IN :caseIdSet';
        System.debug('soqlQuery :: ' + soqlQuery);
        List<Case> existingCaseList = Database.Query(soqlQuery);

        System.debug('existingCaseList :: ' + existingCaseList);
        Map<String,Case> existingCaseMap = new Map<String,Case>();

        if(existingCaseList.size() > 0){
            for(Case tempCase : existingCaseList){
                existingCaseMap.put(tempCase.Id,tempCase);
            }
        }

        System.debug('existingCaseMap :: ' + existingCaseMap);
        return existingCaseMap;

    }

    /*update case details when case id is populated on staging object record
    *Update the staging record status as failed if case failed to update
    *Update the staging record status as Success if case successfully updated
    */
    @TestVisible
    private Map<String,String> updateCase(Map<String,String> getStagingWithContact){
       
        Map<String,Case> existingCaseDetails = getExistingCase();
        Map<String,Case> caseMapToBeUpdated = new Map<String,Case>();
        Map<String,BU_Staging__c> stagingRecordsToBeUpdatedMap = new Map<String,BU_Staging__c>();
        Map<String,String> stagingIdVsCaseId = new Map<String,String>();
        Map<String,String> caseIdVsStagingId = new Map<String,String>();
        List<Case> caseToBeUpadtedList = new List<Case>();
        
        for( BU_Staging__c stagingRecord : stagingDetails){
            Case existingCase = null;
            Boolean needToUpdate = false;  
            if(stagingRecord.Case_Id__c != null && stagingRecord.Processing_Status__c != GlobalConstants.FAILED_PROCESSING_STATUS){
                if(existingCaseDetails.containsKey(stagingRecord.Case_Id__c))
                    existingCase = existingCaseDetails.get(stagingRecord.Case_Id__c);

                if(existingCase != null){
                    /*Iterate over the staging field api name.
                    * check if staging record has the blank value for the the  
                    */
                    for(String stagingApiName : stagingObjectToCaseMapping.keySet()){

                        String stagingField = stagingApiName;
                        String SFField = stagingObjectToCaseMapping.get(stagingApiName);
                        
                        String fieldValue = String.valueOf(stagingRecord.get(stagingField));
                        
                        if(SFField != null && SFField != '' && SFField != 'Id'){
                            if(stagingField == 'Contact_Id__c' && getStagingWithContact.size() > 0 && getStagingWithContact.get(stagingRecord.Id) != null){
                                needToUpdate = true;  
                                existingCase.put(SFField,getStagingWithContact.get(stagingRecord.Id));
                            }else{
                                if(String.isNotEmpty(fieldValue)){
                                    needToUpdate = true;
                                    // Check if the Mode is either Bus or Ligth Rail then change the record type accordingly
                                    if(MappingRecord.modeVsRecordTypeId.containsKey(fieldValue)){
                                        existingCase.put('RecordTypeId',MappingRecord.modeVsRecordTypeId.get(stagingRecord.Mode__c));
                                    }
                                    existingCase.put(SFField,fieldValue);
                                }
                            }
                        }
                    }
                    if(needToUpdate == true){
                        if(!caseMapToBeUpdated.containsKey(existingCase.Id)){
                            caseToBeUpadtedList.add(existingCase);
                        }
                        caseMapToBeUpdated.put(existingCase.Id,existingCase); 
                        caseIdVsStagingId.put(existingCase.Id,stagingRecord.Id); 
                        stagingIdVsCaseId.put(stagingRecord.Id,existingCase.Id);      
                        
                    }
                    
                }       
            }
        }
        
        System.debug('caseMapToBeUpdated :: ' + caseMapToBeUpdated);
        System.debug('stagingIdVsCaseId :: ' + stagingIdVsCaseId);
        
        // Check if the case need to be updated
        if(caseMapToBeUpdated.size() > 0 ){

            Database.SaveResult[] updateResult = Database.update(caseToBeUpadtedList, false);

            // Iterate over the update result (to get success and errors)
            for(Integer i = 0; i < updateResult.size(); i++) {
               // Update was successful 
               if (updateResult.get(i).isSuccess()){
                    System.debug('Sucess: Updated Case Id :: ' + updateResult.get(i).getId());
                    if(caseIdVsStagingId.containsKey(updateResult.get(i).getId())){
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = caseIdVsStagingId.get(updateResult.get(i).getId());
                        stagingToBeUpdated.Case__c = caseToBeUpadtedList.get(i).Id;
                        stagingToBeUpdated.Case_Id__c = caseToBeUpadtedList.get(i).Id;
                        stagingToBeUpdated.Contact__c = caseToBeUpadtedList.get(i).ContactId;
                        stagingToBeUpdated.Contact__c = caseToBeUpadtedList.get(i).ContactId;
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                        stagingRecordsToBeUpdatedMap.put(stagingToBeUpdated.Id,stagingToBeUpdated);
                    }
                }else if (!updateResult.get(i).isSuccess()){// DML operation failed
                    
                    Database.Error error = updateResult.get(i).getErrors().get(0);
                    system.debug('Update case failed ID ::'+caseToBeUpadtedList.get(i).Id);
                    if(caseIdVsStagingId.containsKey(caseToBeUpadtedList.get(i).Id)){
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = caseIdVsStagingId.get(caseToBeUpadtedList.get(i).Id);
                        stagingToBeUpdated.Case__c = caseToBeUpadtedList.get(i).Id;
                        stagingToBeUpdated.Case_Id__c = caseToBeUpadtedList.get(i).Id;
                        stagingToBeUpdated.Contact__c = caseToBeUpadtedList.get(i).ContactId;
                        stagingToBeUpdated.Contact__c = caseToBeUpadtedList.get(i).ContactId;
                        if(stagingToBeUpdated.Failure_Reason__c == null)
                            stagingToBeUpdated.Failure_Reason__c = error.getMessage()+'\r\n';
                        else
                            stagingToBeUpdated.Failure_Reason__c += error.getMessage()+'\r\n';
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.FAILED_PROCESSING_STATUS;
                        stagingRecordsToBeUpdatedMap.put(stagingToBeUpdated.Id,stagingToBeUpdated);
                    }
                 } 
            }

            System.debug('stagingRecordsToBeUpdatedMap ::' + stagingRecordsToBeUpdatedMap);
            if(stagingRecordsToBeUpdatedMap.size() > 0)
                update stagingRecordsToBeUpdatedMap.values();

        }

        System.debug('stagingIdVsCaseId :: ' + stagingIdVsCaseId);
        return stagingIdVsCaseId;

    }

    /* create a new case if the case id is not populated on the staging record
    * Update the staging record processing status as 'Failed' when case failed to insert.
    * Update the staging record processing status as 'Success' when case successfully inserted.
    */
    @TestVisible
    private Map<String,String> createCase(Map<String,String> getStagingWithContact){
        
        System.debug('getStagingWithContact :: ' + getStagingWithContact);
        Map<String,String> stagingIdVsCaseId = new Map<String,String>();
        // store new case detail
        Map<String,Case> caseToBeInserted = new Map<String,Case>();
        //store case number operrator with respective staging record id 
        Map<String,String> caseNumberVsStagingIdMap = new Map<String,String>();
        // store case number with case id of the new inserted
        Map<String,String> caseNumberVsCaseIdMap = new Map<String,String>();
        // used to store staging record needs to be updated for case id
        Map<String,BU_Staging__c> stagingRecordsToBeUpdatedMap = new Map<String,BU_Staging__c>();
		List<Case> caseToBeInsertedList = new List<Case>();

        for( BU_Staging__c stagingRecord : stagingDetails){
            
            Case newCase = new Case();
            Boolean needToBeCreated = false;
            if(stagingRecord.Case__c == null && stagingRecord.Processing_Status__c != GlobalConstants.FAILED_PROCESSING_STATUS){
                //Iterate over the staging fields and check if any field has a value
                for(String stagingApiName : stagingObjectToCaseMapping.keySet()){
                
                    String stagingField = stagingApiName;
                    String SFField = stagingObjectToCaseMapping.get(stagingApiName);
                    String fieldValue = String.valueOf(stagingRecord.get(stagingField));
                    
                    if(SFField != null && SFField != ''){
                        if(stagingField.equalsIgnoreCase('Contact_Id__c') 
                            && SFField.equalsIgnoreCase('ContactId') 
                            && getStagingWithContact.size() > 0 
                            && getStagingWithContact.get(stagingRecord.Id) != null){
                            System.debug('stagingField :: ' + stagingField + '--' + getStagingWithContact.get(stagingRecord.Id));
                            newCase.put(SFField,getStagingWithContact.get(stagingRecord.Id));
                        }else{
                            if(String.isNotEmpty(fieldValue) && (!SFField.equals('ContactId'))){
                                needToBeCreated = true;
                                if(SFField.equals('Date_Time_of_Incident__c'))
                                    newCase.put(SFField,DateTime.valueOf(fieldValue));
                                else
                                    newCase.put(SFField,fieldValue);
                            }
                        }
                    }
                }   
                System.debug('Case needToBeCreated :: ' + needToBeCreated);
                if(needToBeCreated == true){
                    newCase.put('OwnerId',UserInfo.getUserId());
                    if(MappingRecord.modeVsRecordTypeId.containsKey(stagingRecord.Mode__c))
                        newCase.put('RecordTypeId',MappingRecord.modeVsRecordTypeId.get(stagingRecord.Mode__c));

                    System.debug('** New Case ** ' + newCase.Case_Number_Operator__c+ '--'+newCase);
                    caseToBeInserted.put(newCase.Case_Number_Operator__c,newCase);
                    caseNumberVsStagingIdMap.put(newCase.Case_Number_Operator__c,stagingRecord.Id);
                    caseToBeInsertedList.add(newCase);
                    System.debug('caseToBeInserted :: ' + caseToBeInserted);
                    System.debug('caseNumberVsStagingIdMap :: ' + caseNumberVsStagingIdMap);
                }
            }
            
        }

        if(caseToBeInsertedList.size() > 0){
            // save the new case 
            Database.SaveResult[] insertResult = Database.insert(caseToBeInsertedList, false);
            System.debug('caseToBeInserted after :: ' + caseToBeInserted);

            for(Integer i = 0; i < insertResult.size(); i++) {
               if (insertResult.get(i).isSuccess()){
                    System.debug('Sucess: New case:: ' + caseToBeInsertedList.get(i).Case_Number_Operator__c +'-'+caseToBeInsertedList.get(i).ContactId);
                    if(caseNumberVsStagingIdMap.containsKey(caseToBeInsertedList.get(i).Case_Number_Operator__c)){
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = caseNumberVsStagingIdMap.get(caseToBeInsertedList.get(i).Case_Number_Operator__c);
                        stagingToBeUpdated.Case__c = caseToBeInsertedList.get(i).Id;
                        stagingToBeUpdated.Case_Id__c = caseToBeInsertedList.get(i).Id;
                        stagingToBeUpdated.Contact__c = caseToBeInsertedList.get(i).ContactId;
                        stagingToBeUpdated.Contact_Id__c = caseToBeInsertedList.get(i).ContactId;
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.SUCCESS_PROCESSING_STATUS;
                        stagingRecordsToBeUpdatedMap.put(stagingToBeUpdated.Id,stagingToBeUpdated);
                        stagingIdVsCaseId.put(stagingToBeUpdated.Id,caseToBeInsertedList.get(i).Id);
                    }
                }else if (!insertResult.get(i).isSuccess()){
                    // DML operation failed
                    Database.Error error = insertResult.get(i).getErrors().get(0);
                    system.debug('Failed: New Case :: '+caseToBeInsertedList.get(i).Case_Number_Operator__c);

                    if(caseNumberVsStagingIdMap.containsKey(caseToBeInsertedList.get(i).Case_Number_Operator__c)){
                        BU_Staging__c stagingToBeUpdated = new BU_Staging__c();
                        stagingToBeUpdated.Id = caseNumberVsStagingIdMap.get(caseToBeInsertedList.get(i).Case_Number_Operator__c);
                        stagingToBeUpdated.Contact__c = caseToBeInsertedList.get(i).ContactId;
                        stagingToBeUpdated.Contact_Id__c = caseToBeInsertedList.get(i).ContactId;
                        if(stagingToBeUpdated.Failure_Reason__c == null)
                            stagingToBeUpdated.Failure_Reason__c = error.getMessage()+'\r\n';
                        else
                            stagingToBeUpdated.Failure_Reason__c += error.getMessage()+'\r\n';
                        stagingToBeUpdated.Processing_Status__c = GlobalConstants.FAILED_PROCESSING_STATUS;
                        stagingRecordsToBeUpdatedMap.put(stagingToBeUpdated.Id,stagingToBeUpdated);
                    }
                   
                 } 
            }
            System.debug('caseNumberVsCaseIdMap :: ' + caseNumberVsCaseIdMap);
        }
        // Staging record map need to be updated with the case id
        System.debug('stagingRecordsToBeUpdatedMap :: ' + stagingRecordsToBeUpdatedMap);
        if(stagingRecordsToBeUpdatedMap.size() > 0)
            update stagingRecordsToBeUpdatedMap.values();

        System.debug('stagingIdVsCaseId :: ' + stagingIdVsCaseId);
        return stagingIdVsCaseId;

    }
  
}