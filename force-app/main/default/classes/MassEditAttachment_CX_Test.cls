@isTest
private class MassEditAttachment_CX_Test {
    
    @testSetup static void setup() {
        APXTConga4__Conga_Template__c ct1 =  new APXTConga4__Conga_Template__c(APXTConga4__Template_Type__c = 'Document', 
                                                                              APXTConga4__Name__c = 'Case Cover Page - Blue', 
                                                                              APXTConga4__Template_Group__c  = 'Case');
        APXTConga4__Conga_Template__c ct2 =  new APXTConga4__Conga_Template__c(APXTConga4__Template_Type__c = 'Document', 
                                                                              APXTConga4__Name__c = 'Case Cover Page - Blue', 
                                                                              APXTConga4__Template_Group__c  = 'Case');
        APXTConga4__Conga_Template__c ct3 =  new APXTConga4__Conga_Template__c(APXTConga4__Template_Type__c = 'Document', 
                                                                              APXTConga4__Name__c = 'Case Cover Page - Blue', 
                                                                              APXTConga4__Template_Group__c  = 'Case');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new list <APXTConga4__Conga_Template__c>  {ct1, ct2,ct3};
        }
        
        APXTConga4__Conga_Merge_Query__c cmq = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Document Print Query', 
                                                                                    APXTConga4__Query__c = 'Select Id From Attachment');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert cmq;
        }
        
        Case parent =new Case(Subject = 'parent',
                                  Description = 'Theres a parent in the east street, west end crossing in front of busstop',
                                  Status = 'New',
                                  Agency__c = 'Agency1',
                                  Modes__c='Multi-Issue');
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        }
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
            insert parent;    
            RecordType rt = [Select Id From RecordType Where DeveloperName  =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT limit 1];
            NoteOrAttachment__c customAttachment = new NoteOrAttachment__c(Name = 'ABC', Privacy__c = 'Standard', Case__c = parent.Id, RecordTypeId = rt.Id,ContentType__c = 'application/pdf');
            NoteOrAttachment__c customAttachment1 = new NoteOrAttachment__c(Name = 'XYZ', Privacy__c = 'Standard', Case__c = parent.Id,RecordTypeId = rt.Id,ContentType__c = 'image/png');
            insert new list <NoteOrAttachment__c> { customAttachment, customAttachment1 };
            
            Attachment sfattachment = new Attachment(ContentType = 'application/pdf', Name =  'abc.pdf', ParentId = customAttachment.Id, Body = Blob.valueOf('ABC Content'));
            Attachment sfattachment1 = new Attachment(ContentType = 'image/png', Name =  'image.png', ParentId = customAttachment1.Id, Body = Blob.valueOf('Broken Image'));
            insert new list <Attachment> {sfattachment, sfattachment1};
            
            customAttachment.File_Name__c =sfattachment.Name;
            customAttachment.Attachment__c = sfattachment.Id;
            customAttachment.ContentType__c = sfattachment.ContentType;
            
            customAttachment1.File_Name__c =sfattachment1.Name;
            customAttachment1.Attachment__c = sfattachment1.Id;
            customAttachment1.ContentType__c = sfattachment1.ContentType;
            update new list <NoteOrAttachment__c> { customAttachment, customAttachment1 };  
        }
        
                Account testAccount = new Account(name='Test Company Name');
        insert testAccount;
       
        Entitlement testEntitlement = new Entitlement();
        testEntitlement.Name = testAccount.name;
        testEntitlement.StartDate = System.Today();
        testEntitlement.AccountId = testAccount.Id;
     
        insert testEntitlement;
      
        // Verify that the entitlment was created in the database.
        Entitlement NewEntitlement = [SELECT AccountId FROM Entitlement WHERE Name = :testAccount.Name];
        System.assertEquals(testAccount.ID, NewEntitlement.AccountId);
                
    }

    static testMethod void magsOfficerReordersTest() {
        Case caseRecord;
        User magsUser = RetrieveNextUtils_WS_Test.createTestUser('MAGS Officer', 'MAGS_Officer');
        System.runAs(new User(Id=UserInfo.getUserId())) {
            caseRecord = [Select Id, OwnerId From Case limit 1];
            caseRecord.OwnerId = magsUser.Id;
        }
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
            update caseRecord;
        }
        
        System.runAs(magsUser) {
            ApexPages.StandardController std_controller = new ApexPages.StandardController(caseRecord);
            PageReference pRef = Page.ManageSupportingDocuments;
            MassEditAttachment_CX controller = new MassEditAttachment_CX(std_controller);
            Test.setCurrentPageReference(pRef);
            Test.startTest(); 
                controller.init();
                system.assertEquals(true,controller.enableSaveAndReordering);
                system.assertEquals(2, controller.attachments.size());
                controller.attachments[0].Requires_Printing__c = true;
                controller.attachments[0].Sequence__c = 1;
                controller.attachments[1].Requires_Printing__c = true;
                controller.attachments[1].Sequence__c = 2;
                controller.updateDetails();
               
                NoteOrAttachment__c att = [Select Id From NoteOrAttachment__c  Where ContentType__c = 'image/png' limit 1];
                controller.attachmentSelected = att.Id;
                controller.generatePDF();
                list <NoteOrAttachment__c> pdfs = [Select Id, PDF_Attachment__c From NoteOrAttachment__c  Where PDF_Attachment__c != null];
                system.assertEquals(1, pdfs.size());
            Test.stopTest();
        }
    }
    
    static testMethod void magsOfficerErrorTest() {
        Case c = [Select Id, OwnerId From Case limit 1];
        User magsUser = RetrieveNextUtils_WS_Test.createTestUser('MAGS Officer', 'MAGS_Officer');
        System.runAs(new User(Id=UserInfo.getUserId())) {
            c.OwnerId = magsUser.Id;
            update c;
        }
        
        System.runAs(magsUser) {
            ApexPages.StandardController std_controller = new ApexPages.StandardController(c);
            PageReference pRef = Page.ManageSupportingDocuments;
            MassEditAttachment_CX controller = new MassEditAttachment_CX(std_controller);
            Test.setCurrentPageReference(pRef);
            Test.startTest();
            controller.init();
            system.assertNotEquals(null, controller.congaURL);
            controller.generatePDF();
            Test.stopTest();
        }
    }

    
}