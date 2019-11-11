@isTest
private class CaseTriggerDispatcher_Test {
	
   private static void createKeyWordSettings() {
        List<Keywords__c> adviceSubjects= new List<Keywords__c>();
        adviceSubjects.add(new Keywords__c(Name='injured',Priority__c=GlobalConstants.CASE_PRIORITY_HIGH));
        adviceSubjects.add(new Keywords__c(Name='blood',Priority__c=GlobalConstants.CASE_PRIORITY_HIGH));
        adviceSubjects.add(new Keywords__c(Name='hospital',Priority__c=GlobalConstants.CASE_PRIORITY_HIGH));
        insert adviceSubjects;
    }

    @isTest
    static void shouldNotMatchIfBodyContainsKeywordButNoSettings(){
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        System.Assert(CasePriorityUtility.checkMatchesKeyword('I was injured because of the sharp metal jutting out ')==false);

    }

    @isTest
    static void shouldMatchIfBodyContainsKeywordDifferentCase(){
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        createKeyWordSettings();
        System.Assert(CasePriorityUtility.checkMatchesKeyword('I was Injured because of the sharp metal jutting out ')==true);

    }

    @isTest
    static void newCaseShouldNotChangePriorityBecauseMinCorroRecType(){

        createKeyWordSettings();
        String pattern= '%'+GlobalConstants.MIN_CORRO_RECTYPE_NAME+'%';
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName Like :pattern];
        RecordType MINCORRO = caseTypes.size()==0?null:caseTypes[0];
        Case minCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
                                Description='I was Injured because of the sharp metal jutting out ',
                                RecordTypeId=MINCORRO.Id,
                                Status='New',
                                Origin='Web',
                                Priority='Normal');
        Test.startTest();
        insert minCase;
        Test.stopTest();
        minCase=[select Id,Priority from Case where Id=: minCase.Id];
        system.assert('Normal'==minCase.Priority);
    }

    @isTest
    static void newCaseShouldNotChangePriorityBecauseCaseOriginNotWeb(){

        createKeyWordSettings();
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
        RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
        Case busCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
                                Description='I was Injured because of the sharp metal jutting out ',
                                RecordTypeId=BUS.Id,
                                Status='New',
                                Origin='Email',
                                Priority='Normal');
        Test.startTest();
        insert busCase;
        busCase=[select Id,Priority from Case where Id=: busCase.Id];
        system.assert('High'==busCase.Priority);
        Test.stopTest();
        
    }

    @isTest
    static void newCaseShouldNotChangeBecauseAlreadyHighCasePriority(){
        createKeyWordSettings();
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
        RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
        Case busCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
                                Description='I was Injured because of the sharp metal jutting out ',
                                RecordTypeId=BUS.Id,
                                Status='New',
                                Origin='Web',
                                Priority=GlobalConstants.CASE_PRIORITY_HIGH);
        Test.startTest();
        insert busCase;
        Test.stopTest();
        List<Application_Log__c> caseTriggerLogs= [select Id from Application_Log__c where Source__c='CaseBeforeInsertTriggerHandler'];
        system.assertEquals(0, caseTriggerLogs.size());
    }

    @isTest
    static void newCaseShouldMarkHighPriorityIfBodyContainsKeywordDifferentCase() {

        createKeyWordSettings();
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
        RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
        system.debug('case record type - '+BUS);
        Case busCase=new Case(Subject='I was Injured because of the sharp metal jutting out ',
                                Description='I was stopped because of the sharp metal jutting out ',
                                RecordTypeId=BUS.Id,
                                Status='New',
                                Origin='Web',
                                Priority='Normal');
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        Test.startTest();
        insert busCase;
        Test.stopTest();
        busCase=[select Id,Priority from Case where Id=: busCase.Id];
       
    }

    @isTest
    static void oldCaseUpdatedSubjectItShouldMarkHighPriorityIfBodyContainsKeywordDifferentCase() {

        createKeyWordSettings();
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
        RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
        system.debug('case record type - '+BUS);
        Case busCase=new Case(Subject='I was stopped because of the sharp metal jutting out ',
                                Description='I was stopped because of the sharp metal jutting out ',
                                RecordTypeId=BUS.Id,
                                Status='New',
                                Origin='Web',
                                Priority='Normal');
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');

        insert busCase;

        Test.startTest();
        busCase.Subject ='I was Injured because of the sharp metal jutting out ';
        update busCase;
        Test.stopTest();
        busCase=[select Id,Priority from Case where Id=: busCase.Id];
        system.assertEquals(GlobalConstants.CASE_PRIORITY_HIGH, busCase.Priority);
    }

    @isTest
    static void oldCaseUpdatedDescriptionShouldNotChangePriorityBecauseMinRecType() {
        createKeyWordSettings();
        String pattern= '%'+GlobalConstants.MIN_CORRO_RECTYPE_NAME+'%';
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName like :pattern];
        RecordType MINCORRO = caseTypes.size()==0?null:caseTypes[0];
        Case minCase=new Case(Subject='I was stopped because of the sharp metal jutting out ',
                                Description='I was stopped because of the sharp metal jutting out ',
                                RecordTypeId=MINCORRO.Id,
                                Status='New',
                                Origin='Web',
                                Priority='Normal');

        insert minCase;
        Test.startTest();
        minCase.Description='I was Injured because of the sharp metal jutting out ';
        update minCase;
        Test.stopTest();
        minCase=[select Id,Priority from Case where Id=: minCase.Id];

        system.assert('Normal'==minCase.Priority);
    }

    @isTest
    static void oldCaseUpdatedSubjectShouldNotChangeBecauseAlreadyHighCasePriority() {
        createKeyWordSettings();
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
        RecordType BUS = caseTypes.size()==0?null:caseTypes[0];
        Case busCase=new Case(Subject='I was stopped because of the sharp metal jutting out ',
                                Description='I was stopped because of the sharp metal jutting out ',
                                RecordTypeId=BUS.Id,
                                Status='New',
                                Origin='Web',
                                Priority=GlobalConstants.CASE_PRIORITY_HIGH);
        insert busCase;
        Test.startTest();
        busCase.Subject='I was Injured because of the sharp metal jutting out ';
        update busCase;
        Test.stopTest();
        List<Application_Log__c> caseTriggerLogs= [select Id from Application_Log__c where Source__c='CaseBeforeInsertTriggerHandler'];
        system.assertEquals(0, caseTriggerLogs.size());
    }
    
    @isTest
    static void updateErrorIfTriggerParameterNotProper() {
        ApplicationLog_Test.setLoggingSettings();
        CaseBeforeUpdateTriggerHandler updater= new CaseBeforeUpdateTriggerHandler();
        
        updater.mainEntry(null);
        List<Application_Log__c> caseTriggerLogs= [select Id ,Debug_Level__c from Application_Log__c ];
        system.assertEquals(GlobalConstants.ERROR,caseTriggerLogs[0].Debug_Level__c);
    }
    
    @isTest
    static void insertErrorIfTriggerParameterNotProper() {
        ApplicationLog_Test.setLoggingSettings();
        CaseBeforeInsertTriggerHandler inserter= new CaseBeforeInsertTriggerHandler();
        inserter.mainEntry(null);
        List<Application_Log__c> caseTriggerLogs= [select Id ,Debug_Level__c from Application_Log__c ];
        system.assertEquals(GlobalConstants.ERROR,caseTriggerLogs[0].Debug_Level__c);
    }
    
    
    @isTest
    static void caseOwnerChangedNoteRepareneted() {
        id currentAdminUser = UserInfo.getUserId();
        User testUser = RetrieveNextUtils_WS_Test.createTestUser('HCF Case Manager', 'HCF');
        System.runAs(testUser) {
        
            Case c = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');
            c.OwnerId = currentAdminUser;
            insert c;
            
            NoteOrAttachment__c privateNote = NoteOrAttachmentTriggerDispatcher_Test.getNoteOrAttachment('abc.png', c.Id);
            insert privateNote;
            
            Test.startTest();
                c.OwnerId = testUser.Id;
                update c;
                NoteOrAttachment__c noteRecord = [Select Id, OwnerId From NoteOrAttachment__c Where Id =: privateNote.Id];
                system.assertEquals(testUser.Id, noteRecord.OwnerId);
            Test.stopTest();
        }
    }
    
    
    @isTest
    static void caseOwnerChangedToSameOwnerNotesNotReparented() {
        Case c = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');
        insert c;
        
        NoteOrAttachment__c privateNote = NoteOrAttachmentTriggerDispatcher_Test.getNoteOrAttachment('abc.png', c.Id);
        insert privateNote;
        
        Test.startTest();
            c.OwnerId = UserInfo.getUserId();
            update c;
            NoteOrAttachment__c noteRecord = [Select Id, OwnerId From NoteOrAttachment__c Where Id =: privateNote.Id];
            system.assertEquals(UserInfo.getUserId(), noteRecord.OwnerId);
        Test.stopTest();
    }
    
    @isTest
    static void caseDeleteTest() {
        Case c = RetrieveNextUtils_WS_Test.getCaseRecord('Normal');
        insert c;
        
        NoteOrAttachment__c privateNote = NoteOrAttachmentTriggerDispatcher_Test.getNoteOrAttachment('abc.png', c.Id);
        insert privateNote;
        
        delete c;
        
        Test.startTest();
            list <Case> cases = [Select Id From Case];
            system.assertEquals(0, cases.size());
            
            list <NoteOrAttachment__c> attachments = [Select Id From NoteOrAttachment__c];
            system.assertEquals(0, attachments.size());
        Test.stopTest();
    }
   
    //Capture the date when Status is changed to Closed
    private static void testCapturedDateWhenStatusChangedToClosed() {
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
        RecordType bus = caseTypes.size()==0?null:caseTypes[0];
        Case caseRecord = new Case( Subject = 'I was Injured because of the sharp metal jutting out ',
                                    Description = 'I was Injured because of the sharp metal jutting out ',
                                    RecordTypeId = bus.Id,
                                    Status ='New',
                                    Origin ='Phone',
                                    Priority ='Normal',
                                    Agency__c = 'STA',
                                    Division__c = null,
                                    modes__c ='Bus',
                                    ownerid= UserInfo.getUserId(),
                                    branch__c ='');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            insert caseRecord;
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            ReopenDuration__c rd = new ReopenDuration__c(duration__c = 90, Name = 'STA');
            insert rd;
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Case c = [Select Id, Status, Reopen_Till_Date__c, Case_Resolution_Date__c From Case Where Id =: caseRecord.Id limit 1];
            Test.startTest();
                c.Status = GlobalConstants.CASE_SOFTCLOSED_STATUS;
                update c;
            Test.stopTest();
            
            
            Date reOpenTillDate = date.today().addDays(90);
            system.assertEquals(reOpenTillDate, c.Reopen_Till_Date__c);   
        }
    }
    
    //Set the RecentActivityFlag to true if the case status is changed to reopened.
    private static void RecentActivityFlagTest() {
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'Bus'];
        RecordType bus = caseTypes.size()==0?null:caseTypes[0];
        String caseId= UtilityClass.getFakeId(Case.SObjectType);
        Case busCase=new Case(Id=(Id)caseId,
                                Subject='I was Injured because of the sharp metal jutting out ',
                                Description='I was Injured because of the sharp metal jutting out ',
                                RecordTypeId=bus.Id,
                                Status = GlobalConstants.CASE_REOPENED_STATUS,
                                Origin='Phone',
                                Priority='Normal',
                                Agency__c = 'STA',
                                Division__c = null,
                                modes__c='Bus',
                                RecentActivityFlag__c = false,
                                ownerid=  UserInfo.getUserId(),
                                branch__c='');
        
        Case busCaseOld=new Case(Id=(Id)caseId,
                                Subject='I was Injured because of the sharp metal jutting out ',
                                Description='I was Injured because of the sharp metal jutting out ',
                                RecordTypeId=bus.Id,
                                Status= GlobalConstants.CASE_SOFTCLOSED_STATUS,
                                Origin='Phone',
                                Priority='Normal',
                                RecentActivityFlag__c = false,
                                Agency__c = 'STA',
                                Division__c = null,
                                modes__c='Bus',
                                ownerid = UserInfo.getUserId(),
                                branch__c='STA');
        
        List<Case >lists=new List<Case> ();
        lists.add(busCase);
        
        List<Case>oldList= new List<Case> ();
        oldList.add(busCaseOld);
        
        TriggerParameters tp=new TriggerParameters(oldList, lists, new Map<Id,Case>(oldList), new Map<Id,Case>(lists),
                                                  true, false, false, false, true, false, false);
        
        CaseBeforeUpdateTriggerHandler th= new CaseBeforeUpdateTriggerHandler();
        insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        
        Test.startTest();
            th.mainEntry(tp);
        Test.stopTest();
        system.assertEquals(true, busCase.RecentActivityFlag__c);
    }
    
    //Check for Case Group D: Parent of Multi Agency
    private static void stampAgencyOnGroupDCaseOnOwnershipChange() {
        Group STAQueue =[Select Id, Name, DeveloperName, Type from Group where Type = 'Queue' and  DeveloperName =: GlobalConstants.STA_QUEUE_TEST limit 1];
        Id RecordTypeId = [Select Id From RecordType Where SobjectType = 'Case' And DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE_DEV limit 1].id;
        Case caseRecord = new Case(Subject='I was Injured because of the sharp metal jutting out ',
                                 Description='I was Injured because of the sharp metal jutting out ',
                                 Status= GlobalConstants.CASE_SOFTCLOSED_STATUS,
                                 Origin='Phone',
                                 RecordTypeId = RecordTypeId,
                                 MultiAgency__c = false,
                                 Priority='Normal',
                                 RecentActivityFlag__c = false,
                                 Agency__c = null,
                                 Division__c = null,
                                 modes__c='Bus',
                                 ownerid = UserInfo.getUserId(),
                                 branch__c= '');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            insert caseRecord;    
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Case c = [Select Id, MultiAgency__c From Case Where Id =: caseRecord.Id limit 1];
            c.MultiAgency__c = true;
            c.OwnerId = STAQueue.Id;
            update c;
            
            Test.startTest();
            c = [Select Id, Agency__c, MultiAgency__c From Case Where Id =: caseRecord.Id limit 1];
            system.assertEquals('STA', c.Agency__c);
            Test.stopTest();
        }   
    } 
        
    // 25/08/2015 : Added by Pawan Tiwari => Bulk upload cases to create the due date.    
    @isTest
    static void insertAndUpdateBulkCasesForDueDateCalculation(){

        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1]; 
        List<Case> caseListToBeInsertedOrUpdated = new List<Case>();
        
        for(Integer i =0; i< 100;i++){
            Case caseRecord = new Case(Subject='Test Case for due date calculation',
                                 Description='Test cases for bulk insert',
                                 Status= GlobalConstants.ALLOCATION_STATUS_MIN_CORRO,
                                 Origin='Phone',
                                 RecordTypeId = rt.Id,
                                 Priority=GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD,
                                 Portfolio__c = GlobalConstants.MIN_CORR_PORTFOLIO_TRANSPORT,
                                 Signatory__c = 'Minister for Transport and Infrastructure');

            caseListToBeInsertedOrUpdated.add(caseRecord);
        
        }
        Test.startTest();
        insert caseListToBeInsertedOrUpdated;
        System.debug('caseListToBeInsertedOrUpdated :: ' + caseListToBeInsertedOrUpdated);
        System.assertEquals(caseListToBeInsertedOrUpdated.size(),100);

        for(Integer i = 0; i< caseListToBeInsertedOrUpdated.size(); i++ ){
            caseListToBeInsertedOrUpdated[i].Status = GlobalConstants.ALLOCATION_STATUS_MIN_CORRO;
            caseListToBeInsertedOrUpdated[i].Priority = GlobalConstants.CASE_PRIORITY_MP_STANDARD;
        }
        update caseListToBeInsertedOrUpdated;
        System.debug('DML Count :: ' + Limits.getDMLRows());
        System.debug('Soql Queries Count :: ' + Limits.getQueries());
        Test.stopTest();
    }


    //Populate the PBO/LRO email address from custom settings
      
    private static void createQueueVsAgencyBranchDivCustomSetting() {
        list <QueueVsAgency__c> mapping= new list <QueueVsAgency__c>();
        mapping.add(new QueueVsAgency__c(Name = '1', QueueName__c = 'STA_Brookvale_Depot_CFM', Agency__c = 'STA', Division__c = 'Northern Region', Branch__c = 'Brookvale Depot'));
        mapping.add(new QueueVsAgency__c(Name = '2', QueueName__c = 'RMS_AMD_Engineering_Services_CFM', Agency__c = 'RMS', Division__c = 'Asset Maintenance', Branch__c = 'ENGINEERING SERVICES'));
        insert mapping;
    }
}