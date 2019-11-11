@isTest
private class CaseEntitlementUtil_Test
{
	static Entitlement testEntitlement;
	static MilestoneType testMs;
	@testSetup static void setup() {
		ApplicationLog_Test.setLoggingSettings();
		Account testAccount= new Account(Name='Test'); 

		insert testAccount;
		System.runAs(new User(Id=UserInfo.getUserId())){
			testMs= new MilestoneType(Name='Test');
				
			insert testMs;
		}
		System.runAs(new User(Id=UserInfo.getUserId())){
			testEntitlement= new Entitlement(Name='Test', AccountId=testAccount.Id);
			insert testEntitlement;
		}
    }

	@isTest
	static void testInstantiation()
	{
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
		system.assertNotEquals(null,testCaseEntitlement);
	}

	@isTest
	static void testAssignACase(){
		Case busCase=new Case(Id=UtilityClass.getFakeId(Case.sObjectType), OwnerAgency__c='Test', EntitlementId=null);
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
		
		testCaseEntitlement.assign(busCase);
		system.assertNotEquals(null,busCase.EntitlementId);
		


	}
	@isTest
	static void testAssignACaseFailsBadInput(){
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
		Case blank=null;
		testCaseEntitlement.assign(blank);
		List<Application_Log__c> alog= [select Id from Application_Log__c ];
		system.assert(alog.size()>0);
		


	}

	@isTest
	static void testGetOldMilestone(){
		Account testAccount2= new Account(Name='Test2');

		insert testAccount2;
		SlaProcess staProcess=[SELECT Id, Name, NameNorm, Description, IsActive, VersionNumber, IsVersionDefault, VersionNotes, VersionMaster, StartDateField, CreatedDate FROM SlaProcess where Name='STA' order by VersionNumber desc limit 1];
		system.debug('STA process -'+staprocess);
		insert new Entitlement(Name='STA', AccountId=testAccount2.Id,SlaProcessId=staProcess.Id);
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
	
		Id staEntId=CaseEntitlementUtil.entitlementIdByAgencyName.get('STA');
		system.debug('Sta Entitlement  -'+staEntId);
		List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
		RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
		Case busCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
								Description='I was Injured because of the sharp metal jutting out ',
								RecordTypeId=BUS.Id,
								Status='New',
								Origin='Email',
								Priority='Normal',
								Response_Requested__c='Yes',
								Type='Complaint',
								OwnerAgency__c='Serco',
								EntitlementId=staEntId
								 );
		Test.startTest();

		insert busCase;
		busCase.Date_Assigned_to_Agency__c=System.now();
		busCase.OwnerAgency__c='STA';
		update busCase;
		Test.stopTest();
		CaseEntitlementUtil.casesWithOldEntitlements.add(busCase.Id);
		system.debug('CaseEntitlementUtil.casesWithOldEntitlements -'+CaseEntitlementUtil.casesWithOldEntitlements);
		List<CaseMilestone> milesToGo= testCaseEntitlement.getOldMilestones();
		system.debug('got old milestones  -'+milesToGo);
		system.assert(milesToGo.size()>0);
	}
	
	@isTest
	static void testGetOldMilestoneException(){
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
		CaseEntitlementUtil.casesWithOldEntitlements=null;
		List<CaseMilestone> milesToGo= testCaseEntitlement.getOldMilestones();
		List<Application_Log__c> alog= [select Id from Application_Log__c ];
		system.assert(alog.size()>0);
	}
	@isTest
	static void testAssign(){
		Case busCase=new Case(Id=UtilityClass.getFakeId(Case.sObjectType), OwnerAgency__c='Test');
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
		Map<Id,String> agencyByCaseId=new Map<Id,String>();
		agencyByCaseId.put(busCase.Id,'Test');
		List<Case> casesForUpdate=testCaseEntitlement.assign(agencyByCaseId);
		system.assertNotEquals(0,casesForUpdate.size());
		agencyByCaseId.put(busCase.Id,'Not There');
		casesForUpdate=testCaseEntitlement.assign(agencyByCaseId);
		system.debug(casesForUpdate);


	}

	@isTest
	static void testPercolateContactedTimestamps(){
		DateTime now=System.now();
		List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
		RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
		Case busCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
								Description='I was Injured because of the sharp metal jutting out ',
								RecordTypeId=BUS.Id,
								Status='New',
								Origin='Email',
								Priority='Normal',
								Contact_Attempted_Timestamp__c=now, 
								Contact_Made_Timestamp__c=now );
		insert busCase;
		Case childCase= new Case(Subject='I was Injured because of the sharp metal jutting out ',
								Description='I was Injured because of the sharp metal jutting out ',
								RecordTypeId=BUS.Id,
								parentId=busCase.Id,
								Status='New',
								Origin='Email',
								Priority='Normal',
								Contact_Attempted_Timestamp__c=null, 
								Contact_Made_Timestamp__c=null);
		insert childCase;
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
		Map<Id,Case> parentCases= new Map<Id,Case>();
		Map<Id,Case> childCasesForUpdate=testCaseEntitlement.percolateContactedTimestamps(null);
		system.assertEquals(0,childCasesForUpdate.size());
		parentCases.put(busCase.Id,busCase);
		childCasesForUpdate=testCaseEntitlement.percolateContactedTimestamps(parentCases);
		system.assertNotEquals(0,childCasesForUpdate.size());

	}

	@isTest
	static void testCheckMilestoneCompletion(){
		DateTime now=System.now();

		Case oldCase= new Case();
		Case newCase= new Case();
		oldCase.Contact_Attempted_Timestamp__c=null;
		oldCase.Contact_Made_Timestamp__c=null;
		oldCase.status='test';

		newCase.Contact_Attempted_Timestamp__c=now;
		newCase.Contact_Made_Timestamp__c=now;
		newCase.status=GlobalConstants.CASE_SOFTCLOSED_STATUS;
		newCase.OwnerAgency__c= GlobalConstants.AGENCY_NSW_TRAINS;


		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();

		Set<Id> milestoneTypeIds=testCaseEntitlement.checkMilestoneCompletion(null,  null);
		
		system.assertEquals(0,milestoneTypeIds.size());
		milestoneTypeIds=testCaseEntitlement.checkMilestoneCompletion(oldCase,  newCase);
		system.assertEquals(2,milestoneTypeIds.size());

		newCase.OwnerAgency__c=GlobalConstants.AGENCY_TfNSW;
		milestoneTypeIds=testCaseEntitlement.checkMilestoneCompletion(oldCase,  newCase);
		system.assert(milestoneTypeIds.contains(CaseEntitlementUtil.milestoneIdByString.get(GlobalConstants.MILESTONE_IN_PROGRESS)));
		system.assert(milestoneTypeIds.contains(CaseEntitlementUtil.milestoneIdByString.get(GlobalConstants.MILESTONE_CASE_CLOSED)));

		newCase.OwnerAgency__c=GlobalConstants.AGENCY_HCF;
		milestoneTypeIds=testCaseEntitlement.checkMilestoneCompletion(oldCase,  newCase);
		system.assert(milestoneTypeIds.contains(CaseEntitlementUtil.milestoneIdByString.get(GlobalConstants.MILESTONE_CONTACT_MADE)));
		system.assert(milestoneTypeIds.contains(CaseEntitlementUtil.milestoneIdByString.get(GlobalConstants.MILESTONE_CASE_CLOSED)));
		
		newCase.Status=GlobalConstants.CASE_SOFTCLOSED_STATUS_STA;
		newCase.OwnerAgency__c=GlobalConstants.STA_AGENCY;
		milestoneTypeIds=testCaseEntitlement.checkMilestoneCompletion(oldCase,  newCase);
		system.assert(milestoneTypeIds.contains(CaseEntitlementUtil.milestoneIdByString.get(GlobalConstants.MILESTONE_CONTACT_MADE)));
		system.assert(milestoneTypeIds.contains(CaseEntitlementUtil.milestoneIdByString.get(GlobalConstants.MILESTONE_CASE_CLOSED)));
	}
	@isTest
	static void testCompleteMilestoneFailsForBadInput(){
	
		CaseEntitlementUtil testCaseEntitlement= new CaseEntitlementUtil();
		List<CaseMilestone>completeMilestones= testCaseEntitlement.completeMilestones(null);
		system.assertEquals(0,completeMilestones.size());
	}
	@isTest
	static void testUpdateCaseTargetDateFailsForBadInput(){
		Test.startTest();
		CaseEntitlementUtil.updateCaseTargetDate(null);
		Test.stopTest();
		List<Case> cases = [select id from Case]; 
		system.assertEquals(0,cases.size());
	}

	@isTest
	static void testDetectAgencyChange(){
		CaseEntitlementUtil entitle = new CaseEntitlementUtil();
		Test.startTest();
		Test.stopTest();
		
	}
	@isTest
    static void testDetermineMultiAgency() {
    	String child1Id= UtilityClass.getFakeId(Case.sObjectType);
    	String child2Id= UtilityClass.getFakeId(Case.sObjectType);
    	String parentCaseId=UtilityClass.getFakeId(Case.sObjectType);
    	Case child1= new Case(Id=child1Id, OwnerAgency__c='STA', multiAgency__c=false, parentId=parentCaseId);    	
    	Case child2= new Case(Id=child2Id, OwnerAgency__c='NSW Trains', multiAgency__c=false, parentId=parentCaseId);
    	

    	Case parent= new Case(Id=parentCaseId,multiAgency__c=false);

    	List<Case> children=new List<Case>();
		children.add(child1);
    	children.add(child2);

       	CaseEntitlementUtil entitle = new CaseEntitlementUtil();
    	Map<Case,List<Case>> suspectParentChild= new Map<Case,List<Case>>();
    	suspectParentChild.put(parent,children);
    	Map<Id,Case> casesForUpdate=entitle.determineMultiAgency(suspectParentChild);
    	system.assertEquals(3,casesForUpdate.size());
        
    }
}