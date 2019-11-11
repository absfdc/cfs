/*------------------------------------------------------------
Author:        Pawan Tiwari
Company:       Arxxus Technology Partners
Description:   Parse Staging records from the uploaded file and return numeber of the inserted staging records.

History
16/06/2017      Pawan Tiwari         Created.
------------------------------------------------------------*/
public with sharing class BulkUploadStagingRecordsCntrl {

    public Integer rowCount;
    public Integer maxRecordCount;
    private String filedata;
    private Exception ex;
    public BulkUploadStagingRecordsCntrl(String filedata){
        this.filedata = filedata;
        rowCount = 0;
        List<Bulk_Upload_CSV_File_Maximum_Record__mdt> mappingMetadataRecList = [SELECT Count__c 
                                                                                    FROM Bulk_Upload_CSV_File_Maximum_Record__mdt
                                                                                    LIMIT 1];
        Integer recordCount = 0;
        if(mappingMetadataRecList.size() > 0){
            maxRecordCount = Integer.valueOf(mappingMetadataRecList[0].Count__c);
        }
    }

    //Executes the process of insertion of staging records
    //returns number of successfully inserted records
    public Integer execute(){
        Integer success = 0;
        Savepoint sp = Database.setSavepoint();
        List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
        try{
            System.debug('In Execute');
            
            if(filedata == null) {
                throw new BulkLoadException('Incorrect type of data - required data');
            }

            List<BU_Staging__c> stagingRecList;
            stagingRecList = parseStagingRec();
            rowCount = stagingRecList.size();
        
            if(rowCount > maxRecordCount) {
                System.debug('row count greater than allowed limit.');
               // throw new BulkLoadException(Label.MAXIMUM_RECORD_SIZE);
               // return 10000000;
               return rowCount;
            }

            if(rowCount < 1) {
                System.debug('No rows found in the CSV');
               return rowCount;
            }


            
            
            else {
                Database.SaveResult[] srList = Database.insert(stagingRecList, true);

                for (Database.SaveResult sr : srList) {
                    System.debug('srResult = '+sr);
                    if (sr.isSuccess()) {
                        success++;
                        System.debug('success === '+ sr);
                    }else{
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            ApplicationLogMessage message= new ApplicationLogMessage();
                            message.source='BulkUploadStagingRecordsCntrl';
                            message.sourceFunction='execute';
                            message.logMessage=err.getMessage();
                            message.debugLevel=GlobalConstants.ERROR;
                            messages.add(message);
                            ApplicationLogUtility.logMessage(messages);
                            messages.clear();
    
                        }
                        throw new BulkLoadException('Exception in BUlk Upload staging records');
                    }
                }
            }
            System.debug('Get CPU Timeout execute: '+Limits.getCpuTime() + '-'+ Limits.getLimitCpuTime() ); 
            
            //Save records in database not allowing partial insertion
            
            
      
        }catch(Exception e){
      //Rollback the transaction if an exception is occured
            Database.rollback(sp);
            ex = e;
            //throw new BulkLoadException('Exception in BUlk Upload staging records');
      
        } finally{
            System.debug('finally executing.');
      		if(ex != NULL) {
                ApplicationLogMessage message= new ApplicationLogMessage();
                message.source='BulkUploadStagingRecordsCntrl';
                message.sourceFunction='execute';
                message.logMessage=ex.getMessage() + '--' + ex.getLineNumber();
                message.ex=ex;
                message.debugLevel=GlobalConstants.ERROR;
                messages.add(message);
                ApplicationLogUtility.logMessage(messages);
                messages.clear();
            }
        }
        return success;
    }
    
    // Parse the input file content and return the staging records
    @TestVisible
    private List<BU_Staging__c> parseStagingRec() {
        
        System.debug('filedata :: ' + filedata);
        List<BU_Staging__c> newstagingRecords = new List<BU_Staging__c>();
        ATP_CSVParser parser = new ATP_CSVParser(filedata, true, ',', '\r'); 
        
        List<String> headerRow = parser.getHeaderRow();
        List<String> stagingRecord = new List<String>();
        BU_Staging__c newstagingRecord = new BU_Staging__c();
        System.debug('headerRow********'+headerRow);
        newstagingRecords = StagingRecordBuilder.buildStagingRecord(parser,headerRow);
        return newstagingRecords; 
        
    }

    public class BulkLoadException extends Exception {}

}