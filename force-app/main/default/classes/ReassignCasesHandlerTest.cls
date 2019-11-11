@isTest
public class ReassignCasesHandlerTest {
    
    
    @isTest
    static void signedResponseCaseNotFoundErroneousCaseCreationTest() {
        
        Case caseRecord = getTransportCaseRecord();
        User caseOfficer1 = createCaseOfficerUser();
        User caseOfficer2 = createCaseOfficerUser();
        

        Test.startTest();
        system.runAs(caseOfficer1) {        
        insert caseRecord;
        caseRecord.MO_User__c = caseOfficer1.Id;
        
        //SUB: Case reassignment request for Case: 5000k000008mRdmTo: --0050k0000015oTJAAY
        //BODY: 5000k000008mRdm--0050k0000015oTJAAY
        
        String sub = 'Case reassignment request for Case: ' + caseRecord.Id + ': --' + caseOfficer1.Id;
        String body = caseRecord.Id + ': --' + caseOfficer1.Id;
        Group eq = [Select Id From Group Where DeveloperName =: GlobalConstants.ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO And Type = 'Queue' limit 1];
        
        
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
        tempReq.setComments('Submitting response for approval');
        tempReq.setObjectId(caseRecord.Id);
        approvalRequests.add(tempReq);
        
        Approval.ProcessResult[] processResult = Approval.process(approvalRequests, false);
        //System.assertEquals(TRUE, processResult[0].isSuccess());
        
        List < ProcessInstanceWorkitem > workItems = [SELECT Id, ProcessInstanceId, ActorId
                                                      FROM ProcessInstanceWorkitem
                                                      WHERE ProcessInstance.TargetObjectId = :caseRecord.Id limit 1 ];
        
        for(ProcessInstanceWorkitem workItem: workItems)
        	workItem.ActorId = caseOfficer2.Id;
        update workItems;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        ReassignCasesHandler emailHandler = new ReassignCasesHandler();

        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(getInboundEmailSignedResponses(sub, body), env);
        
        }Test.stopTest();
        
    }
    
    public static Case getCaseRecord() {
        RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT limit 1];
        
        return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                        Status = 'New',
                        RecordTypeId = rt.Id,
                        Portfolio__c = 'WestConnex',
                        Priority = 'Normal',
                        Modes__c = 'MAGS', 
                        
                        Signatory__c = 'Minister for Western Sydney, WestConnex, and Sport');
    }
    
    public static Messaging.InboundEmail getInboundEmailSignedResponses(String Subject, String body) {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = body;
        email.fromAddress ='test@demo.com';
        email.toAddresses = new String [] {'tfnswmincorro@gmail.com'};
            email.subject = Subject;
        
        return email;
    }    
    
    public static User createCaseOfficerUser() {
        UserRole dloRole = [Select Id From UserRole Where DeveloperName = 'DLO_WestConnex'];
        User user = new User();
        user.Username = 'cm'+ System.currentTimeMillis() + '@demo.com';
        user.FirstName = 'Serco';
        user.LastName = 'Agent';
        user.Email = 'md@demo.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [select id from Profile where Name='Senior MAGS Officer'].Id;
        user.UserRoleId = dloRole.Id;
        user.LanguageLocaleKey = 'en_US';
        insert user;
        return user;
    }    
    
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
    
    
    
}