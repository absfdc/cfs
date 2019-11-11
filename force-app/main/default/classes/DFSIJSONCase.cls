/*
Date        :December 2017 
Description :Main class for parsing,creating cases queried from DFSI
:Class needs to be finalised based on business outcome on how to create contacts
Test Class: DFSIFeedbackAssistTest
*/
public class DFSIJSONCase
{
	//local constants
	public static final String MULTI_ISSUE='Multi Issue';
	public static final String SUGGESTION='Suggestion';
	public static final String FEEDBACK='Feedback';
	public static final String MED_OR_LOW='Normal';
	public static final String DFSI='DFSI';
	public static final String TRIAGE='Triage';
	public static final String NOTPROVIDED='Not provided';
	public static final String FeedbackAssistCorporate='Feedback Assist Corporate';
	public static DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForRMS = new DFSI_Case_Owner_And_RecordType_Ids__c();
	public static DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForTransport = new DFSI_Case_Owner_And_RecordType_Ids__c();	

	public static List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

	//method for parsing json
	public static boolean parse(String jsonStr)
	{
		try
		{
			objCustomSettingForRMS = [select name, Owner_Id__c, RecordTypeId__c
									from DFSI_Case_Owner_And_RecordType_Ids__c
									where name = 'RMS' limit 1];
			objCustomSettingForTransport = [select name, Owner_Id__c, RecordTypeId__c
										from DFSI_Case_Owner_And_RecordType_Ids__c
										where name = 'Transport' limit 1];
			
			DFSIGetCaseResponse dGetResponseCase = (DFSIGetCaseResponse)JSON.deserialize(jsonStr.replaceAll('__c', ''), DFSIGetCaseResponse.class);
			Schema.SObjectField f = Case.Fields.DFSICaseID__c;
			
			Savepoint sp = Database.setSavepoint();
			boolean errorOccured = false;
			list<Database.UpsertResult> cr = new list<Database.UpsertResult>();
			list<case> caselist = new list<case>();
			caselist =  generateCase(dGetResponseCase.Cases);
			if(caselist != null)
			{
				cr = Database.upsert( caselist, Case.Fields.DFSICaseID__c,false);
			}
			string errormessage = '';
			If(cr != null)
			{
				for(Integer index = 0, size = cr.size(); index < size; index++) 
				{
				    if(!(cr[index].isSuccess())) 
				    {
				    			errorOccured = true;
				    			List<Database.Error> E = cr[index].geterrors();
				            errormessage += 'Status Code is: '+ E[0].getStatusCode() +  ' Error Message is: '+ E[0].getMessage() + ' DFSI Case Number is: ' +caselist[index].DFSICaseNumber__c + '\n';
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
		catch(Exception e)
		{
			DFSICoreService.writeToApplicationLogAndSendEmail('DFSIJSONCase', //write to application log, stacktrace
												'parse',
												e.getMessage(),
												e,
												'Error');
		system.debug('Exception is:::'+e+'message is :'+e.getMessage());
		return false;
		}
		return true;
	}

	public static String generateCaseDescription(string what,string expectation,string additionalcomments)
	{
		string casedescription='';
		if(string.isNotEmpty(what) && what!=null)
		{
			casedescription+='What-\n'+what+'\n\n';
		}
	
		if(string.isNotEmpty(expectation) && expectation!=null)
		{
			casedescription+='Expectation-\n'+expectation+'\n\n';
		}
		if(string.isNotEmpty(additionalcomments) && additionalcomments!=null)
		{
			casedescription+='Additional Comments-\n'+additionalcomments+'\n\n';
		}
		return casedescription;
	}
	
	public static list<string> generateName(string SuppliedName)
	{
		list<string> FirstNameAndLastName= new list<string>();
		string fullname = SuppliedName;
		string name = fullname.trim();
    
		if (name.contains(' ') == true)
		{
			list<string> lstname= new list<string>();
			lstname = name.split(' ');
			if(lstname.size() == 2 && lstName[0].length() < 40)
			{
				FirstNameAndLastName.add(lstName[0]);
				FirstNameAndLastName.add(lstName[1]);
			}
			else if(lstName[0].length() > 40)
			{
				FirstNameAndLastName.add(fullname);
			}
			else
			{
				integer loopcounter = 0;
				string concatenatedLastName = '';
				for(String s: lstname)
				{
					if(loopcounter == 1)
					concatenatedLastName = concatenatedLastName + s;
					else
					if(loopcounter > 1)
					concatenatedLastName = concatenatedLastName +' '+ s;
					loopcounter ++;
				}
				
				FirstNameAndLastName.add(lstName[0]);
				FirstNameAndLastName.add(concatenatedLastName);
			}
		}
		else if(name.length() > 40)
		{
			FirstNameAndLastName.add(name);
		}
		else
		{
			FirstNameAndLastName.add(name);
			FirstNameAndLastName.add(NOTPROVIDED);
		}
		
		return FirstNameAndLastName;
	}
	
	public static Contact generateNameWithContact(Contact objContact, string SuppliedName)
	{
		Contact C = objContact;
		list<string> s = generateName(SuppliedName);
		if(s.size()==1)
		{
			c.lastname = s[0];
		}
		else
		{
			c.firstname = s[0];
			c.lastname = s[1];
		}
		return c;
	}
	//generate case using case list
	public static List<Case> generateCase(List<DFSICase> dCaseLst)
	{
		List<Case> CaseLst=new List<Case>();
		Map<String,Id> CaseContactMatchMap= new Map<String,Id>();
        
        List<Contact> conlist= new List<Contact>();//create contacts associated with the case
        
        List<String> fNameList = new List<String>();//list of fName,lName,Email,phone
        List<String> lNameList = new List<String>();
        List<String> EmailList = new List<String>();
        List<String> PhoneList = new List<String>();
        
        Map<String,Id> CaseConMap= new Map<String,Id>();
        		// moved the try block here 
		try
		{
			for(DFSICase d:dCaseLst)
			{
				if(d.Type!=SUGGESTION)
				{
					Contact c= new contact();   
                    if(String.isNotEmpty(d.SuppliedEmail))
                    {
						EmailList.add(d.SuppliedEmail);
						c.email = d.SuppliedEmail;
                    }
                    
					if(String.isNotEmpty(d.SuppliedPhone))
					{
						PhoneList.add(d.SuppliedPhone);
						c.phone = d.SuppliedPhone;
					}
	                
	                if(String.isNotEmpty(d.SuppliedName))
	                {    
						c = generateNameWithContact(c,d.SuppliedName);
						lNameList.add(c.LastName);
						conlist.add(c);
					}
					system.debug('adding contact'+c);
					
				}
			}
			system.debug('EmailList '+EmailList);
            system.debug('PhoneList '+PhoneList);
            system.debug('lNameList '+lNameList);
            
            system.debug('conlist '+conlist);
            Database.UpsertResult[] sr;
            system.debug('contact list++++++'+conlist.size());
            if(conlist != null)
			{
            		sr=Database.upsert(conlist,FALSE);
			}
            List<ID> conlistids=new List<ID>();
            if(sr.size() != null)
            for(Database.UpsertResult s:sr)
            {
                if(s.isSuccess())
                {
                	    conlistids.add(s.getId());
                }
                /*else
                {
                			Database.rollback(sp1);
                			return null;
                }*/
            }
            
            system.debug('conlistids '+conlistids);
            
			if(conlistids != null)
			{
				for(Contact c:[SELECT Id,FirstName,LastName,Email,Phone 
                               FROM Contact 
                               WHERE ID IN :conlistids OR
                               (LastName IN :lNameList AND (Email IN :EmailList OR Phone IN :PhoneList)) ])
				{
					
					string email=(c.Email==NULL)?'':c.Email.toLowerCase();
					string workphone=(c.Phone==NULL)?'':c.Phone;
					string lname=(c.LastName==NULL)?'':c.LastName.toLowerCase();
					CaseConMap.put(lname+email+workphone,c.Id);
				}
			}
            
            system.debug('CaseConMap '+CaseConMap);
            
	
			Id MultiIssueRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(MULTI_ISSUE).getRecordTypeId();
            Id RMSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Road').getRecordTypeId();
			Id DFSICaseOwnerID=[SELECT Name,Id,DeveloperName 
			FROM Group 
			WHERE DeveloperName=:Label.Serco_Web_Triage_Queue].Id;
			
			Id RMSOwnerId=[SELECT Name,Id,DeveloperName 
			FROM Group 
			WHERE DeveloperName=:Label.RMS_Queue].Id;
            
            Id RMS_CAD_Communications_QueueId=[SELECT Name,Id,DeveloperName 
			FROM Group 
			WHERE DeveloperName=:Label.RMS_CAD_Communications_Queue].Id;
			
			for(DFSICase d:dCaseLst)
			{
				Case c= new Case();
				system.debug('Attachments when not provided:'+d.CombinedAttachments);
				
				if(d.CombinedAttachments == null )
				{
					if(d.RecordTypeId == objCustomSettingForRMS.RecordTypeId__c)
					{
						c.OwnerId = RMSOwnerId; //add RMS queue id
					}
					else
					{
						c.OwnerId = DFSICaseOwnerID; //this is serco queue i.e transport
					}
					
					c.DFSI_Attachment_Synced__c = true;
				}
				c.RecordTypeId=MultiIssueRecordTypeId;
				c.DFSICaseID__c	= d.Id;
				c.DFSICaseNumber__c = d.CaseNumber;
				c.Origin=d.Origin;
				c.Status=TRIAGE;
				c.Subject=d.Subject;
				c.Type=(d.Type==SUGGESTION?FEEDBACK:d.Type);
				c.DFSICreatedDate__c =(DateTime)JSON.deserialize('\"'+d.CreatedDate+'\"', DateTime.class); //date created needs to be in JSON format           
				c.Location_of_Incident__c =d.Location;
				c.DFSIPageSource__c=d.Page;
                
                if(d.Page!=null && d.Page.contains('parkingsigns.nsw.gov.au')){
                    c.OwnerId = RMS_CAD_Communications_QueueId;//Assign parkingsigns cases to a different configurable RMS queue
                    c.Taxonomy_Moment__c = 'Roads';
                    c.Taxonomy_Transaction__c = 'Traffic Management and Safety';
                    c.Taxonomy_Symptom__c = 'Parking';
                    c.Taxonomy_Location_Type__c = 'Roads';
                    c.Taxonomy_Area__c = 'Region';
                    c.Taxonomy_Location__c = 'Sydney';
                    c.Modes__c = 'Road';
                    c.RecordTypeId = RMSRecordTypeId;
                }                                                                               
                
				c.SuppliedName=d.SuppliedName;
				c.SuppliedEmail=d.SuppliedEmail;
				c.SuppliedPhone=d.SuppliedPhone;
				c.DFSIRecordTypeId__c = d.RecordTypeId;
				c.DFSISent_VIA_Rest__c =d.Sent_VIA_Rest;
				c.Description=generateCaseDescription(d.What,d.Expectation,d.Description);
				c.Priority=(d.Priority=='High'?d.Priority:MED_OR_LOW);
				c.Origin_Details__c = FeedbackAssistCorporate;
				
				if(String.isNotEmpty(d.SuppliedName) && d.SuppliedName!=NULL && d.SuppliedName!='')
				{
					c.Response_Requested__c='Yes';//whenever there is a contact associated, this flag needs to be checked
					list<string> names = generateName(d.SuppliedName);
					
					
					if(CaseConMap != null)
					if(names.size() == 1)
                        c.ContactId = CaseConMap.get((names[0].toLowerCase())+
                                                     (String.isEmpty(d.SuppliedEmail)?'':d.SuppliedEmail.toLowerCase())+
                                                     (String.isEmpty(d.SuppliedPhone)?'':d.SuppliedPhone));
					else
					c.ContactId = CaseConMap.get((names[1].toLowerCase())+
                                                     (String.isEmpty(d.SuppliedEmail)?'':d.SuppliedEmail.toLowerCase())+
                                                     (String.isEmpty(d.SuppliedPhone)?'':d.SuppliedPhone));
				}
				else
				{
					c.Response_Requested__c='No';
				}
				
				CaseLst.add(c);
			}
			system.debug('caselst is '+CaseLst);
		}

		catch(Exception e)
		{
			DFSICoreService.writeToApplicationLogAndSendEmail('DFSIJSONCase', //write to application log, stacktrace
													'generateCase',
													e.getMessage(),
													e,
													'Error');
		}
		return CaseLst;
	}
}