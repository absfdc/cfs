/*------------------------------------------------------------
Author:        Ishu Jain
Company:       System Partners
Description:   Helper class which will send the cases to DFSI after insert if the cases 
				are created by FA widget on RMS and .info websites

Test Class:    DFSIUpdateCaseClosedTest
History
29/05/2018     Ishu Jain		       Created
------------------------------------------------------------*/

public without sharing class FASendCasesToDFSIAfterInsert {
	public static final String tfnsw = 'tfnsw';
	public static final String NSWTrains = 'NSW Trains';
	public static final String rmsWebsite = 'RMS Website';
	public static final String infoURL = 'https://transportnsw.info';
	public static final String rmsURL = 'www.rms.nsw.gov.au';
	public static final String FeedbackAssistCorporate='Feedback Assist Corporate';
	public static Boolean counterUpdated = false;
	
	public void SendCasesToDFSI(map <Id, Case> newMap)
	{
		try{
			if(counterUpdated) {
	            return;
	        }
	        
			list<Case> lstCase = new list<Case>();
			Case objCase;
			system.debug('method called SendCasesToDFSI');
			
			if(newMap == null)
			{
				DFSIException E = new DFSIException();
				E.setmessage('newMap is null');
				throw E;
			}
			
			for(ID CaseId : newMap.keyset())
			{
				objCase = new case();
				system.debug('value of isfeedback'+newMap.get(CaseId).isFeedbackAssist__c);
				if(newMap.get(CaseId).isFeedbackAssist__c == true)
				{
					system.debug('case details***:' +newMap.get(CaseId));
					objCase.Id = CaseId;
					objCase.OwnerAgency__c = newMap.get(CaseId).OwnerAgency__c;
					objCase.Agency__c = newMap.get(CaseId).Agency__c;
					objCase.description = newMap.get(CaseId).description;
					objCase.Agency__c = newMap.get(CaseId).Agency__c;
					objCase.RecordTypeId = newMap.get(CaseId).RecordTypeId;
					objCase.Origin = newMap.get(CaseId).Origin;
					objCase.Subject = newMap.get(CaseId).Subject;
					objCase.OwnerId = newMap.get(CaseId).OwnerId;
					if(newMap.get(CaseId).Type == 'Feedback')     //newMap.get(CaseId).Type == 'Enquiry' || 
					{
						objCase.Type = 'Suggestion';
					}
					else
					{
						objCase.Type = newMap.get(CaseId).Type;
					}
					objCase.Location_of_Incident__c = newMap.get(CaseId).Location_of_Incident__c;
					
					if(newMap.get(CaseId).Origin_Details__c == tfnsw || newMap.get(CaseId).Origin_Details__c == NSWTrains)
					{
						objCase.DFSIPageSource__c = infoURL;
					}
					IF(newMap.get(CaseId).Origin_Details__c == rmsWebsite)
					{
						objCase.DFSIPageSource__c = rmsURL;
					}
					objCase.SuppliedName = newMap.get(CaseId).SuppliedName;
					objCase.SuppliedEmail = newMap.get(CaseId).SuppliedEmail;
					objCase.SuppliedPhone = newMap.get(CaseId).SuppliedPhone;
					objCase.DFSISent_VIA_Rest__c = newMap.get(CaseId).DFSISent_VIA_Rest__c;
					objCase.Priority = newMap.get(CaseId).Priority == 'High'?'High':'Medium';
					objCase.isFeedbackAssist__c = newMap.get(CaseId).isFeedbackAssist__c;
					objCase.DFSISent_VIA_Rest__c = true;
					objCase.Status = 'New';
					lstCase.add(objCase);
				}
			}
			
			if(lstCase.size() >0)
			{
				lstCase = checkAndAssignCasesToDFSIQueue(lstCase);
				system.debug('list of cases before JSON'+lstCase);
				string json = FARestCaseWrapper.generateTreeJson(lstCase);
				system.debug('JSON after calling the tree class'+json);
				calloutToDFSI(json);
				counterUpdated = true;
			}
		}
		catch(Exception e)
			{
				DFSICoreService.writeToApplicationLogAndSendEmail('FASendCasesToDFSIAfterInsert', //write to application log, stacktrace
														'SendCasesToDFSI',
														e.getMessage(),
														e,
														'Error');
			}
	}
	public list<case> checkAndAssignCasesToDFSIQueue(list<case> lstCases)
	{
		try
		{
			list<Case> listToReturn = new list<Case>();
			Case objCase;
			DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForRMS = new DFSI_Case_Owner_And_RecordType_Ids__c();
			DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForTransport = new DFSI_Case_Owner_And_RecordType_Ids__c();
			objCustomSettingForRMS = [select name, Owner_Id__c, RecordTypeId__c
										from DFSI_Case_Owner_And_RecordType_Ids__c
										where name = 'RMS' limit 1];
			objCustomSettingForTransport = [select name, Owner_Id__c, RecordTypeId__c
											from DFSI_Case_Owner_And_RecordType_Ids__c
											where name = 'Transport' limit 1];
			
			for(Case C: lstCases)
			{
				objCase = new Case();
				objCase = c;
				system.debug('objCase.OwnerAgency__c**'+objCase.OwnerAgency__c);
				system.debug('objCase.Agency__c**'+objCase.Agency__c);
				if(objCase.OwnerAgency__c == '' || String.IsBlank(objCase.OwnerAgency__c) || String.isEmpty(objCase.OwnerAgency__c) || objCase.OwnerAgency__c == null)
				{
					if(objCase.Agency__c == GlobalConstants.RMS_AGENCY || objCase.Agency__c == GlobalConstants.SNSW_AGENCY)
					{
						objCase.RecordtypeId = objCustomSettingForRMS.RecordTypeId__c;
						objCase.OwnerId = objCustomSettingForRMS.Owner_Id__c;					
					}
					else
					{
						objCase.RecordtypeId = objCustomSettingForTransport.RecordTypeId__c;
						objCase.OwnerId = objCustomSettingForTransport.Owner_Id__c;										
					}
				}
				else
				{
					if(objCase.OwnerAgency__c == GlobalConstants.RMS_AGENCY || objCase.OwnerAgency__c == GlobalConstants.SNSW_AGENCY)
					{
						objCase.RecordtypeId = objCustomSettingForRMS.RecordTypeId__c;
						objCase.OwnerId = objCustomSettingForRMS.Owner_Id__c;
					}
					else
					{
						objCase.RecordtypeId = objCustomSettingForTransport.RecordTypeId__c;
						objCase.OwnerId = objCustomSettingForTransport.Owner_Id__c;					
					}
				}
				listToReturn.add(objCase);
			}
			return listToReturn;
		}
		catch(Exception e)
		{
			DFSICoreService.writeToApplicationLogAndSendEmail('FASendCasesToDFSIAfterInsert', //write to application log, stacktrace
									'checkAndAssignCasesToDFSIQueue',
									e.getMessage(),
									e,
									'Error');
			return null;
		}
	}
	
	@future(callout=true)
	public static void calloutToDFSI(string JSON)
	{
		try
		{
			list<FAParseJson> lstresponse = new list<FAParseJson>();
			map<Id,Id> mapIds = new map<Id,Id>();
			list<case> casesToBeUpdated = new list<case>();
			set<Id> setCaseIds = new set<Id>();
			DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForRMS = new DFSI_Case_Owner_And_RecordType_Ids__c();
			DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForTransport = new DFSI_Case_Owner_And_RecordType_Ids__c();
			objCustomSettingForRMS = [select name, Owner_Id__c, RecordTypeId__c
										from DFSI_Case_Owner_And_RecordType_Ids__c
										where name = 'RMS' limit 1];
			objCustomSettingForTransport = [select name, Owner_Id__c, RecordTypeId__c
											from DFSI_Case_Owner_And_RecordType_Ids__c
											where name = 'Transport' limit 1];
			
			DFSIEndpoint__c objCustomSettingForEndpoint = [select id, name, DFSIMethodURL__c
															from DFSIEndpoint__c
															where name = 'CreateCase'];
			
			
			
			String endpoint = objCustomSettingForEndpoint.DFSIMethodURL__c;
			HTTPResponse res = DFSICoreService.doDFSICallout(endpoint,'POST','application/json',JSON);
			if(res.getStatusCode() != 201)
			{
				DFSIException DE = new DFSIException();
	    			DE.setMessage(res.getBody());
				throw DE;
			}
			string body = res.getBody();
			System.debug('the response body is '+res.getBody());
			if(!(body.startsWith('[')))
			body = '['+body+']';
			system.debug('body after brackets '+body);
			FAParseJson objFAParseJson = new FAParseJson();
			lstresponse = objFAParseJson.parse(body);
			system.debug('the final response'+lstresponse);
			
			if(lstresponse != null)
			{
				for(FAParseJson obj : lstresponse)
				{
					if(obj.hasErrors == false)
					{
						setCaseIds.add(obj.results[0].referenceId);
						mapIds.put(obj.results[0].referenceId,obj.results[0].Id);
					}
				}
				
				if(setCaseIds.size()>0)
				{
					for(Case objCase: [select OwnerAgency__c, DFSICaseId__c, DFSISent_VIA_Rest__c,Agency__c, Origin_Details__c from Case where Id IN:setCaseIds])
					{
						if(objCase.OwnerAgency__c == '' || String.IsBlank(objCase.OwnerAgency__c) || String.isEmpty(objCase.OwnerAgency__c))
						{
							if(objCase.Agency__c == GlobalConstants.RMS_AGENCY || objCase.Agency__c == GlobalConstants.SNSW_AGENCY)
							{
								objCase.DFSIRecordTypeId__c = objCustomSettingForRMS.RecordTypeId__c;					
							}
							else
							{
								objCase.DFSIRecordTypeId__c = objCustomSettingForTransport.RecordTypeId__c;									
							}
						}
						else
						{
							if(objCase.OwnerAgency__c == GlobalConstants.RMS_AGENCY || objCase.OwnerAgency__c == GlobalConstants.SNSW_AGENCY)
							{
								objCase.DFSIRecordTypeId__c = objCustomSettingForRMS.RecordTypeId__c;
							}
							else
							{
								objCase.DFSIRecordTypeId__c = objCustomSettingForTransport.RecordTypeId__c;
							}
						}
						objCase.DFSICaseId__c = mapIds.get(objCase.Id);
						objCase.DFSISent_VIA_Rest__c = true;
                        objCase.DFSI_Attachment_Synced__c = true;
						
						casesToBeUpdated.add(objCase);
					}
					
					list<Database.SaveResult> sr = new list<Database.SaveResult>();
					boolean errorOccured = false;
					if(casesToBeUpdated.size()>0)
					{
						sr = Database.update( casesToBeUpdated, false);	
					}
					
					string errormessage = '';
					
					If(sr != new list<Database.SaveResult>())
					{
						for(Integer index = 0, size = sr.size(); index < size; index++) 
						{
						    if(!(sr[index].isSuccess())) 
						    {
						    			errorOccured = true;
						    			List<Database.Error> E = sr[index].geterrors();
						            errormessage += 'Status Code is: '+ E[0].getStatusCode() +  ' Error Message is: '+ E[0].getMessage() + ' CFS Case Number is: ' +casesToBeUpdated[index].Id + '\n';
						    }
						}
						if(errorOccured == true)
						{
							DMLException DE = new DMLException();
				    			DE.setMessage(errormessage);
							throw DE;
						}
					}
				}
			}
		}
		
		catch(Exception e)
		{
			DFSICoreService.writeToApplicationLogAndSendEmail('FASendCasesToDFSIAfterInsert', //write to application log, stacktrace
													'calloutToDFSI',
													e.getMessage(),
													e,
													'Error');
		}
	}
}