/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A case controller extension for SME selection publisher action

Test Class:    SmeSelectionPublisherAction_Test
History
9 Apr 2015      Dipankar Barman     created
------------------------------------------------------------*/
global with sharing class SmeSelectionPublisherAction_CX {
	public Case thisCase{get;set;}//hidden field in page mapped to its Id
	public RecordType staffType{get;set;}//hidden field in page mapped to its Id
	public SmeSelectionPublisherAction_CX(final ApexPages.StandardController std) {
		if(!test.isRunningTest()) std.addFields(new List<String>{'Assigned_Sme__c','Agency__c','OwnerAgency__c','parentId','modes__c'});
		if(((Case)std.getRecord()).parentId!=null || ((Case)std.getRecord()).modes__c!=GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE) thisCase=(Case)std.getRecord();
		staffType=[SELECT ID FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName =:GlobalConstants.CASE_RECORD_TYPE_STAFF limit 1];

	}


	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Inner bean class represents the data for a Node

	History
	9 Apr 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	global class Node{
		public String id {get;set;}//every node is given an unique id
		public String parent {get;set;}// will be used for placement within hierarchy
		public String text {get;set;}//what will be displayed on the UI
		public State state{get;set;}//selected etc
	}

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   Inner bean class represents the state of a Node

	History
	9 Apr 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	global class State{
		public Boolean selected {get;set;}
		public Boolean opened {get;set;}
	}

	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   remoteaction to obtain the list of SME
	Parameters: 	staff record Type and if agency already stamped
	
	History
	9 Apr 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	@RemoteAction
	global static List<Node> getSmes(Id staffType, String agency, Id smeId) {
		Map<Id,Node> smeNodes= new Map<Id,Node>();
		List<Contact> agencies;
		if (String.isEmpty(agency)){
			agencies=[select Id,Name, Account.Type, Account.Id, Account.Name ,Account.parent.Id, Account.parent.Name from contact where recordTypeId=:staffType and Account.Type=:GlobalConstants.ACCOUNT_TYPE_DIVISION];
		}else{
			agencies=[select Id,Name, Account.Type, Account.Id, Account.Name ,Account.parent.Id, Account.parent.Name from contact where Account.parent.Name=:agency and recordTypeId=:staffType and Account.Type=:GlobalConstants.ACCOUNT_TYPE_DIVISION];
		}
		for(Contact sme: agencies){
			Node agencyNode;
			if(!smeNodes.containsKey(sme.Account.Parent.Id)){	
				agencyNode= new Node();
				agencyNode.id=sme.Account.Parent.Id;
				agencyNode.text=sme.Account.Parent.Name;
				agencyNode.parent='#';
				State st= new State();
				agencyNode.state=st;

				if(agency!=null && agency.equalsIgnoreCase(agencyNode.text) ){
					st.selected=false;
					st.opened=true;
				}else{
					st.selected=false;
					st.opened=false;
				}
				smeNodes.put(agencyNode.Id,agencyNode);

			}
			
			Node divisionNode;
			if(!smeNodes.containsKey(sme.Account.Id)){
				divisionNode= new Node();
				divisionNode.id=sme.Account.Id;
				divisionNode.text=sme.Account.Name;
				divisionNode.parent=sme.Account.Parent.Id;
				
				smeNodes.put(divisionNode.Id,divisionNode);

			}

			Node smeNode= new Node();
			smeNode.text=sme.Name;
			smeNode.id=sme.Id;
			smeNode.parent=sme.Account.Id;
			State st= new State();	
			if(smeId!=null && smeId==smeNode.Id){
				st.opened=true;
				st.selected=true;
			}
			smeNode.state=st;
			smeNodes.put(smeNode.Id,smeNode);

		}


		return smeNodes.values();
		

	}



	/*------------------------------------------------------------
	Author:        Dipankar Barman
	Company:       Arxxus.com
	Description:   This method updates the case with selected sme
	Inputs:        caseid, smeid
	History
	9 Apr 2015      Dipankar Barman     created
	------------------------------------------------------------*/
	@RemoteAction
	global static void updateSme(string caseId, String smeId) {
		List<ApplicationLogMessage> lms = new List<ApplicationLogMessage>();	
		try{
			caseId=String.escapeSingleQuotes(caseId);
			Case thisCase=[select Id,Assigned_Sme__c from Case where Id=:caseId];
			thisCase.Assigned_SME__c=smeId;
			update thisCase;
		}catch(Exception e){
			system.debug('Caught exception - '+e);
			ApplicationLogMessage lm = new ApplicationLogMessage();
			lm.source='SmeSelectionPublisherAction_CX';
			lm.sourceFunction='updateSme';
			
			lm.logMessage=e.getMessage();
			lm.ex=e;
			lm.debugLevel=GlobalConstants.ERROR;
			
			lms.add(lm);
			throw e;
			
		}finally{
			ApplicationLogUtility.logMessage(lms);
		}
		
	}

}