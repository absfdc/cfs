@isTest(seeAllData = false)
public class ActionPlanApproverUpdateBatchTest {
    private static List<EmailMessage> emails;
    
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
    
    static testmethod void testApproverUpdateBatch(){
        setupTestData(5);
        ActionPlanCreator apCreator = new ActionPlanCreator(emails);
        List<Action_Plan__c> actionPlans = apCreator.createAdviceRequestPlans();
        List<Id> apIds = new List<Id>();
        //actionPlans.clear();
        for(Action_Plan__c ap : [select Time_Sent_for_Last_Approval__c,Status__c from Action_Plan__c]){
            ap.Time_Sent_for_Last_Approval__c = DateTime.now();
            ap.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;            
            actionPlans.add(ap);
        }
        insert actionPlans;
        List<Action_Plan__c> updatedActionPlans = new List<Action_Plan__c>();
        for(Action_Plan__c ap : actionPlans){
            ap.Response__c = 'test';
            ap.OwnerId = UserInfo.getUserId();
            ap.Status__c = GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS;
                        ap.Approver_Level_1__c = null;
            ap.Approver_Level_2__c = null;
            ap.Approver_Level_3__c = null;
            updatedActionPlans.add(ap);
        }
        update updatedActionPlans;
        //system.assertEquals(updatedActionPlans,null );
        for(Action_Plan__c ap : actionPlans){
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Approve.');
            req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req.setObjectId(ap.Id);
            //Submit the approval request
            Approval.ProcessResult result = Approval.process(req);
        }
        Test.startTest();
        //ActionPlanApproverUpdateBatch ins = new ActionPlanApproverUpdateBatch();
        String CRON_EXP = '0 0 23 * * ? *';
        ActionPlanApproverUpdateBatch ins = new ActionPlanApproverUpdateBatch();
        system.schedule('Batch Job - Update Approver', CRON_EXP, ins);
        //database.executeBatch(ins);
        Test.stopTest();
        
    }

}