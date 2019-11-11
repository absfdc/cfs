/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    utility class for creating attachments for the cases generated from webform
Inputs:         "caseRecord" - instance of case which needs to be associated with the attachments
                "filesToAttach" list of attachments that needs to be created on case
Test Class:     WebToCaseAttachmentCreator_Test
History:
<Date>          <Authors Name>      <Brief Description of Change>
26/04/2016      Deepak Soni         Changes class to without sharing, so that attachments created by Feedback Site guest user can be shared with 
                                    SNSW. With Sharing, attachments can not be shared with SNSW as Case reassigned to Serco user after creation 
                                    and guest user do have access on that case any more
                                    
12/09/2016      Arxxus              Updated to include method that inserts custom attachment (actual attachment place holders), uploaded by the user 
                                    from min cor api on case
                                    
15/06/2017      Ian Fitzgerald      Added new constructor that takes a list of the original filenames as a parameter.  
                                    Updated createCaseCustAttachmentOnly to use list of the original filenames to populate File_Name__c                              
------------------------------------------------------------*/
public without sharing class WebToCaseAttachmentCreator {

    private Case caseRecord;
    private List<Attachment> filesToAttach;
    private List<String> fileNames;
    private final Set<String> allowedFileExtensions;
    
    public WebToCaseAttachmentCreator(Case caseRecord, List<Attachment> filesToAttach) {
        if(caseRecord == null || filesToAttach == null || filesToAttach.isEmpty()) {
            throw new InvalidParameterException('Failed to create attachments for case. Either invalid case or attachment details received.');
        }
        this.caseRecord = caseRecord;
        this.filesToAttach = filesToAttach;
        Map<String, AllowableFileExtensions__c> fileExtensions = AllowableFileExtensions__c.getAll();
        allowedFileExtensions = new Set<String>();
        allowedFileExtensions.addAll(fileExtensions.keySet());
    }
    
    /*------------------------------------------------------------
    Author:         Ian Fitzgerald 
    Date:           Jun/15/2017
    Description:    Pass list of original filenames to keep track of file names > 80 chars 
    ------------------------------------------------------------*/
    public WebToCaseAttachmentCreator(Case caseRecord, List<Attachment> filesToAttach, List<String> fileNames) {
    	this(caseRecord, filesToAttach);
        this.fileNames= fileNames;
    }
    
       /*------------------------------------------------------------
    Author:         Dipankar Barman
    Company:        Salesforce.com
    Description:    Function inserts custom attachment (actual attachment place holders), uploaded by the user from min cor api on case.
    Inputs:         
    Returns:        
    History:
        Updated by Ian Fitzgerald Jun/15/2017 
            -Added retrieving original file name from fileNames list so that file names > 80 chars are tracked
    ------------------------------------------------------------*/  
    public List<NoteOrAttachment__c> createCaseCustAttachmentOnly() {
        List<RecordType> customAttachmentRecordType = [SELECT Id FROM RecordType WHERE DeveloperName =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT LIMIT 1];
        if(customAttachmentRecordType.isEmpty()) {
            return null;
        }
        Map<Integer, Attachment> attachmentMap = new Map<Integer, Attachment>();
        Map<Integer, NoteOrAttachment__c> customAttachmentMap = new Map<Integer, NoteOrAttachment__c>();
        system.debug('createCaseCustAttachmentOnly :: ' + filesToAttach);
        for(Integer i = 0; i < filesToAttach.size(); i++) {
            if( isAllowableFile(filesToAttach[i].Name)) {
                filesToAttach[i].ParentId = caseRecord.Id;
                
                NoteOrAttachment__c customAttach = new NoteOrAttachment__c();
                customAttach.Case__c = caseRecord.Id;
                customAttach.RecordTypeId = customAttachmentRecordType[0].Id;
                customAttach.Name = filesToAttach[i].Name;
                if (fileNames!=null && fileNames.size()>0){
                    customAttach.File_Name__c = fileNames[i];
                } else{
                    customAttach.File_Name__c = filesToAttach[i].Name;   
                }             
                customAttach.OwnerId = caseRecord.OwnerId;
                customAttachmentMap.put(i,customAttach);
            }
        }
        if(!customAttachmentMap.isEmpty()) {
            insert customAttachmentMap.values();
        }
        return customAttachmentMap.values();
    }
        
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Salesforce.com
    Description:    Function inserts attachments uploaded by the user on case.
    Inputs:         
    Returns:        
    History:
    ------------------------------------------------------------*/  
    public void createCaseAttachment() {
        List<RecordType> customAttachmentRecordType = [SELECT Id FROM RecordType WHERE DeveloperName =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT LIMIT 1];
        if(customAttachmentRecordType.isEmpty()) {
            return;
        }
        Map<Integer, Attachment> attachmentMap = new Map<Integer, Attachment>();
        Map<Integer, NoteOrAttachment__c> customAttachmentMap = new Map<Integer, NoteOrAttachment__c>();
        
        for(Integer i = 0; i < filesToAttach.size(); i++) {
            if(filesToAttach[i].body != null && isAllowableFile(filesToAttach[i].Name)) {
                filesToAttach[i].ParentId = caseRecord.Id;
                
                NoteOrAttachment__c customAttach = new NoteOrAttachment__c();
                customAttach.Case__c = caseRecord.Id;
                customAttach.RecordTypeId = customAttachmentRecordType[0].Id;
                customAttach.Name = filesToAttach[i].Name;
                customAttach.File_Name__c = filesToAttach[i].Name;                
                
                attachmentMap.put(i, filesToAttach[i]);
                customAttachmentMap.put(i,customAttach);
            }
        }
        
        if(!attachmentMap.isEmpty()) {
            insert customAttachmentMap.values();
            for(Integer attachIndex : attachmentMap.keySet()) {
                attachmentMap.get(attachIndex).ParentId = customAttachmentMap.get(attachIndex).Id;
            }
            insert attachmentMap.values();
            
            for(Integer attachIndex : attachmentMap.keySet()) {
                customAttachmentMap.get(attachIndex).Attachment__c = attachmentMap.get(attachIndex).Id;
                customAttachmentMap.get(attachIndex).OwnerId = caseRecord.OwnerId;
            }
            update customAttachmentMap.values();
        }
    }
    
    private Boolean isAllowableFile(String filename) {
        if(!String.isBlank(filename) && filename.lastIndexOf('.') > -1) {
            String extension = filename.substring(filename.lastIndexOf('.'), filename.length());
            if(allowedFileExtensions.contains(extension.toLowerCase())) {
                return true;
            }            
        }
        return false;        
    }
    
    public class InvalidParameterException extends Exception {}
}