/*
Date        :December 2017 
Description :Feedback Assist Class for callout to DFSI Cases. Class to be run as Feedback Site Guest User
*/

public with sharing class DFSIFeedbackAssist implements CaseAttachmentService{
    
    //application logging messages
    private static List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    
    private static final string GETCASES = 'getCases';  //local constants
    private static final String GET_ATTACHMENTS_DATA = 'GET_ATTACHMENTS_DATA'; 
    private static final String DFSI = 'DFSI';  
    
    
    @future(callout=true)//Method to call DFSI Cases which are greater than the timestamp
    public static void getDFSICases(DateTime dtTimeStamp){//The timestamp is passed by the scheduled job,
        //timestamp in this format "2017-09-12+00:00:00"
        
        try{
            
            HTTPResponse res=DFSICoreService.doDFSICallout(
                DFSICoreService.getDFSIMethodURL(GETCASES)+'?timeStamp='+
                String.valueof(dtTimeStamp).replaceall(' ','+'),'GET'
            );
            
            String JSON=res.getbody();
            System.debug('JSON::' + JSON);
            boolean boolNoError = DFSIJSONCase.parse(JSON);//parse response from callout
            if(boolNoError == true)            
            setDFSIJobTime(DFSI);//setting job completion time custom setting
            
        } catch(Exception e) {
            DFSICoreService.writeToApplicationLog('DFSIFeedbackAssist', //write to application log, stacktrace
                                                  'getDFSICases',
                                                  e.getMessage(),
                                                  e,
                                                  'Error');
        }
    }
    
    //method to get the attachments
    public Map<String, Attachment> getAttachments(Case scope){
        
        String endpoint = getDFSIAttachmentDataURL(scope);
        
        HTTPResponse response=DFSICoreService.doDFSICallout(endpoint, 'POST', 'application/json; charset=UTF-8');
        
        if(response.getStatusCode() == 200) {
            return getAttachments(response.getBody());
            
        } else if(response.getStatusCode() == 400) {
            throw new DFSIException('Error::{' + scope.Id +'}::' + response.getBody());
        } else {
            throw new DFSIException('Error::{' + scope.Id +'}::' + response.getStatusCode() + ' ' + response.getStatus());
        }
        
        return null;
    }
    
    private Map<String, Attachment> getAttachments(String jsonStr) {
        List<DFSIAttachment> attachments = DFSIAttachment.parse(jsonStr);
        
        if(attachments == null)
            return null;
        
        
        Map<String, Attachment> attachmentToAdd = new Map<String, Attachment>();
        
        
        for(DFSIAttachment dfsiAtt: attachments) {
            attachmentToAdd.put(dfsiAtt.Id, dfsiAtt.convert());
        }
        
        return attachmentToAdd;
        
    }
    
    public Map<String, List<NoteOrAttachment__c>> getAttachmentMetadata(List<Case> scope) {
        String endpoint = getDFSIAttachmentURL(scope);
        
        system.debug('In getattachment');
        HTTPResponse response=DFSICoreService.doDFSICallout(endpoint, 'POST', 'application/json; charset=UTF-8');
        
        system.debug('response is '+response);
        
        if(response.getStatusCode() == 200) {
            return getAttachmentsMetaData(response.getBody());
            
        } else if(response.getStatusCode() == 400) {
            throw new DFSIException('Error::{' + getCaseIds(scope) +'}::' + response.getBody());
        } else {
            throw new DFSIException('Error::{' + getCaseIds(scope) +'}::' + response.getStatusCode() + ' ' + response.getStatus());
        }
        
        return null;
    }
    
    public Map<String, List<NoteOrAttachment__c>> getAttachmentsMetadata(String jsonString) {
        
        System.debug('DFSIFeedbackAssist::getAttachmentsMetadata::Start');
        List<DFSIAttachmentMetadata> attachments = DFSIAttachmentMetadata.parse(jsonString);
        
        if(attachments == null)
            return null;
        
        
        Map<String, List<NoteOrAttachment__c>> attachmentListMap = new Map<String, List<NoteOrAttachment__c>>();
        
        System.debug('DFSIFeedbackAssist::getAttachmentsMetadata::Entering Loop');
        
        for(DFSIAttachmentMetadata dfsiAtt: attachments) {
            
            List<NoteOrAttachment__c> attachmentList = attachmentListMap.get(dfsiAtt.ParentId);
            if(attachmentList == null) {
                attachmentList = new List<NoteOrAttachment__c>();
                attachmentListMap.put(dfsiAtt.ParentId, attachmentList);
            }
            
            attachmentList.add(dfsiAtt.convert());
        }
        
        return attachmentListMap;
        
    }
    
    String getCaseIds(List<Case> cases) {
        String result = '';
        for(Case c: cases) {
            result += (',' + c.DFSICaseID__c);
        }
        return result.substring(1);
        
    }
    
    @TestVisible
    private String getDFSIAttachmentDataURL(Case scope) {
        return DFSICoreService.getDFSIMethodURL(GET_ATTACHMENTS_DATA) + '?CaseId='+scope.DFSICaseID__c + '&Action=GetAttachmentDataByCaseId';
        
    }
    @TestVisible
    private String getDFSIAttachmentURL(List<Case> scope) {
        return DFSICoreService.getDFSIMethodURL(GET_ATTACHMENTS_DATA) + '?CaseIds='+getCaseIds(scope) + '&Action=GetAttachmentsByCaseIds';
        
    }
    //this method is to set the next scheduled time for batch job
    private static void setDFSIJobTime(string methodName){
        try{
            DFSIScheduledJobRun__c dt= DFSIScheduledJobRun__c.getValues(methodName);
            if(dt!=NULL){
                dt.LastJobEndTime__c=Datetime.now();
            }
            upsert dt;
        }
        catch(Exception e){
            DFSICoreService.writeToApplicationLog('DFSIFeedbackAssist', //write to application log, stacktrace
                                                  'setDFSIJobTime',
                                                  e.getMessage(),
                                                  e,
                                                  'Error');
        }
    } 
    
}