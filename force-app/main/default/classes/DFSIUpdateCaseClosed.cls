/*
Date        :December 2017 
Description :Update Case status to DFSI whenever Case is Closed in transportnsw org
*/
public class DFSIUpdateCaseClosed {
    @InvocableMethod(label='Update DFSI Case' description='Updates Case in DFSI when a Case is Closed in Transport')
    public static void updateCase(List<ID> ids) {
        try{
            List<String> CaseNumbers = new List<String>();
            
            DFSIUpdateCaseFutureCallout updateJob = new DFSIUpdateCaseFutureCallout(ids);
            ID jobID = System.enqueueJob(updateJob);// enqueue the job for processing
        }
        catch(Exception e){
            DFSICoreService.writeToApplicationLog('DFSIUpdateCaseClosed', //write to application log, stacktrace
                                                  'updateCase',
                                                  e.getMessage(),
                                                  e,
                                                  'Error');
        }
    }
}