/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Extension class for displaying parent attachments on the child action plan
Test Class:    NewActionPlanAttachment_CX_Test
History
27/06/2015     Manish Damle       Created
-----------------------------------------------------------------------------------*/
public without sharing class ParentNoteOrAttachmentViewer_CX {
	private string childActionPlanId;
    public list <AP_NoteOrAttachment__c> attachments {get;set;}
    
    public ParentNoteOrAttachmentViewer_CX(ApexPages.StandardController controller)  {
        childActionPlanId = ApexPages.currentPage().getParameters().get('id');
        attachments = new list <AP_NoteOrAttachment__c>();
    }
    
    public PageReference init() {
        try {
            if(childActionPlanId == null || childActionPlanId == '') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid Parameters'));
                return null;
            }
            
            Action_Plan__c childActionPlan = [Select Id, Parent_Action_Plan__c From Action_Plan__c Where Id =: childActionPlanId limit 1];
            
            if(childActionPlan != null && childActionPlan.Parent_Action_Plan__c != null) {
                attachments = [Select Id, Name, Note_Attachment__r.Name, Note_Attachment__r.Privacy__c, Note_Attachment__r.View__c, Note_Attachment__r.RecordType.Name, Note_Attachment__r.Requires_Printing__c 
                               From  AP_NoteOrAttachment__c 
                               Where Action_Plan__c =: childActionPlan.Parent_Action_Plan__c And Note_Attachment__r.RecordType.Name =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT] ;
            }
        }catch(Exception e) {
            system.debug('----Exception Parent Attachments------'  + e.getMessage() + '---' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while fetching attachments'));
            return null;
        }
        return null;
    }
}