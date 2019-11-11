/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Test class for NewCaseAttachment page controller
History
<Date>         <Authors Name>     <Brief Description of Change>
27/04/2015     Manish Damle       Created
-----------------------------------------------------------------------------------*/
@isTest
private class NewCaseAttachment_CC_Test {

    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Test method for New attachment creation testing 
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/    
    static testMethod void newAttachmentTest() {
       	Case caseRecord = NewActionPlanAttachment_CX_Test.getCaseRecord();
        insert caseRecord;  
         
        PageReference pref = Page.NewCaseAttachment;
        pref.getParameters().put('cid', caseRecord.Id);
        Test.setCurrentPageReference(pref);
        NewCaseAttachment_CC ctrl = new NewCaseAttachment_CC();
        
        Test.startTest();
        	ctrl.init();
        	ctrl.customAttachment.Name = null; //Name id required but not provided.Validation will fire
        	ctrl.customAttachment.Body__c = 'This is test note body';
        	ctrl.sfattachment.Name = 'desert.txt';
        	ctrl.sfattachment.Body = Blob.valueOf('This for testing purpose');
        	system.assert(ctrl.saveAttachment().getUrl().contains('/' + ctrl.customAttachment.Id));
        Test.stopTest();
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Test method for exception handling
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/    
    static testMethod void errorTest() {
        Case caseRecord = NewActionPlanAttachment_CX_Test.getCaseRecord();
        insert caseRecord;  
        
        PageReference pref = Page.NewCaseAttachment;
        pref.getParameters().put('cid', caseRecord.Id);
        Test.setCurrentPageReference(pref);
        NewCaseAttachment_CC ctrl = new NewCaseAttachment_CC();
        
        Test.startTest();
        	ctrl.customAttachment.Name = null; //Name id required but not provided.Validation will fire
        	ctrl.customAttachment.Body__c = 'This is test note body';
        	system.assertEquals(null, ctrl.saveAttachment());
        Test.stopTest();
    }
}