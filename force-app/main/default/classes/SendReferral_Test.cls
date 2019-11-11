@isTest
private class SendReferral_Test {
    
    static Case referralCase;
    static Contact customer ;
    static  Contact staff;
    static Contact additionalContact;
    static Additional_Corro_Recipients__c additionalRecipient;
    static referral_template_by_response_type__c templateSetting;

    static void setupTestData() {
        
        //populate customer, staff, and additional contact
        customer = new Contact(Salutation='Mr',LastName='Customer', Firstname='Contact',Email='customer@contact.com');
        staff = new Contact(Salutation='Mr',LastName='Staff', Firstname='Contact',Email='staff@contact.com');
        additionalContact = new Contact(Salutation='Mr',LastName='Additional', Firstname='Contact',Email='additional@contact.com');

        insert new List<Contact>{customer,staff,additionalContact};

        //populate a case record type transport ministreal correspondance
        Map<String,Schema.RecordTypeInfo> rtMapByName =Schema.SObjectType.Case.getRecordTypeInfosByName();
        Schema.RecordTypeInfo minCorRoadRecordType=rtMapByName.get(GlobalConstants.CASE_RECORD_TYPE_LABEL_MINCORR_ROAD);

        referralCase=new Case(
            contactId=customer.Id,
            staff_contact__c=staff.Id,
            recordtypeId=minCorRoadRecordType.getRecordTypeId(),
            response_type__c=GlobalConstants.CASE_RESPONSE_TYPE_PARTIAL_REFERRAL,
            subject= 'test',
            description ='test',
            status=GlobalConstants.MAGS_APPROVED_MIN_CORRO
        );
        
        insert referralCase;
        
        //populate additional corro recipients
        additionalRecipient= new Additional_Corro_Recipients__c(case__c=referralCase.Id,contact__c=additionalContact.Id);
        insert additionalRecipient;
        
        //populate custom settings for Referral
        templateSetting = new referral_template_by_response_type__c(
            
            Name='Partial Referral',
            Additional_Contacts__c='Partial_Referral_Additional_contacts_Template',
            Customer__c='Partial_Referral_Customer_Template',
            Staff__c='Partial_Referral_Staff_Template', 
            Staff_attachment_categories__c='Signed Response', 
            customer_attachment_categories__c='Signed Response', 
            additional_contact_attachment_categories__c='Signed Response,Incoming'
        );
        insert templateSetting;
        

        NoteOrAttachment__c noraIncoming= new NoteOrAttachment__c(
            Name='incoming',
            Category__c='Incoming',
            case__c=referralCase.Id,
            File_Name__c='incoming'
        );
       
        NoteOrAttachment__c noraResponse= new NoteOrAttachment__c(
            Name='Unsigned Response',
            Category__c='Signed Response',
            case__c=referralCase.Id,
            File_Name__c='Signed Response'
        );
        insert new list<NoteOrAttachment__c>{noraResponse,noraIncoming};
       
       
        //todo insert attachments
        Attachment incoming= new Attachment();
        incoming.Body=Blob.valueOf('incoming');
        incoming.Name='incoming';
        incoming.parentId=noraIncoming.Id;
        
        noraIncoming.Attachment__c = incoming.Id;
        
        update noraIncoming;
        
        //todo insert attachments
        Attachment usResponse= new Attachment();
        usResponse.Body=Blob.valueOf('Signed Response');
        usResponse.Name='Signed Response';
        usResponse.parentId=noraResponse.Id;
        insert new List<Attachment>{incoming,usResponse};

        noraResponse.Attachment__c = usResponse.Id;
        
        update noraResponse;
    }
    
    @isTest static void test_sendReferral() {
        
        setupCaseRecTypesToExcludeCS();
        setupTestData();
        
        //set up the id parameter of current page and invoke the sendReferral method
        Test.startTest();
        PageReference sendReferralPageReference= Page.SendReferral;
        system.assertNotEquals(referralCase,null);
        system.assertNotEquals(referralCase.id,null);
        system.assertNotEquals(sendReferralPageReference.getParameters(),null);

        sendReferralPageReference.getParameters().put('id',referralCase.id);
        Test.setCurrentPage(sendReferralPageReference);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Additional_Corro_Recipients__c>{additionalRecipient});
        ssc.setSelected(new List<Additional_Corro_Recipients__c>{additionalRecipient});
        Referrals sendMail = new Referrals(ssc);

        Test.stopTest();
        for(ApexPages.Message msg : ApexPages.getMessages()) {
            System.debug(msg.getSummary());
            System.debug(msg.getDetail());

        }
        system.assertNotEquals(sendMail.recipients,null);
    }
    
    @isTest static void test_send() {
        
        setupCaseRecTypesToExcludeCS();
        setupTestData();
        
        //set up the id parameter of current page and invoke the send method
        //set up the id parameter of current page and invoke the sendReferral method
        PageReference sendReferralPageReference= Page.SendReferral;
        system.assertNotEquals(referralCase,null);
        system.assertNotEquals(referralCase.id,null);
        system.assertNotEquals(sendReferralPageReference.getParameters(),null);
        sendReferralPageReference.getParameters().put('id',referralCase.id);
        Test.setCurrentPage(sendReferralPageReference);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Additional_Corro_Recipients__c>{additionalRecipient});
        ssc.setSelected(new List<Additional_Corro_Recipients__c>{additionalRecipient});
        Referrals sendMail= new Referrals(ssc);
        Test.startTest();
        
        for(Referrals.Recipient recipient : sendMail.recipients) {
            recipient.doSend = true;
        }
        
        sendMail.send();
        Test.stopTest();
        
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
           
            System.debug(msg.getSummary());
            System.debug(msg.getDetail());

        }
        
        Case updatedCase = [select id, Are_All_Recipients_Referrel__c, status from Case where Id=:sendMail.caseId];
        //system.assertEquals(updatedCase.Are_All_Recipients_Referrel__c, true);   
    }
    
    @isTest static void test_sendReferralSettingFailure() {
        
        setupCaseRecTypesToExcludeCS();
        setupTestData();
        
        List<referral_template_by_response_type__c> referralCustomSettings = referral_template_by_response_type__c.getall().values();
        
        delete referralCustomSettings;
        
        //set up the id parameter of current page and invoke the send method
        //set up the id parameter of current page and invoke the sendReferral method
        PageReference sendReferralPageReference= Page.SendReferral;
        system.assertNotEquals(referralCase,null);
        system.assertNotEquals(referralCase.id,null);
        system.assertNotEquals(sendReferralPageReference.getParameters(),null);
        sendReferralPageReference.getParameters().put('id',referralCase.id);
        Test.setCurrentPage(sendReferralPageReference);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Additional_Corro_Recipients__c>{additionalRecipient});
        ssc.setSelected(new List<Additional_Corro_Recipients__c>{additionalRecipient});
        Referrals sendMail= new Referrals(ssc);
        Test.startTest();
        
        for(Referrals.Recipient recipient : sendMail.recipients) {
            recipient.doSend = true;
        }
        
        sendMail.send();
        Test.stopTest();
        
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
           
            System.debug(msg.getSummary());
            System.debug(msg.getDetail());

        }
        
        Case updatedCase= [select id, Are_All_Recipients_Referrel__c, status from Case where Id = :sendMail.caseId];
        system.assertEquals(updatedCase.Are_All_Recipients_Referrel__c, false);   
    }
    
    @isTest static void test_sendReferralFailure() {
        
        setupCaseRecTypesToExcludeCS();
        setupTestData();
        
        //set up the id parameter of current page and invoke the send method
        //set up the id parameter of current page and invoke the sendReferral method
        PageReference sendReferralPageReference= Page.SendReferral;
        system.assertNotEquals(referralCase,null);
        system.assertNotEquals(referralCase.id,null);
        system.assertNotEquals(sendReferralPageReference.getParameters(),null);
        
        //sendReferralPageReference.getParameters().put('id', referralCase.id);
        Test.setCurrentPage(sendReferralPageReference);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Additional_Corro_Recipients__c>{});
        ssc.setSelected(new List<Additional_Corro_Recipients__c>{});
        Referrals sendMail = new Referrals(ssc);
        
        Case updatedCase= [select id, Are_All_Recipients_Referrel__c, status from Case where Id = :referralCase.Id];
        system.assertEquals(updatedCase.Are_All_Recipients_Referrel__c, false);   
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