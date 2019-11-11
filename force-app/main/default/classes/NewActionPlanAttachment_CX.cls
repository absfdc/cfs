/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Extension class for New Note or attachment from action plan record.
Test Class:    NewActionPlanAttachment_CX_Test
History
23/04/2015     Manish Damle       Created
04/05/2015     Manish Damle       Updated the code to redirec user to attachment/note record
                                  Separate pages added for attachment and note.
								  Open in subtab and close subtab functionality 
								  added to the pages
-----------------------------------------------------------------------------------*/  
public with sharing class NewActionPlanAttachment_CX {
    
    //Custom Attachment object record to be created.
    //This record will be parent record for the salesforce standard attachment
    public NoteOrAttachment__c customAttachment {get;set;}
    public transient String attachmentIdToBeCloned {get;set;}
    public transient String attachmentIdToBeDeleted {get;set;}
    private String recordType;
    
    //Indicates whether error occcured or not
    public boolean errorOnPage {get;set;}
    
    //Attachment record to be created in the salesforce
    public Attachment sfattachment {get { if(sfattachment == null) {
    									    sfattachment = new Attachment();
    									  }
                                          return sfattachment;
                                         } set;}

    //For pagination
    public Integer pageSize {get;set;}
    public Integer noOfAttachments {get;set;}    
	public Action_Plan__c actionPlan {get;set;} 
    
    private map <String, String> recordTypes;
    
    //Case Attachment List
    public map <String, CaseAttachment> caseAttachments;
    //Default constructor
    public NewActionPlanAttachment_CX(ApexPages.StandardController controller) {
        noOfAttachments = 0;
        customAttachment = new NoteOrAttachment__c(Privacy__c = 'Standard');
        actionPlan = (Action_Plan__c) controller.getRecord();
        actionPlan = [Select Id, Name, Parent_Case__c From Action_Plan__c Where Id =: actionPlan.Id];
        recordType = ApexPages.currentPage().getParameters().get('display') != null ? ApexPages.currentPage().getParameters().get('display') :  'Attachment';
        recordTypes = new map <String, String>();
        for(RecordType rt : [Select Id, DeveloperName, Name 
                             From RecordType 
                             Where SObjectType = 'NoteOrAttachment__c']) {
            recordTypes.put(rt.DeveloperName, rt.Id);
        }
    }
    
	/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will save or update the custom attachment record. 
				   This will also check whether name of the attachment is provided or not.
				   Name is nothing but a title for an attachment
    History
    23/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/    
    public PageReference saveAttachment() {
		SavePoint sp = Database.setSavepoint();        
        try {
            if(customAttachment.Privacy__c == null || customAttachment.Privacy__c == '') {
           		customAttachment.Privacy__c = 'Standard';
        	}
  			customAttachment.RecordTypeId = recordTypes.get('Attachment');
            upsert customAttachment;
            
            AP_NoteOrAttachment__c  apAtt = new AP_NoteOrAttachment__c(Action_Plan__c = actionPlan.Id, Note_Attachment__c  = customAttachment.Id);
            upsert apAtt;
            
            system.debug('-----Attachment---' + sfattachment);
            sfattachment.OwnerId = UserInfo.getUserId();
        	sfattachment.ParentId = customAttachment.Id; 
        	sfattachment.IsPrivate = false;
            upsert sfattachment;
            
            customAttachment = [Select Id, ContentType__c, Name, Case__c, Attachment__c, View__c, Privacy__c, RecordType.Name, RecordTypeId 
                                From NoteOrAttachment__c 
                                Where Id =: customAttachment.Id limit 1];
            String attId = customAttachment.Id;
            customAttachment.Name = customAttachment.Name == attId.substring(0, 15) ? sfattachment.Name : customAttachment.Name;
            customAttachment.Attachment__c = sfattachment.Id;
            customAttachment.ContentType__c = sfattachment.ContentType;
            update customAttachment;
            sfattachment.body = null;
            return new pageReference('/' + apAtt.Id);
        }catch(Exception e) {
             Database.rollback(sp); 
             System.debug('-----New Attachment Creation Failed-----'+ e.getMessage() + '--LINE--' + e.getLineNumber());
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while creating attachment'));
             sfattachment.body = null;
             customAttachment.Id = null;
        }
    	return null;    
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will allow user to create not under action plan
    History
    24/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/ 
    public PageReference saveNote() {
		SavePoint sp = Database.setSavepoint();        
        try {
            if(!validateDetails()) return null;
  			customAttachment.RecordTypeId = recordTypes.get('Note');
            insert customAttachment;
            
            AP_NoteOrAttachment__c  apAtt = new AP_NoteOrAttachment__c(Action_Plan__c = actionPlan.Id, Note_Attachment__c  = customAttachment.Id);
            insert apAtt;
            return new pageReference('/' + apAtt.Id);
        }catch(Exception e) {
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while creating attachment'));
             Database.rollback(sp);
             return null;
        }
        return null;
    }
    
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Required field validation
    History
    24/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/     
    private boolean validateDetails() {
        system.debug('------Name----' + customAttachment.Name);
        if(customAttachment.Name == '' || customAttachment.Name == null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please enter title'));
            sfattachment.body = null;
            return false;
        }
        
        if(customAttachment.Privacy__c == null || customAttachment.Privacy__c == '') {
           customAttachment.Privacy__c = 'Standard';
        }
        return true;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   If user cancels the attachment creation then he/she will be redirected
				   to the action plan detail page
    History
    23/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/  
    public PageReference returnToActionPlanDetailsPage() {
    	return new PageReference('/' + actionPlan.Id);    
    }    
   
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create a juction object under Action Plan and it will 
				   add reference to the selected NoteOrAttachment.
    History
    23/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public PageReference getAttachmentFromTheCase() {
        if(attachmentIdToBeCloned != null) {
            system.debug('-----Attachment To Copied------'  + attachmentIdToBeCloned);
            list <AP_NoteOrAttachment__c> existingAttachments = [Select Id 	
                                                                 From AP_NoteOrAttachment__c 
                                                                 Where Note_Attachment__c =: attachmentIdToBeCloned  
                                                                   And Action_Plan__c =: actionPlan.Id limit 1];
            
        	Database.SaveResult result = Database.insert(new AP_NoteOrAttachment__c(Action_Plan__c = actionPlan.Id, Note_Attachment__c  = attachmentIdToBeCloned), false);
            if(result.isSuccess()) {
                return null;
            }
            
            system.debug('----Exception------'  + result);
        } 
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Unable to create attachment from existing attachments.'));
        return null;
    }
    
   	/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Delete attachment/note
    History
    22/05/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public PageReference deleteAttachment() {
        if(attachmentIdToBeDeleted != null) {
            Database.DeleteResult result = Database.delete(new AP_NoteOrAttachment__c(Id = attachmentIdToBeDeleted), false);
             if(result.isSuccess()) {
                return null;
            }
        }
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Unable to delete existing note/attachment.'));
        return null;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Standard set controller for NoteOrattachment
    History
    23/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    private ApexPages.StandardSetController setCon {
        get {
            if(setCon == null && actionPlan.Parent_Case__c != null){
                pageSize = 5;
                string queryString = 'Select Id, Name, Case__c, Privacy__c, View__c, Requires_Printing__c, Sequence__c, RecordType.Name, RecordTypeId From NoteOrAttachment__c '+ 
                    			     'Where Case__c = \'' + actionPlan.Parent_Case__c + '\' And RecordTypeId =\'' + recordTypes.get(recordType) + '\'';
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(pageSize);
                noOfAttachments = setCon.getResultSize();
                system.debug('---noOfAttachments---' + noOfAttachments);
            }
            return setCon;
        } set;
    }
    
     
    /*------Custom Pagination--------*/
    //Wrapper class to hold a flag and Note / Attachment object
    public class CaseAttachment {
        public boolean added {get;set;}
        public NoteOrAttachment__c noteOrAttachment {get;set;}
        public AP_NoteOrAttachment__c apNoteOrAttachment {get;set;}
        public CaseAttachment(boolean added, NoteOrAttachment__c noteOrAttachment, AP_NoteOrAttachment__c apNoteOrAttachment) {
			this.added = added;
            this.noteOrAttachment = noteOrAttachment;
            this.apNoteOrAttachment = apNoteOrAttachment;
        }
    }
    
    // returns a list of wrapper objects for the sObjects in the current page set
    public map <String, CaseAttachment> getCaseAttachments() {
      	caseAttachments = new map <String, CaseAttachment>();
        map<Id, AP_NoteOrAttachment__c> existingAttachments = new map <Id, AP_NoteOrAttachment__c>();
        //Fetch existing Note OR attachments on the Action Plan.
        for(AP_NoteOrAttachment__c apNoteOrAttachment : [Select Id, Note_Attachment__c From AP_NoteOrAttachment__c Where Action_Plan__c =: actionPlan.Id]) {
            if(apNoteOrAttachment.Note_Attachment__c != null)
            	existingAttachments.put(apNoteOrAttachment.Note_Attachment__c, apNoteOrAttachment);
        }
        system.debug('---existingAttachments---' + existingAttachments);
        if(setCon != null) {       
            for(NoteOrAttachment__c noteOrAttchment : (list <NoteOrAttachment__c>) setCon.getRecords()) {
                if(existingAttachments.containsKey(noteOrAttchment.Id)) {
                    caseAttachments.put(noteOrAttchment.Id, new CaseAttachment(true, noteOrAttchment, existingAttachments.get(noteOrAttchment.Id)));
                    system.debug('---KEY---' + noteOrAttchment.Id + '--TRUE---');
                } else {
                    caseAttachments.put(noteOrAttchment.Id, new CaseAttachment(false, noteOrAttchment, new AP_NoteOrAttachment__c()));
                    system.debug('---KEY---' + noteOrAttchment.Id + '--FALSE---');
                }
            }
        }
        system.debug('---caseAttachments---' + caseAttachments);
        return caseAttachments;
    }
    
    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }

    // returns the page number of the current page set
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }

    // returns the first page of records
     public void first() {
         setCon.first();
     }

     // returns the last page of records
     public void last() {
         setCon.last();
     }

     // returns the previous page of records
     public void previous() {
         setCon.previous();
     }

     // returns the next page of records
     public void next() {
         setCon.next();
     }
}