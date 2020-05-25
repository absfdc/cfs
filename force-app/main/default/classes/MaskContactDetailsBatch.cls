/*******************************************************************************************
* Author:         Abhi Indulkar
* Company:        TfNSW
* Description:    Batch class to Mask contact details from Contacts
* 
* Test Class:    MaskContactDetailsBatchTest
* History
* <Date>      <Authors Name>      <Brief Description of Change>
* 10/12/2018  Abhi Indulkar    		Created
*******************************************************************************************/
global class MaskContactDetailsBatch implements Database.Batchable<SObject>, Database.Stateful {
    private static String MASK_SFX = '.invalid';
    private Boolean isSandbox = false;
    private Set<String> lExceptions = new Set<String>();
    private static String resultEmail;
    public static String sCRMTeamEmail = 'salesforcerequests@transport.nsw.gov.au';
    private Integer batchSize = 200;
    public Boolean callNextBatchJob = true;
    
    private Integer failedRecCount = 0;
    private Integer successRecCount = 0;
    
    global MaskContactDetailsBatch() {
        this.isSandbox = runningInASandbox();
    }
    
    global MaskContactDetailsBatch(String pEmail, Integer pBatchSize, Boolean callRemainingBatchJob) {
        this.isSandbox = runningInASandbox();
        resultEmail = pEmail;
        batchSize = pBatchSize;
        callNextBatchJob = callRemainingBatchJob;
    }
    
    /**
    * @description gets invoked when the batch job starts
    * @param context contains the job ID
    * @returns the record set as a QueryLocator object that will be batched for execution
    */
    global Database.QueryLocator start(Database.BatchableContext context) {
        String dummyId = '000000000000000';
        if (this.isSandbox || Test.isRunningTest()) {           
            return Database.getQueryLocator([SELECT Email, MOEmail__c FROM Contact]);
        }else{
            return Database.getQueryLocator([SELECT Email, MOEmail__c FROM Contact WHERE Id = :dummyId]);
        }
    }
    
    /**
    * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
    * @param context contains the job ID
    * @param scope contains the batch of records to process.
    */
    global void execute(Database.BatchableContext context, List<Contact> scope) {       
        
        List<Contact> lContacts = new List<Contact> ();
        Boolean toggle = true;
        for (Contact c : scope) {
            if(String.isNotBlank(c.Email) || String.isNotBlank(c.MOEmail__c) ){
                c.Email = getInvalidEmail(c.Email);
                c.MOEmail__c = getInvalidEmail(c.MOEmail__c);       
                if(Test.isRunningTest() && toggle){
                    c.No_CFM_cases_12_mth_rolling__c = 1235473474; //more than 6 digit number
                    toggle=false;
                }
                lContacts.add(c);
            }
        }
        if(!lContacts.isEmpty()){
            Database.SaveResult[] updateResultList =  Database.update(lContacts, false);
            
            Map<Id, String> mFailedRecords = new Map<Id, String>();
            // Iterate through each returned result
            for(Database.SaveResult sr : updateResultList){              
                if(!sr.isSuccess()) {
                    // Operation failed, so get all errors
                    String sErrorDetails;               
                    for(Database.Error err : sr.getErrors()) {
                        sErrorDetails = err.getMessage() + ': Error Fields- ' + err.getFields();
                        lExceptions.add(sErrorDetails);
                    }
                    mFailedRecords.put(sr.id, sErrorDetails);
                    failedRecCount++;
                }else{
                    successRecCount++;
                }
            }
            
            //Log errors in application log
            List<Application_Log__c> lAppLogs = new List<Application_Log__c>();
            for(Id recId : mFailedRecords.keySet()){
                Application_Log__c log = new Application_Log__c();
                log.Debug_Level__c = 'Info';
                log.Reference_Id__c = recId;
                log.Reference_Info__c = mFailedRecords.get(recId);
                log.Source__c = 'MaskContactDetailsBatch';
                log.Source_Function__c = 'execute';
                lAppLogs.add(log);
            }
            insert lAppLogs;
        }
        
    }
    
    /**
    * @description gets invoked when the batch job finishes. Place any clean up code in this method.
    * @param context contains the job ID
    */
    global void finish(Database.BatchableContext context) {
        
        // Send an email to the Apex job's submitter notifying of job completion.  
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        String[] toAddresses = new String[] {sCRMTeamEmail};        
            if(String.isNotBlank(resultEmail)){
                toAddresses.add(resultEmail);
            }
        mail.setToAddresses(toAddresses);        
        mail.setSubject('Contact masking batch completed');
        String bodyText = 'BATCH MaskContactDetailsBatch Summary:\n\n';
        bodyText = bodyText + 'Number of total records: ' + (successRecCount + failedRecCount);
        bodyText = bodyText + '\n\tSuccessfully updated records: ' + successRecCount;
        bodyText = bodyText + '\n\tFailed to update records: ' + failedRecCount;
        
        if(!lExceptions.isEmpty()){
            bodyText = bodyText + '\n\nError Summary\n\n';
            for(String err : lExceptions) {
                bodyText = bodyText + '\n' + err + '\n';
            }
        }
        
        bodyText = bodyText + '\n\n';
        mail.setPlainTextBody (bodyText);
        try{ 
        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }catch(Exception e){
        	//Do Nothing
        }
        
        //Invoke next batch jobs if requested
        if (!Test.isRunningTest() && this.isSandbox) {
			if (callNextBatchJob)
				ID batchProcessId = Database.executeBatch(new MaskCaseDetailsBatch(), this.batchSize);
		}
        
    }
   /* 
    private String getInvalidNumber(String pNumber) {
        String sInvalidNumber;
        if (String.isNotBlank(pNumber) && pNumber.length() > 3) {
            sInvalidNumber = pNumber.substring(0, 3) + '1' + pNumber.substring(3);
        } else {
            sInvalidNumber = pNumber;
        }
        return sInvalidNumber;
    }*/
    
    private String getInvalidEmail(String pEmail) {
        String sInvalidEmail;
        if (String.isNotBlank(pEmail) && !pEmail.endsWith(MASK_SFX)) {
            pEmail = pEmail.length() > 245 ? pEmail.substring(10) : pEmail;
            sInvalidEmail = pEmail + MASK_SFX;
        } else {
            sInvalidEmail = pEmail;
        }
        return sInvalidEmail;
    }
    
    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}