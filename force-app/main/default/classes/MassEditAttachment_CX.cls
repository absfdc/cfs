/*-----------------------------------------------------------------------------------------
Author:       Manish Damle
Company:      Arxxus.com
Description:  Case Controller extension to control the Mass update 
              of attachments which are ready for printing

Test Class:   MassEditAttachment_CX_Test
History
8/06/2015     Manish Damle     created
9/02/2017     Arxxus           updated - to enable roads, transport and OOS DLO/PA 
                               and office managers to enable attachment mass editing.
20/09/2017	  Arxxus 		   Oct 2017 Release changes - addded Generate combined PDF link on page
-------------------------------------------------------------------------------------------*/
public with sharing class MassEditAttachment_CX {
    
    public case caseRecord {get;set;}
    transient public String attachmentSelected {get;set;}
    public list <NoteOrAttachment__c> attachments {get; set;}
    public String congaURL {get;set;}
    public boolean enableSaveAndReordering {get;set;}
    public boolean enablePrintSelected {get;set;}
    public Boolean enablePrintCombinedPDF {get;set;} // Oct 2017 Release
    public String combinedPDFCongaURL {get;set;}
    private Id caseId = null;
    
    //Default constructor
    public MassEditAttachment_CX(ApexPages.StandardController controller) {
        caseId = (String) controller.getRecord().Id;
        attachmentSelected = null;
    }
    
    /*-------------------------------------------------------------------------------------------
    Author:       Manish Damle
    Company:      Arxxus.com
    Description:  This method is responsible for
                  1. Fetch the case details
                  2. Set flag enableSaveAndReordering
                     enableSaveAndReordering = true if Logged in user is MAGS
                     enableSaveAndReordering = false if logged in user is CRGS admin
    
    History
    8/06/2015     Manish Damle     created
    -------------------------------------------------------------------------------------------*/
    public PageReference init() {
        try {
            //if case id is null then throw an error
            if(caseId == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Invalid Parameters'));  
                return null;
            }
            
            //Get logged in user profile details
            Profile currentProfile = [Select Id, Name 
                                      From Profile 
                                      Where Id =: UserInfo.getProfileId() limit 1];
            
            List<User> currentUserRole = [Select Id, Role_Dev_Name__c from User where Id = : UserInfo.getUserId() limit 1];                          
            
            if(GlobalConstants.MAGS_PROFILE_NAMES.contains(currentProfile.Name) || currentProfile.Name == GlobalConstants.SYSTEM_ADMINISTRATOR_PROFILE_NAME) {
  
                if(GlobalConstants.CONGA_PRINT_ACCESS_ROLE_NAMES.contains(currentUserRole[0].Role_Dev_Name__c)){
                    enableSaveAndReordering = true;               
                    enablePrintSelected = true;
                }else {
                    enablePrintSelected = false;
                    enableSaveAndReordering = true;               
                }    
            } else {
                enableSaveAndReordering = false;               
                enablePrintSelected = true;
            }
    		/**
				Oct 2017 Generate Combined PDF link access to Profiles- MAGS Officers, Senior MAGS Officers, MAGS Editor, CRGS Super Admin
			*/
            if(GlobalConstants.MAGS_PROFILE_NAMES.contains(currentProfile.Name) || GlobalConstants.CRGS_PROFILE_NAME == currentProfile.Name) {
                enablePrintCombinedPDF = true; 
            } else{
                enablePrintCombinedPDF = false;
            }
            system.debug('---Current Profile---' + currentProfile.Name + '--' + currentUserRole[0].Role_Dev_Name__c +'--'+ enableSaveAndReordering + '--'+ enablePrintSelected);
    
            caseRecord = [Select Id, Status, RecordTypeId, OwnerId, Conga_Template_Id__c, RecordType.Name, Priority, CaseNumber 
                          From Case 
                          Where Id =: String.escapeSingleQuotes(caseId) limit 1]; 
            //Convert knowledge articles to NoteOrAttachment record              
            checkForExistingKnowledgeArticles();
            //Fetch all the attachments from the case
            attachments = fetchAttachmentsBySequence();
            //Generate the conga URL
            generateCongaURL();
            
            //oct 2017 combined pdf
            generateCombinedPDFCongaURL(caseRecord.CaseNumber);
        }Catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
        }
        return null;
    }
    
    /*-------------------------------------------------------------------------------------------
    Author:       Manish Damle
    Company:      Arxxus.com
    Description:  This method will generate the pdf from image attachment.
    
    History
    8/06/2015     Manish Damle     created
    -------------------------------------------------------------------------------------------*/    
    public PageReference generatePDF() {
        try {
            system.debug('--------------Attachment Selected------' + attachmentSelected);
            if(attachmentSelected != null) {
                //Fetch the custom NoteOrAttachment details for further processing
                NoteOrAttachment__c att = fetchAttachmentDetails();
                if(att.Attachment__c != null) {
                    Attachment sf_att = [Select Id, ContentType, Name, ParentId, Body 
                                         From Attachment 
                                         Where Id =: att.Attachment__c limit 1];
                    //Create name with .pdf extensio
                    String attachmentName = att.Name + GlobalConstants.EXTENSION_PDF;
                    
                    //Call ImageToPdf page and get the blob as pdf
                    PageReference pdf = Page.ImageTOPdf;
                    pdf.getParameters().put('id',sf_att.Id);
                    Blob body = null;

                    if(!Test.isRunningTest()) {
                      body = pdf.getContent();
                    } else {
                        body = Blob.valueOf('This is pdf content');
                    }
                    
                    //Create new attachment object under custom NoteOrAttachment
                    Attachment sf_pdf_att = new Attachment(ContentType = GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF, 
                                                           Name =  attachmentName, 
                                                           ParentId = sf_att.ParentId, Body = body);
                    insert sf_pdf_att;
                    
                    //Update the pdf attachment id on the parent record
                    att.PDF_Attachment__c = sf_pdf_att.Id;
                    update att;
                    
                    //Fetch all the attachments to refresh the UI with new updates
                    attachments = fetchAttachmentsBySequence();
                } else {
                    //If standard Attachment is  deleted and id is not present on the parent 
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Document not found.'));   
                }
            } else {
                 //If attachmentSelected is null that means selected attachment id was sent to server
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No document was selected'));
            }
        }catch(Exception e) {
            system.debug('--------------Error------' + e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Error occured while generating pdf'));
        }
        return null;
    }

    /*-------------------------------------------------------------------------------------------
    Author:       Manish Damle
    Company:      Arxxus.com
    Description:  This method will update the Sequence & Printing flag.
    
    History
    8/06/2015     Manish Damle     created
    -------------------------------------------------------------------------------------------*/    
    public PageReference updateDetails() {
        try {
            update attachments;
            //Fetch all the attachments to refresh the UI with new updates
            attachments = fetchAttachmentsBySequence();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'Document order updated successfully'));  
        } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Error in updating attachments'));     
        }
        return null;
    }
    
    /*-------------------------------------------------------------------------------------------
    Author:       Manish Damle
    Company:      Arxxus.com
    Description:  This method will fetch the Attachments from the 
                  case in asc order of sequence number
    
    History
    8/06/2015     Manish Damle     created
    -------------------------------------------------------------------------------------------*/
    private list <NoteOrAttachment__c> fetchAttachmentsBySequence() {
        list <NoteOrAttachment__c>  attachments = [Select Id, Name, RecordType.Name, RecordTypeId ,Attachment__c,Case__c, ContentType__c, 
                                                          CreatedDate,PDF_Attachment__c, Is_Image__c, File_Name__c,Privacy__c, Requires_Printing__c, 
                                                          Sequence__c, View__c, CaseArticle__c,Attachment_Id__c
                                                    From NoteOrAttachment__c 
                                                    Where Case__c =: caseRecord.Id 
                                                    And (  ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.PDF)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.JPG)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.PNG)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.JPEG) 
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.MSWORD)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.GIF)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.PPT)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.XLSX)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.XLX)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.PPTX)
                                                        OR ContentType__c LIKE: String.escapeSingleQuotes(GlobalConstants.WORD)
                                                        )
                                                    And RecordType.Name =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT order by Sequence__c]; 
        List <NoteOrAttachment__c> filteredAttachments = new List <NoteOrAttachment__c>();
        
        for(NoteOrAttachment__c tempAtt : attachments) {
         
         String attName = tempAtt.Name;
         
         if(!(attName.contains('response_') && tempAtt.ContentType__c == 'application/msword'))
          filteredAttachments.add(tempAtt);
        }     
        
        return filteredAttachments;
    }
    
    /*-------------------------------------------------------------------------------------------
    Author:       Manish Damle
    Company:      Arxxus.com
    Description:  This method will fetch the NoteOrAttachment details
    
    History
    8/06/2015     Manish Damle     created
    -------------------------------------------------------------------------------------------*/
    private NoteOrAttachment__c fetchAttachmentDetails() {
           NoteOrAttachment__c att = [Select Id, Name, RecordType.Name, RecordTypeId ,Attachment__c,Case__c, ContentType__c, 
                                             CreatedDate,PDF_Attachment__c,Is_Image__c, File_Name__c,Privacy__c, Requires_Printing__c, 
                                             Sequence__c, View__c, CaseArticle__c
                                      From NoteOrAttachment__c 
                                      Where Case__c =: caseRecord.Id 
                                      And Id =: attachmentSelected limit 1];
        return att;
    }
    

    /*-------------------------------------------------------------------------------------------
    Author:       Manish Damle
    Company:      Arxxus.com
    Description:  This method will create a NoteOrAttachment record 
                  on a case from the attached Knowledge article on a case.                  
    
    History
    6/07/2015     Manish Damle     created
    -------------------------------------------------------------------------------------------*/
    private void checkForExistingKnowledgeArticles() {
        list <NoteOrAttachment__c> existingNoteOrAttachments = fetchAttachmentsBySequence();
        KnowledgeArticleToAttachmentConverter kavConverter = new KnowledgeArticleToAttachmentConverter();
        kavConverter.convert(existingNoteOrAttachments, caseRecord);
    }

    /*-------------------------------------------------------------------------------------------
    Author:       Manish Damle
    Company:      Arxxus.com
    Description:  This method will generate conga merge URL.
                  Uses conga template and conga query objects.
    
    History
    8/06/2015     Manish Damle     created
    -------------------------------------------------------------------------------------------*/
    private void generateCongaURL() { 
        try {
            APXTConga4__Conga_Merge_Query__c congaQuery = [Select Id From APXTConga4__Conga_Merge_Query__c Where APXTConga4__Name__c =: GlobalConstants.CONGA_QUERY_NAME];
            /*Jan 12 2017 - Updating Conga URL - adding attachmentId parameter and assigning {QVar0} as values. SFCOE - 784*/
            congaURL = '&Qvar0Id='+ congaQuery.id + '&TemplateId='+ caseRecord.Conga_Template_Id__c + '&AttachmentId={QVar0}&ds7=3&BML=File+is+getting+generated.+Please+wait+...';   
            system.debug('-----Conga URL Generated------' + congaURL);
        }catch(Exception e) {
            system.debug('-----Conga URL NOT Generated------' + e.getMessage() + '---' + e.getLineNumber());
        }
    }
	
    /*-------------------------------------------------------------------------------------------
    Author:       Arxxus
    Description:  used to generate conga query for combined PDF
    
    History
    20/09/2017	  Arxxus Oct 2017 release added new method  
    -------------------------------------------------------------------------------------------*/
    private void generateCombinedPDFCongaURL(String caseNumber) { 
        try {
            APXTConga4__Conga_Merge_Query__c congaQuery = [Select Id From APXTConga4__Conga_Merge_Query__c Where APXTConga4__Name__c =: GlobalConstants.combinedPDFQ0];
            Id offsetQId = [Select Id From APXTConga4__Conga_Merge_Query__c Where APXTConga4__Name__c =: GlobalConstants.combinedPDFQ1].Id;
            String timestamp = String.valueOf(System.now());
			timestamp = timestamp.replace(':','-');
            timestamp = timestamp.replace(' ','+');
            timestamp = timestamp.substring(0,timestamp.length()-3);
            combinedPDFCongaURL = '&Qvar0Id='+ congaQuery.id + '&Qvar1Id='+offsetQId+'&templateId={Qvar1}'+'&AttachmentId={QVar0}&BML=File+is+getting+generated.+Please+wait+...'+'&ds7=3&OFN='+caseNumber+'_Combined+PDF_'+timestamp;   
            
            system.debug('-----combinedPDFCongaURL Generated------' + combinedPDFCongaURL);
        }catch(Exception e) {
            system.debug('-----Conga URL NOT Generated------' + e.getMessage() + '---' + e.getLineNumber());
        }
    }
   
}