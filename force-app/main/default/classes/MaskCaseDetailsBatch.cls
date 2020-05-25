/*******************************************************************************************
* Author:         Abhi Indulkar
* Company:        TfNSW
* Description:    Batch class to Mask contact details from Case
* 
* Test Class:    MaskCaseDetailsBatchTest
* History
* <Date>      <Authors Name>      <Brief Description of Change>
* 10/12/2018  Abhi Indulkar    		Created
*******************************************************************************************/
global class MaskCaseDetailsBatch implements Database.Batchable<SObject>, Database.Stateful {
    private static String MASK_SFX = '.invalid';
    private Boolean isSandbox = false;
    private Set<String> lExceptions = new Set<String>();
    private static String resultEmail;
    public static String sCRMTeamEmail = 'salesforcerequests@transport.nsw.gov.au';
    
    private Integer failedRecCount = 0;
    private Integer successRecCount = 0;
    
    global MaskCaseDetailsBatch() {
        this.isSandbox = runningInASandbox();
    }
    
    global MaskCaseDetailsBatch(String pEmail) {
        this.isSandbox = runningInASandbox();
        resultEmail = pEmail;
    }
    
    /**
    * @description gets invoked when the batch job starts
    * @param context contains the job ID
    * @returns the record set as a QueryLocator object that will be batched for execution
    */
    global Database.QueryLocator start(Database.BatchableContext context) {
        String dummyId = '000000000000000';
        if (this.isSandbox || Test.isRunningTest()) {           
            return Database.getQueryLocator([SELECT SuppliedEmail, Contact_Email__c,OBO_Email__c,SNSW_Referral_Email__c,Manager_Email__c,Last_Queue_Assigned_Email__c,High_Priority_Train_Recepient__c,PBLROperator_Email_Address__c FROM Case]);
        }else{
            return Database.getQueryLocator([SELECT SuppliedEmail, Contact_Email__c,OBO_Email__c,SNSW_Referral_Email__c,Manager_Email__c,Last_Queue_Assigned_Email__c,High_Priority_Train_Recepient__c,PBLROperator_Email_Address__c FROM Case WHERE Id = :dummyId]);
        }
    }
    
    /**
    * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
    * @param context contains the job ID
    * @param scope contains the batch of records to process.
    */
    global void execute(Database.BatchableContext context, List<Case> scope) {       
        
        List<Case> lCases = new List<Case> ();
        Boolean toggle = true;
        for (Case c : scope) {
            if(String.isNotBlank(c.SuppliedEmail) 
               || String.isNotBlank(c.Contact_Email__c)
               || String.isNotBlank(c.OBO_Email__c) 
               || String.isNotBlank(c.SNSW_Referral_Email__c)
               || String.isNotBlank(c.Manager_Email__c) 
               || String.isNotBlank(c.Last_Queue_Assigned_Email__c)
               || String.isNotBlank(c.PBLROperator_Email_Address__c) 
               || String.isNotBlank(c.High_Priority_Train_Recepient__c))
            {
                c.SuppliedEmail = getInvalidEmail(c.SuppliedEmail);
                c.Contact_Email__c = getInvalidEmail(c.Contact_Email__c);  
                c.OBO_Email__c = getInvalidEmail(c.OBO_Email__c);  
                c.SNSW_Referral_Email__c = getInvalidEmail(c.SNSW_Referral_Email__c); 
                c.Manager_Email__c = getInvalidEmail(c.Manager_Email__c); 
                c.Last_Queue_Assigned_Email__c = getInvalidEmail(c.Last_Queue_Assigned_Email__c); 
                c.PBLROperator_Email_Address__c = getInvalidEmail(c.PBLROperator_Email_Address__c); 
                c.High_Priority_Train_Recepient__c = getInvalidEmail(c.High_Priority_Train_Recepient__c); 
                if(Test.isRunningTest() && toggle){
                    c.Bus_driver_identification__c = 'TextmoreThan10Chars';
                    toggle = false;
                }
                lCases.add(c);
            }
            
        }
        
        if(!lCases.isEmpty()){
            Database.SaveResult[] updateResultList =  Database.update(lCases, false);
            
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
                log.Source__c = 'MaskCaseDetailsBatch';
                log.Source_Function__c = 'execute';
                lAppLogs.add(log);
            }
            Database.insert(lAppLogs, false) ;
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
        mail.setSubject('Case masking batch completed');
        String bodyText = 'BATCH MaskCaseDetailsBatch Summary:\n\n';
        bodyText = bodyText + 'Number of total records: ' + (successRecCount + failedRecCount);
        bodyText = bodyText + '\n\tSuccessfully updated records: ' + successRecCount;
        bodyText = bodyText + '\n\tFailed to update records: ' + failedRecCount;
        
        if(!lExceptions.isEmpty()){
            bodyText = bodyText + '\n\nError Summary\n';
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