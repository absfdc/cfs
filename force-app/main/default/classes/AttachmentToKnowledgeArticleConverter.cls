/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class is responsible for converting the Attachment to Kav. (Knowledge Articles)
               When case look up or Category is changed then the ka is created.
History 
<Date>         <Authors Name>     <Brief Description of Change>
14/07/2015     Manish Damle       Created
-------------------------------------------------------------------------------------*/
public without sharing class AttachmentToKnowledgeArticleConverter {
	private TriggerParameters tp;
	//Default constructor
	public AttachmentToKnowledgeArticleConverter(TriggerParameters tp) {
		this.tp = tp;
	}

    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will convert the Attachment to KA
                   Considerations:
                   Attachment ContentType -> 'application/pdf'
				   Category Changed to Signed Response
                   Case Lookup changed
                   Attachment Id not null
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
	public void convert() {
		try {
			map <Id, SignedResponse__kav> customAttIdVsKav = new map <Id, SignedResponse__kav>();
			map <Id, NoteOrAttachment__c> kavIdVsCaseNumber = new map <Id, NoteOrAttachment__c>();
			map <Id, Id> attIdVsKavId = new map <Id, Id> ();
			set <Id> standardAttachmentIds = new set <Id>();

			list <SignedResponse__DataCategorySelection> dataCategorySelections = new list <SignedResponse__DataCategorySelection>();
			list <CaseArticle> caseArticles = new list <CaseArticle>();
			system.debug('-----@KAV Conversion---');
            if(tp.oldMap != null) {
                for(Id attId : (set <Id>) tp.newMap.keySet()) {
                    NoteOrAttachment__c oldAtt = (NoteOrAttachment__c) tp.oldMap.get(attId);
                    NoteOrAttachment__c newAtt = (NoteOrAttachment__c) tp.newMap.get(attId);
                    system.debug('-----@KAV Attachment Details---' + newAtt.Attachment__c + '---' + newAtt.Category__c + '---' + newAtt.Case__c + '---' + newAtt.ContentType__c);
                    if(newAtt.Attachment__c != null 
                        && newAtt.Category__c == GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE
                        && newAtt.Case__c != null
                        && newAtt.IsMinCorroRelated__c
                        && newAtt.ContentType__c == GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF) {
                        system.debug('-----@KAV Standard Attachment ID Found---');
                        standardAttachmentIds.add(newAtt.Attachment__c);
                    }	 
                }
            } 
            
			system.debug('-----@KAV Standard Attachments---' + standardAttachmentIds);
            
			map <Id, Attachment> standardAttachments = new map <Id, Attachment> ([Select Name, Body, ParentId, Id, OwnerId, ContentType 
																				  From Attachment
																	              Where Id IN: standardAttachmentIds]);
			//Only consider the attachments where CaseArticle__c is null. CaseArticle__c != null then Ka is already created.
			for(NoteOrAttachment__c att : (list <NoteOrAttachment__c>) tp.newList) {
				if(att.Attachment__c != null 
					&& standardAttachments.containsKey(att.Attachment__c) 
					&& standardAttachments.get(att.Attachment__c) != null 
					&& att.CaseArticle__c == null
					&& att.Case__c != null) {
					customAttIdVsKav.put(att.Id, getKArticleRecord(standardAttachments.get(att.Attachment__c), att.CaseNumber__c));	
				}
			}
			
            system.debug('-----@KAV Count---' + customAttIdVsKav.size());
			
            if(customAttIdVsKav.size() > 0) {
				//Insert Articles
				insert customAttIdVsKav.values();
				system.debug('-----@KAV Records Created---');
				for(Id attId : customAttIdVsKav.keySet()) {
					if(tp.newMap.containsKey(attId) 
						&& tp.newMap.get(attId) != null 
						&& customAttIdVsKav.get(attId) != null
						&& customAttIdVsKav.get(attId).Id != null) {
						kavIdVsCaseNumber.put(customAttIdVsKav.get(attId).Id, (NoteOrAttachment__c) tp.newMap.get(attId));
						attIdVsKavId.put(attId, customAttIdVsKav.get(attId).Id);
					}
				}

				for(SignedResponse__kav sr : customAttIdVsKav.values()) {
					dataCategorySelections.add(getDataCategoryForSignedResponse(sr.Id));
				}

				//Insert data categories
				insert dataCategorySelections;
				system.debug('-----@KAV Data Category Selection Records Created---');	
				//Publish the article
				for(SignedResponse__kav sr : [Select Id, KnowledgeArticleId From SignedResponse__kav Where Id IN: customAttIdVsKav.values()]) {
					if(kavIdVsCaseNumber.containsKey(sr.Id) && kavIdVsCaseNumber.get(sr.Id) != null ) {
						caseArticles.add(new CaseArticle(CaseId = kavIdVsCaseNumber.get(sr.Id).Case__c, KnowledgeArticleId = sr.KnowledgeArticleId));
						KbManagement.PublishingService.publishArticle(sr.KnowledgeArticleId, true); //REVIEW required. Bulk publishing not supported. 
					}
				}
				
				//Insert Case Articles
				insert caseArticles;
				system.debug('-----@KAV Case Article Records Created---');	
				//Update the article id on NoteOrAttachment Record
				updateTheArticleIdOnNoteOrAttachmentRecords(attIdVsKavId);
                system.debug('-----@KAV @future called---');
			}

		} catch(Exception e) {
			system.debug('---Exception Knowledge Article---' + e.getMessage() + '--LINE--' + e.getLineNumber());
		}
	}

    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will return the Ka object
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
	private SignedResponse__kav getKArticleRecord(Attachment binaryAtt, String caseNumber){
        system.debug('-----Attachment Details---' +  binaryAtt.Name + '---' + binaryAtt.ContentType);
		return  new SignedResponse__kav(Title = binaryAtt.Name,
								        UrlName = 'case-' + caseNumber + '-R',
								        Summary = 'This is signed response for Case # ' + caseNumber,
								        SignedResponse__Name__s = binaryAtt.Name,
								        SignedResponse__ContentType__s = binaryAtt.ContentType,
								        SignedResponse__Body__s = binaryAtt.Body);
	}

    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will return the Data Category Selection object
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
	private SignedResponse__DataCategorySelection getDataCategoryForSignedResponse(Id articleId) {
		return new SignedResponse__DataCategorySelection( ParentId = articleId,
													  DataCategoryGroupName = GlobalConstants.SIGNED_RESPONSE_DATA_CATEGORY_GROUP_NAME,
													  DataCategoryName = GlobalConstants.SIGNED_RESPONSE_DATA_CATEGORY_NAME);
	}

    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will return the Data Category Selection object
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
	@future
	public static void updateTheArticleIdOnNoteOrAttachmentRecords(map <Id, Id> attIdVsKavId) {
        system.debug('-----@future Update Article Ids---');
		list <NoteOrAttachment__c> attachments = new list <NoteOrAttachment__c>();
		for(Id attId : attIdVsKavId.keySet()) {
		   attachments.add(new NoteOrAttachment__c(Id = attId, CaseArticle__c = attIdVsKavId.get(attId)));
		}

		update attachments;
        system.debug('-----@future Updated Article Ids---');
	}
    
	/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will update amendment count of the cases
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    20/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
	@future
	public static void updateAmendmentCountOfTheCases(set <Id> amendments) {
        system.debug('-----@future Update Amendment Count---');
        map <Id, Case> existingAmendments = new map <Id, Case>([Select Id, Amendment__c, Amendment_Count__c, Amendment_Triaged__c From Case Where Id IN: amendments]);
        for(Case caseRecord : existingAmendments.values()) {
            system.debug('-----@future Case Record---' + caseRecord);
            caseRecord.Amendment__c = true;
            caseRecord.Amendment_Count__c = caseRecord.Amendment_Count__c == null ? 1 : caseRecord.Amendment_Count__c + 1;
            caseRecord.Amendment_Triaged__c = false;
        }

		update existingAmendments.values();
        system.debug('-----@future Updated Amendment Count---');
	}
    
	 /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will update the case status to Signed.
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
	@future
	public static void updateCaseStatusToSigned(set <Id> caseIds) {
        system.debug('-----@future Update Case Status To Signed---');
		list <Case> cases = new list <Case>();
        for(Id caseId : caseIds) {
            cases.add(new Case(Id = caseId, Status = GlobalConstants.CASE_SIGNED_STATUS_MIN_CORRO));
        }
        
		update cases;
        system.debug('-----@future Updated Case Status To Signed---');
	}
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will detach the KA from old case and attaches it to new case record
    History 
    <Date>         <Authors Name>     <Brief Description of Change>
    14/07/2015     Manish Damle       Created
    -------------------------------------------------------------------------------------*/
    public void attachCaseArticleToNewCase() {
        map <Id,Id> oldVsNewCaseIds = new map <Id,Id>();
        set <Id> signedCasesIds = new set <Id> ();
        map <Id,Id> oldVsNewAmendmentCaseIds = new map <Id,Id> ();
        if(tp.oldMap != null) {
            for(Id attId : (set <Id>) tp.newMap.keySet()) {
                NoteOrAttachment__c oldAtt = (NoteOrAttachment__c) tp.oldMap.get(attId);
                NoteOrAttachment__c newAtt = (NoteOrAttachment__c) tp.newMap.get(attId);
                system.debug('-----@KAV Attachment Details---' + newAtt.Attachment__c + '---' + newAtt.Category__c + '---' + newAtt.Case__c + '---' + newAtt.ContentType__c);
                if(newAtt.Attachment__c != null 
                   && oldAtt.Case__c != null
                   && newAtt.Case__c != null
                   && oldAtt.Case__c != newAtt.Case__c 
                   && newAtt.Category__c == GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE
                   && newAtt.ContentType__c == GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF) {
                       oldVsNewCaseIds.put(oldAtt.Case__c, newAtt.Case__c);
                }	
                
                if(newAtt.Attachment__c != null 
                   && oldAtt.Case__c != null
                   && newAtt.Case__c != null
                   && oldAtt.Case__c != newAtt.Case__c 
                   && newAtt.Category__c == GlobalConstants.ATTACHMENT_CATEGORY_AMENDMENT
                   && newAtt.ContentType__c == GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF) {
                       oldVsNewAmendmentCaseIds.put(oldAtt.Case__c, newAtt.Case__c);
                }	
            }
        } 
        
        if(oldVsNewCaseIds.size() > 0) {
            list <CaseArticle> articlesToBeAttached = new list <CaseArticle>();
            map <Id, Id> oldCasesVsKavIds = new map <Id,Id>();
            list <CaseArticle> caseArticles = [Select CaseId, KnowledgeArticleId From CaseArticle Where CaseId IN: oldVsNewCaseIds.keySet()];
            for(CaseArticle ca : caseArticles ) {
                oldCasesVsKavIds.put(ca.CaseId, ca.KnowledgeArticleId);
            }
            delete caseArticles;
            system.debug('-----@KAV Old Case Articles deleted---');
            for(Id oldCaseId : oldVsNewCaseIds.keySet()) {
                if(oldCasesVsKavIds.containsKey(oldCaseId)  && oldCasesVsKavIds.get(oldCaseId) != null) {
                	articlesToBeAttached.add(new CaseArticle(CaseId = oldVsNewCaseIds.get(oldCaseId), KnowledgeArticleId = oldCasesVsKavIds.get(oldCaseId)));
                    signedCasesIds.add(oldVsNewCaseIds.get(oldCaseId));
                }
            }
            
            insert articlesToBeAttached; 
            updateCaseStatusToSigned(signedCasesIds);
            system.debug('-----@KAV Old Case Articles created---');
        }
        
        if(oldVsNewAmendmentCaseIds.size() > 0) {
            map <Id, Case> oldCases = new map <Id,Case>([Select Id, Amendment__c From Case Where Id IN: oldVsNewAmendmentCaseIds.keySet()]);
            set <Id> amendmentCaseId = new set <Id> ();
            for(Id oldCaseId : oldVsNewAmendmentCaseIds.keySet()) {
                if(oldCases.containsKey(oldCaseId) && oldCases.get(oldCaseId) != null && oldCases.get(oldCaseId).Amendment__c == true) {
                    amendmentCaseId.add(oldVsNewAmendmentCaseIds.get(oldCaseId));
                }
            }
            updateAmendmentCountOfTheCases(amendmentCaseId);
            system.debug('-----@KAV Amendment Captured---');
        }   
    }
}