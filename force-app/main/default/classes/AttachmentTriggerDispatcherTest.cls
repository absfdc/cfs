@isTest
private class AttachmentTriggerDispatcherTest
{
    
     @testSetup
    static void setUpUser(){

        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MinCo Webform API Integration User'];        
       
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', FirstName = 'MinCo Webform', LastName='API Integration User', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;

    } 
    
    @isTest
    static void createCustomNotesAndAttachemntBeforeInsertingAttachmentToCase()
    {
        Case thisCase= setupCase();
        insert thisCase;
        Attachment thisAttachment= new Attachment(
            parentId=thisCase.Id,
            Name='This is dummy name for the attachment used to test the 80 characters size limit.pdf',
            Body=Blob.valueOf('test'));
        Test.startTest();
        insert thisAttachment;
        Test.stopTest();
        List<NoteOrAttachment__c> thisNoteAttachments= [select Id from NoteOrAttachment__c where Attachment__c=:thisAttachment.Id];
        system.assertEquals(1,thisNoteAttachments.size() );

    }


    @isTest
    static void createCustomNotesAndAttachemntAfterInsertingAttachmentToCase()
    {
        Case thisCase= setupCase();
        insert thisCase;
        Attachment thisAttachment= new Attachment(
            parentId=thisCase.Id,
            Name='Incoming Correspondence MO 20161109 153150 0001',
            Body=Blob.valueOf('Incoming Correspondence MO 20161109 153150 0001'));
        Test.startTest();
        insert thisAttachment;
        system.debug('attachment :: ' + thisAttachment);
        Test.stopTest();
        List<NoteOrAttachment__c> thisNoteAttachments= [select Id from NoteOrAttachment__c where Attachment__c=:thisAttachment.Id];
        system.debug('thisNoteAttachments :: ' + thisNoteAttachments);
        system.assertEquals(1,thisNoteAttachments.size() );

    }

    @isTest
    static void createCustomNotesAndAttachemntAfterInsertingAttachmentToCaseWithMinCorroUser()
    {
        User u = [Select Id from User where Email = 'standarduser1@nsw.gov.au.com' limit 1];
        
        system.runAs(u){
            Case thisCase= setupCase();
            insert thisCase;

            NoteOrAttachment__c customAttachment = new NoteOrAttachment__c();
            customAttachment.Name = 'Incoming Correspondence MO 20161109 153150 0001';
            customAttachment.Case__c = thisCase.Id;
            insert customAttachment;

            Attachment thisAttachment= new Attachment(
                parentId=customAttachment.Id,
                Name='Incoming Correspondence MO 20161109 153150 0001',
                Body=Blob.valueOf('Incoming Correspondence MO 20161109 153150 0001'));
            Test.startTest();
            insert thisAttachment;
            system.debug('attachment by :: ' + thisAttachment);
            customAttachment.Attachment__c = thisAttachment.Id;
            update customAttachment;
            Test.stopTest();
            List<NoteOrAttachment__c> thisNoteAttachments= [select Id,CreatedBy.Name from NoteOrAttachment__c where Attachment__c=:thisAttachment.Id ];

            system.debug('thisNoteAttachments by :: ' + thisNoteAttachments[0].CreatedBy.Name);
            system.assertEquals(1,thisNoteAttachments.size() );
        }
    }

    @isTest
    static void deleteCustomNotesAndAttachemntAfterDeletingAttachmentfromCase()
    {
        Case thisCase= setupCase();
        insert thisCase;
        Attachment thisAttachment= new Attachment(
            parentId=thisCase.Id,
            Name='test',
            Body=Blob.valueOf('test'));
        insert thisAttachment;
        Test.startTest();
        delete thisAttachment;
        Test.stopTest();
        List<NoteOrAttachment__c> thisNoteAttachments= [select Id from NoteOrAttachment__c where Attachment__c=:thisAttachment.Id];
        system.assertEquals(0,thisNoteAttachments.size() );

    }
    @isTest
    static void createCustomNotesAndAttachemntAfterUndeletingAttachmentfromCase()
    {
        Case thisCase= setupCase();
        insert thisCase;
        Attachment thisAttachment= new Attachment(
            parentId=thisCase.Id,
            Name='test',
            Body=Blob.valueOf('test'));
        insert thisAttachment;
        delete thisAttachment;

        Test.startTest();
        undelete thisAttachment;
        Test.stopTest();
        List<NoteOrAttachment__c> thisNoteAttachments= [select Id from NoteOrAttachment__c where Case__c=:thisCase.Id];
        system.assertEquals(1,thisNoteAttachments.size() );

    }
    
    @isTest
    static void beforeInsertErrorIfTriggerParameterNotProper()
    {
        ApplicationLog_Test.setLoggingSettings();
        AttachmentBeforeInsertTriggerHandler beforeInserter= new AttachmentBeforeInsertTriggerHandler();
        
        beforeInserter.mainEntry(null);
        List<Application_Log__c> attachemntLogs= [select Id ,Debug_Level__c from Application_Log__c ];
        system.assertEquals(GlobalConstants.ERROR,attachemntLogs[0].Debug_Level__c);

    }
    
    @isTest
    static void insertErrorIfTriggerParameterNotProper()
    {
        ApplicationLog_Test.setLoggingSettings();
        AttachmentAfterInsertTriggerHandler inserter= new AttachmentAfterInsertTriggerHandler();
        
        inserter.mainEntry(null);
        List<Application_Log__c> attachemntLogs= [select Id ,Debug_Level__c from Application_Log__c ];
        system.assertEquals(GlobalConstants.ERROR,attachemntLogs[0].Debug_Level__c);

    }
    @isTest
    static void deleteErrorIfTriggerParameterNotProper()
    {
        ApplicationLog_Test.setLoggingSettings();
        AttachmentAfterDeleteTriggerHandler deleter= new AttachmentAfterDeleteTriggerHandler();
        
        deleter.mainEntry(null);
        List<Application_Log__c> attachemntLogs= [select Id ,Debug_Level__c from Application_Log__c ];
        system.assertEquals(GlobalConstants.ERROR,attachemntLogs[0].Debug_Level__c);

    }
    @isTest
    static void undeleteErrorIfTriggerParameterNotProper()
    {
        ApplicationLog_Test.setLoggingSettings();
        AttachmentAfterUndeleteTriggerHandler undeleter= new AttachmentAfterUndeleteTriggerHandler();
        
        undeleter.mainEntry(null);
        List<Application_Log__c> attachemntLogs= [select Id ,Debug_Level__c from Application_Log__c ];
        system.assertEquals(GlobalConstants.ERROR,attachemntLogs[0].Debug_Level__c);

    }

    public static Case setupCase(){
        Case aCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
                                Description='I was Injured because of the sharp metal jutting out ',
                                Status='New',
                                Origin='Web',
                                Priority='Normal');
        return aCase;
    }
}