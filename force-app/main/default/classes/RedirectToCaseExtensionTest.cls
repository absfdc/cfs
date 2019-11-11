@isTest
public class RedirectToCaseExtensionTest {
	
    @isTest
	static void caseExtTest() {
        
        Case cs = new Case();
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
								OwnerAgency__c='Serco'
								 );
        insert busCase;
        ApexPages.StandardController sc = new ApexPages.StandardController(busCase);
        RedirectToCaseExtension test = new RedirectToCaseExtension(sc);
        test.getBaseURL();
    }
}