/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus Technology Partners
Description:   1. Get total number of staging records being inserted after the file upload.
               2. Get count for maximum number of records allowed for a upload.
               3. List of csv column header from 'BU Staging Field Mapping Metadata'
Inputs:        Uploaded file content

History
16/06/2017      Pawan Tiwari         Created.
------------------------------------------------------------*/
public with sharing class BulkUploadStagingRecords {
    
    //Input :- Content of CSV file uploaded 
    //Output :- Number of successfully inserted records
    @AuraEnabled
    public static Integer addRecordsCSV(String fileContent){
        Integer successUploads;
        System.debug('fileContent is = '+fileContent);
        BulkUploadStagingRecordsCntrl bfl = new BulkUploadStagingRecordsCntrl(fileContent);
        successUploads = bfl.execute();
        System.debug('SuccessFully inserted '+ successUploads +' Stagging Records');
        return successUploads;
    }

    // Get count for maximum number of records allowed for a upload.
    @AuraEnabled
    public static Integer getUploadRecordCount(){
        Integer recordCount;

            List<Bulk_Upload_CSV_File_Maximum_Record__mdt> mappingMetadataRecList = [SELECT Count__c 
                                                                                    FROM Bulk_Upload_CSV_File_Maximum_Record__mdt
                                                                                    LIMIT 1];
                
            if(mappingMetadataRecList.size() > 0){
                recordCount = Integer.valueOf(mappingMetadataRecList[0].Count__c);
            }

            return recordCount;
        
    }

    // Get list of csv column headers from 'BU Staging Field Mapping Metadata'
    @AuraEnabled
    public static List<String> getCSVColumnHeaders(){
         List<String> columnHeaders = new List<String>();
            List<BU_Staging_Field_Mapping_Metadata__mdt> mappingMetadataRecList = [SELECT Column_Header__c
                                                                                    FROM BU_Staging_Field_Mapping_Metadata__mdt ];
                
            
            for(BU_Staging_Field_Mapping_Metadata__mdt mappingMetadataRec : mappingMetadataRecList){
                columnHeaders.add(mappingMetadataRec.Column_Header__c);
            }
            System.debug('getCSVColumnHeaders :: ' + columnHeaders );
            return columnHeaders;
        
    }

}