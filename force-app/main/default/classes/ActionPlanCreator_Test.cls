@isTest
private class ActionPlanCreator_Test{

    private static List<EmailMessage> emails;
    private static testMethod void testForInvalidData() {
        System.Test.startTest();
        try{
            ActionPlanCreator apCreator = new ActionPlanCreator(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        try{
            ActionPlanCreator apCreator = new ActionPlanCreator(new List<EmailMessage>());
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForSingleAdviceEmailMessage() {
        setUpTestData(1);
        System.Test.startTest();
        ActionPlanCreator apCreator = new ActionPlanCreator(emails);
        List<Action_Plan__c> actionPlans = apCreator.createAdviceRequestPlans();
        System.assert(actionPlans != null);
        System.assert(actionPlans.size() == 1);
        System.assert(actionPlans[0].SME_Email__c == emails[0].ToAddress);
        System.assert(actionPlans[0].Parent_Case__c == emails[0].ParentId);
        System.assert(actionPlans[0].Status__c == GlobalConstants.ACTION_PLAN_NEW_STATUS);
        System.assert(actionPlans[0].Type__c  == GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
        System.assert(actionPlans[0].Branch__c  == 'test branch');
        System.assert(actionPlans[0].Agency__c  == 'test agency');

        System.Test.stopTest();
    }
    
    private static testMethod void testForAPCreationForSupportingQueue() {
        setUpTestData(1);
        Group groupRec = [SELECT Id FROM Group g WHERE type = 'Queue' AND DeveloperName = 'Serco_Web_Triage_CFM'];
        List<Case> cases = [SELECT id, OwnerId FROM Case];
        for(Case caseRecord : cases) {
            caseRecord.OwnerId = groupRec.Id;
        }
        update cases;
        System.Test.startTest();
        ActionPlanCreator apCreator = new ActionPlanCreator(emails);
        List<Action_Plan__c> actionPlans = apCreator.createAdviceRequestPlans();
        System.assert(actionPlans != null);
        System.assert(actionPlans.size() == 1);
        System.assert(actionPlans[0].SME_Email__c == emails[0].ToAddress);
        System.assert(actionPlans[0].Parent_Case__c == emails[0].ParentId);
        System.assert(actionPlans[0].Status__c == GlobalConstants.ACTION_PLAN_NEW_STATUS);
        System.assert(actionPlans[0].Type__c  == GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
        System.assert(actionPlans[0].Branch__c  == 'test branch');
        System.assert(actionPlans[0].Agency__c  == 'test agency');
        System.assert(actionPlans[0].OwnerId  == groupRec.Id);

        System.Test.stopTest();
    }
    
    private static testMethod void testForAPCreationForNonSupportingQueue() {
        setUpTestData(1);
        Group groupRec = [SELECT Id FROM Group g WHERE type = 'Queue' AND DeveloperName = 'ErroneousCases_MC'];
        List<Case> cases = [SELECT id, OwnerId FROM Case];
        for(Case caseRecord : cases) {
            caseRecord.OwnerId = groupRec.Id;
        }
        update cases;
        System.Test.startTest();
        ActionPlanCreator apCreator = new ActionPlanCreator(emails);
        List<Action_Plan__c> actionPlans = apCreator.createAdviceRequestPlans();
        System.assert(actionPlans != null);
        System.assert(actionPlans.size() == 1);
        System.assert(actionPlans[0].SME_Email__c == emails[0].ToAddress);
        System.assert(actionPlans[0].Parent_Case__c == emails[0].ParentId);
        System.assert(actionPlans[0].Status__c == GlobalConstants.ACTION_PLAN_NEW_STATUS);
        System.assert(actionPlans[0].Type__c  == GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
        System.assert(actionPlans[0].Branch__c  == 'test branch');
        System.assert(actionPlans[0].Agency__c  == 'test agency');
        System.assert(actionPlans[0].OwnerId  == UserInfo.getUserId());

        System.Test.stopTest();
    }
    
    private static testMethod void testForBulkAdviceEmailMessage() {
        setUpTestData(10);
        System.Test.startTest();
        ActionPlanCreator apCreator = new ActionPlanCreator(emails);
        List<Action_Plan__c> actionPlans = apCreator.createAdviceRequestPlans();
        System.assert(actionPlans != null);
        System.assert(actionPlans.size() == 10);
        System.assert(actionPlans[0].SME_Email__c == emails[0].ToAddress);
        System.assert(actionPlans[0].Status__c == GlobalConstants.ACTION_PLAN_NEW_STATUS);
        System.assert(actionPlans[0].Type__c  == GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST);
        System.Test.stopTest();
    }
    
    private static testMethod void testForAdviceEmailWithoutParentId() {
        setUpTestData(1);
        emails[0].ParentId = null;
        System.Test.startTest();
        ActionPlanCreator apCreator = new ActionPlanCreator(emails);
        List<Action_Plan__c> actionPlans = apCreator.createAdviceRequestPlans();
        System.assert(actionPlans != null);
        System.assert(actionPlans.isEmpty());
        System.Test.stopTest();
    }
    
    private static void setUpTestData(Integer emailCount) {
        emails = new List<EmailMessage>();
        List<Case> cases = createCases(emailCount);
        for(Case caseDetail : cases) {
            EmailMessage message = new EmailMessage();
            message.TextBody = 'Test advice request email';
            message.ParentId = caseDetail.Id;
            message.ToAddress = 'test.user@transport.gov.nsw.au';
            
            emails.add(message);
        }
    }
    private static List<Case> createCases(Integer caseCount) {
        List<Case> caseRecords = new List<Case>();
        for(Integer i = 0; i < caseCount; i++) {
            Case caseRecord = new Case();
            caseRecord.Description = 'Test case for creating action plan';
            caseRecord.Origin = 'Web';
            caseRecord.Priority = 'Normal';
            caseRecord.Type = 'Feedback';
            caseRecord.Taxonomy_Symptom__c = 'Difficult to Use';
            caseRecord.Taxonomy_Location__c = '140';
            caseRecord.Taxonomy_Area__c = 'Willoughby';
            caseRecord.Taxonomy_Location_Type__c = 'Sydney Buses';
            caseRecord.Taxonomy_Transaction__c = 'Agency Website';
            caseRecord.Taxonomy_Moment__c = 'Planning the Trip';
            caseRecord.Modes__c = 'Bus';
            caseRecord.branch__c= 'test branch';
            caseRecord.Agency__c= 'test agency';
            
            caseRecords.add(caseRecord);
        }
        
        if(!caseRecords.isEmpty()) insert caseRecords;
        
        return caseRecords;
    }
}