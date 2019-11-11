@isTest
public class RetrieveNextUtils_WS_Test {
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   User is a direct member of the queue.
                   Queue : Q1
                            -> User
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    09/04/2015     Manish Damle       Created
    19/12/2016     Arxxus             Added test setup method to create dummy entitlement rule
    -----------------------------------------------------------------------------------*/
    static testMethod void testMethod1() {
        User testUser = createTestUser('System Administrator', 'STA');
        Group g = new Group(Type='Queue', Name='Q1');
        Group g1 = new Group(Type='Queue', Name='Q2');
        insert new list <Group> {g,g1};
        
        List<QueueSobject> qs = new List<QueueSobject>();
        qs.add(new QueueSobject(QueueId=g.Id, SObjectType='Case'));
        insert qs;
        
        GroupMember gm = new GroupMember(UserOrGroupId = testUser.Id, GroupId = g.Id);
        insert gm;
        
        system.runAs(testUser) {
            RetrieveNextUtils_WS rn = new RetrieveNextUtils_WS();
            set <Id> groupIds  = RetrieveNextUtils_WS.getGroupsForUser(new set <Id> {g.Id, g1.Id}, testUser , null);
            system.assertEquals(1, groupIds.size());
            system.assert(groupIds.contains(g.Id));
            RetrieveNextUtils_WS.retrieveNextCase(testUser.Id);
        }
    }
    
     /*-----------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Create new case with two issues: one Trains, one bus
                    Assign parent case and train child case to Sydney trains customer relations queue
                    Assign bus child case to one of the STA queues
                    Log in as Sydney Trains CM user and click get next button
                    Both parent case and child trains case should be assigned to Syd Trains CM user; bus issue should remain on STA queu
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    15/06/2015     Dipankar Barman       Created
    -----------------------------------------------------------------------------------*/
    static testMethod void testAssignRelatedCases(){
        List<Case> relatedCases= getRelatedCases();
        List<Group> queues= new List<Group>();
        Group sydneyTrainsQueue = new Group(Name='Sydney trains customer relations', Type='Queue');
        Group staQueue = new Group(Name='sta', Type='Queue');
        queues.add(sydneyTrainsQueue);
        queues.add(staQueue);

        insert queues;
        User sydTrainsUser;

        System.runAs(new User(Id=UserInfo.getUserId())) {
            sydTrainsUser = createTestUser('SYD Trains Case Manager', 'STA');
        }

        System.runAs(new User(Id=UserInfo.getUserId()))
        {   List <QueueSObject> caseQueues= new List <QueueSObject> ();
            caseQueues.add( new QueueSObject(QueueID = sydneyTrainsQueue.id, SObjectType = 'Case'));
            caseQueues.add( new QueueSObject(QueueID = staQueue.id, SObjectType = 'Case'));

            insert caseQueues;
            GroupMember member= new GroupMember(
                GroupId=sydneyTrainsQueue.id,
                UserOrGroupId=sydTrainsUser.id
                );
            insert member;
        }
        //Assign parent case and train child case to Sydney trains customer relations queue
        relatedCases[0].ownerId= sydneyTrainsQueue.id;
        relatedCases[2].ownerId= sydneyTrainsQueue.id;

        //Assign bus child case to one of the STA queues
        relatedCases[1].ownerId= staQueue.id;

        test.StartTest();
        update relatedCases;
        Map<Id,Case> relatedCasesMap= new Map<Id,Case>(relatedCases);
        //Log in as Sydney Trains CM user and click get next button

        System.runAs(sydTrainsUser)
        {
            RetrieveNextUtils_WS.retrieveNextCase(sydTrainsUser.id);
        }
        Test.stopTest();
        //Both parent case and child trains case should be assigned to Syd Trains CM user; bus issue should remain on STA queu
        relatedCasesMap=new Map<Id,Case>([select Id, ownerId from Case where id =: relatedCasesMap.keySet()]);
        system.assertEquals(sydTrainsUser.Id, relatedCasesMap.get(relatedCases[0].Id).ownerId);
        system.assertEquals(sydTrainsUser.Id, relatedCasesMap.get(relatedCases[2].Id).ownerId);
        system.assertEquals(staQueue.Id, relatedCasesMap.get(relatedCases[1].Id).ownerId);
    }
     /*-----------------------------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Create new case with two issues: one Trains, one bus
                    Assign parent case and train child case to Sydney trains customer relations queue
                    Assign bus child case to one of the STA queues
                    Log in as Sydney Trains CM user and click get next button
                    Both parent case and child trains case should be assigned to Syd Trains CM user; bus issue should remain on STA queu
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    15/06/2015     Dipankar Barman       Created
    -----------------------------------------------------------------------------------*/
    static testMethod void testAssignRelatedCasesWhenChildCaseIsNested(){
        List<Case> relatedCases= getRelatedCases();
        List<Group> queues= new List<Group>();
        Group sydneyTrainsQueue = new Group(Name='Sydney trains customer relations', Type='Queue');
        Group staQueue = new Group(Name='sta', Type='Queue');
        queues.add(sydneyTrainsQueue);
        queues.add(staQueue);

        insert queues;
        User sydTrainsUser;

        System.runAs(new User(Id=UserInfo.getUserId())) {
            sydTrainsUser = createTestUser('SYD Trains Case Manager', 'STA');
        }

        System.runAs(new User(Id=UserInfo.getUserId()))
        {   List <QueueSObject> caseQueues= new List <QueueSObject> ();
            caseQueues.add( new QueueSObject(QueueID = sydneyTrainsQueue.id, SObjectType = 'Case'));
            caseQueues.add( new QueueSObject(QueueID = staQueue.id, SObjectType = 'Case'));

            insert caseQueues;
            GroupMember member= new GroupMember(
                GroupId=sydneyTrainsQueue.id,
                UserOrGroupId=sydTrainsUser.id
                );
            insert member;
        }
        //Assign parent case and train child case to Sydney trains customer relations queue
        relatedCases[0].ownerId= sydneyTrainsQueue.id;
        relatedCases[2].ownerId= sydneyTrainsQueue.id;
        relatedCases[0].priority= GlobalConstants.CASE_PRIORITY_HIGH;

        //Assign bus child case to one of the STA queues
        relatedCases[1].ownerId= staQueue.id;
        test.StartTest();
        update relatedCases;
        Map<Id,Case> relatedCasesMap= new Map<Id,Case>(relatedCases);
        //Log in as Sydney Trains CM user and click get next button

        System.runAs(sydTrainsUser)
        {
            RetrieveNextUtils_WS.retrieveNextCase(sydTrainsUser.id);
        }
        Test.stopTest();
        //Both parent case and child trains case should be assigned to Syd Trains CM user; bus issue should remain on STA queu
        relatedCasesMap=new Map<Id,Case>([select Id, ownerId from Case where id =: relatedCasesMap.keySet()]);
        system.assertEquals(sydTrainsUser.Id, relatedCasesMap.get(relatedCases[0].Id).ownerId);
        system.assertEquals(staQueue.Id, relatedCasesMap.get(relatedCases[1].Id).ownerId);
    }
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create test users
    Parameters:    profile, role
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    09/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static User createTestUser(String profileName, String RoleName) {
        User user = new User();
        user.Username = 'md'+ System.currentTimeMillis() + '@demo.com';
        user.LastName = 'dam';
        user.Email = 'md@demo.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.UserPermissionsKnowledgeUser = true;
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [Select Id From Profile Where Name =: profileName].Id;
        user.UserRoleId = [Select Id From UserRole Where DeveloperName =: RoleName].Id;
        user.LanguageLocaleKey = 'en_US';
        user.isActive = true;
        insert user;
        return user;
    }

    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates a case record sobject
    Inputs:        
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    09/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static Case getCaseRecord(String priority) {
        return new Case(Subject = 'Pothole',
                        Description = 'Theres a pothole in the east street, west end crossing in front of busstop',
                        Status = 'New',
                        Agency__c = 'Agency1',
                        Priority = priority);
    }
    //Create new case with two issues: one train one bus
    public static List<Case> getRelatedCases(){
        
         List<Case> cases = new  List<Case> ();

        Case parent =new Case(Subject = 'parent',
                        Description = 'Theres a parent in the east street, west end crossing in front of busstop',
                        Status = 'New',
                        Agency__c = 'Agency1',
                        Modes__c='Multi-Issue');
        System.runAs(new User(Id=UserInfo.getUserId())){
            insert parent;
        }
        

        Case firstChild= new Case(Subject = 'parent',
                        Description = 'Theres a parent in the east street, west end crossing in front of busstop',
                        Status = 'New',
                        Agency__c = 'Agency1',
                        Modes__c='Train',
                        ParentId=parent.Id);
        cases.add(firstChild);
         
        Case secondChild=new Case(Subject = 'Pothole',
                        Description = 'Theres a Bus in the east street, west end crossing in front of busstop',
                        Status = 'New',
                        Agency__c = 'Agency1',
                        Modes__c='Bus',
                        ParentId=parent.Id);
        cases.add(secondChild);

        System.runAs(new User(Id=UserInfo.getUserId())){
            insert cases;
        }
        cases.add(parent);
        return cases;

    }
    
    @testSetup
    static void CreateEntitlement_TestOne() {
     
     Account testAccount = new Account(name='Test Company Name');
     insert testAccount;
       
     Entitlement testEntitlement = new Entitlement();
     testEntitlement.Name = testAccount.name;
     testEntitlement.StartDate = System.Today();
     testEntitlement.AccountId = testAccount.Id;
     
     insert testEntitlement;
      
     // Verify that the entitlment was created in the database.
     Entitlement NewEntitlement = [SELECT AccountId FROM Entitlement WHERE Name = :testAccount.Name];
     System.assertEquals(testAccount.ID, NewEntitlement.AccountId);
    }
}