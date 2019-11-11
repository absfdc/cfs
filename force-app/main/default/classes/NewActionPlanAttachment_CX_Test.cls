/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Test class for New Action plan page controller
History
<Date>         <Authors Name>     <Brief Description of Change>
27/04/2015     Manish Damle       Created
-----------------------------------------------------------------------------------*/
@isTest
public class NewActionPlanAttachment_CX_Test {
 	/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Test method for New note creation testing 
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    static testMethod void newNoteTest() {
        Case caseRecord  = getCaseRecord();
        insert caseRecord;
        
        Action_Plan__c ap = getActionPlanRecord(caseRecord.Id);
        insert ap;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(ap);
        PageReference pref = Page.NewActionPlanNote;
        pref.getParameters().put('display','Note');
        Test.setCurrentPageReference(pref);
        NewActionPlanAttachment_CX ctrl = new NewActionPlanAttachment_CX(stdController);
        Test.startTest();
        	ctrl.customAttachment.Name = null; //Name id required but not provided.Validation will fire
        	ctrl.customAttachment.Body__c = 'This is test note body';
        	system.assertEquals(null, ctrl.saveNote());
        	ctrl.customAttachment.Name = 'Test Note';
        	ctrl.saveNote();
        Test.stopTest();
        list <NoteOrAttachment__c> notes =  [Select Id From NoteOrAttachment__c]; //Will not be attached to the case
        system.assertEquals(1, notes.size());
        list <AP_NoteOrAttachment__c> apnotes =  [Select Id From AP_NoteOrAttachment__c Where Action_Plan__c =: ap.Id];
        system.assertEquals(1, apnotes.size());
    }
    
 	/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Test method for New attachment creation testing 
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/    
    static testMethod void newAttachmentTest() {
        Case caseRecord  = getCaseRecord();
        insert caseRecord;
        
        Action_Plan__c ap = getActionPlanRecord(caseRecord.Id);
        insert ap;
        
        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(ap);
            PageReference pref = Page.NewActionPlanAttachment;
            pref.getParameters().put('display','Attachment');
            Test.setCurrentPageReference(pref);  
            NewActionPlanAttachment_CX ctrl = new NewActionPlanAttachment_CX(stdController);
        
        	ctrl.customAttachment.Body__c = 'This is test note body';
        	ctrl.sfattachment.Name = 'desert.txt';
        	ctrl.sfattachment.Body = Blob.valueOf('This for testing purpose');
        	ctrl.saveAttachment();
        Test.stopTest();
        
        list <NoteOrAttachment__c> notes =  [Select Name, Id From NoteOrAttachment__c];
        system.assertEquals(1, notes.size());
        system.assertEquals('desert.txt', notes[0].Name);
        list <AP_NoteOrAttachment__c> apnotes =  [Select Id From AP_NoteOrAttachment__c Where Action_Plan__c =: ap.Id];
        system.assertEquals(1, apnotes.size());
    }
    
 	/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Test method for adding the existing attachment from the case record.
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/    
    static testMethod void addExistingAttachmentTest() {
        Case caseRecord  = getCaseRecord();
        insert caseRecord;
        
        Action_Plan__c ap = getActionPlanRecord(caseRecord.Id);
        insert ap;
        
        NoteOrAttachment__c attachmentRecord = getNoteOrAttachmentRecord(caseRecord.Id);
        insert attachmentRecord;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(ap);
        PageReference pref = Page.NewActionPlanAttachment;
        pref.getParameters().put('display','Attachment');
        Test.setCurrentPageReference(pref);
        NewActionPlanAttachment_CX ctrl = new NewActionPlanAttachment_CX(stdController);
        
        Test.startTest();
		    ctrl.attachmentIdToBeCloned = attachmentRecord.Id;
        	ctrl.getAttachmentFromTheCase();        	
        	ctrl.getCaseAttachments();
        Test.stopTest();
        list <AP_NoteOrAttachment__c> apnotes =  [Select Id, Note_Attachment__c From AP_NoteOrAttachment__c Where Action_Plan__c =: ap.Id];
        system.assertEquals(1, apnotes.size());
        system.assertEquals(attachmentRecord.Id, apnotes[0].Note_Attachment__c);
        
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Test method cover exception handling
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/    
    static testMethod void errorTest() {
        Case caseRecord  = getCaseRecord();
        insert caseRecord;
        
        Action_Plan__c ap = getActionPlanRecord(caseRecord.Id);
        insert ap;
        
        NoteOrAttachment__c attachmentRecord = getNoteOrAttachmentRecord(caseRecord.Id);
        insert attachmentRecord;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(ap);
        PageReference pref = Page.NewActionPlanAttachment;
        pref.getParameters().put('display','Attachment');
        Test.setCurrentPageReference(pref);
        NewActionPlanAttachment_CX ctrl = new NewActionPlanAttachment_CX(stdController);
        
        Test.startTest();
       		ctrl.customAttachment.Name = 'Test Note';
        	ctrl.customAttachment.Body__c = 'This is test note body';
		    system.assertEquals(null, ctrl.saveAttachment());
        Test.stopTest();
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates a case record sobject
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static Case getCaseRecord() {
        return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',
                        Status = 'New',
                        Agency__c = 'Agency1',
                        Priority = 'Normal');
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates a action plan record sobject
    Inputs:        Parent Case Id
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static Action_Plan__c getActionPlanRecord(Id parentCaseId) {
        return new Action_Plan__c(
        	Parent_Case__c = parentCaseId,
            Mode__c = 'Bus');
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates a NoteOrAttachment record sobject of the type attachment
    Inputs:        Case Id
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    27/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static NoteOrAttachment__c getNoteOrAttachmentRecord(Id caseId) {
        return new NoteOrAttachment__c(
        	Name = 'Test Attchament',
            Privacy__c = 'Standard',
            RecordTypeId = [Select Id From RecordType Where SObjectType = 'NoteOrAttachment__c' And DeveloperName = 'Attachment'].Id,
            Case__c = CaseId
        );
    }
}