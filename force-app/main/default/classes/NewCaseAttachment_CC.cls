/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class is an extension  to the NoteOrAttachment Controller.
               This enable the user to create attachment with file uploaded in salesforce.
Test Class:    NewCaseAttachment_CX_Test
History
23/04/2015     Manish Damle       Created
-----------------------------------------------------------------------------------*/
public with sharing class NewCaseAttachment_CC {
    
    //Custom Attachment object record to be created.
    //This record will be parent record for the salesforce standard attachment
    public NoteOrAttachment__c customAttachment {get;set;}
    
    //Indicates whether error occcured or not
    public boolean errorOnPage {get;set;}
    
    //Attachment record to be created in the salesforce
    public Attachment sfattachment {
  		get {
            if (sfattachment == null)
                sfattachment = new Attachment();
                return sfattachment;
    	}
  		set;
  	}
    
    //Get the case Id from the URL
    private String caseId;
    
    //Default constructor
    public NewCaseAttachment_CC() {
    	customAttachment = new NoteOrAttachment__c();
        errorOnPage = false;
    }    
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will initialize the custom attachment object.
                   If wrong id is passed in url then it throws an errror on page
    
    History
    23/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public PageReference init() {
        caseId = ApexPages.currentPage().getParameters().get('cid');
        system.debug('------Case Id------' + caseId);

        if(caseId == null && caseId == '') {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Invalid Parameters'));   
            return null;
        }
       
        customAttachment.Case__c = caseId;
        customAttachment.RecordTypeId = getAttachmentRecordTypeId();  
        return null;
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
            upsert customAttachment;
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
            return returnToCaseDetailsPage();
        }catch(Exception e) {
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while creating attachment'));
             customAttachment.Id = null;
             sfattachment.body = null;
             Database.rollback(sp);
        }
    	return null;    
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   If user cancels the attachment creation then he/she will be redirected
				   to the case detail page
    History
    23/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/  
    public PageReference returnToCaseDetailsPage() {
    	return new PageReference('/' + customAttachment.Id);    
    }    
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   fetch the existing record type id of the record type Attachment.
    History
    23/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/    
    public Id getAttachmentRecordTypeId() {
       	RecordType tr = [Select Id From RecordType Where DeveloperName =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT limit 1];
        return tr.Id;
    } 
}