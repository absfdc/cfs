global class DFSISyncCaseAttachments implements Database.Batchable<sObject>, Database.AllowsCallouts{
	
	@TestVisible
	private CaseAttachmentService attachmentService = null;

	List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

	global void startBatch() {
		// 1 call for the metadata
		// 9 calls for attachment data
		Database.executeBatch(this, 1);
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([Select Id, DFSICaseID__c, DFSIRecordTypeId__c, DFSIPageSource__c
											From Case
											Where DFSI_Attachment_Synced__c = false
											  	  AND DFSICaseID__c <> null]);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope)
   	{

		List<Case> cases = (List<Case>) scope;

   		List<Case> casesToUpdate = new List<Case>();
   		list<DFSI_Case_Owner_And_RecordType_Ids__c> objCustomSettingForRMS = new  list<DFSI_Case_Owner_And_RecordType_Ids__c>();
		objCustomSettingForRMS = [select name, Owner_Id__c, RecordTypeId__c
									from DFSI_Case_Owner_And_RecordType_Ids__c
									where name = 'RMS' limit 1];
		Id RMSOwnerId=[SELECT Name,Id,DeveloperName 
						FROM Group 
						WHERE DeveloperName=:Label.RMS_Queue].Id;
		
        Id RMS_CAD_Communications_QueueId=[SELECT Name,Id,DeveloperName 
                                           FROM Group 
                                           WHERE DeveloperName=:Label.RMS_CAD_Communications_Queue].Id;			
   		

        system.debug('cases '+scope);
        //Map of external case id and attachments of the case
   		Map<String, List<NoteOrAttachment__c>> noteAndAttachmentsMap = null;
        try
        {
        		noteAndAttachmentsMap = getAttachmentService().getAttachmentMetadata(cases);
    		} 
    		catch(Exception e)
    		{
    			DFSICoreService.writeToApplicationLogAndSendEmail('DFSISyncCaseAttachments', //write to application log, stacktrace
												'execute',
												e.getMessage(),
												e,
												'Error');
    			return;
    		}
   		 
   		System.debug('DFSISyncCaseAttachments::execute::noteAndAttachmentsMap ->' + noteAndAttachmentsMap);

   		// Map of extenal attachment Id and Notes and attachment object
   		Map<String, NoteOrAttachment__c> allNoteAndAttachmentsMap = getAllNotesAndAttachments(noteAndAttachmentsMap);


   		//Map of External case id and Case object
   		Map<String, Case> caseMap = new Map<String, Case>();

   		//Map of external attachment Id and all attachments for all cases.
   		Map<String, Attachment> allAttachmentsMap = new Map<String, Attachment>();
   		Id DFSICaseOwnerID=[SELECT Name,Id,DeveloperName 
							FROM Group 
							WHERE DeveloperName=:Label.Serco_Web_Triage_Queue].Id;

   		for(Case dfsiCase: cases) 
   		{
   			try
   			{
   				System.debug('DFSISyncCaseAttachments::execute::dfsiCase.DFSICaseID__c ->' + dfsiCase.DFSICaseID__c);
   				List<NoteOrAttachment__c> attachmentForCase = noteAndAttachmentsMap.get(dfsiCase.DFSICaseID__c);
   				System.debug('DFSISyncCaseAttachments::execute::attachmentForCase ->' + attachmentForCase);

   				if(attachmentForCase != null && attachmentForCase.size() >0) 
   				{
					// Get the attachment from the remote Service
					allAttachmentsMap.putAll(getAttachmentService().getAttachments(dfsiCase));
	   				}
	   				Case caseTobeUpdated = new Case(Id = dfsiCase.Id, DFSI_Attachment_Synced__c = true);
					//casesToUpdate.add(new Case(Id = dfsiCase.Id, DFSI_Attachment_Synced__c = true, Ownerid = DFSICaseOwnerID));
					if(objCustomSettingForRMS.size()>0)
					{
						if(dfsiCase.DFSIRecordTypeId__c == objCustomSettingForRMS[0].RecordTypeId__c)
						{
							caseTobeUpdated.Ownerid = RMSOwnerId; //add RMS queue id
						}
						else
						{
							caseTobeUpdated.Ownerid = DFSICaseOwnerID; //this is serco queue i.e transport
						}
                	if(dfsiCase.DFSIPageSource__c!=null && dfsiCase.DFSIPageSource__c.contains('parkingsigns.nsw.gov.au')) caseTobeUpdated.OwnerId = RMS_CAD_Communications_QueueId;//Assign parkingsigns cases to a different configurable RMS queue                        
                        
					}
					else
					{
						DFSIException DE = new DFSIException();
			    			DE.setMessage('RMS record in DFSI Case Owner And RecordType Ids custom setting is missing');
						throw DE;
					}
					casesToUpdate.add(caseTobeUpdated);
	   				caseMap.put(dfsiCase.DFSICaseID__c, dfsiCase);
   				} 
   			
			catch(Exception e) 
   			{
	   			DFSICoreService.writeToApplicationLogAndSendEmail('DFSISyncCaseAttachments', //write to application log, stacktrace
												'execute',
												e.getMessage(),
												e,
												'Error');
	   			return;
	   		}
   		}
		
   		if(allAttachmentsMap.size() > 0) 
   		{
   			Savepoint sp = Database.setSavepoint();
			try
			{
	   			// Insert the notes as id is required to set parent id for attachments
	   			insert allNoteAndAttachmentsMap.values();
	
	   			populateParentId(allAttachmentsMap, allNoteAndAttachmentsMap);
		   		
		   		//insert all attachments to get the Ids.
		   		insert allAttachmentsMap.values();
	
				List<NoteOrAttachment__c> allNoteAndAttachments = populateValues(caseMap, noteAndAttachmentsMap, allAttachmentsMap);
	
		   		//insert all notes and attachments for all cases
		   		update allNoteAndAttachments;
		   		
		   		//update cases
		   		update casesToUpdate;
			}
			
			catch(Exception e)
			{
				Database.rollback(sp);
				DFSICoreService.writeToApplicationLogAndSendEmail('DFSISyncCaseAttachments', //write to application log, stacktrace
												'execute',
												e.getMessage(),
												e,
												'Error');
			return;
				
			}
   		}
	}



	@TestVisible
	private void populateParentId(Map<String, Attachment> allAttachmentsMap,
												Map<String, NoteOrAttachment__c> allNoteAndAttachmentsMap) {
		for(String externalId: allAttachmentsMap.keySet()) {
			NoteOrAttachment__c natt = allNoteAndAttachmentsMap.get(externalId);
			Attachment att = allAttachmentsMap.get(externalId);
			att.ParentId = natt.Id;
		}
	}

	@TestVisible
	private List<NoteOrAttachment__c> populateValues(Map<String, Case> caseMap, 
														Map<String, List<NoteOrAttachment__c>> noteAndAttachmentsMap, 
														Map<String, Attachment> allAttachmentsMap) {

		List<NoteOrAttachment__c> allNoteAndAttachments = new List<NoteOrAttachment__c>();

		for(String extCaseId: noteAndAttachmentsMap.keySet()) {

			// Get the case for the external Id
			Case c = caseMap.get(extCaseId);

			// Iterate over each Note And Attachment object for this case
			for(NoteOrAttachment__c n_a: noteAndAttachmentsMap.get(extCaseId)) {
				// Link the note and attachment to Cse
				n_a.Case__c = c.Id;

				// Link the attachmnet object with the Note and Attachment object
				n_a.Attachment__c = allAttachmentsMap.get(n_a.DFSIAttachmentId__c).Id;

				allNoteAndAttachments.add(n_a);
			}
		}
		return allNoteAndAttachments;

	}

	@TestVisible
	private Map<String, NoteOrAttachment__c> getAllNotesAndAttachments(Map<String, List<NoteOrAttachment__c>> noteAndAttachmentsMap) {
		Map<String, NoteOrAttachment__c> allAttachmentsMap = new Map<String, NoteOrAttachment__c>();
		

		for(List<NoteOrAttachment__c> attachments: noteAndAttachmentsMap.values()) {
			for(NoteOrAttachment__c attachment: attachments) {
				allAttachmentsMap.put(attachment.DFSIAttachmentId__c, attachment);
			}
		}

		return allAttachmentsMap;
	}


	@TestVisible
	private CaseAttachmentService getAttachmentService() {
		if(attachmentService == null)  {
			attachmentService = new DFSIFeedbackAssist();
		}
		return attachmentService;
	}
	
	global void finish(Database.BatchableContext BC) {
	
	}

		
	}