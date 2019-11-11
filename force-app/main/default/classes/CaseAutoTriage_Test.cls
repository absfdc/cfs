/**********************************************************************************************
Created By:     Arxxus
Created date:   25/10/2017
Description:    Test class for CaseAutoTriage 
************************************************************************************************/
@isTest
private class CaseAutoTriage_Test{
    
    @testSetup
    static void setUpTestData(){
        
        List<Case> caseListToTest = new List<Case>();
        Case lightRailCase1 = getCaseRecord();
        caseListToTest.add(lightRailCase1);
        Case lightRailCase2 = getCaseRecord();
        lightRailCase2.Description = 'http://www.test.com/json';
        lightRailCase2.Subject = 'Pothole2';
        caseListToTest.add(lightRailCase2);
        Case lightRailCase3 = getCaseRecord();
        lightRailCase3.Description = 'Theres a pothole in the east street, west end crossing in front of busstop ';
        lightRailCase3.Subject = 'Pothole3';
        caseListToTest.add(lightRailCase3);
        insert caseListToTest;
        
    }
    
    @isTest 
    static void testProfanityFilterandHPScoreCalculator() {
        Test.startTest();
        List<Case> caseList = [SELECT Id,Description,Subject from Case order by Subject asc];
        // Test if only 3 case records are inserted 
        System.assertEquals(3,caseList.size());
        // Test if the case description containing abusive words is replaced by '<profanity>'
        System.assert(caseList[0].Description.contains('[profanity]'));
        // Test if the case description containing "http" is replaced by '[bad_url]'
        System.assert(caseList[1].Description.contains('[bad_url]'));
        // Test if the case description not containing "http" and any abusive word neither contains '[profanity]' nor '[bad_url]'
        System.assert(!caseList[2].Description.contains('[bad_url]') && !caseList[2].Description.contains('[profanity]'));
        // Test if the case description is same as provided, no modification to any word in description text
        System.assert(caseList[2].Description.equals('Theres a pothole in the east street, west end crossing in front of busstop'));
        CaseAutoTriage caseAutoTraigeObj = new CaseAutoTriage(caseList);
        Test.stopTest();
    }
    
/*---------------------------------------------------------------------------------
Author: Arxxus       
Description:   This method creates a  case record sobject
-----------------------------------------------------------------------------------*/
    public static Case getCaseRecord() {
        
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.LIGHT_RAIL_RECORD_TYPE limit 1];
        
        return new Case(Subject = 'Pothole1',
                        Description = 'anal pothole xxxxxxx attack touched tripped transportNSW.info unsafe vandals abuse bomb blow up yyyyy zzzzzz test description as.s the east street, f.u.c.k west end crossing in front of busstop   aids',                       
                        Status = 'New',
                        RecordTypeId = rt.Id,
                        Priority = 'Normal',
                        Modes__c = 'MAGS', 
                        Signatory__c = 'Minister for Roads, Maritime and Freight');
    }
}