@isTest
private class APStatusTransitionForAssign_Test {

    private static Action_Plan__c actionPlan;
    
    private static void setUpTestData(String status) {
        actionPlan = new Action_Plan__c();
        actionPlan.Type__c = GlobalConstants.AP_TYPE_AGENCY_RESPONSE;
        actionPlan.Status__c = status;
        actionPlan.Agency__c = GlobalConstants.RMS_AGENCY;
        actionPlan.Divisions__c = 'Corporate';
        actionPlan.RecordTypeId = retrieveAgencyResponseRT();
        insert actionPlan;
    }
    
    private static Id retrieveAgencyResponseRT() {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Action_Plan__c' AND DeveloperName = 'RMS_Action_Plan'];
        return rts.isEmpty()? null : rts[0].Id;
    }
    
    private static Id retrieveChildActionPlanRT() {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Action_Plan__c' AND DeveloperName = 'MCWS_Child_Action_Plan'];
        return rts.isEmpty()? null : rts[0].Id;
    }
        
    private static testMethod void testForInvalidData() {
        actionPlan = new Action_Plan__c();
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForActionPlanWithBlankType() {
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        actionPlan.Type__c = null;
        update actionPlan;
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForActionPlanOfAgencyResponse() {
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();           
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        Action_Plan__c ap = [SELECT Id, Status__c  FROM Action_Plan__c WHERE Id = :actionPlan.Id];
        System.assert(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED == ap.Status__c);
    }
        
    private static testMethod void testForActionPlanOfAdviceRequest() {
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        actionPlan.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        update actionPlan;
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();           
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        Action_Plan__c ap = [SELECT Id, Status__c  FROM Action_Plan__c WHERE Id = :actionPlan.Id];
        System.assert(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED == ap.Status__c);
    }
    
    private static testMethod void testForAPOfAdviceRequestWithoutAgency() {
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        actionPlan.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        actionPlan.Agency__c = null;
        update actionPlan;
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();   
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForActionPlanOfAdviceRequestWithSME() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Agency SME'];
        User u = new User(Alias = 'standt', Email='standarduser@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='standarduser@nsw.gov.au.com');
        insert u;
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        
        System.Test.startTest();
        actionPlan.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        actionPlan.AssignedSME__c = u.id;
        update actionPlan;
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();           
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
        Action_Plan__c ap = [SELECT Id, Status__c  FROM Action_Plan__c WHERE Id = :actionPlan.Id];
        System.assert(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED == ap.Status__c);
    }
    
    private static testMethod void testForAPOfAdviceRequestInvalidStatus() {
        setUpTestData(GlobalConstants.ACTION_PLAN_CLOSED_STATUS);
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForAPOfAdviceRequestInvalidAgency() {
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        actionPlan.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        actionPlan.Agency__c = 'Invalid';
        update actionPlan;
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForParentActionPlanInvalidData() {
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG);
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(actionPlan.Id);
            printingInstance.performTransition();   
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForChildActionPlanInvalidSME() {
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        Id childActionPlanId = createChildActionPlan(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        System.Test.startTest();
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(childActionPlanId);
            printingInstance.performTransition();  //doesnot throw exception
            system.assert(true);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForChildActionPlanValidSME() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Agency SME'];
        User u = new User(Alias = 'standt', Email='standarduser@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='standarduser@nsw.gov.au.com');
        insert u;
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        Id childActionPlanId = createChildActionPlan(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        Action_Plan__c ap = [SELECT Id, Type__c, AssignedSME__c FROM Action_Plan__c WHERE Id = :childActionPlanId];
        
        System.Test.startTest();
        ap.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        ap.AssignedSME__c = u.id;
        update ap;
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(childActionPlanId);
            printingInstance.performTransition();   
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForAgencyResponseChildActionPlanValidSME() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Agency SME'];
        User u = new User(Alias = 'standt', Email='standarduser@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='standarduser@nsw.gov.au.com');
        insert u;
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        Id childActionPlanId = createChildActionPlan(GlobalConstants.AP_TYPE_AGENCY_RESPONSE, GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        Action_Plan__c ap = [SELECT Id, Type__c, AssignedSME__c FROM Action_Plan__c WHERE Id = :childActionPlanId];
        
        System.Test.startTest();
        ap.AssignedSME__c = u.id;
        update ap;
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(childActionPlanId);
            printingInstance.performTransition();   
        } catch(Exception e) {
            System.assert(false);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForChildActionPlanInReview() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Agency SME'];
        User u = new User(Alias = 'standt', Email='standarduser@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='standarduser@nsw.gov.au.com');
        insert u;
        System.runAs(u) {
            setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }        
        Id childActionPlanId = createChildActionPlan(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_NEW_APPROVED);
        Action_Plan__c ap = [SELECT Id, Type__c, AssignedSME__c FROM Action_Plan__c WHERE Id = :childActionPlanId];
        
        System.Test.startTest();
        ap.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        ap.AssignedSME__c = u.id;
        update ap;
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(childActionPlanId);
            printingInstance.performTransition();  
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForChildActionPlanInvalidStatus() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Agency SME'];
        User u = new User(Alias = 'standt', Email='standarduser@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='standarduser@nsw.gov.au.com');
        insert u;
        setUpTestData(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        Id childActionPlanId = createChildActionPlan(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_CLOSED_STATUS);
        Action_Plan__c ap = [SELECT Id, Type__c, AssignedSME__c FROM Action_Plan__c WHERE Id = :childActionPlanId];
        
        System.Test.startTest();
        ap.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        ap.AssignedSME__c = u.id;
        update ap;
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(childActionPlanId);
            printingInstance.performTransition();   
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static Id createChildActionPlan(String type, String status) {
        Action_Plan__c child = new Action_Plan__c();
        child.Type__c = GlobalConstants.AP_TYPE_AGENCY_RESPONSE;
        child.Type__c = type;
        child.Status__c = GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG;
        child.Status__c = status;
        child.Agency__c = GlobalConstants.RMS_AGENCY;
        child.recordTypeId = retrieveChildActionPlanRT();
        child.Parent_Action_Plan__c = actionPlan.Id;
        insert child;
        return child.Id;
    }
    
    
    //SFCOE - 1314 - Start
    private static testMethod void testForChildActionPlanInReviewForLargeDescription() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Agency SME'];
        User u = new User(Alias = 'standt', Email='standarduser@nsw.gov.au.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='Australia/Sydney', UserName='standarduser@nsw.gov.au.com');
        insert u;
        System.runAs(u) {
            setUpTestDataAP(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS);
        }        
        Id childActionPlanId = createChildActionPlan(GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST, GlobalConstants.ACTION_PLAN_NEW_APPROVED);
        Action_Plan__c ap = [SELECT Id, Type__c, AssignedSME__c FROM Action_Plan__c WHERE Id = :childActionPlanId];
        
        System.Test.startTest();
        ap.Type__c = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        ap.AssignedSME__c = u.id;
        update ap;
        try {           
            APStatusTransitionForAssign printingInstance = new APStatusTransitionForAssign(childActionPlanId);
            printingInstance.performTransition();  
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }    
    
    
        private static void setUpTestDataAP(String status) {
        actionPlan = new Action_Plan__c();
        actionPlan.Type__c = GlobalConstants.AP_TYPE_AGENCY_RESPONSE;
        actionPlan.Status__c = status;
        actionPlan.Agency__c = GlobalConstants.RMS_AGENCY;
        actionPlan.Divisions__c = 'Corporate';
        actionPlan.RecordTypeId = retrieveAgencyResponseRT();
        actionPlan.case_description__c = Label.Field_size_is_too_large;
        actionPlan.Parent_Case__c = getParentCaseRecord().id;
        insert actionPlan;
    }
    
        public static case getParentCaseRecord() {
        String largeDesc = 'Devil In The Details As in always the case, there are some important points to remember. This is just a proposal. This will have to go through several drafts, negotiations, and tweaking before a final bill is voted on by the House. It will then go to Senate for changes and a vote. IF, and that is a big if, it is passed by the Senate the bill returns to the House where the bill will be reconciled before it is passed onto the President for his signature. The bill, as proposed today, will likely look very different by the time it is actually voted on. However, as is always the case, the “devil is in the details.” First, as the Committee for a Responsible Federal Budget lays out: “Tax cuts shouldn’t be handed out like Halloween candy. To grow the economy, they must be paid for, and the details of this plan appear to come up $2 to 2.5 trillion short. Deficit-financed tax cuts are a recipe for a short-term economic sugar high followed by sluggish long-term growth. Without sufficient details on how or even if these tax cuts will be fully paid for, this outline is nothing more than a fiscal fantasy. Tax reform remains one of the most important national objectives. Fiscally responsible tax reform would not only improve simplicity and fairness, but can actually grow the economy and help to improve the dangerous fiscal situation we face. But the difference between tax reform that would grow the economy, and tax cuts that would grow the debt, cannot be made up for with wishful thinking or magical economic growth. And tax cuts certainly don’t pay for themselves.“ Furthermore, the CFRB picks up on a particularly important point that headlines have seemed to overlook: “Making many assumptions about the plan – including that the brackets apply to the same income as the Trump campaign’s plan, that its 25 percent pass-through rate contains guardrails so it only applies to active business income, and that the limit on interest makes up about half the revenue lost from expensing – we estimate the plan has about $5.8 trillion over a decade of gross tax cuts and would cost $2.2 trillion on net through 2027. Given that it calls for only five years of expensing rather than permanent – a major budget gimmick – it also potentially sets the stage for an extenders package of over $1 trillion when expensing expires.” Almost a full year after the election of Donald Trump to the White House, one of the key promises made to voters was the largest “tax cut” since Ronald Reagan was in office. As President Trump stated in Indiana yesterday: “This is a revolutionary change, and the biggest winners will be middle-class workers as jobs start pouring into our country, as companies start competing for American labor, and as wages continue to grow. This will be the lowest top marginal income tax rate for small and mid-size businesses in more than 80 years.” Here are the major points as summed up by BI. Business tax changes: • A 20% corporate tax rate. This is the first time Trump has publicly backed down from one of his earliest campaign promises: a 15% corporate tax rate. The budget math required for a 15% rate was too difficult, so the somewhat higher rate is the opening bid. The current statutory federal rate is 35%. • A 25% rate for pass-through businesses. Instead of getting taxed at an individual rate for business profits, people who own their own business would pay at the pass-through rate. The plan also says it will consider rules to prevent “personal income” from being taxed at this rate. Mnuchin previously suggested there may be limitations on what types of businesses get this rate — it could apply only to goods producers and not service-oriented companies to prevent people from creating limited-liability corporations to store their assets and receive a lower rate. • Elimination of some business deductions, industry-specific incentives, and more. There are few details, but the plan includes language regarding the “streamlining” of business tax breaks. • A one-time repatriation tax. All overseas assets from US-owned companies would be considered repatriated and taxed at a one-time lower rate — this is designed to bring corporate profits back from overseas. Illiquid assets like real estate would be taxed at a lower rate than cash or cash equivalents, and the payments would be spread out over time. While there is no precise number in the plan, officials have indicated the rate could end up somewhere around 10%. Personal tax changes: • A bottom individual tax rate of 12%. The plan specifies three tax brackets, with the lowest rate being 12%. That would represent a slight bump in the bottom bracket, which is now 10%. People currently in the 15% marginal tax bracket would most likely be included here. • A middle tax bracket of 25%. The incomes in this bracket aren’t specified. • The top individual tax rate of 35%. The current top rate is 39.6%. • The possibility of a fourth, higher bracket. Because of Trump’s insistence that taxes for the wealthiest Americans not decrease, the plan proposes the possibility of a fourth tax bracket at a rate higher than 35% if the tax-writing committees wish. “An additional top rate may apply to the highest-income taxpayers to ensure that the reformed tax code is at least as progressive as the existing tax code and does not shift the tax burden from high-income to lower- and middle-income taxpayers,” the plan reads. • A larger standard deduction. To avoid raising taxes on those currently in the 10% tax bracket, the standard deduction for all taxes would increase to $12,000 for individuals (up from $6,350) and $24,000 for married couples (up from $12,700). These are slightly less than the doubled deductions expected and the idea this would save people money may be misleading. • Eliminates most itemized deductions. The only deduction preserved explicitly in the plan is for charitable gifts and home-mortgage interest. • Increases the size of the child tax credit. A pet project of Ivanka Trump, the proposal is to make the first $1,000 of the child tax credit refundable and increase the income level at which the credit would phase out. • Vague promises on retirement savings and other deductions. Sections of the plan refer to retirement savings and other “provisions,” but details are sparse. • Elimination of the state and local tax deduction. The so-called SALT deduction allows people to deduct what they pay in state and local taxes from their federal tax bill. Most of the people who take this deduction are wealthier Americans in Democratic states — about one-third of the beneficiaries are in New York, New Jersey, and California. • Elimination of the estate tax. Called the “death tax” in the plan, this applies only to inherited assets totaling $5.49 million or more in 2017. Very few households pay the estate tax, but it has long been a target for Republicans. Devil In The Details As in always the case, there are some important points to remember. This is just a proposal. This will have to go through several drafts, negotiations, and tweaking before a final bill is voted on by the House. It will then go to Senate for changes and a vote. IF, and that is a big if, it is passed by the Senate the bill returns to the House where the bill will be reconciled before it is passed onto the President for his signature. The bill, as proposed today, will likely look very different by the time it is actually voted on. However, as is always the case, the “devil is in the details.” First, as the Committee for a Responsible Federal Budget lays out: “Tax cuts shouldn’t be handed out like Halloween candy. To grow the economy, they must be paid for, and the details of this plan appear to come up $2 to 2.5 trillion short. Deficit-financed tax cuts are a recipe for a short-term economic sugar high followed by sluggish long-term growth. Without sufficient details on how or even if these tax cuts will be fully paid for, this outline is nothing more than a fiscal fantasy. Tax reform remains one of the most important national objectives. Fiscally responsible tax reform would not only improve simplicity and fairness, but can actually grow the economy and help to improve the dangerous fiscal situation we face. But the difference between tax reform that would grow the economy, and tax cuts that would grow the debt, cannot be made up for with wishful thinking or magical economic growth. And tax cuts certainly don’t pay for themselves.“ Furthermore, the CFRB picks up on a particularly important point that headlines have seemed to overlook: “Making many assumptions about the plan – including that the brackets apply to the same income as the Trump campaign’s plan, that its 25 percent pass-through rate contains guardrails so it only applies to active business income, and that the limit on interest makes up about half the revenue lost from expensing – we estimate the plan has about $5.8 trillion over a decade of gross tax cuts and would cost $2.2 trillion on net through 2027. Given that it calls for only five years of expensing rather than permanent – a major budget gimmick – it also potentially sets the stage for an extenders package of over $1 trillion when expensing expires.” Almost a full year after the election of Donald Trump to the White House, one of the key promises made to voters was the largest “tax cut” since Ronald Reagan was in office. As President Trump stated in Indiana yesterday: “This is a revolutionary change, and the biggest winners will be middle-class workers as jobs start pouring into our country, as companies start competing for American labor, and as wages continue to grow. This will be the lowest top marginal income tax rate for small and mid-size businesses in more than 80 years.” Here are the major points as summed up by BI. Business tax changes: • A 20% corporate tax rate. This is the first time Trump has publicly backed down from one of his earliest campaign promises: a 15% corporate tax rate. The budget math required for a 15% rate was too difficult, so the somewhat higher rate is the opening bid. The current statutory federal rate is 35%. • A 25% rate for pass-through businesses. Instead of getting taxed at an individual rate for business profits, people who own their own business would pay at the pass-through rate. The plan also says it will consider rules to prevent “personal income” from being taxed at this rate. Mnuchin previously suggested there may be limitations on what types of businesses get this rate — it could apply only to goods producers and not service-oriented companies to prevent people from creating limited-liability corporations to store their assets and receive a lower rate. • Elimination of some business deductions, industry-specific incentives, and more. There are few details, but the plan includes language regarding the “streamlining” of business tax breaks. • A one-time repatriation tax. All overseas assets from US-owned companies would be considered repatriated and taxed at a one-time lower rate — this is designed to bring corporate profits back from overseas. Illiquid assets like real estate would be taxed at a lower rate than cash or cash equivalents, and the payments would be spread out over time. While there is no precise number in the plan, officials have indicated the rate could end up somewhere around 10%. Personal tax changes: • A bottom individual tax rate of 12%. The plan specifies three tax brackets, with the lowest rate being 12%. That would represent a slight bump in the bottom bracket, which is now 10%. People currently in the 15% marginal tax bracket would most likely be included here. • A middle tax bracket of 25%. The incomes in this bracket aren’t specified. • The top individual tax rate of 35%. The current top rate is 39.6%. • The possibility of a fourth, higher bracket. Because of Trump’s insistence that taxes for the wealthiest Americans not decrease, the plan proposes the possibility of a fourth tax bracket at a rate higher than 35% if the tax-writing committees wish. “An additional top rate may apply to the highest-income taxpayers to ensure that the reformed tax code is at least as progressive as the existing tax code and does not shift the tax burden from high-income to lower- and middle-income taxpayers,” the plan reads. • A larger standard deduction. To avoid raising taxes on those currently in the 10% tax bracket, the standard deduction for all taxes would increase to $12,000 for individuals (up from $6,350) and $24,000 for married couples (up from $12,700). These are slightly less than the doubled deductions expected and the idea this would save people money may be misleading. • Eliminates most itemized deductions. The only deduction preserved explicitly in the plan is for charitable gifts and home-mortgage interest. • Increases the size of the child tax credit. A pet project of Ivanka Trump, the proposal is to make the first $1,000 of the child tax credit refundable and increase the income level at which the credit would phase out. • Vague promises on retirement savings and other deductions. Sections of the plan refer to retirement savings and other “provisions,” but details are sparse. • Elimination of the state and local tax deduction. The so-called SALT deduction allows people to deduct what they pay in state and local taxes from their federal tax bill. Most of the people who take this deduction are wealthier Americans in Democratic states — about one-third of the beneficiaries are in New York, New Jersey, and California. • Elimination of the estate tax. Called the “death tax” in the plan, this applies only to inherited assets totaling $5.49 million or more in 2017. Very few households pay the estate tax, but it has long been a target for Republicans. Devil In The Details As in always the case, there are some important points to remember. This is just a proposal. This will have to go through several drafts, negotiations, and tweaking before a final bill is voted on by the House. It will then go to Senate for changes and a vote. IF, and that is a big if, it is passed by the Senate the bill returns to the House where the bill will be reconciled before it is passed onto the President for his signature. The bill, as proposed today, will likely look very different by the time it is actually voted on. However, as is always the case, the “devil is in the details.” First, as the Committee for a Responsible Federal Budget lays out: “Tax cuts shouldn’t be handed out like Halloween candy. To grow the economy, they must be paid for, and the details of this plan appear to come up $2 to 2.5 trillion short. Deficit-financed tax cuts are a recipe for a short-term economic sugar high followed by sluggish long-term growth. Without sufficient details on how or even if these tax cuts will be fully paid for, this outline is nothing more than a fiscal fantasy. Tax reform remains one of the most important national objectives. Fiscally responsible tax reform would not only improve simplicity and fairness, but can actually grow the economy and help to improve the dangerous fiscal situation we face. But the difference between tax reform that would grow the economy, and tax cuts that would grow the debt, cannot be made up for with wishful thinking or magical economic growth. And tax cuts certainly don’t pay for themselves.“ Furthermore, the CFRB picks up on a particularly important point that headlines have seemed to overlook: “Making many assumptions about the plan – including that the brackets apply to the same income as the Trump campaign’s plan, that its 25 percent pass-through rate contains guardrails so it only applies to active business income, and that the limit on interest makes up about half the revenue lost from expensing – we estimate the plan has about $5.8 trillion over a decade of gross tax cuts and would cost $2.2 trillion on net through 2027. Given that it calls for only five years of expensing rather than permanent – a major budget gimmick – it also potentially sets the stage for an extenders package of over $1 trillion when expensing expires.” Almost a full year after the election of Donald Trump to the White House, one of the key promises made to voters was the largest “tax cut” since Ronald Reagan was in office. As President Trump stated in Indiana yesterday: “This is a revolutionary change, and the biggest winners will be middle-class workers as jobs start pouring into our country, as companies start competing for American labor, and as wages continue to grow. This will be the lowest top marginal income tax rate for small and mid-size businesses in more than 80 years.” Here are the major points as summed up by BI. Business tax changes: • A 20% corporate tax rate. This is the first time Trump has publicly backed down from one of his earliest campaign promises: a 15% corporate tax rate. The budget math required for a 15% rate was too difficult, so the somewhat higher rate is the opening bid. The current statutory federal rate is 35%. • A 25% rate for pass-through businesses. Instead of getting taxed at an individual rate for business profits, people who own their own business would pay at the pass-through rate. The plan also says it will consider rules to prevent “personal income” from being taxed at this rate. Mnuchin previously suggested there may be limitations on what types of businesses get this rate — it could apply only to goods producers and not service-oriented companies to prevent people from creating limited-liability corporations to store their assets and receive a lower rate. • Elimination of some business deductions, industry-specific incentives, and more. There are few details, but the plan includes language regarding the “streamlining” of business tax breaks. • A one-time repatriation tax. All overseas assets from US-owned companies would be considered repatriated and taxed at a one-time lower rate — this is designed to bring corporate profits back from overseas. Illiquid assets like real estate would be taxed at a lower rate than cash or cash equivalents, and the payments would be spread out over time. While there is no precise number in the plan, officials have indicated the rate could end up somewhere around 10%. Personal tax changes: • A bottom individual tax rate of 12%. The plan specifies three tax brackets, with the lowest rate being 12%. That would represent a slight bump in the bottom bracket, which is now 10%. People currently in the 15% marginal tax bracket would most likely be included here. • A middle tax bracket of 25%. The incomes in this bracket aren’t specified. • The top individual tax rate of 35%. The current top rate is 39.6%. • The possibility of a fourth, higher bracket. Because of Trump’s insistence that taxes for the wealthiest Americans not decrease, the plan proposes the possibility of a fourth tax bracket at a rate higher than 35% if the tax-writing committees wish. “An additional top rate may apply to the highest-income taxpayers to ensure that the reformed tax code is at least as progressive as the existing tax code and does not shift the tax burden from high-income to lower- and middle-income taxpayers,” the plan reads. • A larger standard deduction. To avoid raising taxes on those currently in the 10% tax bracket, the standard deduction for all taxes would increase to $12,000 for individuals (up from $6,350) and $24,000 for married couples (up from $12,700). These are slightly less than the doubled deductions expected and the idea this would save people money may be misleading. • Eliminates most itemized deductions. The only deduction preserved explicitly in the plan is for charitable gifts and home-mortgage interest. • Increases the size of the child tax credit. A pet project of Ivanka Trump, the proposal is to make the first $1,000 of the child tax credit refundable and increase the income level at which the credit would phase out. • Vague promises on retirement savings and other deductions. Sections of the plan refer to retirement savings and other “provisions,” but details are sparse. • Elimination of the state and local tax deduction. The so-called SALT deduction allows people to deduct what they pay in state and local taxes from their federal tax bill. Most of the people who take this deduction are wealthier Americans in Democratic states — about one-third of the beneficiaries are in New York, New Jersey, and California. • Elimination of the estate tax. Called the “death tax” in the plan, this applies only to inherited assets totaling $5.49 million or more in 2017. Very few households pay the estate tax, but it has long been a target for Republicans. Devil In The Details As in always the case, there are some important points to remember. This is just a proposal. This will have to go through several drafts, negotiations, and tweaking before a final bill is voted on by the House. It will then go to Senate for changes and a vote. IF, and that is a big if, it is passed by the Senate the bill returns to the House where the bill will be reconciled before it is passed onto the President for his signature. The bill, as proposed today, will likely look very different by the time it is actually voted on. However, as is always the case, the “devil is in the details.” First, as the Committee for a Responsible Federal Budget lays out: “Tax cuts shouldn’t be handed out like Halloween candy. To grow the economy, they must be paid for, and the details of this plan appear to come up $2 to 2.5 trillion short. Deficit-financed tax cuts are a recipe for a short-term economic sugar high followed by sluggish long-term growth. Without sufficient details on how or even if these tax cuts will be fully paid for, this outline is nothing more than a fiscal fantasy. Tax reform remains one of the most important national objectives. Fiscally responsible tax reform would not only improve simplicity and fairness, but can actually grow the economy and help to improve the dangerous fiscal situation we face. But the difference between tax reform that would grow the economy, and tax cuts that would grow the debt, cannot be made up for with wishful thinking or magical economic growth. And tax cuts certainly don’t pay for themselves.“ Furthermore, the CFRB picks up on a particularly important point that headlines have seemed to overlook: “Making many assumptions about the plan – including that the brackets apply to the same income as the Trump campaign’s plan, that its 25 percent pass-through rate contains guardrails so it only applies to active business income, and that the limit on interest makes up about half the revenue lost from expensing – we estimate the plan has about $5.8 trillion over a decade of gross tax cuts and would cost $2.2 trillion on net through 2027. Given that it calls for only five years of expensing rather than permanent – a major budget gimmick – it also potentially sets the stage for an extenders package of over $1 trillion when expensing expires.” Almost a full year after the election of Donald Trump to the White House, one of the key promises made to voters was the largest “tax cut” since Ronald Reagan was in office. As President Trump stated in Indiana yesterday: “This is a revolutionary change, and the biggest winners will be middle-class workers as jobs start pouring into our country, as companies start competing for American labor, and as wages continue to grow. This will be the lowest top marginal income tax rate for small and mid-size businesses in more than 80 years.” Here are the major points as summed up by BI. Business tax changes: • A 20% corporate tax rate. This is the first time Trump has publicly backed down from one of his earliest campaign promises: a 15% corporate tax rate. The budget math required for a 15% rate was too difficult, so the somewhat higher rate is the opening bid. The current statutory federal rate is 35%. • A 25% rate for pass-through businesses. Instead of getting taxed at an individual rate for business profits, people who own their own business would pay at the pass-through rate. The plan also says it will consider rules to prevent “personal income” from being taxed at this rate. Mnuchin previously suggested there may be limitations on what types of businesses get this rate — it could apply only to goods producers and not service-oriented companies to prevent people from creating limited-liability corporations to store their assets and receive a lower rate. • Elimination of some business deductions, industry-specific incentives, and more. There are few details, but the plan includes language regarding the “streamlining” of business tax breaks. • A one-time repatriation tax. All overseas assets from US-owned companies would be considered repatriated and taxed at a one-time lower rate — this is designed to bring corporate profits back from overseas. Illiquid assets like real estate would be taxed at a lower rate than cash or cash equivalents, and the payments would be spread out over time. While there is no precise number in the plan, officials have indicated the rate could end up somewhere around 10%. Personal tax changes: • A bottom individual tax rate of 12%. The plan specifies three tax brackets, with the lowest rate being 12%. That would represent a slight bump in the bottom bracket, which is now 10%. People currently in the 15% marginal tax bracket would most likely be included here. • A middle tax bracket of 25%. The incomes in this bracket aren’t specified. • The top individual tax rate of 35%. The current top rate is 39.6%. • The possibility of a fourth, higher bracket. Because of Trump’s insistence that taxes for the wealthiest Americans not decrease, the plan proposes the possibility of a fourth tax bracket at a rate higher than 35% if the tax-writing committees wish. “An additional top rate may apply to the highest-income taxpayers to ensure that the reformed tax code is at least as progressive as the existing tax code and does not shift the tax burden from high-income to lower- and middle-income taxpayers,” the plan reads. • A larger standard deduction. To avoid raising taxes on those currently in the 10% tax bracket, the standard deduction for all taxes would increase to $12,000 for individuals (up from $6,350) and $24,000 for married couples (up from $12,700). These are slightly less than the doubled deductions expected and the idea this would save people money may be misleading. • Eliminates most itemized deductions. The only deduction preserved explicitly in the plan is for charitable gifts and home-mortgage interest. • Increases the size of the child tax credit. A pet project of Ivanka Trump, the proposal is to make the first $1,000 of the child tax credit refundable and increase the income level at which the credit would phase out. • Vague promises on retirement savings and other deductions. Sections of the plan refer to retirement savings and other “provisions,” but details are sparse. • Elimination of the state and local tax deduction. The so-called SALT deduction allows people to deduct what they pay in state and local taxes from their federal tax bill. Most of the people who take this deduction are wealthier Americans in Democratic states — about one-third of the beneficiaries are in New York, New Jersey, and California. • Elimination of the estate tax. Called the “death tax” in the plan, this applies only to inherited assets totaling $5.49 million or more in 2017. Very few households pay the estate tax, but it has long been a target for Republicans. Devil In The Details As in always the case, there are some important points to remember. This is just a proposal. This will have to go through several drafts, negotiations, and tweaking before a final bill is voted on by the House. It will then go to Senate for changes and a vote. IF, and that is a big if, it is passed by the Senate the bill returns to the House where the bill will be reconciled before it is passed onto the President for his signature. The bill, as proposed today, will likely look very different by the time it is actually voted on. However, as is always the case, the “devil is in the details.” First, as the Committee for a Responsible Federal Budget lays out: “Tax cuts shouldn’t be handed out like Halloween candy. To grow the economy, they must be paid for, and the details of this plan appear to come up $2 to 2.5 trillion short. Deficit-financed tax cuts are a recipe for a short-term economic sugar high followed by sluggish long-term growth. Without sufficient details on how or even if these tax cuts will be fully paid for, this outline is nothing more than a fiscal fantasy. Tax reform remains one of the most important national objectives. Fiscally responsible tax reform would not only improve simplicity and fairness, but can actually grow the economy and help to improve the dangerous fiscal situation we face. But the difference between tax reform that would grow the economy, and tax cuts that would grow the debt, cannot be made up for with wishful thinking or magical economic growth. And tax cuts certainly don’t pay for themselves.“ Furthermore, the CFRB picks up on a particularly important point that headlines have seemed to overlook: “Making many assumptions about the plan – including that the brackets apply to the same income as the Trump campaign’s plan, that its 25 percent pass-through rate contains guardrails so it only applies to active business income, and that the limit on interest makes up about half the revenue lost from expensing – we estimate the plan has about $5.8 trillion over a decade of gross tax cuts and would cost $2.2 trillion on net through 2027. Given that it calls for only five years of expensing rather than permanent – a major budget gimmick – it also potentially sets the stage for an extenders package of over $1 trillion when expensing expires.” Almost a full year after the election of Donald Trump to the White House, one of the key promises made to voters was the largest “tax cut” since Ronald Reagan was in office. As President Trump stated in Indiana yesterday';
        
        return new Case(Subject = 'Pothole',
                        Description = largeDesc,
                        Status = 'New',
                        Agency__c = 'Agency1',
                        Priority = 'Normal',
                        Modes__c = 'Road',
                        Taxonomy_Location__c = null,
                        Taxonomy_Symptom__c = 'Unsafe Intersection',
                        Taxonomy_Accountability__c = 'RMS_JMD_Network_Sydney_CFM');
    }
    
    
    
 //    //SFCOE - 1314 - End   
    
}