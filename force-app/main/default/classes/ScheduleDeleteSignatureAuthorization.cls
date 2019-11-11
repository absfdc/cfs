global class ScheduleDeleteSignatureAuthorization implements Schedulable{
   
    public void execute(SchedulableContext ctx){
       
        System.debug('Time: '+System.now().addMinutes(-30).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        String dateTimeFormat = System.now().addMinutes(-30).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        String query = 'Select Id, Case_Id__c, CreatedDate FROM Signature_Authorisation__c WHERE CreatedDate < '+dateTimeFormat;
        
        if(!Test.isRunningTest())  {              
          Database.executeBatch(new BatchExecutor(new SignatureAuthorization(), query, null)); 
        }
    }
  
}