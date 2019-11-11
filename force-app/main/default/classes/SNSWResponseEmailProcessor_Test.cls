@isTest
private class SNSWResponseEmailProcessor_Test {

    private static Map<Id, EmailMessage> caseVsSnswResponse;
    
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try {
            SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(new Map<Id, EmailMessage>());
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try {
            Map<Id, EmailMessage> caseVsMessage = new Map<Id, EmailMessage>();
            caseVsMessage.put(null, new EmailMessage());
            SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(caseVsMessage);
            snswResponseProcessor.processSnswResponses();
            System.assert(true);
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForSnswResponseOnResolvedCase() {
        setUpTestData(1, GlobalConstants.CASE_SOFTCLOSED_STATUS);
        System.Test.startTest();
        SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(caseVsSnswResponse);
        snswResponseProcessor.processSnswResponses();
        System.Test.stopTest();
        List<Case> cases = [SELECT id, Agency__c, Status FROM Case WHERE Id IN :caseVsSnswResponse.keySet()];
        System.assert(!cases.isEmpty());
        for(Case caseRecord: cases) {            
            System.assert(caseRecord.Agency__c == GlobalConstants.RMS_AGENCY); 
        }
    }
    
    private static testMethod void testForSnswResponseOnClosedCase() {
        setUpTestData(1, GlobalConstants.CASE_SOFTCLOSED_STATUS);
        List<Case> casesToUpdate = [SELECT id, Status, Agency__c FROM Case];
        for(Case caseRecord : casesToUpdate) {
            caseRecord.status = GlobalConstants.CASE_CLOSED_STATUS;
        }
        update casesToUpdate;
        System.Test.startTest();
        SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(caseVsSnswResponse);
        snswResponseProcessor.processSnswResponses();
        System.Test.stopTest();
        List<Case> cases = [SELECT id, Agency__c, Status FROM Case WHERE ParentId IN :caseVsSnswResponse.keySet()];
        System.assert(!cases.isEmpty());
        for(Case caseRecord: cases) {            
            System.assert(caseRecord.Agency__c == GlobalConstants.RMS_AGENCY); 
        }
    }   
    
    private static testMethod void testForSubsequentSnswResponseOnCase() {        
        setUpTestData(1, GlobalConstants.CASE_SOFTCLOSED_STATUS);
        SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(caseVsSnswResponse);
        snswResponseProcessor.processSnswResponses();
        System.Test.startTest();
        snswResponseProcessor = new SNSWResponseEmailProcessor(caseVsSnswResponse);
        snswResponseProcessor.processSnswResponses();
        System.Test.stopTest();
        List<Case> cases = [SELECT id, Agency__c, Status FROM Case WHERE Id IN :caseVsSnswResponse.keySet()];
        System.assert(!cases.isEmpty());
        for(Case caseRecord: cases) {
            System.assert(caseRecord.Agency__c == GlobalConstants.RMS_AGENCY); 
        }
    }
    
    private static testMethod void bulkTestForSnswResponse() {
        setUpTestData(5, GlobalConstants.CASE_SOFTCLOSED_STATUS);
        System.Test.startTest();
        SNSWResponseEmailProcessor snswResponseProcessor = new SNSWResponseEmailProcessor(caseVsSnswResponse);
        snswResponseProcessor.processSnswResponses();
        System.Test.stopTest();
        List<Case> cases = [SELECT id, Agency__c, Status FROM Case WHERE Id IN :caseVsSnswResponse.keySet()];
        System.assert(!cases.isEmpty());
        for(Case caseRecord: cases) {            
            System.assert(caseRecord.Agency__c == GlobalConstants.RMS_AGENCY); 
        }
    }
    
    private static void setUpTestData(Integer bulkRecordCount, String status) {
        createCases(bulkRecordCount, status);
        createEmailMessage();
    }
    
    private static void createCases(Integer caseCount, String status) {
        List<Case> cases = new List<Case>();
        for(Integer index=0; index < caseCount; index++) {
            Case caseRecord = new Case();
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Compliment';
            caseRecord.Description = 'Test SNSW response flow';
            caseRecord.Agency__c = 'SNSW';
            caseRecord.status = status;
            cases.add(caseRecord);
        }
        if(!cases.isEmpty()) {
            List<AssignmentRule> rules = [  SELECT id 
                                            FROM AssignmentRule 
                                            WHERE SobjectType = 'Case' 
                                                    AND Active = true LIMIT 1];
            Database.DMLOptions dmlOpts = new Database.DMLOptions();        
            if (!rules.isEmpty()){                       
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].id;
                dmlOpts.assignmentRuleHeader.useDefaultRule = false;            
            }
            
            Database.insert( cases, dmlOpts);    
            //insert cases;
        }       
    }
    
    private static void createEmailMessage() {
        List<Case> cases = [SELECT Id FROM Case];
        caseVsSnswResponse = new Map<Id, EmailMessage>();
        for(Case caseRecord : cases) {
            EmailMessage snswResponse = new EmailMessage(FromAddress='snsw@service.nsw.au.com',
                                                      FromName='SNSW Team',
                                                      HtmlBody='this case needs to be handled by RMS team.' ,
                                                      Incoming = true,
                                                      ParentId = caseRecord.Id,
                                                      Subject= Label.SNSW_referral_subject,
                                                      TextBody='this case needs to be handled by RMS team.',
                                                      ToAddress='customerservice@rms.com.au');
            caseVsSnswResponse.put(caseRecord.Id, snswResponse);
        }        
    }
}