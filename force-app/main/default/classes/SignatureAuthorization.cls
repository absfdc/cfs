public class SignatureAuthorization implements BatchExecutor.CustomBatchable{
  
    private List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
      
    public void execute(List<Signature_Authorisation__c > targetObjectData) {
         
        List<Signature_Authorisation__c > authorizationRecordToDelete = new List<Signature_Authorisation__c>();
        
        for(Signature_Authorisation__c  getAuthorizationRecord : targetObjectData){
            authorizationRecordToDelete.add(getAuthorizationRecord);
        }
        system.debug('Signature Authorisation records to delete :: ' + authorizationRecordToDelete );
        if(authorizationRecordToDelete.size() > 0)
            delete authorizationRecordToDelete;         

    }
    
    public void finish() {
        
        DateTime currentDateTime = System.Now();
        DateTime nextScheduleDateTime = currentDateTime.addMinutes(1);
        
        String day = string.valueOf(nextScheduleDateTime.day());
        String month = string.valueOf(nextScheduleDateTime.month());
        String hour = string.valueOf(nextScheduleDateTime.hour());
        String minute = string.valueOf(nextScheduleDateTime.minute());
        String year = string.valueOf(nextScheduleDateTime.year());
               
        String strJobName = 'Job-DeleteSignatureAuthorisation' + System.Now().Format();
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        if( !Test.isRunningTest() )
            System.schedule(strJobName, strSchedule, new ScheduleDeleteSignatureAuthorization());
        
    }  
    
}