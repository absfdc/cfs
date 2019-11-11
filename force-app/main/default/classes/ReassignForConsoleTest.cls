@isTest
public class ReassignForConsoleTest {
    
    @isTest static void testvalidateAndReassign() {
        Case caseRecord = getCaseRecord();
        caseRecord.Taxonomy_Location__c  = 'Sydney';
        
        User caseOfficer1 = createCaseOfficerUser();
        User caseOfficer2 = createCaseOfficerUser();
        
        Test.startTest();
        system.runAs(caseOfficer1) {        
            insert caseRecord;
            PageReference pref = Page.ReassignForConsolex;
            pref.getParameters().put('id', caseRecord.Id);
            Test.setCurrentPageReference(pref);
            ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
            
            ReassignForConsole rfc = new ReassignForConsole(controller);
            rfc.caseId = caseRecord.Id;
            rfc.newCase = caseRecord;
            
            ReassignForConsole.validateAndReassign((String)(caseRecord.Id), (String)(caseOfficer1.Id));
            
        }
        Test.stopTest();
    }
    
    @isTest static void testvalidateAndReassignWithaQueue() {
        Group westConnexDLOQueue = new Group(Name='WestConnex DLO Queue', Type='Queue');
        insert westConnexDLOQueue;
        
        QueueSObject westConnexDLOQueueSObject = new QueueSObject(QueueID = westConnexDLOQueue.id, SObjectType = 'Case');
        insert westConnexDLOQueueSObject;
        
        Case caseRecord = getCaseRecord();
        caseRecord.Taxonomy_Location__c  = 'Sydney';
        
        User caseOfficer1 = createCaseOfficerUser();
        User caseOfficer2 = createCaseOfficerUser();
        
        Test.startTest();
        system.runAs(caseOfficer1) {        
            insert caseRecord;
            PageReference pref = Page.ReassignForConsolex;
            pref.getParameters().put('id', caseRecord.Id);
            Test.setCurrentPageReference(pref);
            ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
            
            ReassignForConsole rfc = new ReassignForConsole(controller);
            rfc.caseId = caseRecord.Id;
            rfc.newCase = caseRecord;
            
            ReassignForConsole.validateAndReassign((String)(caseRecord.Id), (String)(westConnexDLOQueue.Id));
            
        }
        Test.stopTest();
    }    
    
    @isTest static void testCancel() {
        Case caseRecord = getCaseRecord();
        caseRecord.Taxonomy_Location__c  = 'Sydney';
        
        User caseOfficer1 = createCaseOfficerUser();
        User caseOfficer2 = createCaseOfficerUser();
        
        Test.startTest();
        system.runAs(caseOfficer1) {
            insert caseRecord;
            PageReference pref = Page.ReassignForConsolex;
            pref.getParameters().put('Id', caseRecord.Id);
            Test.setCurrentPageReference(pref);
            ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
            
            ReassignForConsole rfc = new ReassignForConsole();
            rfc.Cancel();
        }
        Test.stopTest();
    }
    
    
    public static User createCaseOfficerUser() {
        UserRole dloRole = [Select Id From UserRole Where DeveloperName = 'DLO_WestConnex'];
        User user = new User();
        user.Username = 'cm'+ System.currentTimeMillis() + '@demo.com';
        user.FirstName = 'Serco';
        user.LastName = 'Agent';
        user.Email = 'md@demo.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [select id from Profile where Name='Senior MAGS Officer'].Id;
        user.UserRoleId = dloRole.Id;
        user.LanguageLocaleKey = 'en_US';
        insert user;
        return user;
    }
    
    public static Case getCaseRecord() {
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1];
        
        return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                        Status = 'New',
                        RecordTypeId = rt.Id,
                        Portfolio__c = 'WestConnex',
                        Priority = 'Normal',
                        Modes__c = 'MAGS', 
                        Signatory__c = 'Minister for Western Sydney, WestConnex, and Sport');
    }
    
    
    @isTest static void testException() {
        Case caseRecord = getCaseRecord();
        caseRecord.Taxonomy_Location__c  = 'Sydney';
        
        User caseOfficer1 = createCaseOfficerUser();
        User caseOfficer2 = createCaseOfficerUser();
        
        Test.startTest();
        system.runAs(caseOfficer1) {        
            insert caseRecord;
            PageReference pref = Page.ReassignForConsolex;
            pref.getParameters().put('id', caseRecord.Id);
            Test.setCurrentPageReference(pref);
            ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
            
            ReassignForConsole rfc = new ReassignForConsole(controller);
            rfc.caseId = caseRecord.Id;
            rfc.newCase = caseRecord;
            
            ReassignForConsole.validateAndReassign('', '');
            
        }
        Test.stopTest();
    }    
    
}