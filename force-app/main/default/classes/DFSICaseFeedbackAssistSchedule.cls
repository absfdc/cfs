/*
Date        :December 2017 
Description :Schedule Class for FeedbackAssist. Class to be run as Feedback Site Guest User
*/
global class DFSICaseFeedbackAssistSchedule implements Schedulable {
    
    private static final String DFSI='DFSI';
    
    global static void execute(SchedulableContext SC) {
        try{
            DFSIFeedbackAssist.getDFSICases(getDFSIJobTime(DFSI).addhours(-1));
        }
        catch(Exception e){
            
            DFSICoreService.writeToApplicationLog('DFSICaseFeedbackAssistSchedule', //write to application log, stacktrace
                                                  'execute.getDFSICases',
                                                  e.getMessage(),
                                                  e,
                                                  'Error');
        }
        //commented because its not creating cases when there is an error with attachments
        try{
            DFSISyncCaseAttachments ds= new DFSISyncCaseAttachments();
            ds.startBatch(); 
        }
        catch(Exception e){
            DFSICoreService.writeToApplicationLog('DFSICaseFeedbackAssistSchedule', //write to application log, stacktrace
                                                  'execute.DFSISyncCaseAttachments',
                                                  e.getMessage(),
                                                  e,
                                                  'Error');
        }
        
    }
    
    //method to get the latest datetime of the last job run
    private static Datetime getDFSIJobTime(string methodName){
        Datetime dt = DFSIScheduledJobRun__c.getValues(methodName).LastJobEndTime__c; 
        
        return (dt==NULL?Datetime.now().adddays(-1):dt);
    }
}