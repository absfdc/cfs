@isTest
public class NoteOrAttachmentTriggerDispatcher_Test{

    static testMethod void insertPrivateNotesTest() {
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        
        Test.startTest();
            NoteOrAttachment__c pn1 = getNoteOrAttachment('Private Note 1', caseRecord.Id);
            NoteOrAttachment__c pn2 = getNoteOrAttachment('Private Note 2', caseRecord.Id);
            insert new list <NoteOrAttachment__c> { pn1, pn2};
        Test.stopTest();
        
        Case updatedCaseRecord = [Select Id,Private_Notes_Count__c From Case Where Id =: caseRecord.Id];
        system.assertEquals(2, updatedCaseRecord.Private_Notes_Count__c);
        
    }
    
    static testMethod void updatePrivateNotesTest() {
        
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        
        Case caseRecord1 = getCaseRecord();
        insert caseRecord1;
        
        Test.startTest();
            NoteOrAttachment__c pn1 = getNoteOrAttachment('Private Note 1', caseRecord.Id);
            NoteOrAttachment__c pn2 = getNoteOrAttachment('Private Note 2', caseRecord.Id);
            
            insert new list <NoteOrAttachment__c> {pn1, pn2};
            
            NoteOrAttachment__c thunderHeadDummyResponseDraft = getNoteOrAttachment('response_dummy Thunderhead Response Draft', caseRecord.Id);
            insert thunderHeadDummyResponseDraft;
            
            Attachment attach = new Attachment();    
            attach.Name = 'Dummy Thunderhead Response Draft WordML';
            Blob bodyBlob = Blob.valueOf('Dummy Thunderhead Response Draft WordML');
            attach.body = bodyBlob;
            attach.parentId = thunderHeadDummyResponseDraft.id;
            insert attach;
            
            thunderHeadDummyResponseDraft.Attachment__c = attach.Id;
            thunderHeadDummyResponseDraft.ContentType__c = 'application/msword';
            update thunderHeadDummyResponseDraft;
            
            pn2.Case__c = caseRecord1.Id; //reparenting the private note
            update pn2; 
        Test.stopTest();
        
        Case updatedCaseRecord = [Select Id,Private_Notes_Count__c From Case Where Id =: caseRecord.Id];
        system.assertEquals(2, updatedCaseRecord.Private_Notes_Count__c);
        
        Case updatedCaseRecord1 = [Select Id,Private_Notes_Count__c From Case Where Id =: caseRecord1.Id];
        system.assertEquals(1, updatedCaseRecord1.Private_Notes_Count__c);
        
        thunderHeadDummyResponseDraft = [SELECT Conga_Response_PDF_Generated__c FROM NoteOrAttachment__c WHERE Id = :thunderHeadDummyResponseDraft.Id];
        System.assertEquals(TRUE, thunderHeadDummyResponseDraft.Conga_Response_PDF_Generated__c);
    }
    
    //Exception handling test for NoteOrAttAfterUpdateTriggerHandler
    @isTest
    static void exceptionHandlingTest() {
   
     NoteOrAttAfterUpdateTriggerHandler tempAftrUpdateHandler = new NoteOrAttAfterUpdateTriggerHandler();
     tempAftrUpdateHandler.mainEntry(NULL);
     System.assertEquals(TRUE, tempAftrUpdateHandler.exceptionInvoked);
     
     NoteOrAttBeforeUpdateTriggerHandler tempBeforeUpdateHandler = new NoteOrAttBeforeUpdateTriggerHandler();
     tempBeforeUpdateHandler.mainEntry(NULL);
     System.assertEquals(TRUE, tempBeforeUpdateHandler.exceptionInvoked);
    }
 
    static testMethod void deletePrivateNotesTest() {
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        
        Test.startTest();
            NoteOrAttachment__c pn1 = getNoteOrAttachment('Private Note 1', caseRecord.Id);
            NoteOrAttachment__c pn2 = getNoteOrAttachment('Private Note 2', caseRecord.Id);
            insert new list <NoteOrAttachment__c> { pn1, pn2};
        Test.stopTest();
        
        delete pn1;
        
        Case updatedCaseRecord = [Select Id,Private_Notes_Count__c From Case Where Id =: caseRecord.Id];
        system.assertEquals(1, updatedCaseRecord.Private_Notes_Count__c);
    }
    
    static testMethod void undeletePrivateNotesTest() {
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        NoteOrAttachment__c pn1 = getNoteOrAttachment('Private Note 1', caseRecord.Id);
        NoteOrAttachment__c pn2 = getNoteOrAttachment('Private Note 2', caseRecord.Id);
        insert new list <NoteOrAttachment__c> { pn1, pn2};
        delete pn1;
        Test.startTest();
            Case updatedCaseRecord = [Select Id,Private_Notes_Count__c From Case Where Id =: caseRecord.Id];
            system.assertEquals(1, updatedCaseRecord.Private_Notes_Count__c);
        Test.stopTest();
        
        undelete pn1;
        updatedCaseRecord = [Select Id,Private_Notes_Count__c From Case Where Id =: caseRecord.Id];
        system.assertEquals(2, updatedCaseRecord.Private_Notes_Count__c);
    }
    
    static testMethod void bulkInsertTest() {
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        
        Test.startTest();
            list <NoteOrAttachment__c> pNotes = new list <NoteOrAttachment__c> ();
            for(Integer i = 0; i < 100; i++) {
                NoteOrAttachment__c pn1 = getNoteOrAttachment('Private Note ' + i , caseRecord.Id);
                pNotes.add(pn1);
            }
            insert pNotes; 
        Test.stopTest();
        
        Case updatedCaseRecord = [Select Id,Private_Notes_Count__c From Case Where Id =: caseRecord.Id];
        system.assertEquals(100, updatedCaseRecord.Private_Notes_Count__c);
    
    }
    
    static testMethod void errorTest() {
        ApplicationLog_Test.setLoggingSettings();
        
        NoteOrAttBeforeInsertTriggerHandler handler = new NoteOrAttBeforeInsertTriggerHandler();
        handler.mainEntry(null);
        
        NoteOrAttAfterDeleteTriggerHandler handler1 = new NoteOrAttAfterDeleteTriggerHandler();
        handler1.mainEntry(null);
        
        NoteOrAttAfterInsertTriggerHandler handler2 = new NoteOrAttAfterInsertTriggerHandler();
        handler2.mainEntry(null);
        
        NoteOrAttAfterUndeleteTriggerHandler handler3 = new NoteOrAttAfterUndeleteTriggerHandler();
        handler3.mainEntry(null);
        
        NoteOrAttAfterUpdateTriggerHandler handler4 = new NoteOrAttAfterUpdateTriggerHandler();
        handler4.mainEntry(null);
        
        Test.startTest();
        List<Application_Log__c> caseTriggerLogs= [select Id ,Debug_Level__c from Application_Log__c ];
        system.assertEquals(GlobalConstants.ERROR,caseTriggerLogs[0].Debug_Level__c);
        Test.stopTest();
        
    }
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates a case record sobject
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    20/04/2015     Manish Damle       Created
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
    Description:   This method creates a private note record
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    20/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static NoteOrAttachment__c getNoteOrAttachment(String title, Id caseId) {
        return new NoteOrAttachment__c(Name = title,
                                       Body__c = 'Sample Body of ' + title,
                                       Case__c = caseId,
                                       Privacy__c = 'Restricted');
    }
}