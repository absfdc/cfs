@isTest
private class TimeWithAdminCalculator_Test {

    private static List<Case> cases;

    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try{
            TimeWithAdminCalculator calculator = new TimeWithAdminCalculator(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForSingleCase() {
        setupTestData(1);
        insert cases;
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRecord : cases) {
            caseIds.add(caseRecord.Id);
        }
        System.Test.startTest();
        TimeWithAdminCalculator calculator = new TimeWithAdminCalculator(caseIds);
        calculator.calculate();
        System.Test.stopTest();
        for(Case caseRecord : [SELECT Id, Time_with_Admin__c FROM Case WHERE Id IN :caseIds]) {
            System.debug('Calculated time with admin: ' + caseRecord.Time_with_Admin__c);
            System.assert(caseRecord.Time_with_Admin__c != null);
        }
    }
    
    private static testMethod void testForBulkOperation() {
        setupTestData(5);
        insert cases;
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRecord : cases) {
            caseIds.add(caseRecord.Id);
        }
        System.Test.startTest();
        TimeWithAdminCalculator calculator = new TimeWithAdminCalculator(caseIds);
        calculator.calculate();
        System.Test.stopTest();
        for(Case caseRecord : [SELECT Id, Time_with_Admin__c FROM Case WHERE Id IN :caseIds]) {
            System.debug('Calculated time with admin (bulk): ' + caseRecord.Time_with_Admin__c);
            System.assert(caseRecord.Time_with_Admin__c != null);
        }
    }
    
    private static testMethod void testForNonGISCase() {
        setupTestData(1);
        cases[0].OwnerId = UserInfo.getUserId();
        insert cases;
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRecord : cases) {
            caseIds.add(caseRecord.Id);
        }
        System.Test.startTest();
        TimeWithAdminCalculator calculator = new TimeWithAdminCalculator(caseIds);
        System.Test.stopTest();
        for(Case caseRecord : [SELECT Id, Time_with_Admin__c FROM Case WHERE Id IN :caseIds]) {
            System.assert(caseRecord.Time_with_Admin__c == null);
        }
    }   
    
    private static void setupTestData(Integer caseCount) {
        cases = new List<Case>();
        List<BusinessHours> businessHrs = [SELECT b.Name, b.Id FROM BusinessHours b WHERE b.IsActive = true];
        List<Group> groups = [SELECT g.Id, g.DeveloperName FROM Group g WHERE g.Type = 'Queue' AND g.DeveloperName = :GlobalConstants.GIS_ADMIN_QUEUE];
        for(Integer index = 0; index < caseCount; index++) {
            Case caseRecord = new Case();
            if(!businessHrs.isEmpty()) {
                caseRecord.BusinessHoursId = businessHrs[0].Id;
            }
            if(!groups.isEmpty()) {
                caseRecord.OwnerId = groups[0].Id;
            }
            caseRecord.Agency__c = GlobalConstants.RMS_AGENCY;
            cases.add(caseRecord);
        }
    }
}