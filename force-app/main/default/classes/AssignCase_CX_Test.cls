/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus
Description:   Test class for Assign Case
History
21/04/2015     Manish Damle Created
------------------------------------------------------------*/
@isTest
private class AssignCase_CX_Test {
    static testMethod void userHasReadAccessOnCaseAssignmentSuccessful() {
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        
        caseRecord.Taxonomy_Location__c  = 'Sydeny';
        update caseRecord;
        
        Test.startTest();
            PageReference pref = Page.AssignCase;
            pref.getParameters().put('id', caseRecord.Id);
            Test.setCurrentPageReference(pref);
            ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
            AssignCase_CX cs = new AssignCase_CX(controller);
            PageReference redirectToPage = cs.autoRun();
            system.assertEquals(true, redirectToPage.getUrl().contains(caseRecord.Id));
            system.assertEquals(true, cs.HasReadAccess);
        Test.stopTest();
    }
    
    static testMethod void userHasNoReadAccessOnCaseAssignmentSuccessful() {
        User caseManager = createCaseManagerUser();
        Case caseRecord = getCaseRecord();
        caseRecord.OwnerId = caseManager.Id;
        insert caseRecord;
        
        caseRecord.Taxonomy_Location__c  = 'Sydeny';
        update caseRecord;
        
        system.runAs(caseManager) {
            PageReference pref = Page.AssignCase;
            pref.getParameters().put('id', caseRecord.Id);
            Test.setCurrentPageReference(pref);
            ApexPages.StandardController controller = new ApexPages.StandardController(caseRecord);
            AssignCase_CX cs = new AssignCase_CX(controller);
            PageReference redirectToPage = cs.autoRun();
            system.assertEquals(null, redirectToPage);
            system.assertEquals(false, cs.HasReadAccess);
        }
    }
    
    static testMethod void errorConditionsNullIdPassed() {
        PageReference pref = Page.AssignCase;
        pref.getParameters().put('id', '');
        Test.setCurrentPageReference(pref);
        ApexPages.StandardController controller = new ApexPages.StandardController(getCaseRecord());
        AssignCase_CX cs = new AssignCase_CX(controller);
        PageReference redirectToPage = cs.autoRun();
        system.assertEquals(null, redirectToPage);
        system.assertEquals(false, cs.HasReadAccess);
        
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   create Case Manager User
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    21/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static User createCaseManagerUser() {
        User user = new User();
        user.Username = 'cm'+ System.currentTimeMillis() + '@demo.com';
        user.FirstName = 'Case';
        user.LastName = 'Manager';
        user.Email = 'md@demo.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [select id from Profile where Name='TMC Case Manager'].Id;
        user.LanguageLocaleKey = 'en_US';
        insert user;
        return user;
    }
    
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates a case record sobject
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    21/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
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
    
}