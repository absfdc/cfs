global class AttachArticleToCase_Batch implements Database.Batchable<sObject> , Database.Stateful, Database.AllowsCallouts{
	global final Integer SCOPE_SIZE=20;//probabaly simultanious http get to same host limit
	global final String newCaseArticlesQuery;
	global final String NotesOrAttachment_Privacy='Standard'; 
	global final String baseUrl=URL.getSalesforceBaseUrl().toExternalForm();
	global final RecordType NotesOrAttachment_RecType=[select Id from RecordType where SobjectType='NoteOrAttachment__c' and DeveloperName=:GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT limit 1];
	global Set<Id> existingCaseArticleId;
	global List<NoteOrAttachment__c> existingAttachedArticles;
	private String sessionId;
	List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

	global AttachArticleToCase_Batch(String sessionId) {
		this.sessionId= sessionId;
		existingAttachedArticles=[select CaseArticle__c from NoteOrAttachment__c where CaseArticle__c!=null];
		

		if (existingAttachedArticles.size()>0){
			existingCaseArticleId= new Set<Id>();
			for (NoteOrAttachment__c aCaseAttachment:existingAttachedArticles) existingCaseArticleId.add(aCaseAttachment.CaseArticle__c);
			newCaseArticlesQuery='select Id, CaseId,ArticleVersionNumber,KnowledgeArticleId from CaseArticle where Id NOT in: existingCaseArticleId';
			
		}else{
			newCaseArticlesQuery='select Id, CaseId,ArticleVersionNumber,KnowledgeArticleId from CaseArticle';

		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(newCaseArticlesQuery);
	}
	//call with less that 20
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<CaseArticle> newCaseArticles=(List<CaseArticle>)scope;
   		Map<Id, Id> caseArticleVsArticleId= new Map<Id, Id>();
   		Map<Id,Id> caseArticleVsCaseId=new Map<Id,Id>();
   		Map <Id, Attachment> caseArticleIdVsAttachment = new Map <Id, Attachment>();
   		Map <Id, NoteOrAttachment__c> caseArticleIdVsNotesOrAttachment = new Map <Id, NoteOrAttachment__c>();


   		for (CaseArticle aNewCaseArticle:newCaseArticles){
   			caseArticleVsCaseId.put(aNewCaseArticle.Id, aNewCaseArticle.CaseId);
   			caseArticleVsArticleId.put(aNewCaseArticle.Id,aNewCaseArticle.KnowledgeArticleId);
   		}
		List<KnowledgeArticleVersion> possibleNewKavs= [SELECT Title,ArticleType,Id,KnowledgeArticleId,UrlName,VersionNumber FROM KnowledgeArticleVersion where PublishStatus='Online' and Language='en_US' and KnowledgeArticleId in:caseArticleVsArticleId.values()];
		Map<String,KnowledgeArticleVersion> possibleNewKavIdVersionIdVsKav= new Map<String,KnowledgeArticleVersion>();
		for (KnowledgeArticleVersion aPossibleKav: possibleNewKavs) possibleNewKavIdVersionIdVsKav.put(''+aPossibleKav.KnowledgeArticleId+aPossibleKav.VersionNumber,aPossibleKav);

		for (CaseArticle aNewCaseArticle:newCaseArticles){
			if (possibleNewKavIdVersionIdVsKav.containskey(''+aNewCaseArticle.KnowledgeArticleId+aNewCaseArticle.ArticleVersionNumber)){
				KnowledgeArticleVersion aNewKav = possibleNewKavIdVersionIdVsKav.get(''+aNewCaseArticle.KnowledgeArticleId+aNewCaseArticle.ArticleVersionNumber);
				HttpResponse anArticleContent=getArticleContent(aNewKav.ArticleType,aNewKav.UrlName);
				String anArticleText= anArticleContent.getBody();
				Attachment kaAttachment=getAttachmentPdf(caseArticleVsCaseId.get(aNewCaseArticle.Id),anArticleText,aNewKav.Title);
				String endPoint= baseUrl+'/articles/'+aNewKav.ArticleType.split('__',2)[0]+'/'+aNewKav.UrlName;
				//String endPoint='https://test.salesforce.com/?ec=302&startURL=/articles/'+aNewKav.ArticleType.split('__',2)[0]+'/'+aNewKav.UrlName+'/p';

				kaAttachment.Description=endPoint;
				caseArticleIdVsAttachment.put(aNewCaseArticle.Id,kaAttachment);
				caseArticleIdVsNotesOrAttachment.put(aNewCaseArticle.Id,  new NoteOrAttachment__c(
					Name=kaAttachment.Name,
					Case__c=kaAttachment.parentId,
					File_Name__c=kaAttachment.Name,
					Privacy__c=NotesOrAttachment_Privacy,
					RecordTypeId=NotesOrAttachment_RecType.Id,
					Requires_Printing__c=true,
					CaseArticle__c=aNewCaseArticle.Id,
					ContentType__c='pdf',
					Type__c='Article',
					Body__c=endPoint+'##'+sessionId+'##'+anArticleText
				));
			}

		}
		if (caseArticleIdVsNotesOrAttachment.size()>0){
			insert caseArticleIdVsNotesOrAttachment.values();
			for (Id caseArticleId: caseArticleIdVsAttachment.keySet()){
				Attachment kaAttachment= caseArticleIdVsAttachment.get(caseArticleId);
				NoteOrAttachment__c kaNotesOrAttachment=caseArticleIdVsNotesOrAttachment.get(caseArticleId);
				kaAttachment.parentId=kaNotesOrAttachment.Id;
			}
			insert caseArticleIdVsAttachment.values();
			for (Id caseArticleId: caseArticleIdVsNotesOrAttachment.keySet()){
				NoteOrAttachment__c aNoteOrAttachment=caseArticleIdVsNotesOrAttachment.get(caseArticleId);
				Attachment anAttachment=caseArticleIdVsAttachment.get(caseArticleId);
				aNoteOrAttachment.Attachment__c=anAttachment.Id;
			}
			update caseArticleIdVsNotesOrAttachment.values();
		}

	}


	
	global void finish(Database.BatchableContext BC) {
		ApplicationLogUtility.logMessage(messages);

		existingAttachedArticles=[select CaseArticle__c from NoteOrAttachment__c where CaseArticle__c!=null];
		

		if (existingAttachedArticles.size()>0){
			existingCaseArticleId= new Set<Id>();
			Id batchInstanceId;
			for (NoteOrAttachment__c aCaseAttachment:existingAttachedArticles) existingCaseArticleId.add(aCaseAttachment.CaseArticle__c);
			List<CaseArticle> remainder=[select Id, CaseId,ArticleVersionNumber,KnowledgeArticleId from CaseArticle where Id NOT in: existingCaseArticleId];
			if (remainder.size()>0) {
				//send a outboundmessage to a service with sessionid that starts this in batch
				//batchInstanceId = Database.executeBatch(new AttachArticleToCase_Batch(), SCOPE_SIZE);
			} 
		}
	}

	global Attachment getAttachmentPdf(Id caseId,String articleText,String title){
		Attachment attachmentPDF = new Attachment();
        attachmentPDF.parentId = caseId;
        attachmentPDF.Name = title+ '.pdf';
        try{
        	attachmentPDF.body = Blob.toPDF(articleText); //This creates the PDF content

        }catch(Exception e){
        	attachmentPDF.body= Blob.valueOf(e.getMessage());
        }
        return attachmentPDF;
	}

	global HttpResponse getArticleContent(String articleType, String urlName){
		//https://cs5.salesforce.com/articles/Explanation_of_Fault/Guidelines-for-making-an-insurance-claim/p
		Http h = new Http();
		HttpRequest webReq = new HttpRequest();
		webReq.setMethod('GET');
		webReq.setHeader('Cookie','sid '+sessionId);
		//String endPoint='https://test.salesforce.com/?ec=302&startURL=/articles/'+articleType.split('__',2)[0]+'/'+urlName+'/p';
		String endPoint= baseUrl+'/articles/'+articleType.split('__',2)[0]+'/'+urlName;
		system.debug('endPoint - '+endPoint);
		webReq.setEndpoint(endPoint);
		
		return h.send(webReq);
		

	}
	
}