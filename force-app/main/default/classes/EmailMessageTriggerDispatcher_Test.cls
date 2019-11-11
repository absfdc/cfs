@isTest
private class EmailMessageTriggerDispatcher_Test
{
    static Contact customer;
    static Contact sme;
    static String caseRefRegex='(?<=(ref:))(.*?)(?=(:ref))';
    static final string ADVICE_REQUEST_SUBJECT = 'Advice Request-';
    static final string SME_ACTIONPLAN_WAITING_STATUS = 'New';
    private static void createContacts(){
        customer= new Contact(FirstName='dip',
                                        LastName='bar',
                                        Email='dipbar@test.com');
        insert customer;
        sme= new Contact(FirstName='sme',
                                        LastName='stud',
                                        Email='sme@test.com');
        insert sme;
    }
    
    private static void createAdviceSubjectSettings(){
        SMEActivitySubject__c adviceSubject= new SMEActivitySubject__c(Name = ADVICE_REQUEST_SUBJECT);
        insert adviceSubject;
        
        CaseObjectConfigurations__c defaultOwner = new CaseObjectConfigurations__c();
        defaultOwner.Name = 'DefaultCaseOwner';
        defaultOwner.Value__c = UserInfo.getUserId();
        insert defaultOwner;
    }

    private static void createSNSWTaxonomyData() {
        Taxonomy_Metadata__c l0 = new Taxonomy_Metadata__c(Name = 'Road', Type__c = 'Mode', Customer_Value__c = 'Road');
        insert l0;

        Taxonomy_Metadata__c l1 = new Taxonomy_Metadata__c(Name = 'Roads', Type__c = 'Issue', Parent_Id__c = l0.Id, Customer_Value__c = 'Roads');
        insert l1;

        Taxonomy_Metadata__c l2 = new Taxonomy_Metadata__c(Name = 'Tolling', Type__c = 'Issue', Parent_Id__c = l1.Id, Customer_Value__c = 'Tolling');
        insert l2;

        Taxonomy_Metadata__c l3 = new Taxonomy_Metadata__c(Name = 'E-tags', Type__c = 'Issue', Parent_Id__c = l2.Id, Customer_Value__c = 'E-tags');
        insert l3;

        Taxonomy_Metadata__c lt1 = new Taxonomy_Metadata__c(Name = 'Roads', Type__c = 'Location', Parent_Id__c = l0.Id, Customer_Value__c = 'Roads');
        insert lt1;

        Taxonomy_Metadata__c lt2 = new Taxonomy_Metadata__c(Name = 'Region', Type__c = 'Location', Parent_Id__c = lt1.Id, Customer_Value__c = 'Region');
        insert lt2;

        Taxonomy_Metadata__c lt3 = new Taxonomy_Metadata__c(Name = 'Sydney', Type__c = 'Location', Parent_Id__c = lt2.Id, Customer_Value__c = 'Sydney');
        insert lt3;
    }
    
    private static void createCustomSettingEntryForSnsw() {
        SNSW_referral_email_address__c snswSetting = new SNSW_referral_email_address__c();
        snswSetting.To_address__c = 'tnsw@service.nsw.gov.au';
        snswSetting.Name = 'Tolling';
        
        insert snswSetting;
    }

    
     @isTest
    static void inboundSnswResponseClosedCloned()
    {
        system.runAs(new User(id = UserInfo.getUserId())) {
            createContacts();
            createSNSWTaxonomyData();
            createCustomSettingEntryForSnsw();
        }
        List<Group> queues = [Select Id,DeveloperName From Group WHERE Type = 'Queue' and DeveloperName = 'SNSW_Holding'];
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Road' limit 1];
        RecordType CASE_REC_TYPE = caseTypes.size()==0?null:caseTypes[0];
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Agency__c='SNSW',
                                RecordTypeId=CASE_REC_TYPE.Id,
                                Modes__c = 'Road',
                                Taxonomy_Moment__c = 'Roads',
                                Taxonomy_Transaction__c = 'Tolling',
                                Taxonomy_Symptom__c = 'E-tags',
                                Taxonomy_Location_Type__c = 'Roads',
                                Taxonomy_Area__c = 'Region',
                                Taxonomy_Location__c = 'Sydney',
                                OwnerId = queues[0].Id);
        insert thisCase;
        thisCase.Status='Finalised';
        update thisCase;
        List <Case> latestCases = [SELECT Id, Status,Agency__c FROM Case WHERE Id = :thisCase.Id];
        system.debug('----Updated Case Information------' + latestCases);
        EmailMessage snswResponse = new EmailMessage(FromAddress='tnsw@service.nsw.gov.au',
                                                        FromName='SNSW Team',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming = true,
                                                        ParentId=thisCase.Id,
                                                        Subject = Label.SNSW_referral_subject + ' ref:' + getThreadId(thisCase.Id) + ':ref',
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='sme@test.com');
        Test.startTest();        
        insert snswResponse;
        Test.stoptest();
        List<Case> cases= [SELECT Id, Status FROM Case WHERE ParentId = :thisCase.Id];
        //System.assert(!cases.isEmpty());
    }
    
    
    @isTest
    static void outboundAdviceCreatesActionPlan() {   
        createAdviceSubjectSettings();
        createContacts();
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New');
        insert thisCase;
     
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                      FromName='manager',
                                                      HtmlBody='this pothole has been repaired',
                                                      Incoming=false,
                                                      ParentId= thisCase.Id,
                                                      Subject= ADVICE_REQUEST_SUBJECT,
                                                      TextBody='this pothole has been repaired',
                                                      ToAddress='sme@test.com');
        Test.startTest();
            insert adviceOutbound;
        Test.stoptest();
        Action_Plan__c waitingAP = [Select Id, Status__c From Action_Plan__c Where Parent_Case__c =: thisCase.Id];
        system.assertEquals(waitingAP.Status__c, SME_ACTIONPLAN_WAITING_STATUS);
    }
    
    @isTest
    static void secondOutboundAdviceCreatesNoActionPlan() {    
        createAdviceSubjectSettings();
        createContacts();
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId = customer.Id,
                                Status='New');
        insert thisCase;
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='check out the pothole problem',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject=ADVICE_REQUEST_SUBJECT,
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='sme@test.com');
        insert adviceOutbound;
        
        EmailMessage adviceOutbound2= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='reminder to check the pothole again',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject=ADVICE_REQUEST_SUBJECT,
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='sme@test.com');
        Test.startTest();
            insert adviceOutbound2;
        Test.stoptest();

        list <Action_Plan__c> waitingAP = [Select Id, Status__c From Action_Plan__c];
        system.assertEquals(1, waitingAP.size());
    }

    @isTest
    static void secondOutboundAdviceOnAnotherCaseCreatesActionPlan()
    {   
        system.runAs(new User(Id = UserInfo.getUserId())){
            createAdviceSubjectSettings();
            createContacts();
        }
        
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Taxonomy_Moment__c = 'A',
                                Taxonomy_Transaction__c = 'B',
                                Taxonomy_Symptom__c = 'C',
                                Taxonomy_Location_Type__c = 'D',
                                Taxonomy_Area__c = 'E',
                                Taxonomy_Location__c = 'F');

        Case anotherCase= new Case(Subject='graffiti',
                                   Description='theres a graffiti in busstop near bondi beach',
                                   ContactId=customer.Id,
                                   Status='New',
                                   Taxonomy_Moment__c = 'A',
                                   Taxonomy_Transaction__c = 'B',
                                   Taxonomy_Symptom__c = 'C',
                                   Taxonomy_Location_Type__c = 'D',
                                   Taxonomy_Area__c = 'E',
                                   Taxonomy_Location__c = 'F');
        system.runAs(new User(Id = UserInfo.getUserId())){
            insert thisCase;    
        }
        
        system.runAs(new User(Id = UserInfo.getUserId())){
            insert anotherCase;
        }
        Test.startTest();

        system.runAs(new User(Id = UserInfo.getUserId())){
            EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                            FromName='manager',
                                                            HtmlBody='check out the pothole problem',
                                                            Incoming=false,
                                                            ParentId=thisCase.Id,
                                                            Subject=ADVICE_REQUEST_SUBJECT,
                                                            TextBody='this pothole has been repaired',
                                                            ToAddress='sme@test.com');
            insert adviceOutbound;
        }
        Test.stoptest(); 
        system.runAs(new User(Id = UserInfo.getUserId())){
            EmailMessage adviceOutbound2= new EmailMessage(FromAddress='tnsw@test.com',
                                                            FromName='manager',
                                                            HtmlBody='reminder to check the pothole again',
                                                            Incoming=false,
                                                            ParentId=anotherCase.Id,
                                                            Subject=ADVICE_REQUEST_SUBJECT,
                                                            TextBody='this pothole has been repaired',
                                                            ToAddress='sme@test.com');
            
                insert adviceOutbound2;
                   
            list<Action_Plan__c> waitingAP = [Select Id, Status__c From Action_Plan__c Where Parent_Case__c IN (:thisCase.Id, :anotherCase.Id)];
            system.assertEquals(2,waitingAP.size());

        }
        
    }
    
    @isTest
    static void inboundAdviceUpdatesActionPlan()
    {
        createContacts();
        
        createAdviceSubjectSettings();
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Taxonomy_Moment__c = 'A',
                                Taxonomy_Transaction__c = 'B',
                                Taxonomy_Symptom__c = 'C',
                                Taxonomy_Location_Type__c = 'D',
                                Taxonomy_Area__c = 'E',
                                Taxonomy_Location__c = 'F');
        insert thisCase;
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='this pothole to be repaired',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject=ADVICE_REQUEST_SUBJECT,
                                                        TextBody='this pothole to be repaired',
                                                        ToAddress='sme@test.com');
        insert adviceOutbound;
        Test.startTest();
        EmailMessage adviceinbound= new EmailMessage(FromAddress='sme@test.com',
                                                        FromName='sme',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=true,
                                                        ParentId=thisCase.Id,
                                                        Subject= ADVICE_REQUEST_SUBJECT+' ref:'+getThreadId(thisCase.Id)+':ref',
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='tnsw@test.com');

        insert adviceinbound;
        Test.stoptest();
        Action_Plan__c waitingAP = [Select Id, Status__c From Action_Plan__c Where Parent_Case__c =: thisCase.Id];
        system.assertEquals('Completed',waitingAP.Status__c);

    }
    @isTest
    static void inboundRequestDoesnotUpdateActionPlanIfSubjectNotInSettings()
    {   createAdviceSubjectSettings();
        
        createContacts();
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Taxonomy_Moment__c = 'A',
                                Taxonomy_Transaction__c = 'B',
                                Taxonomy_Symptom__c = 'C',
                                Taxonomy_Location_Type__c = 'D',
                                Taxonomy_Area__c = 'E',
                                Taxonomy_Location__c = 'F');
        insert thisCase;
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='this pothole to be repaired',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject=ADVICE_REQUEST_SUBJECT,
                                                        TextBody='this pothole to be repaired',
                                                        ToAddress='sme@test.com');
        insert adviceOutbound;
        Test.startTest();
        EmailMessage adviceinbound= new EmailMessage(FromAddress='sme@test.com',
                                                        FromName='sme',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=true,
                                                        ParentId=thisCase.Id,
                                                        Subject=' ref:'+getThreadId(thisCase.Id)+':ref',
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='tnsw@test.com');

        insert adviceinbound;
        Test.stoptest();
        Action_Plan__c waitingAP = [Select Id, Status__c From Action_Plan__c Where Parent_Case__c =: thisCase.Id];
        system.assertEquals(SME_ACTIONPLAN_WAITING_STATUS, waitingAP.Status__c);

    }
    @isTest
    static void outboundCustomerMailDoesNotCreateActionPlan()
    {
        createContacts();
        
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Taxonomy_Moment__c = 'A',
                                Taxonomy_Transaction__c = 'B',
                                Taxonomy_Symptom__c = 'C',
                                Taxonomy_Location_Type__c = 'D',
                                Taxonomy_Area__c = 'E',
                                Taxonomy_Location__c = 'F');
        insert thisCase;
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject='reply to your call-',
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='dipbar@test.com');
        Test.startTest();
        insert adviceOutbound;
        Test.stoptest();
        list <Action_Plan__c> waitingAP = [Select Id, Status__c From Action_Plan__c Where Parent_Case__c =: thisCase.Id];
        system.assertEquals(waitingAP.size(),0);
    }

    @isTest
    static void inboundCustomerMailDoesNotUpdateActionPlanDoesNotClone()
    {   createAdviceSubjectSettings();

        createContacts();
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Taxonomy_Moment__c = 'A',
                                Taxonomy_Transaction__c = 'B',
                                Taxonomy_Symptom__c = 'C',
                                Taxonomy_Location_Type__c = 'D',
                                Taxonomy_Area__c = 'E',
                                Taxonomy_Location__c = 'F');
        insert thisCase;
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject=ADVICE_REQUEST_SUBJECT,
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='sme@test.com');
        insert adviceOutbound;
        Test.startTest();
        EmailMessage customerinbound= new EmailMessage(FromAddress='dipbar@test.com',
                                                        FromName='Customer',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=true,
                                                        ParentId=thisCase.Id,
                                                        Subject='folloup- ref:'+getThreadId(thisCase.Id)+':ref',
                                                        TextBody='this pothole has not been repaired',
                                                        ToAddress='tnsw@test.com');

        insert customerinbound;
        Test.stoptest();
        Action_Plan__c waitingAP = [Select Id, Status__c From Action_Plan__c Where Parent_Case__c =: thisCase.Id];
        system.assertNotEquals(waitingAp.Status__c, 'Closed');
        List<Case> cases=[select Id From Case];
        system.assertEquals(cases.size(),1);
    }

    @isTest
    static void inboundCustomerMailCaseRecentlyClosedReopens()
    {
        createContacts();
        
        ReopenDuration__c reopenCfg= new ReopenDuration__c (name='Agency1',Duration__c=1);
        insert reopenCfg;
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Agency__c='Agency1',
                                Taxonomy_Moment__c = 'A',
                                Taxonomy_Transaction__c = 'B',
                                Taxonomy_Symptom__c = 'C',
                                Taxonomy_Location_Type__c = 'D',
                                Taxonomy_Area__c = 'E',
                                Taxonomy_Location__c = 'F');
        insert thisCase;
        thisCase.Status='Finalised';
        update thisCase;
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject=ADVICE_REQUEST_SUBJECT,
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='sme@test.com');
        insert adviceOutbound;
        Test.startTest();
        EmailMessage customerinbound= new EmailMessage(FromAddress='dipbar@test.com',
                                                        FromName='Customer',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=true,
                                                        ParentId=thisCase.Id,
                                                        Subject='followup- ref:'+getThreadId(thisCase.Id)+':ref',
                                                        TextBody='this pothole has not been repaired',
                                                        ToAddress='tnsw@test.com');

        insert customerinbound;
        Test.stoptest();
    }

    @isTest
    static void inboundCustomerMailCaseLongTimeClosedCloned()
    {
        createContacts();
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName != :GlobalConstants.MIN_CORRO_RECTYPE_NAME limit 1];
        RecordType CASE_REC_TYPE = caseTypes.size()==0?null:caseTypes[0];
        Case thisCase= new Case(Subject='pothole',
                                Description='theres a pothole in the east street, west end crossing in front of busstop',
                                ContactId=customer.Id,
                                Status='New',
                                Agency__c='Agency1',
                                RecordTypeId=CASE_REC_TYPE.Id,
                                Taxonomy_Moment__c = 'A',
                                Taxonomy_Transaction__c = 'B',
                                Taxonomy_Symptom__c = 'C',
                                Taxonomy_Location_Type__c = 'D',
                                Taxonomy_Area__c = 'E',
                                Taxonomy_Location__c = 'F'
                                );
        insert thisCase;
        thisCase.Status='Finalised';
        update thisCase;
        EmailMessage adviceOutbound= new EmailMessage(FromAddress='tnsw@test.com',
                                                        FromName='manager',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=false,
                                                        ParentId=thisCase.Id,
                                                        Subject=ADVICE_REQUEST_SUBJECT,
                                                        TextBody='this pothole has been repaired',
                                                        ToAddress='sme@test.com');
        insert adviceOutbound;
        Test.startTest();
        EmailMessage customerinbound= new EmailMessage(FromAddress='dipbar@test.com',
                                                        FromName='Customer',
                                                        HtmlBody='this pothole has been repaired',
                                                        Incoming=true,
                                                        ParentId=thisCase.Id,
                                                        Subject='folloup- ref:'+getThreadId(thisCase.Id)+':ref',
                                                        TextBody='this pothole has not been repaired',
                                                        ToAddress='tnsw@test.com');

        insert customerinbound;
        Test.stoptest();

        List<Case> cases= [Select Id, Status From Case];
        //system.assertEquals(2, cases.size());
    }
    
   
    
    private static String getThreadId(String caseid) {
      
        String orgId= (String) UserInfo.getOrganizationId();
        String caseThreadId = '_'+
        ((string)orgId).substring(0,((string)orgId).substring(3,4)=='0'?3:4)+
        ((string)orgId).substring(4+((string)orgId).substring(4).indexOfAnyBut('0')-1,15) +'._'+
        caseid.substring(0,4) + '0' + caseid.substring(10,15);
        return caseThreadId;
    }
}