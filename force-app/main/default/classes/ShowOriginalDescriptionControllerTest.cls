@isTest
public class ShowOriginalDescriptionControllerTest {
    
    static testMethod void setUpProfaneData(){
        
        List<Case> caseListToTest = new List<Case>();
        Case lightRailCase1 = getCaseRecord();
        caseListToTest.add(lightRailCase1);
        Case lightRailCase2 = getCaseRecord();
        lightRailCase2.Description = 'http://www.test.com/json';
        lightRailCase2.Subject = 'Pothole2';
        caseListToTest.add(lightRailCase2);
        insert caseListToTest;
        String description = ShowOriginalDescriptionController.getOrigianlDescription(lightRailCase1.Id);
        System.assert(!description.contains('profanity'));
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