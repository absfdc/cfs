/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus Technology Partners
Description:   Craete staging record from the csv file rows and return the list of staging records

History
16/06/2017      Pawan Tiwari         Created.
------------------------------------------------------------*/
public with sharing class StagingRecordBuilder {
    
    /* build staging records from the csv file.
    * Delete the blank rows present in the csv files using the regex match
    */
    public static List<BU_Staging__c> buildStagingRecord(ATP_CSVParser csvParser,List<String> headerRow){
        System.debug('csvParser::'+csvParser);
        String uploadJobId = null;
        
        // get job id start number from BU Staging Job Detail custom setting record
        Map<String,BU_Staging_Job_Detail__c> jobIdMetadata = BU_Staging_Job_Detail__c.getAll();
        if(jobIdMetadata.containsKey(GlobalConstants.BU_STAGINING_JOB_ID))
            uploadJobId = jobIdMetadata.get(GlobalConstants.BU_STAGINING_JOB_ID).Job_Id__c;

        // update the BU Staging Job Detail custom setting Job Id by 1.
        if(uploadJobId != null){
            BU_Staging_Job_Detail__c newStagingJobRecord = new BU_Staging_Job_Detail__c();
            newStagingJobRecord.Id = jobIdMetadata.get(GlobalConstants.BU_STAGINING_JOB_ID).Id;
            newStagingJobRecord.Job_Id__c = String.valueOf(Integer.valueOf(uploadJobId)+1);
            newStagingJobRecord.Name = GlobalConstants.BU_STAGINING_JOB_ID;
            update newStagingJobRecord; 
        }

        System.debug('uploadJobId :: ' + uploadJobId );    
        
        List<BU_Staging__c> stgRec = new List<BU_Staging__c>();
        Schema.DescribeSObjectResult buStaggingObject = BU_Staging__c.sObjectType.getDescribe();
        SObject tempStaggingRecord;
        List<SObject> staggingRecords = new List<SObject>();
        
        Map<String,String> stagingObjAPIfieldVsColmnHeader = new Map<String,String>();
        
        System.debug('Get CPU Timeout before :: '+Limits.getCpuTime()  + '-'+ Limits.getLimitCpuTime() );

        // Get the records from the BU Staging Field Mapping Metadata mapping 
        List<BU_Staging_Field_Mapping_Metadata__mdt> mappingMetadataRecList = [SELECT Column_Header__c, Is_Staging_Field_Mandatory__c, Object_Name__c ,Sobject_Field_API_Name__c,Staging_Field_API_Name__c
                                                                                FROM BU_Staging_Field_Mapping_Metadata__mdt];
        system.debug('mappingMetadataRecList :: ' + mappingMetadataRecList );
        
        for(BU_Staging_Field_Mapping_Metadata__mdt mappingMetadataRec : mappingMetadataRecList){
            stagingObjAPIfieldVsColmnHeader.put(mappingMetadataRec.Column_Header__c, mappingMetadataRec.Staging_Field_API_Name__c);
        }

        System.debug('Get CPU Timeout after 1 :: '+Limits.getCpuTime() + '-'+ Limits.getLimitCpuTime() ); 

        Integer rowIterationCount = 1;

        // Iterate over the parser result to get the csv rows
        while(csvParser.hasNext()) {
            
            Integer columnIterationCount = 0;
            tempStaggingRecord = new BU_Staging__c();

            // default set false, true only if there is a blank row
            Boolean deleteBlankRows = false;
                
            List<String> row = csvParser.next();
            System.debug('CSV Row :: ' + row);
            
            // convert list of string to string to match with a regex for blank rows
            String csvRow = String.join(row, '');
            System.debug('csvRow after :: ' + csvRow );

            System.debug('Row blank match :: ' + Pattern.matches('[,\\s*\\n\\r]*', csvRow));

            if(Pattern.matches('[,\\s*\\n\\r]*', csvRow))
                deleteBlankRows= true;

            if(deleteBlankRows == false){
                // Increase the row counter by 1.
                ++rowIterationCount;

                System.debug('Get CPU Timeout after 2 :: '+Limits.getCpuTime()  + '-'+ Limits.getLimitCpuTime() ); 
                // Iterate over the header rows to get the value for each column and put in the staging field
                for(String headerRowColumn : headerRow) {
                    
                    if(columnIterationCount == row.size())
                        break;
                  
                    if(stagingObjAPIfieldVsColmnHeader.containsKey(headerRow[columnIterationCount])) {
                        String mappedColumnAPIKey = stagingObjAPIfieldVsColmnHeader.get(headerRow[columnIterationCount]);
                        if(buStaggingObject.fields.getMap().get(mappedColumnAPIKey) != NULL) {
                            // create staging record based on the csv header columns
                            tempStaggingRecord.put(mappedColumnAPIKey,row[columnIterationCount]);
                          
                        }
                            
                    }
                    // Increase the column counter by 1.
                    columnIterationCount++;
                    
                }
                System.debug('Get CPU Timeout after 3 :: '+Limits.getCpuTime() + '-'+ Limits.getLimitCpuTime() ); 

                // if row counter is less than by 1 then put the '0' as beigning
                if(rowIterationCount <= 9){
                    tempStaggingRecord.put('Job_Id__c',uploadJobId+'-'+String.valueOf('0'+rowIterationCount));
                }else{
                    tempStaggingRecord.put('Job_Id__c',uploadJobId+'-'+rowIterationCount);
                }
                
                staggingRecords.add(tempStaggingRecord);

                System.debug('staggingRecords :: ' + staggingRecords);
            }
        }
        System.debug('Get CPU Timeout after 4 :: '+Limits.getCpuTime() + '-'+ Limits.getLimitCpuTime() ); 

        return staggingRecords;
    }
       
    public class StagingRecordBuilderException extends Exception {}
}