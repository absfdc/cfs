public without sharing class KnowledgeArticleToAttachmentConverter {
	/*---------------------------------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   This method is responsible for converting the Case Articles to
	               NoteOrAttachment records whenever User clicks on Manager Supporting
	               Documents button.
	               
	Test Class:    MassEditAttachment_CX_Test
	History
	<Date>         <Authors Name>     <Brief Description of Change>
	22/07/2015     Manish Damle       Created
	-----------------------------------------------------------------------------------------*/
	public void convert(list <NoteOrAttachment__c> existingNoteOrAttachments, Case caseRecord) {
		try {
			set <Id> articleIds = new set <Id>();
	        map <String, NoteOrAttachment__c> kaIdVsAttachment = new map <String,NoteOrAttachment__c> ();
	        map <String, Attachment> attachments = new map <String, Attachment>();
	        map <String, NoteOrAttachment__c> customAttachments = new map <String, NoteOrAttachment__c>();
	        Id attachmentRecordTypeId = [Select Id 
                                         From RecordType 
                                         Where SObjectType = 'NoteOrAttachment__c' 
                                         And DeveloperName =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT].Id; 
            
	        for(NoteOrAttachment__c noteOrAttachment : existingNoteOrAttachments) {
	        	if(noteOrAttachment.CaseArticle__c != null)
	            	kaIdVsAttachment.put(noteOrAttachment.CaseArticle__c, noteOrAttachment);
	       }

	        for(CaseArticle ca: [Select Id, KnowledgeArticleId From CaseArticle Where CaseId =: caseRecord.Id]) {
	            articleIds.add(ca.KnowledgeArticleId);
	        }
	        
	        system.debug('----Case Articles----' + articleIds);
	        //NOTE: We can not bind variable with PublishStatus and Language field on KAV. We must use direct values.
	        for(SignedResponse__kav signedResponse : [Select Id,Title, UrlName, ArticleNumber, Summary, KnowledgeArticleId, 
                                                      		 SignedResponse__Name__s, SignedResponse__ContentType__s, SignedResponse__Body__s 
	                                                  From SignedResponse__kav 
	                                                  Where PublishStatus = 'Online' 
	                                                  And language = 'en_US' 
	                                                  And IsLatestVersion = true 
	                                                  And KnowledgeArticleId IN: articleIds]) {

	            system.debug('----Article----' + signedResponse.SignedResponse__Name__s + '---Id---' + signedResponse.Id + '---Number--' + signedResponse.ArticleNumber);
	            
	            if(signedResponse.KnowledgeArticleId != null && !kaIdVsAttachment.containsKey(signedResponse.KnowledgeArticleId)) {
	                attachments.put(signedResponse.KnowledgeArticleId + '-' + signedResponse.SignedResponse__Name__s, 
	                				new Attachment(Name = signedResponse.KnowledgeArticleId + '-' + signedResponse.SignedResponse__Name__s,
                                                   Body = signedResponse.SignedResponse__Body__s,
                                                   ContentType = signedResponse.SignedResponse__ContentType__s));

	                customAttachments.put(signedResponse.KnowledgeArticleId + '-' + signedResponse.SignedResponse__Name__s, 
	                	            	  new NoteOrAttachment__c(Name = signedResponse.SignedResponse__Name__s,
		                                                          Privacy__c = GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD,
		                                                          Case__c = caseRecord.Id,
		                                                          OwnerId = caseRecord.OwnerId,
		                                                          CaseArticle__c = signedResponse.KnowledgeArticleId,
		                                                          RecordTypeId = attachmentRecordTypeId));
	            }
	        }

	        system.debug('----Custom Attachments----' + customAttachments.size());
	        if(customAttachments.size() > 0) {
	            insert customAttachments.values();
	            for(String fileName : customAttachments.keySet()) {
	                if(attachments.containsKey(fileName) 
	                    && customAttachments.get(fileName) != null 
	                    && customAttachments.get(fileName).Id != null) {
	                    attachments.get(fileName).ParentId = customAttachments.get(fileName).Id;
	                }
	            }
	            
	            insert attachments.values();
	            
	            for(Attachment att: attachments.values()) {
	                if(customAttachments.containsKey(att.Name) 
	                   && customAttachments.get(att.Name) != null 
	                   && customAttachments.get(att.Name).Id != null) {
	                    customAttachments.get(att.Name).Attachment__c = att.Id;
	                    customAttachments.get(att.Name).ContentType__c = att.ContentType;
	                }
	            }
	            
	            update customAttachments.values();
	        }
        }Catch(Exception e){
        	System.debug('----@Kav To Attachment Conversion Failed-----' + e.getMessage() + '--LINE--' + e.getLineNumber());
        	//Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            Throw(e);
        }
	}
}