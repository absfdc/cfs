@isTest
public class EmailPublisherAction_CX_Test {
	
    @isTest static void test_method_one() {
		User caseManager = createCaseManagerUser();
        Case caseRecord = getCaseRecord();
        caseRecord.Taxonomy_Location__c  = 'Sydney';
        caseRecord.OwnerId = caseManager.Id;
        insert caseRecord;
        createCustomSetting();

        system.runAs(caseManager) {        
        PageReference pref = Page.EmailStaffMemberPublisher;
        pref.getParameters().put('id', caseRecord.Id);
        Test.setCurrentPageReference(pref);
		ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
        
    	EmailPublisherAction_CX epa = new EmailPublisherAction_CX(controller);
       // epa.orgWideEmail = 'tfnswfeedback@gmail.com,tfnswdev1@gmail.com,rmsuatforwarder@gmail.com';
        //epa.emailVsDisplayName = 'tfnswfeedback@gmail.com,tfnswdev1@gmail.com,rmsuatforwarder@gmail.com';
            
        system.assert(epa.orgWideEmail.length()>1);
        system.assert(epa.emailVsDisplayName.length()>1);
        }
        
    }
    
        public static User createCaseManagerUser() {
        User user = new User();
        user.Username = 'cm'+ System.currentTimeMillis() + '@demo.com';
        user.FirstName = 'Serco';
        user.LastName = 'Agent';
        user.Email = 'md@demo.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [select id from Profile where Name='Serco Agent'].Id;
        user.LanguageLocaleKey = 'en_US';
        insert user;
        return user;
    }
    
        public static Case getCaseRecord() {
        return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',
                        Status = 'New',
                        Agency__c = 'Agency1',
                        Priority = 'Normal',
                        Modes__c = 'Road',
                        Taxonomy_Location__c = null,
                        Taxonomy_Symptom__c = 'Unsafe Intersection',
                        Taxonomy_Accountability__c = 'RMS_JMD_Network_Sydney_CFM');
    }
    
        private static void createCustomSetting() {
        list <ProfileVsOrgWideEmailAddMappings__c> mapping= new list <ProfileVsOrgWideEmailAddMappings__c>();
        mapping.add(new ProfileVsOrgWideEmailAddMappings__c(Name = 'Serco Agent', OrgWideEmailAddresses__c = 'tfnswfeedback@gmail.com,tfnswdev1@gmail.com,rmsuatforwarder@gmail.com'));
        //mapping.add(new ProfileVsOrgWideEmailAddMappings__c(Name = '2', QueueName__c = 'RMS_AMD_Engineering_Services_CFM', Agency__c = 'RMS', Division__c = 'Asset Maintenance', Branch__c = 'ENGINEERING SERVICES'));
        insert mapping;
    }

    
    
}