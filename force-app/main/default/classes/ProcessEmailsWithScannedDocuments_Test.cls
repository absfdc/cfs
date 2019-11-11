/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Test class for inbound email handler for Mcorr E2C

History
10/04/2015     Manish Damle       Created
16/07/2015     Manish Damle       Updated as per the WI1061
02/11/2016     Arxxus             Updated to include test cases for road & transport flow
-----------------------------------------------------------------------------------*/
@isTest
public class ProcessEmailsWithScannedDocuments_Test {
    
   
    //CAMPAIGN MEMBER CREATION
    @isTest
    static void campaignMemberCreationTest() {
        Id campaignMemberRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_CAMPAIGNMEMBER limit 1].Id;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        Test.startTest();
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailCampaignMember(), env);
        Test.stopTest();
        //system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, RecordTypeId From Case];    
        //system.assertEquals(1, cases.size());
        //system.assertEquals(campaignMemberRecordTypeId, cases[0].RecordTypeId);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0'];
       // system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
       // system.assertEquals(1, attachments.size());
    }
    
    //EXCEPTION IN CAMPAIGN MEMBER CREATION
    @isTest
    static void campaignMemberCreationFailedTest() {
        system.assertEquals(false, new CaseCampaignMemberCreator().process(null,null,null).success);
    }
    
    //CASE MARKED AS AMENDMENT
    @isTest
    static void amendmentCreationTest() {
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        
        Test.startTest();
            //Fetch the case record to get the Case Reference Number Generated
            Case existingCase = [Select Id, CaseNumber From Case Where Id =: caseRecord.Id];
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailAmendment('Amendment Scanned email |||' + existingCase.CaseNumber + '|||'), env);
        Test.stopTest();
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, Amendment__c, Amendment_Count__c, Amendment_Triaged__c, RecordTypeId From Case];    
        system.assertEquals(1, cases.size());
        system.assertEquals(1, cases[0].Amendment_Count__c);
        system.assertEquals(true, cases[0].Amendment__c);
        system.assertEquals(false, cases[0].Amendment_Triaged__c);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0' And ParentId =: existingCase.Id];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c Where Case__c =: caseRecord.Id];
        system.assertEquals(1, attachments.size());  
    }
    
    //AMEDNDMENT CREATION FAILED
    @isTest
    static void amendmentCreationFailedTest() {
        system.assertEquals(false, new CaseAmendmentEmailsProcessor().process(null,null,null).success);
    }
    
    //CASE NOT FOUND AMENDMENT NOT CREATED
    @isTest
    static void amendmentNotCreatedCreatedTest() {
        Group eq = [Select Id From Group Where DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO And Type = 'Queue' limit 1];
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        Test.startTest();
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailAmendment('Amendment Scanned email |||NOTFOUND|||'), env);
        Test.stopTest();
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, Status, RecordTypeId,OwnerId From Case];    
        system.assertEquals(1, cases.size());
        system.assertEquals(eq.Id, cases[0].OwnerId);
        system.assertEquals('Error - Case Not Found', cases[0].Status);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0'];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size()); 
    }
    
    //PATTERN NOT FOUND AMENDMENT NOT CREATED
    @isTest
    static void amendmentNotCreatedPatternNotFoundCreatedTest() {
        Group eq = [Select Id From Group Where DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO And Type = 'Queue' limit 1];
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        Test.startTest();
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailAmendment('Amendment Email'), env);
        Test.stopTest();
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, Status, RecordTypeId,OwnerId From Case];    
        system.assertEquals(1, cases.size());
        system.assertEquals(eq.Id, cases[0].OwnerId);
        system.assertEquals('Error - Case Not Found', cases[0].Status);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0'];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size()); 
    }
    
    //ORDINARY CASE CREATED
    @isTest
    static void normalCaseCreationTest() {
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        Test.startTest();
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailSignedResponses('Incomming Correspondence 348743_khfsdf'), env);
        Test.stopTest();
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, RecordTypeId From Case];    
        system.assertEquals(1, cases.size());
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0'];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size());     
    }
    
    //SCANNED RESPONSE ATTACHED TO THE CASE
    @isTest
    static void signedResponseCreationTest() {
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        Case caseRecord = getCaseRecord();
        insert caseRecord;
        
        Test.startTest();
            //Fetch the case record to get the Case Reference Number Generated
            Case existingCase = [Select Id, CaseNumber From Case Where Id =: caseRecord.Id];
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailSignedResponses('Scanned email |||'+ existingCase.CaseNumber +'|||'), env);
        Test.stopTest();
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, Status,RecordTypeId From Case];    
        system.assertEquals(1, cases.size());
        system.assertEquals('Signed', cases[0].Status);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0' And ParentId =: existingCase.Id];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c Where Case__c =: caseRecord.Id];
        system.assertEquals(1, attachments.size());    
        Boolean isKaUser = [Select Id, UserPermissionsKnowledgeUser From User Where Id =: UserInfo.getUserId() limit 1].UserPermissionsKnowledgeUser;
        if(isKaUser) {
            list <CaseArticle> caseKav = [Select Id From CaseArticle Where CaseId =: caseRecord.Id];
            system.assertEquals(1, caseKav.size());    
        }
    }
    
    //CASE NOT FOUND SIGNED RESPONSE NOT CREATED. ERROR CASE CREATED
    @isTest
    static void signedResponseCaseNotFoundErroneousCaseCreationTest() {
        Group eq = [Select Id From Group Where DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO And Type = 'Queue' limit 1];
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        Test.startTest();
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailSignedResponses('Scanned email |||76721376|||'), env);
        Test.stopTest();
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, Status, RecordTypeId,OwnerId From Case];    
        system.assertEquals(1, cases.size());
        system.assertEquals(eq.Id, cases[0].OwnerId);
        system.assertEquals('Error - Case Not Found', cases[0].Status);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0'];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size()); 
    }
    
    //SCANNED RESPONSE CREATION FAILED
    @isTest
    static void signedResponseCreationFailedTest() {
        system.assertEquals(false, new CaseSignedResponseProcessor().process(null,null,null).success);
    }
    
    @isTest
    static void futureMethodTestKAV() {
        createPrefixSuffixConfigurationCustomSetting();
        Case caseRecord = getCaseRecord();
        system.runAs(new User(Id= UserInfo.getUserId())) {    
            insert caseRecord;
        }
        
        Group eq = [Select Id From Group Where DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO And Type = 'Queue' limit 1];
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        Test.startTest();
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailSignedResponses('Scanned email |||76721376|||'), env);
        Test.stopTest();
        
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, Status, RecordTypeId,OwnerId From Case];    
        list <NoteOrAttachment__c> attachments = [Select Id, Case__c From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size()); 
        
        system.runAs(new User(Id= UserInfo.getUserId())) {    
            NoteOrAttachment__c att  = attachments[0];
            att.Case__c = caseRecord.Id;
            update att;
        }
        
        attachments = [Select Id, Case__c From NoteOrAttachment__c Where Case__c =: caseRecord.Id];
        system.assertEquals(1, attachments.size()); 
    }
    
    @isTest
    static void futureMethodTestAmendment() {
        createPrefixSuffixConfigurationCustomSetting();
        Case caseRecord = getCaseRecord();
            
        system.runAs(new User(Id= UserInfo.getUserId())) {    
            insert caseRecord;
        }
        
        Group eq = [Select Id From Group Where DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO And Type = 'Queue' limit 1];
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        Test.startTest();
            Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailAmendment('Amendment Email'), env);
        Test.stopTest();
        system.assertEquals(true, result.success);
        list <Case> cases = [Select Id, Status,Amendment__c, RecordTypeId,OwnerId From Case Where Amendment__c = true];  
        system.assertEquals(1, cases.size()); 
        list <NoteOrAttachment__c> attachments = [Select Id, Case__c From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size()); 
        
        system.runAs(new User(Id= UserInfo.getUserId())) {    
            NoteOrAttachment__c att  = attachments[0];
            att.Case__c = caseRecord.Id;
            update att;
        }
    }
    
    /*------------------------------------------------------------------- ----------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates a case record sobject
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    16/07/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static Case getCaseRecord() {
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.MIN_CORRO_RECTYPE_API_NAME limit 1];
        return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                        Status = 'New',
                        RecordTypeId = rt.Id,
                        Agency__c = 'Agency1',
                        Priority = 'High');
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method create email object for testing Campaign Member
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    10/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static Messaging.InboundEmail getInboundEmailCampaignMember() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'This is campaign member';
        email.fromAddress ='test@demo.com';
        email.toAddresses = new String [] {'tfnswcamapigns@gmail.com'};
        email.subject = 'Campaign Member 12321_82173_93';
        
        //Binary attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'cm_4535.pdf';
        attachment.mimeTypeSubType = 'application/pdf';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        return email;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method create email object for testing Amendments
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    10/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static Messaging.InboundEmail getInboundEmailAmendment(String Subject) {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'This is an amendment';
        email.fromAddress ='test@demo.com';
        email.toAddresses = new String [] {'tfnswamendments@gmail.com'};
        email.subject = Subject;//'Scanned email |||' ++ '|||';
        
        //Binary attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'amendment_splip.pdf';
        attachment.mimeTypeSubType = 'application/pdf';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        return email;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method create email object for testing signed responses
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    10/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static Messaging.InboundEmail getInboundEmailSignedResponses(String Subject) {
       
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'This is scanned response';
        email.fromAddress ='test@demo.com';
        email.toAddresses = new String [] {'tfnswmincorro@gmail.com'};
        email.subject = Subject;//'Scanned email |||' ++ '|||';
        
        //Binary attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = '2637238234_R.pdf';
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.Name = 'Content-Type';
        header.value='application/pdf;';
        attachment.headers = new List<Messaging.InboundEmail.Header> {header};
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        return email;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Arxxus
    Description:   This method create email object for testing roads correspondence
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    02/011/2016     Arxxus             Created
    -----------------------------------------------------------------------------------*/
    public static Messaging.InboundEmail getInboundEmailRoads() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'This is roads correspondence';
        email.fromAddress ='test@demo.com';
        email.toAddresses = new String [] {'tfnswroads@gmail.com'};
        email.subject = 'Roads Correspondence';
        
        //Binary attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'cm_4535.pdf';
        attachment.mimeTypeSubType = 'application/pdf';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        return email;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Arxxus
    Description:   This method create email object for testing transport correspondence
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    02/011/2016     Arxxus             Created
    -----------------------------------------------------------------------------------*/
    public static Messaging.InboundEmail getInboundEmailTransport() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'This is transport correspondence';
        email.fromAddress ='test@demo.com';
        email.toAddresses = new String [] {'tfnswtransport@gmail.com'};
        email.subject = 'Transport Correspondence';
        
        //Binary attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'cm_4535.pdf';
        attachment.mimeTypeSubType = 'application/pdf';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        return email;
    }
    
    //Roads Correspondence Case Creation
    @isTest
    static void roadsCaseCreationTest() {
        
        Id roadsRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD limit 1].Id;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        
        Test.startTest();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailRoads(), env);
        Test.stopTest();
        
        System.assertEquals(true, result.success);
        
        List<Case> cases = [Select Id, RecordTypeId From Case];    
        
        system.assertEquals(1, cases.size());
        system.assertEquals(roadsRecordTypeId, cases[0].RecordTypeId);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0'];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size());
    }
    
    //Transport Correspondence Case Creation
    @isTest
    static void transportCaseCreationTest() {
        
        Id transportRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1].Id;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailsWithScannedDocumentsHandler emailHandler = new InboundEmailsWithScannedDocumentsHandler();
        createPrefixSuffixConfigurationCustomSetting();
        
        Test.startTest();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailTransport(), env);
        Test.stopTest();
        
        System.assertEquals(true, result.success);
        
        List<Case> cases = [Select Id, RecordTypeId From Case];    
        
        system.assertEquals(1, cases.size());
        system.assertEquals(transportRecordTypeId, cases[0].RecordTypeId);
        list <EmailMessage> emailMessages = [Select Id From EmailMessage Where Status = '0'];
        system.assertEquals(1, emailMessages.size());
        list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
        system.assertEquals(1, attachments.size());
    }
    
    //EXCEPTION IN ROADS/Transport CASE CREATION
    @isTest
    static void roadsTransportCaseCreationFailedTest() {
     
     System.assertEquals(false, new CaseRoadsTransportCreator().process(null,null,null).success);
    }
    
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates custom setting data
    Inputs:        prefix and suffix strings
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    10/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static void createPrefixSuffixConfigurationCustomSetting() {
       
        EmailSubjectPatternConfiguration__c patternConfiguration = new EmailSubjectPatternConfiguration__c();
        patternConfiguration.Name = 'EmailSubjectPatternConfiguration';
        patternConfiguration.Prefix__c = 'Scanned email |||';
        patternConfiguration.Suffix__c = '|||';
        patternConfiguration.New_Case_Origin__c = 'Email';
        patternConfiguration.New_Case_Priority__c = 'Normal';
        patternConfiguration.ToAddress__c = 'ministerialc@8-29deax1wci890oh2i6n8oa5d31nn7aivow40811jw1vgkp35wr.o-51g8amae.cs5.apex.sandbox.salesforce.com,tfnswmincorro@gmail.com';
        patternConfiguration.New_Case_Record_Type_Name__c = 'General_Ministerial_Correspondence';
        patternConfiguration.Erroneous_Case_Record_Type_Name__c = 'ErroneousCasesMinisterialCorrespondence';
        patternConfiguration.HandlerClass__c = 'CaseSignedResponseProcessor';
        patternConfiguration.New_Case_Status__c = 'Registration';
        insert patternConfiguration;
        
        EmailSubjectPatternConfiguration__c patternConfiguration1 = new EmailSubjectPatternConfiguration__c();
        patternConfiguration1.Name = 'EmailSubjectPatternConfigAmendment';
        patternConfiguration1.Prefix__c = 'Scanned email |||';
        patternConfiguration1.Suffix__c = '|||';
        patternConfiguration1.New_Case_Origin__c = 'Email';
        patternConfiguration1.New_Case_Priority__c = 'Normal';
        patternConfiguration1.ToAddress__c = 'ministerialc@8-29deax1wci890oh2i6n8o56767nn7aivow40811jw1vgkp35wr.o-51g8amae.cs5.apex.sandbox.salesforce.com,tfnswamendments@gmail.com';
        patternConfiguration1.New_Case_Record_Type_Name__c = 'General_Ministerial_Correspondence';
        patternConfiguration1.Erroneous_Case_Record_Type_Name__c = 'ErroneousCasesMinisterialCorrespondence';
        patternConfiguration1.HandlerClass__c = 'CaseAmendmentEmailsProcessor';
        patternConfiguration.New_Case_Status__c = 'Registration';
        insert patternConfiguration1;
        
        EmailSubjectPatternConfiguration__c patternConfiguration2 = new EmailSubjectPatternConfiguration__c();
        patternConfiguration2.Name = 'EmailSubjectPatternConfigurationCamp';
        patternConfiguration2.Prefix__c = 'Scanned email |||';
        patternConfiguration2.Suffix__c = '|||';
        patternConfiguration2.New_Case_Origin__c = 'Email';
        patternConfiguration2.New_Case_Priority__c = 'Normal';
        patternConfiguration2.ToAddress__c = 'ministerial@8-29deax1wci890oh2i6n8oa5d31nn7aivow40811jw1vgkp35wr.o-51g8amae.cs5.apex.sandbox.salesforce.com,tfnswcamapigns@gmail.com';
        patternConfiguration2.New_Case_Record_Type_Name__c = 'CampaignMember';
        patternConfiguration2.Erroneous_Case_Record_Type_Name__c = 'ErroneousCasesMinisterialCorrespondence';
        patternConfiguration2.HandlerClass__c = 'CaseCampaignMemberCreator';
        patternConfiguration.New_Case_Status__c = 'Registration';
        insert patternConfiguration2;
        
        EmailSubjectPatternConfiguration__c patternConfiguration3 = new EmailSubjectPatternConfiguration__c();
        patternConfiguration3.Name = 'EmailSubjectPatternConfigRoads';
        patternConfiguration3.Prefix__c = '';
        patternConfiguration3.Suffix__c = '';
        patternConfiguration3.New_Case_Origin__c = 'Email';
        patternConfiguration3.New_Case_Priority__c = 'Normal';
        patternConfiguration3.ToAddress__c = 'roads_ministerial_correspondence_e2c@2diitviya9fslhnqg7gzomgg2krm5jsg1qsmz9wlmosf0p27tv.p-1b3weau.cs31.apex.sandbox.salesforce.com,tfnswroads@gmail.com';
        patternConfiguration3.New_Case_Record_Type_Name__c = 'Roads_Freight_Ministerial_Correspondence';
        patternConfiguration3.Erroneous_Case_Record_Type_Name__c = 'ErroneousCasesMinisterialCorrespondence';
        patternConfiguration3.HandlerClass__c = 'CaseRoadsTransportCreator';
        patternConfiguration.New_Case_Status__c = 'Pre-Registration';
        insert patternConfiguration3;
        
        EmailSubjectPatternConfiguration__c patternConfiguration4 = new EmailSubjectPatternConfiguration__c();
        patternConfiguration4.Name = 'EmailSubjectPatternConfigTransport';
        patternConfiguration4.Prefix__c = '';
        patternConfiguration4.Suffix__c = '';
        patternConfiguration4.New_Case_Origin__c = 'Email';
        patternConfiguration4.New_Case_Priority__c = 'Normal';
        patternConfiguration4.ToAddress__c = 'transport_ministerial_correspondence_e2c@s-21zbuu6917dh35kmpbr1u5ga7g6jolx7wvl3vfedgu1rhccgsc.p-1b3weau.cs31.apex.sandbox.salesforce.com,tfnswtransport@gmail.com';
        patternConfiguration4.New_Case_Record_Type_Name__c = 'Transport_Ministerial_Correspondence';
        patternConfiguration4.Erroneous_Case_Record_Type_Name__c = 'ErroneousCasesMinisterialCorrespondence';
        patternConfiguration4.HandlerClass__c = 'CaseRoadsTransportCreator';
        patternConfiguration.New_Case_Status__c = 'Pre-Registration';
        insert patternConfiguration4;
        
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