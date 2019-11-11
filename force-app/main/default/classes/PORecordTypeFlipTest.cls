@isTest
private class PORecordTypeFlipTest {
    
    private static List<Case> cases;    
    private static String mode;
    private static Id recordTypeId;
    
    private static testMethod void testForCaseDataUpdate() {
		mode = 'Bus';
        setUpTestData(100);
		Id pboQId = [select Id, Name FROM Group WHERE Type = 'Queue' AND Name like 'PBO - Blue Mountains Transit%' limit 1].Id;
        List<Case> casesToUpdate = new List<Case>();        
        for(Case cs : [SELECT Id, OwnerId FROM Case]) {
            cs.OwnerId = pboQId;
            casesToUpdate.add(cs);
        }
        System.debug('casestoupdate: '+casesToUpdate);
        Test.startTest(); 
        update casesToUpdate;
		Test.stopTest();       
    }
    
	private static void createCases(Integer caseCount) {
        cases = new List<Case>();
        for(Integer i=0; i < caseCount; i++) {
            Case caseRecord = new Case();
            caseRecord.Modes__c = 'Bus';
            caseRecord.Taxonomy_Accountability__c = '';
            caseRecord.Taxonomy_Location__c = 'Sydney';
            caseRecord.Agency__c = 'PBO';
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Compliment';
            caseRecord.Description = 'Test case for web to case creation';
            caseRecord.RecordTypeId = recordTypeId;
            
            cases.add(caseRecord);
        }
        insert cases;
    }
	private static void setUpTestData(Integer caseCount) {
        createQueueVsAgencyBranchDivCustomSetting();
        retrieveRecordTypes();
        createCases(caseCount);
        
    }
    private static void retrieveRecordTypes() {
		
        List<RecordType> rt = [ SELECT Id, Name FROM RecordType WHERE sObjectType = 'Case' AND Name = 'Bus'];
        if(!rt.isEmpty()) {
            recordTypeId = rt[0].Id;
        }
    }
	
    private static void createQueueVsAgencyBranchDivCustomSetting() {
        list <QueueVsAgency__c> mapping= new list <QueueVsAgency__c>();
        mapping.add(new QueueVsAgency__c(Name = '1', QueueName__c = 'PBO_Blue_Mountains_Transit', Agency__c = 'PBO', Division__c = 'Blue Mountains Transit', Branch__c = 'Blue Mountains Transit'));
        insert mapping;
    }

}