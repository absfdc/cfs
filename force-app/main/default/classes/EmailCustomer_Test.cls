@isTest
private class EmailCustomer_Test {
    
    @testSetup
    static void setUpUser(){
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'MAGS Officer'];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Senior MAGS Officer'];
       
        UserRole r1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'DLO_Transport'];  
        UserRole r2 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Minister_of_Transport'];
        
       
        User u1 = new User(Alias = 'standt', Email = 'standarduser1@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r1.Id, ProfileId = p1.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u1;
        
        User u2 = new User(Alias = 'standt', Email = 'standarduser2@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', UserRoleId = r2.Id, ProfileId = p2.Id, TimeZoneSidKey='Australia/Sydney', UserName='md' + System.currentTimeMillis() + '@nsw.gov.au.com', isActive = true);
        insert u2;
    }
    
    @isTest
    static void prepareAndSendEmailTest(){

        User u = [Select Id from User Where email = 'standarduser1@nsw.gov.au.com' limit 1];

        setupCaseRecTypesToExcludeCS();

        MO_Template_by_Response_Type__c moTemplate = new MO_Template_by_Response_Type__c();
        moTemplate.Name = 'MO View Email Attachment';
        moTemplate.Additional_Contact_Attachment_Categories__c = 'Signed Response,Incoming,Enclosures';
        moTemplate.Additional_Contacts_Email_Template__c = 'MOViewAdditionalCorroContactEmailTemplate';
        moTemplate.Contact_Attachment_Categories__c = 'Signed Response,Enclosures';
        moTemplate.Customer_Email_Template__c = 'MOViewCustomerContactEmailTemplate';
        moTemplate.Staff_Attachment_Categories__c = 'Signed Response,Enclosures';
        moTemplate.Staff_Email_Template__c =  'MOViewStaffContactEmailTemplate';
        insert moTemplate;                                              

        Contact customer = new Contact(Salutation='Mr',LastName='Customer', Firstname='Contact',Email='customer@contact.com');
        Contact staff = new Contact(Salutation='Mr',LastName='Staff', Firstname='Contact',Email='staff@contact.com');
        Contact additionalContact = new Contact(Salutation='Mr',LastName='Additional', Firstname='Contact',Email='additional@contact.com');

        insert new List<Contact>{customer,staff,additionalContact};

        Case transportCase = getTransportCaseRecord();
        transportCase.contactId=customer.Id;
        transportCase.staff_contact__c=staff.Id;
        insert transportCase;

        Additional_Corro_Recipients__c additionalRecipient = new Additional_Corro_Recipients__c(case__c=transportCase.Id,contact__c=additionalContact.Id);
        insert additionalRecipient;


        NoteOrAttachment__c responseCustomAttachment = new NoteOrAttachment__c();
        responseCustomAttachment.Name = 'Response_timestamp';
        responseCustomAttachment.ContentType__c = 'application/pdf';
        responseCustomAttachment.Case__c = transportCase.Id;
        responseCustomAttachment.IsMinCorroCaseNote__c = TRUE;
        responseCustomAttachment.Category__c = GlobalConstants.ATTACHMENT_CATEGORY_SIGNED_RESPONSE;

        NoteOrAttachment__c enclosureCustomAttachment = new NoteOrAttachment__c();
        enclosureCustomAttachment.Name = 'Enclosure';
        enclosureCustomAttachment.ContentType__c = 'application/pdf';
        enclosureCustomAttachment.Case__c = transportCase.Id;
        enclosureCustomAttachment.IsMinCorroCaseNote__c = TRUE;
        enclosureCustomAttachment.Category__c = GlobalConstants.ENCLOUSER;
       
        insert new List<NoteOrAttachment__c>{responseCustomAttachment,enclosureCustomAttachment};
       
        Attachment responseAttach = new Attachment();    
        responseAttach.Name = 'Dummy Response pdf';
        Blob responseBodyBlob = Blob.valueOf('Dummy pdf');
        responseAttach.body = responseBodyBlob;
        responseAttach.parentId = responseCustomAttachment.Id;

        Attachment enclosureAttach = new Attachment();    
        enclosureAttach.Name = 'Dummy Response pdf';
        Blob enclosureBodyBlob = Blob.valueOf('Dummy pdf');
        enclosureAttach.body = enclosureBodyBlob;
        enclosureAttach.parentId = enclosureCustomAttachment.Id;

        insert new List<Attachment>{responseAttach,enclosureAttach};       
        
        responseCustomAttachment.Attachment__c = responseAttach.Id;
        enclosureCustomAttachment.Attachment__c = enclosureAttach.Id;
        update new List<NoteOrAttachment__c>{responseCustomAttachment,enclosureCustomAttachment};


        Test.startTest();
        EmailCustomer.prepareAndSendEmail(transportCase.Id);
        Test.stopTest();


    }   


    @isTest
    static void prepareAndSendEmailExceptionHandling(){
        Test.startTest();
        EmailCustomer.prepareAndSendEmail(NULL);
        Test.stopTest();        
    }

    /*------------------------------------------------------------------- ----------------
    Author:  Arxxus      
    Description:   This method creates a roads case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getRoadsCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'MAGS Approved',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            MO_User__c = NULL,
                            Response_Type__c = 'Draft response',
                            Signatory__c = 'Minister for Roads, Maritime and Freight');
    }
       
    /*------------------------------------------------------------------- ----------------
    Author:        
    Description:   This method creates a transport case record sobject
    -----------------------------------------------------------------------------------*/
    public static Case getTransportCaseRecord() {
       
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1];
       
        return new Case(Subject = 'Pothole',
                            Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                            Status = 'MAGS Approved',
                            RecordTypeId = rt.Id,
                            Priority = 'Normal',
                            Modes__c = 'MAGS', 
                            MO_User__c = NULL,
                            Response_Type__c = 'Draft response',
                            Signatory__c = 'Minister for Transport and Infrastructure');
    }

    public static void setupCaseRecTypesToExcludeCS() {
   
        List<CaseRecordTypesToExcludeFromRtFlip__c> rtToExclude = new List<CaseRecordTypesToExcludeFromRtFlip__c>();
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'General Ministerial Correspondence', Record_Type_Name__c = 'General Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Roads & Freight Ministerial Cor', Record_Type_Name__c = 'Roads & Freight Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Transport Ministerial Correspondence', Record_Type_Name__c = 'Transport Ministerial Correspondence'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign', Record_Type_Name__c = 'Campaign'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Campaign Member', Record_Type_Name__c = 'Campaign Member'));
        rtToExclude.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name= 'Erroneous Cases', Record_Type_Name__c = 'Erroneous Cases Ministerial Correspondence'));
        insert rtToExclude;
    }
    
}