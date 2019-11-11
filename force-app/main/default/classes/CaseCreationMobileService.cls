/*------------------------------------------------------------
Author:        Deepak Soni
Company:       Arxxus Technology Partners
Description:   Rest API to log complaints or Feedback as cases from Mobile App
Inputs:        Json object that contains list of Cases to be logged with associated Contacts and attachments.
Test Class:    CaseCreationMobileService_Test

History
<Date>      	<Authors Name>		<Brief Description of Change>
22/02/2016      Deepak Soni     	Implemented Rest API service
26/04/2016		Deepak Soni 		Remove attachment creation by ourselves and starts using WebToCaseAttachmentCreator class to create attachments, 
									so that attachments can be shared with SNSW
------------------------------------------------------------*/
@RestResource(urlMapping='/cfm/v1/createCases/*')
global class CaseCreationMobileService {
	public class CustomException extends Exception {}

	public static final String REQUEST_WRAPPER_ATTACHMENT_PROPERTY_KEY = 'attachments';
	public static final String DEBUG_LOG_LEVEL_INFO = 'Info';
	public static final String DEBUG_LOG_LEVEL_ERROR = 'Error';
	public static Contact cont;
	public static Contact matchedContact;

	@HttpPost
    global static ResponseWrapper doPost() {
    	ResponseWrapper response = new ResponseWrapper();

    	Map<String, FullMatchDuplicateContactRules__c> fullConfidenceRules = FullMatchDuplicateContactRules__c.getAll();
    	List<ApplicationLogMessage> logMessages =new List<ApplicationLogMessage>();
    	
    	PublicSiteDomainName__c psdn = PublicSiteDomainName__c.getValues('Instance URL');
	    String salesforceBaseUrl = psdn.Domain_Name__c;

    	Savepoint caseCreationSP = Database.setSavepoint();
    	try {
    		List<CaseResultWrapper> casesResponse = new List<CaseResultWrapper>();

			String casesJson = RestContext.request.requestBody.tostring();

			ApplicationLogMessage payloadLogMsg = new ApplicationLogMessage();
            payloadLogMsg.source = 'CaseCreationMobileService';
            payloadLogMsg.sourceFunction = 'doPost';
            payloadLogMsg.logMessage = 'Request Body, contains all information of cases and associated contact except their attachments.';
            payloadLogMsg.debugLevel = DEBUG_LOG_LEVEL_INFO;

            String reqWrAttPropKeyWithDoubleQuotes = '"' + REQUEST_WRAPPER_ATTACHMENT_PROPERTY_KEY + '"';
            // Remove attachments from payload if exits
			Integer attachmentsStartPosition = casesJson.indexOf(reqWrAttPropKeyWithDoubleQuotes);
			if(attachmentsStartPosition < 0) {
				payloadLogMsg.payLoad=casesJson;
			} else {
				String subStringEndsBeforeAttachments = casesJson.substringBefore(reqWrAttPropKeyWithDoubleQuotes).trim().removeEnd(',');
				String subStringStartWithAttachments = casesJson.substring(attachmentsStartPosition);
				String subStringAfterAttachmentsProperty = subStringStartWithAttachments.substringAfter('}]');

				payloadLogMsg.payLoad = subStringEndsBeforeAttachments + subStringAfterAttachmentsProperty;
			}

            logMessages.add(payloadLogMsg);

			List<RequestWrapper> casesToBeCreated = (List<RequestWrapper>) JSON.deserialize(casesJson, List<RequestWrapper>.class);

			if(!casesToBeCreated.isEmpty()) {
	    		List<Contact> contacts = new List<Contact>();
	    		
	    		Map<String, Integer> contactIndexByLocalId = new Map<String, Integer>();
	    		Map<Integer, String> contactLocalIdByIndex = new Map<Integer, String>();
	    		Integer counter = 0;
	    		for(RequestWrapper reqW :casesToBeCreated) {
	    			if(reqW.toBeContacted) {
	    				Contact con = new Contact();
			    		con.FirstName = reqW.firstName;	
			    		con.LastName = reqW.lastName;
			    		con.Email = reqW.email;
			    		con.MobilePhone = reqW.mobile;
			    		con.MailingStreet = reqW.mailingStreet;
						con.MailingCity = reqW.mailingCity;
						con.MailingState = reqW.mailingState;
						con.MailingPostalCode = reqW.mailingPostalCode;
						con.MailingCountry = reqW.mailingCountry;

			    		ContactCreator creator = new ContactCreator(con);
			    		reqW.contactId = creator.createContact();
			    		if(creator.FullMatch == true){
            				updateMatchedRecord(creator.duplicateContacts[0].id, reqW);
        				}
			    		//call a future method to empty phone fields
			    		System.debug('req contactId: '+reqW.contactId);
			    		con = resetAppContactPhoneFields(reqW.contactId);
			    		
			    		contacts.add(con);
			    		contactIndexByLocalId.put(reqW.localId, counter);
			    		contactLocalIdByIndex.put(counter, reqW.localId);

	    				counter++;
	    			}
	    		}

	    		Map<String, String> contactIdByLocalId = new Map<String, String>();
	    		Map<String, String> contactErrMsgByLocalId = new Map<String, String>();
	    		Map<String, String> dupContactErrMsgByLocalId = new Map<String, String>();
	    		Map<String, List<Contact>> dupContactsByLocalId = new Map<String, List<Contact>>();
	    		Map<String, Contact> dupContByLocalIdForFullConfidenceMatch = new Map<String, Contact>();

	    		counter = 0;
	    		
	    		List<Case> cases = new List<Case>();
	    		Map<Integer, String> caseLocalIdByIndex = new Map<Integer, String>();
	    		Map<String, String> caseGuidByLocalId = new Map<String, String>();

	    		String multiIssueRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE).getRecordTypeId();

	    		counter = 0;
	    		for(RequestWrapper reqW :casesToBeCreated) {
	    			String caseLocalId = reqW.localId;
	    			String caseGuid = generateGUID();

	    			caseGuidByLocalId.put(caseLocalId, caseGuid);

	    			Case newCase = new Case();
			        newCase.RecordTypeId = multiIssueRecordTypeId;
			        newCase.Status = GlobalConstants.DEFAULT_WEBTOCASE_STATUS_TRIAGE;
			        newCase.Origin = GlobalConstants.CASE_ORIGIN_CFM_API;
			        newCase.GUID__c = caseGuid;
			        newCase.Modes__c = reqW.mode;
			        newCase.Description = reqW.description;
			        newCase.LocalId__c = caseLocalId;
			        newCase.GPS_Incident_Location__Latitude__s = reqW.incidentLatitude;
			        newCase.GPS_Incident_Location__Longitude__s = reqW.incidentLongitude;
			        newCase.SuppliedEmail = reqW.email;
			        newCase.Location_of_Incident__c = reqW.location;
			        newcase.ContactId = reqW.contactId;

			        if(String.isNotEmpty(reqW.originDetail)) {
			        	newCase.Origin_Details__c = reqW.originDetail;
			        }

			        newCase.Subject = reqW.mode + ' / ' + reqW.category;

			        if(newCase.Subject.trim().length() > 255) {
			        	newCase.Subject = newCase.Subject.trim().substring(0, 252) + '...';
			        }
			        // append category details to description
					newCase.Description += '\n\n ***** Category Details ***** \n Category: ' + reqW.category;
					// append location details to description
					newCase.Description += '\n\n ***** Location Details ***** \n Location: ' + reqW.location;
			        newCase.Response_Requested__c = 'No';
                    
                    
                    //SFCOE-1484 Feedback2Go - 17-05-2017 - Start
                    //If customer has chosen to be contacted from Feedback2GO App (toBeContacted = true), set the same as Yes in Salesforce

                    if(reqW.toBeContacted) {
			        	newCase.Response_Requested__c = 'Yes';
                    }
                    
                    //SFCOE-1484 Feedback2Go - 17-05-2017 - End
                    
                    
			        cases.add(newCase);
			        caseLocalIdByIndex.put(counter, reqW.localId);
			        counter++;
	    		}

	    		List<AssignmentRule> rules = [SELECT id 
	                                          FROM AssignmentRule 
	                                          WHERE SobjectType = 'Case' 
	                                          AND Active = true LIMIT 1];

		        Database.DMLOptions dmlOpts = new Database.DMLOptions();
		        dmlOpts.OptAllOrNone = false;

		        if(!rules.isEmpty()) {                   
		            dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].id;
		            dmlOpts.assignmentRuleHeader.useDefaultRule = false;            
		        }
		        
		        Database.SaveResult[] caseResults = Database.insert(cases, dmlOpts);

		        ApplicationLogMessage caseResultsLogMsg = new ApplicationLogMessage();
	            caseResultsLogMsg.source = 'CaseCreationMobileService';
	            caseResultsLogMsg.sourceFunction = 'doPost';
	            caseResultsLogMsg.logMessage = 'Cases creation result';
	            caseResultsLogMsg.debugLevel = DEBUG_LOG_LEVEL_INFO;
	            caseResultsLogMsg.referenceInfo = JSON.serialize(caseResults);
	            logMessages.add(caseResultsLogMsg);

		       	List<String> caseIds = new List<String>();
		        for(Database.SaveResult caseres :caseResults) {
		        	if(caseres.isSuccess()) {
	    				caseIds.add(caseres.getId());
		    		}
		        }

		        Map<String, String> caseIdByLocalId = new Map<String, String>();
		        Map<String, Case> caseMap = new Map<String, Case>([Select Id, CaseNumber, OwnerId From Case Where Id IN :caseIds]); 

		        counter = 0;
		        for(Database.SaveResult caseres :caseResults) {
		        	String caseLocalId = caseLocalIdByIndex.get(counter);

		        	CaseResultWrapper resW = new CaseResultWrapper();
		        	resW.localId = caseLocalId;
		        	resW.guid = caseGuidByLocalId.get(caseLocalId);

	    			if(caseres.isSuccess()) {
	    				resW.success = true;
						System.debug('successfully executed the API');
	    				Case caseRec = caseMap.get(caseres.getId());
	    				resW.caseNumber = caseRec.CaseNumber;

	    				caseIdByLocalId.put(caseLocalId, caseRec.Id);
		    		} else {
                        System.debug('error in executing the API');
		    			resW.success = false;

		    			String errMsg = '';
		    			for(Database.Error err :caseres.getErrors()) {
		    				errMsg += ' ' + err.getMessage();
		    			}

		    			resW.errorMessage = errMsg;
		    		}

		    		casesResponse.add(resW);
		    		counter++;
	    		}

	    		Boolean isImagesTooLarge = false;
	    		List<String> imageNames = new List<String>();
	    		Map<String, List<Attachment>> attachmentsByCaseId = new Map<String, List<Attachment>>();

	    		for(RequestWrapper reqW :casesToBeCreated) {
	    			String caseId = caseIdByLocalId.get(reqW.localId);

	    			if(null != reqW.attachments && !reqW.attachments.isEmpty()) {
	    				for(AttachmentWrapper attWr :reqW.attachments) {
	    					String fileName = attWr.name;
	    					String imagedata = attWr.body;
							string picStr =  imagedata.substring(imagedata.lastIndexOf(',')+1);
							Blob pic = EncodingUtil.base64Decode(picStr);

							Integer imageSizeInKB = pic.size()/1000;

							if(imageSizeInKB > 1000) {
								isImagesTooLarge = true;
								imageNames.add(fileName);
							}

							attWr.attObj = new Attachment (ParentId = caseId,
							                            Body = pic,
							                            ContentType = 'image/jpg',
							                            Name = fileName);
		    			
							if(attachmentsByCaseId.containsKey(caseId)) {
								attachmentsByCaseId.get(caseId).add(attWr.attObj);
							} else {
								attachmentsByCaseId.put(caseId, new List<Attachment>{attWr.attObj});
							}
	    				}
		    		}
	    		}

	    		if(isImagesTooLarge) {
	    			throw new CustomException('Image too large, Image size must not be greater than 1MB. The following images "' + String.join(imageNames, ', ') + '" are larger');
	    		}

	    		// create attachments
	    		for(String caseId :attachmentsByCaseId.keySet()) {
	    			if(caseMap.containsKey(caseId)) {
			    		WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseMap.get(caseId), attachmentsByCaseId.get(caseId));
		            	attachmentCreator.createCaseAttachment();
		            }
	            }

	    		// update all NotesAndAttachment records thats get created on creation of attachments with given DateTime
	    		Map<String, NoteOrAttachment__c> customAttsByStandardAttId = new Map<String, NoteOrAttachment__c>();
	    		for(NoteOrAttachment__c customAtt :[Select Id, Attachment__c, Attachment_DateTime__c From NoteOrAttachment__c Where Case__c IN :attachmentsByCaseId.keySet()]) {
	    			customAttsByStandardAttId.put(customAtt.Attachment__c, customAtt);
	    		}

	    		List<NoteOrAttachment__c> customAttsToBeUpdated = new List<NoteOrAttachment__c>();
	    		for(RequestWrapper reqW :casesToBeCreated) {
	    			String caseId = caseIdByLocalId.get(reqW.localId);

	    			if(null != reqW.attachments && !reqW.attachments.isEmpty()) {
	    				for(AttachmentWrapper attWr :reqW.attachments) {

	    					if(customAttsByStandardAttId.containsKey(attWr.attObj.Id)) {
	    						NoteOrAttachment__c cusAtt = customAttsByStandardAttId.get(attWr.attObj.Id);
	    						Long cdtInMillis = attWr.createdDateTime;
	    						
	    						if(null == cdtInMillis) {
	    							cusAtt.Attachment_DateTime__c = Datetime.now();
	    						} else {
	    							cusAtt.Attachment_DateTime__c = Datetime.newInstance(cdtInMillis);
	    						}

	    						customAttsToBeUpdated.add(cusAtt);
	    					}
	    				}
	    			}
                }
                
                update customAttsToBeUpdated;
            }
            response.success = true;
            response.caseResults.addAll(casesResponse);
        } catch(Exception ex) {
            Database.rollback(caseCreationSP);

			response.success = false;
			response.errorMessage = ex.getMessage();

			ApplicationLogMessage logMsg = new ApplicationLogMessage();
            logMsg.source = 'CaseCreationMobileService';
            logMsg.sourceFunction = 'doPost';
            logMsg.logMessage = 'An exception occurred';
            logMsg.debugLevel = DEBUG_LOG_LEVEL_ERROR;
            logMsg.logMessage = ex.getMessage();
            logMsg.ex = ex;
            logMessages.add(logMsg);
            System.debug('logMsg = '+logMsg);
		} finally {
			ApplicationLogUtility.logMessage(logMessages);
            logMessages.clear(); 
		}
        system.debug('response.isSuccess = '+response.success);
        return response;
    }

    public static Contact resetAppContactPhoneFields(Id conId){
        System.debug('conId: '+conId);
    	if(conId != null)
        cont = [SELECT Id, Phone, MobilePhone, HomePhone, Other_Phone__c, Normalized_Work_Phone__c, Normalized_Mobile__c, Normalized_Home_Phone__c, Normalized_Other_Phone__c
        						 FROM Contact 
        						 WHERE Id =:conId 
        						 LIMIT 1];
		System.debug('cont: '+cont);
        if(cont.Normalized_Mobile__c == cont.Normalized_Home_Phone__c)
            cont.HomePhone = '';
        if(cont.Normalized_Mobile__c == cont.Normalized_Other_Phone__c)
            cont.Other_Phone__c = '';
        if(cont.Normalized_Mobile__c == cont.Normalized_Work_Phone__c)
            cont.Phone = '';
        
        Database.DMLOptions updateDmlOpt = new Database.DMLOptions();
        updateDmlOpt.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult matchedContactUpdateResults = Database.update(cont, updateDmlOpt);
        return cont;
    }

    public static void updateMatchedRecord(Id matchedConId, RequestWrapper reqW){
    	
        if(matchedConId != null){
        	matchedContact = [SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, HomePhone, Other_Phone__c, Normalized_Work_Phone__c, Normalized_Mobile__c, 
                              Normalized_Home_Phone__c, Normalized_Other_Phone__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
        						 FROM Contact 
        						 WHERE Id =:matchedConId 
        						 LIMIT 1];
        }
        
        if(String.isNotEmpty(reqW.FirstName)) matchedContact.FirstName = reqW.FirstName;
        if(String.isNotEmpty(reqW.LastName)) matchedContact.LastName = reqW.LastName;
        System.debug('Email in matched Contact : '+matchedContact.Email);
        
        if(matchedContact.Email == reqW.Email) {
            //workphone set
            System.debug('email is same.Updating phone.'+reqW);
			if(reqW.mobile != matchedContact.MobilePhone && 
               reqW.mobile != matchedContact.Other_Phone__c &&
               reqW.mobile != matchedContact.Phone &&
               reqW.mobile != matchedContact.HomePhone &&
               reqW.mobile != '') 
                matchedContact.mobilephone = reqW.mobile;
        } else {
            System.debug('email is not same.'+reqW);
            if(String.isNotEmpty(reqW.Email)) matchedContact.Email = reqW.Email;
        }
    
        if(String.isNotEmpty(reqW.MailingStreet)) matchedContact.MailingStreet = reqW.MailingStreet;
        if(String.isNotEmpty(reqW.MailingCity)) matchedContact.MailingCity = reqW.MailingCity;
        if(String.isNotEmpty(reqW.MailingState)) matchedContact.MailingState = reqW.MailingState;
        if(String.isNotEmpty(reqW.MailingPostalCode)) matchedContact.MailingPostalCode = reqW.MailingPostalCode;
        if(String.isNotEmpty(reqW.MailingCountry)) matchedContact.MailingCountry = reqW.MailingCountry;

        Database.DMLOptions updateDmlOption = new Database.DMLOptions();
        updateDmlOption.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult matchedContactUpdateResults = Database.update(matchedContact, updateDmlOption);
        System.debug('result = '+matchedContactUpdateResults.isSuccess());
        System.debug('Error is :'+matchedContactUpdateResults.getErrors());      
		
    }

    global class RequestWrapper {
    	// Case Details
    	public String mode {get; set;}
    	public String category {get; set;}
    	public String location {get; set;}
    	public Double incidentLatitude {get; set;}
    	public Double incidentLongitude {get; set;}
    	public String description {get; set;}
    	public String originDetail {get; set;}
    	public String localId {get; set;}
    	public Id contactId;

    	// Contact details
    	public Boolean toBeContacted {get; set;}
		public String firstName {get; set;}
    	public String lastName {get; set;}
    	public String email {get; set;}
    	public String mobile {get; set;}
    	public String mailingStreet {get; set;}
    	public String mailingCity {get; set;}
    	public String mailingState {get; set;}
    	public String mailingPostalCode {get; set;}
    	public String mailingCountry {get; set;}

    	public List<AttachmentWrapper> attachments {get; set;}

    	public RequestWrapper() {
			attachments = new List<AttachmentWrapper>();	
    	}
    }

    global class AttachmentWrapper {
    	public String name {get; set;}
    	public String body {get; set;}
    	public Long createdDateTime {get; set;}
    	public Attachment attObj {get; private set;}
    }

    global class ResponseWrapper {
    	public Boolean success {get; set;}
    	public String errorMessage {get; set;}
    	public List<CaseResultWrapper> caseResults {get; set;}

    	public ResponseWrapper() {
    		success = false;
    		caseResults = new List<CaseResultWrapper>();
    	}
    }

    global class CaseResultWrapper {
    	public Boolean success {get; set;}
    	public String errorMessage {get; set;}
    	public String localId {get; set;}
    	public String guid {get; set;}
    	public String caseNumber {get; set;}

    	public CaseResultWrapper() {
    		success = false;
    	}
    }

    // generate a global/universal unique identifier
    private static String generateGUID() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

        return guid;
    }
}