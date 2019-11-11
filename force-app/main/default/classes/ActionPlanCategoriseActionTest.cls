/*------------------------------------------------------------------------
Author:        Author
Company:       Salesforce.com
Description:   UnitTests for custom publisher action for action plan categorisation
               Tests executed:
               1 - actionPlanContextIsCaptured()
               The context of the actionPlan in which the custom publisher action was opened is captured
               2 - testGetModes()
                The modes are fetched from the medes__c picklist options configured in the Taxonomy metadata
               3 - testNodeCreation()
                Just that the bean can be set and the attributes fetched
               4 - testLocationChecker()
                LocationChecker if initialised with a actionPlan record figures out whether a Location taxonomy is already persisted in the actionPlan field
               5 - testIssueChecker()
                IssueChecker if initialised with a actionPlan record figures out whether an Issue taxonomy is already persisted in the actionPlan field
               6 - testGetLocation()
               Gets the locations from taxonomy metadata for the input mode
               7 - testWontGetLocationIfNotStaffFacing()
                Wont get Locations unless the metadata records are marked as Active for Staff facing
               8 - testGetIssues()
                Gets the Issues from taxonomy metadata for the input mode
               9 - testUpdateEx()
                We are able to update the mode, issue, Location or description for a actionPlan.
               11 - testUpdateExDoesnotUpdateIfNoInput()
                If all inputs are null no update is made to the actionPlan
               12 - testUpdateExDoesnotUpdateIfStatusQuo()
                if the input values are same as in case then no update is made to case
History
3-Jun-2015  Author  UnitTests for custom publisher action for case categorisation
----------------------------------------------------------------------------*/
@isTest
public class ActionPlanCategoriseActionTest
{
    public static Action_Plan__c anAp;


    @isTest
    static void actionPlanContextIsCaptured()

    {   Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);
        insert thisAp;
        Test.startTest();
        PageReference actionPlanCategorisation= Page.ActionPlanCategorisationUISample;
        Test.setCurrentPage(actionPlanCategorisation);
        ApexPages.StandardController std=new ApexPages.StandardController(thisAp);
        ActionPlanCategorisationAction ext= new ActionPlanCategorisationAction(std);
        Test.stopTest();

        system.assertEquals(thisAp.Id,ext.actionPlan.id);


    }
    
    
    @isTest
    static void testGetModes()
    {
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);
        thisAp.mode__c='Train';
        insert thisAp;

        Test.startTest();
        List<ActionPlanCategorisationAction.Node> modes=ActionPlanCategorisationAction.getModes(thisAp.Id);

        Test.stopTest();
        ActionPlanCategorisationAction.Node selectedMode;
        system.assertEquals(1,modes.size());
        for (ActionPlanCategorisationAction.Node aNode:modes){
            if ('Train'==aNode.text) selectedMode=aNode;
        }
        system.assert(selectedMode.state.selected==true);


    }
    @isTest
    static void testNodeCreation()
    {
        ActionPlanCategorisationAction.Node aNode= new ActionPlanCategorisationAction.Node();
        aNode.id='test id';
        aNode.text='test';
        aNode.parent='test parent';
        aNode.state=new ActionPlanCategorisationAction.State();
        aNode.state.selected=true;
        system.assertEquals('test id',aNode.id);
        system.assertEquals('test',aNode.text);

        system.assertEquals(true,aNode.state.selected);



    }
    @isTest
    static void testLocationChecker()
    {   Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location, issue);//'Test Location' is sent in case
        thisAp.Location_Level_3_Id__c=location.Id;
        insert thisAp;
        ActionPlanCategorisationAction.StateChecker locationChecker= new ActionPlanCategorisationAction.LocationChecker(thisAp);
        ActionPlanCategorisationAction.State state= locationChecker.getState(location);
        system.assertEquals(true,state.selected);
    }

    @isTest
    static void testIssueChecker()
    {   Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);//'Test Symptom' is sent in case
        thisAp.Issue_Level_3_Id__c=issue.Id;

        insert thisAp;

        ActionPlanCategorisationAction.StateChecker issueChecker= new ActionPlanCategorisationAction.IssueChecker(thisAp);
        ActionPlanCategorisationAction.State state= issueChecker.getState(issue);
        system.assertEquals(true,state.selected);
    }
    @isTest
    static void testGetLocation()
    {
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);  

        thisAp.mode__c='Train';
        thisAp.Location_Level_3__c='location1';
        thisAp.Location_Level_3_Id__c=location.Id;
        insertLocationsTaxonomy(train);
        insert thisAp;

        Test.startTest();
        List<ActionPlanCategorisationAction.Node> locations=ActionPlanCategorisationAction.getLocations(thisAp.Id,train.id);

        Test.stopTest();
        ActionPlanCategorisationAction.Node selectedLocation;
        system.assertEquals(14,locations.size());
        for (ActionPlanCategorisationAction.Node aLocation:locations){
            if (location.Id==aLocation.id) selectedLocation=aLocation;
        }
        system.assert(selectedLocation.state.selected==true);


    }
    @isTest
    static void testWontGetLocationIfNotStaffFacing()
    {   Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);
        thisAp.mode__c='Train';
        thisAp.Location_Level_3__c='location1';
        insert thisAp;
        List<Taxonomy_metadata__c> locationTaxonomies=insertLocationsTaxonomy(train);
        locationTaxonomies[0].Status_Staff_Facing__c='InActive';
        update locationTaxonomies[0];
        Test.startTest();
        List<ActionPlanCategorisationAction.Node> locations=ActionPlanCategorisationAction.getLocations(thisAp.Id,train.Id);

        Test.stopTest();
        system.assertEquals(13,locations.size());
    }
    @isTest
    static void testGetIssues()
    {   Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);
        thisAp.mode__c='Train';
        thisAp.Issue_Level_3__c='issue1';
        thisAp.Issue_Level_3_Id__c=issue.Id;
        insertIssuesTaxonomy(train);
        insert thisAp;


        Test.startTest();
        List<ActionPlanCategorisationAction.Node> issues=ActionPlanCategorisationAction.getIssues(thisAp.Id,train.Id);

        Test.stopTest();
        ActionPlanCategorisationAction.Node selectedIssue;
        system.assertEquals(14,issues.size());
        for (ActionPlanCategorisationAction.Node anIssue:issues){
            if (issue.Id==anIssue.id) selectedIssue=anIssue;
        }
        system.assert(selectedIssue.state.selected==true);


    }

    @isTest
    static void testUpdateEx()
    {
        Taxonomy_Metadata__c train=insertModeTaxonomy();
        List<Taxonomy_Metadata__c> issueTaxonomies=insertIssuesTaxonomy(train);
        List<Taxonomy_Metadata__c> locationTaxonomies=insertLocationsTaxonomy(train);

        
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);
        thisAp.mode__c='Train';
        thisAp.Issue_Level_3__c=issueTaxonomies[0].name;
        thisAp.Issue_Level_3_Id__c=issueTaxonomies[0].Id;
        thisAp.Location_Level_3__c=locationTaxonomies[0].name;
        thisAp.Location_Level_3_Id__c=locationTaxonomies[0].Id;
        insert thisAp;
        Test.startTest();
        ActionPlanCategorisationAction.updateEx(thisAp.Id
                                                    ,'Testing now'
                                                    ,'Train'
                                                    ,locationTaxonomies[0].name
                                                    ,locationTaxonomies[0].id
                                                    ,issueTaxonomies[0].name
                                                    ,issueTaxonomies[0].id
                                                    ,'Test parent Issue'
                                                    , 'Test parent Location'
                                                    , 'Test grand Issue'
                                                    , 'Test grand Location'
                                                    ,  'Test type');
        Test.stopTest();
        thisAp=[select Id,Mode__c,Case_Description__c, Location_Level_3__c,Issue_Level_3__c from Action_Plan__c where Id=:thisAp.id];
        system.assertEquals('Testing now',thisAp.Case_Description__c);
        system.assertEquals('Train',thisAp.Mode__c);
        system.assertEquals(locationTaxonomies[0].name,thisAp.Location_Level_3__c);
        system.assertEquals(issueTaxonomies[0].name,thisAp.Issue_Level_3__c);
    }

    @isTest
    static void testUpdateExDoesnotUpdateIfNoInput()
    {   Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);
        thisAp.mode__c='Train';
        thisAp.Issue_Level_3__c='issue1';
        insert thisAp;
        Test.startTest();
        ActionPlanCategorisationAction.updateEx(thisAp.Id,null,null,null,null,null,null,null,null,null,null,null);
        Test.stopTest();
        thisAp=[select Id,Mode__c,Case_Description__c, Location_Level_3__c,Issue_Level_3__c from Action_Plan__c where Id=:thisAp.id];
        system.assertEquals('I was Injured because of the sharp metal jutting out',thisAp.Case_Description__c);
        system.assertEquals('Train',thisAp.Mode__c);

    }

    @isTest
    static void testUpdateExDoesnotUpdateIfStatusQuo()
    {
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert location;
        Action_Plan__c thisAp=setupActionPlan(location,issue);
        Id issueId= thisAp.Issue_Level_3_Id__c;
        Id locationId= thisAp.Location_Level_3_Id__c;
        thisAp.mode__c='Train';
        thisAp.Issue_Level_3__c='issue1';
        insert thisAp;
        Test.startTest();
        ActionPlanCategorisationAction.updateEx(thisAp.Id,'I was Injured because of the sharp metal jutting out ','Train',null,null,issueId,locationId,'Test parent Issue', 'Test parent Location', 'Test grand Issue', 'Test grand Location',  'Test type');
        Test.stopTest();
        thisAp=[select Id,Mode__c,Case_Description__c, Location_Level_3__c,Issue_Level_3__c from Action_Plan__c where Id=:thisAp.id];
        List<Application_Log__c> categoryLog=[select id,Debug_Level__c,Source_Function__c from Application_Log__c where Debug_Level__c=:GlobalConstants.DEBUG and Source_Function__c='updateEx' ];
        system.assertEquals(0,categoryLog.size());


    }
    
    

//utility methods for populating the test data
    public static Taxonomy_metadata__c insertModeTaxonomy(){
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode',Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING);
        insert train;
        
        return train;
    }

    public static List<Taxonomy_metadata__c> insertLocationsTaxonomy(Taxonomy_metadata__c train){
        List<Taxonomy_metadata__c> locations= new List<Taxonomy_metadata__c>();
    
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        
        for (integer ii=1;ii<10;ii++){

            Taxonomy_metadata__c aLocation= new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,

                name='location'+ii,
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
            locations.add(aLocation);
        }
        insert locations;
        return locations;
    }
    public static Taxonomy_metadata__c insertParentLocationsTaxonomy(Taxonomy_metadata__c locationGrand){
        
        
        Taxonomy_metadata__c locationParent=new Taxonomy_metadata__c(
                Parent_Id__c=locationGrand.Id,

                name='locationparent',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert locationParent;
        
        return locationParent;
    }
    public static Taxonomy_metadata__c insertGrandLocationsTaxonomy(Taxonomy_metadata__c mode){
        
        Taxonomy_metadata__c locationGrand=new Taxonomy_metadata__c(
                Parent_Id__c=mode.Id,

                name='locationgrand',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.LOCATION_TYPE
            );
        insert locationGrand;
        
        return locationGrand;
    }
    public static List<Taxonomy_metadata__c> insertIssuesTaxonomy(Taxonomy_metadata__c train){

        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));
        
        List<Taxonomy_metadata__c> issues= new List<Taxonomy_metadata__c>();
        for (integer ii=1;ii<10;ii++){

            Taxonomy_metadata__c anIssue= new Taxonomy_metadata__c(
                parent_id__c=issueParent.Id,
                name='issue'+ii,
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
            issues.add(anIssue);
        }
        insert issues;
        return issues;
    }
    public static Taxonomy_metadata__c insertGrandIssuesTaxonomy(Taxonomy_metadata__c mode){
        
        Taxonomy_metadata__c issueGrand=new Taxonomy_metadata__c(
                Parent_Id__c=mode.Id,

                name='issuegrand',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issueGrand;
        return issueGrand;
    }
    public static Taxonomy_metadata__c insertParentIssuesTaxonomy(Taxonomy_metadata__c issueGrand){
        
        Taxonomy_metadata__c issueParent=new Taxonomy_metadata__c(
                Parent_Id__c=issueGrand.Id,

                name='issueparent',
                Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING ,
                Type__c=ActionPlanCategorisationAction.ISSUE_TYPE
            );
        insert issueParent;
        
        return issueParent;
    }
    public static Taxonomy_metadata__c insertModeTrain(){
        
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode',Status_Staff_Facing__c=ActionPlanCategorisationAction.STAFF_FACING);
        insert train;
        return train;
    }
    public static Action_Plan__c setupActionPlan(Taxonomy_metadata__c location, Taxonomy_metadata__c issue){
    
        List<RecordType> actionPlanTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Action_Plan__c' AND DeveloperName != :GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME limit 1];
        RecordType ACTION_PLAN_REC_TYPE = actionPlanTypes.size()==0?null:actionPlanTypes[0];
        anAp=new Action_Plan__c(
                                Case_Description__c='I was Injured because of the sharp metal jutting out',
                                RecordTypeId=ACTION_PLAN_REC_TYPE.Id,
                                Status__c='New',
                                Agency__c='Policy',
                                Mode__c='Test Mode',
                                Location_Level_3__c='Test Location',
                                Issue_Level_3__c='Test Symptom',
                                Location_Level_3_Id__c=issue!=null?issue.Id:null,
                                Issue_Level_3_Id__c=location!=null?location.Id:null
                                );

        return anAp;

    }
}