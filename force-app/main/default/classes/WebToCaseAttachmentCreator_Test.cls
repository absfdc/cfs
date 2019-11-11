@isTest
private class WebToCaseAttachmentCreator_Test {
    
    private static List<Attachment> attachments;
    private static Case caseRecord;
    
    private static testMethod void testForInvalidTestData() {
        setUpTestData(1);
        System.Test.startTest();
        try {
            WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(null, attachments);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseRecord, null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseRecord, new List<Attachment>());
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForSingleAttachment() {
        setUpTestData(1);
        System.Test.startTest();
        WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseRecord, attachments);
        attachmentCreator.createCaseAttachment();
        System.Test.stopTest();
        List<NoteOrAttachment__c> customAttachment = [SELECT ID, Attachment__c FROM NoteOrAttachment__c WHERE Case__c = :caseRecord.Id];
        System.assert(!customAttachment.isEmpty());
        List<Attachment> caseAttachments = [SELECT Id FROM Attachment WHERE ParentId = :customAttachment];
        System.assert(!caseAttachments.isEmpty());
        System.assert(caseAttachments.size() == 1);
    }
    
    private static testMethod void testForMultipleAttachments() {
        setUpTestData(10);
        System.Test.startTest();
        WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseRecord, attachments);
        attachmentCreator.createCaseAttachment();
        System.Test.stopTest();
        List<NoteOrAttachment__c> customAttachment = [SELECT ID, Attachment__c FROM NoteOrAttachment__c WHERE Case__c = :caseRecord.Id];
        System.assert(!customAttachment.isEmpty());
        List<Attachment> caseAttachments = [SELECT Id FROM Attachment WHERE ParentId = :customAttachment];
        System.assert(!caseAttachments.isEmpty());
        System.assert(caseAttachments.size() == 10);
    }
    
    private static testMethod void testForBlankAttachmentBody() {
        setUpTestData(1);
        attachments[0].Body = null;
        System.Test.startTest();
        WebToCaseAttachmentCreator attachmentCreator = new WebToCaseAttachmentCreator(caseRecord, attachments);
        attachmentCreator.createCaseAttachment();
        System.Test.stopTest();
        List<Attachment> caseAttachments = [SELECT Id FROM Attachment WHERE ParentId = :caseRecord.Id];
        System.assert(caseAttachments.isEmpty());       
    }
    
    private static void setUpTestData(Integer attachmentCount) {
        createCase();
        attachments = new List<Attachment>();
        for(Integer i = 0; i < attachmentCount; i++) {
            Attachment attach = new Attachment();
            attach.body = Blob.valueOf('Test attachment');
            attach.Name = 'testFile.txt';
            attachments.add(attach);
        }
        createCustomSetting();
    }
    
    private static void createCase() {      
        caseRecord = new Case();
        caseRecord.Origin = 'Web';
        caseRecord.Priority = 'Normal';
        caseRecord.Type = 'Compliment';
        caseRecord.Description = 'Test case for spam check';    
        insert caseRecord;
        caseRecord = [SELECT Id, OwnerId FROM Case WHERE Id = :caseRecord.Id];
    }
    
    private static void createCustomSetting() {
        AllowableFileExtensions__c allowedFiles = new AllowableFileExtensions__c(Name = '.txt');
        insert allowedFiles;
    }
}