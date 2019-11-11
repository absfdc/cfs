//JIRA# SFCOE-1837 Send an email notification with User License overuse information (test class) - 26-05

@isTest
public class NotifyForLicenseOveruse_Test {
    static testmethod void testschedule(){
        Test.StartTest();
        
        Agency_Specific_License_limits__c agencyLimitsConfigRMS = new Agency_Specific_License_limits__c();
        agencyLimitsConfigRMS.name = 'RMS';
        agencyLimitsConfigRMS.Max_Force_com_Licenses_Allowed__c = 1;
        agencyLimitsConfigRMS.Max_Service_Cloud_Licenses_Allowed__c = 2;
        insert agencyLimitsConfigRMS;
        
        Agency_Specific_License_Email_Config__c recepientEmails = new Agency_Specific_License_Email_Config__c();
        recepientEmails.Name = 'Salesforce Requests';
        recepientEmails.Recepient_Email__c = 'salesforcerequests@transport.nsw.gov.au';
        insert recepientEmails;
        
        NotifyForLicenseOveruse sh1 = new NotifyForLicenseOveruse();      
        String sch = '0  00 1 3 * ?';
        system.schedule('Test', sch, sh1);

        Test.stopTest();
    }
    
}