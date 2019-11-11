/*------------------------------------------------------------------------
Author:        Author
Company:       Salesforce.com
Description:   UnitTests for custom publisher action for case categorisation
               Tests executed:
               1 - caseContextIsCaptured()
               The context of the case in which the custom publisher action was opened is captured
               2 - testGetModes()
                The modes are fetched from the records of type modes configured in the Taxonomy metadata
               3 - testNodeCreation()
                Just that the bean can be set and the attributes fetched 
               4 - testLocationChecker()
                LocationChecker if initialised with a case record figures out whether a Location taxonomy is already persisted in the case field
               5 - testIssueChecker()
                IssueChecker if initialised with a case record figures out whether an Issue taxonomy is already persisted in the case field
               6 - testGetLocation()
               Gets the locations from taxonomy metadata for the input mode
               7 - testWontGetLocationIfNotStaffFacing()
                Wont get Locations unless the metadata records are marked as Active for Staff facing
               8 - testGetIssues()
                Gets the Issues from taxonomy metadata for the input mode
               9 - testUpdateEx()
                We are able to update the mode, issue, Location or description for a case.
               11 - testUpdateExDoesnotUpdateIfNoInput()
                If all inputs are null no update is made to the case
               12 - testUpdateExDoesnotUpdateIfStatusQuo()
                if the input values are same as in case then no update is made to case
               13 - testGetOnlyConfiguredModesForCFMCase
History
10-Apr-2015 Author  UnitTests for custom publisher action for case categorisation
----------------------------------------------------------------------------*/
@isTest
public class IssueItemisationPublisherAction_Test
{
    public static Case aCase;


    @isTest
    static void caseContextIsCaptured()

    {   Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        Taxonomy_metadata__c mags= new Taxonomy_metadata__c(name=GlobalConstants.MIN_CORRO_MODE_NAME,type__c='Mode');
        insert train;
        insert mags;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);

        Test.startTest();
        PageReference issueItemisation= Page.IssueItemisationPublisherAction;
        Test.setCurrentPage(issueItemisation);
        ApexPages.StandardController std=new ApexPages.StandardController(thisCase);
        IssueItemisationPublisherAction_CX ext= new IssueItemisationPublisherAction_CX(std);
        Test.stopTest();

        system.assertEquals(thisCase,ext.thisCase);


    }
    @isTest
    static void testGetTypes()
    {
        Case thisCase=setupCase(null,null);
        thisCase.Type='Compliment';
        insert thisCase;

        Test.startTest();
        List<IssueItemisationPublisherAction_CX.Node> types=IssueItemisationPublisherAction_CX.getTypes(thisCase.Id);

        Test.stopTest();
        IssueItemisationPublisherAction_CX.Node selectedType;
        system.assert(types.size()>=2);//there are more than two
        for (IssueItemisationPublisherAction_CX.Node aNode:types){
            if ('Compliment'==aNode.text) selectedType=aNode;
        }
        system.assert(selectedType.state.selected==true);


    }
    @isTest
    static void testCaseCategory()
    {
        IssueItemisationPublisherAction_CX.CaseCategory cc= new IssueItemisationPublisherAction_CX.CaseCategory();

        
        cc.mode ='test';
        cc.location ='test';
        cc.issue ='test';
        cc.subject ='test';
        cc.parentIssue ='test';
        cc.parentlocation ='test';
        cc.grandIssue ='test';
        cc.grandlocation ='test';
        cc.issueKpi ='test';
        cc.issueDriver ='test';
        cc.issueAccountability ='test';
        cc.parent ='test';
        cc.type ='test';
        cc.issueAgency ='test';
        cc.locationAgency ='test';
        system.assertEquals('test',cc.mode);
    }
    @isTest
    static void testGetModes()
    {   CFMModes__c accessibleModes=new CFMModes__c(
            Name='default',
            CFM_Modes_del__c='Train');
        insert accessibleModes;
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);
        thisCase.modes__c='Train';
        insert thisCase;

        Test.startTest();
        List<IssueItemisationPublisherAction_CX.Node> modes=IssueItemisationPublisherAction_CX.getModes(thisCase.Id);

        Test.stopTest();
        IssueItemisationPublisherAction_CX.Node selectedMode;
        system.assertEquals(1,modes.size());
        for (IssueItemisationPublisherAction_CX.Node aNode:modes){
            if ('Train'==aNode.text) selectedMode=aNode;
        }
        system.assert(selectedMode.state.selected==true);


    }
    @isTest
    static void testNodeCreation()
    {
        IssueItemisationPublisherAction_CX.Node aNode= new IssueItemisationPublisherAction_CX.Node();
        aNode.id='test id';
        aNode.text='test';
        aNode.parent='test parent';
        aNode.state=new IssueItemisationPublisherAction_CX.State();
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location, issue);//'Test Location' is sent in case
        thisCase.Taxonomy_Location_Id__c=location.Id;
        insert thisCase;
        IssueItemisationPublisherAction_CX.StateChecker locationChecker= new IssueItemisationPublisherAction_CX.LocationChecker(thisCase);
        IssueItemisationPublisherAction_CX.State state= locationChecker.getState(location);
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);//'Test Symptom' is sent in case
        thisCase.Taxonomy_Symptom_Id__c=issue.Id;

        insert thisCase;

        IssueItemisationPublisherAction_CX.StateChecker issueChecker= new IssueItemisationPublisherAction_CX.IssueChecker(thisCase);
        IssueItemisationPublisherAction_CX.State state= issueChecker.getState(issue);
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_ISSUE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);    

        thisCase.modes__c='Train';
        thisCase.Taxonomy_Location__c='location1';
        thisCase.Taxonomy_Location_Id__c=location.Id;
        insertLocationsTaxonomy(train);
        insert thisCase;

        Test.startTest();
        List<IssueItemisationPublisherAction_CX.Node> locations=IssueItemisationPublisherAction_CX.getLocations(thisCase.Id,train.id);

        Test.stopTest();
        IssueItemisationPublisherAction_CX.Node selectedLocation;
        system.assertEquals(14,locations.size());
        for (IssueItemisationPublisherAction_CX.Node aLocation:locations){
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);
        thisCase.modes__c='Train';
        thisCase.Taxonomy_Location__c='location1';
        insert thisCase;
        List<Taxonomy_metadata__c> locationTaxonomies=insertLocationsTaxonomy(train);
        locationTaxonomies[0].Status_Staff_Facing__c='InActive';
        update locationTaxonomies[0];
        Test.startTest();
        List<IssueItemisationPublisherAction_CX.Node> locations=IssueItemisationPublisherAction_CX.getLocations(thisCase.Id,train.Id);

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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);
        thisCase.modes__c='Train';
        thisCase.Taxonomy_Symptom__c='issue1';
        thisCase.Taxonomy_Symptom_Id__c=issue.Id;
        insertIssuesTaxonomy(train);
        insert thisCase;


        Test.startTest();
        List<IssueItemisationPublisherAction_CX.Node> issues=IssueItemisationPublisherAction_CX.getIssues(thisCase.Id,train.Id);

        Test.stopTest();
        IssueItemisationPublisherAction_CX.Node selectedIssue;
        system.assertEquals(14,issues.size());
        for (IssueItemisationPublisherAction_CX.Node anIssue:issues){
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);
        thisCase.modes__c='Train';
        thisCase.Taxonomy_Symptom__c=issueTaxonomies[0].name;
        thisCase.Taxonomy_Symptom_Id__c=issueTaxonomies[0].Id;
        thisCase.Taxonomy_Location__c=locationTaxonomies[0].name;
        thisCase.Taxonomy_Location_Id__c=locationTaxonomies[0].Id;
        insert thisCase;
        Test.startTest();
        IssueItemisationPublisherAction_CX.updateEx(thisCase.Id
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
        thisCase=[select Id,Modes__c,description,subject,Taxonomy_Location__c,Taxonomy_Symptom__c from Case where Id=:thisCase.id];
        system.assertEquals('Testing now',thisCase.subject);
        system.assertEquals('Train',thisCase.Modes__c);
        system.assertEquals(locationTaxonomies[0].name,thisCase.Taxonomy_Location__c);
        system.assertEquals(issueTaxonomies[0].name,thisCase.Taxonomy_Symptom__c);
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);
        thisCase.modes__c='Train';
        thisCase.Taxonomy_Symptom__c='issue1';
        insert thisCase;
        Test.startTest();
        IssueItemisationPublisherAction_CX.updateEx(thisCase.Id,null,null,null,null,null,null,null,null,null,null,null);
        Test.stopTest();
        thisCase=[select Id,Modes__c,description,Taxonomy_Location__c,Taxonomy_Symptom__c from Case where Id=:thisCase.id];
        system.assertEquals('I was Injured because of the sharp metal jutting out',thisCase.description);
        system.assertEquals('Train',thisCase.Modes__c);

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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);
        Id issueId= thisCase.Taxonomy_Symptom_Id__c;
        Id locationId= thisCase.Taxonomy_Location_Id__c;
        thisCase.modes__c='Train';
        thisCase.Taxonomy_Symptom__c='issue1';
        insert thisCase;
        Test.startTest();
        IssueItemisationPublisherAction_CX.updateEx(thisCase.Id,'I was Injured because of the sharp metal jutting out ','Train',null,null,issueId,locationId,'Test parent Issue', 'Test parent Location', 'Test grand Issue', 'Test grand Location',  'Test type');
        Test.stopTest();
        thisCase=[select Id,Modes__c,description,Taxonomy_Location__c,Taxonomy_Symptom__c from Case where Id=:thisCase.id];
        List<Application_Log__c> categoryLog=[select id,Debug_Level__c,Source_Function__c from Application_Log__c where Debug_Level__c=:GlobalConstants.DEBUG and Source_Function__c='updateEx' ];
        system.assertEquals(0,categoryLog.size());


    }
    //parent case will be set multi issue mode
    @isTest
    static void testUpdateCategories(){
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        List<Taxonomy_metadata__c> locationTaxonomies=insertLocationsTaxonomy( train);
        List<Taxonomy_metadata__c> issueTaxonomies= insertIssuesTaxonomy( train);
        Taxonomy_metadata__c parentCaseLocation=locationTaxonomies[0];
        Taxonomy_metadata__c parentCaseIssue=issueTaxonomies[0];
        Case parentCase=setupCase(parentCaseLocation,parentCaseIssue);
        insert parentCase;
        List<IssueItemisationPublisherAction_CX.CaseCategory>  caseCategorisations= new List<IssueItemisationPublisherAction_CX.CaseCategory> ();
        IssueItemisationPublisherAction_CX.CaseCategory parentCaseCategory= new IssueItemisationPublisherAction_CX.CaseCategory();
        parentCaseCategory.caseId=parentCase.Id;
        parentCaseCategory.mode ='';
        parentCaseCategory.location ='';
        parentCaseCategory.issue ='';
        parentCaseCategory.subject ='test';
        parentCaseCategory.parentIssue ='';
        parentCaseCategory.parentlocation ='';
        parentCaseCategory.grandIssue ='';
        parentCaseCategory.grandlocation ='';
        parentCaseCategory.issueKpi ='';
        parentCaseCategory.issueDriver ='';
        parentCaseCategory.issueAccountability ='';
        parentCaseCategory.parent =null;
        parentCaseCategory.type ='';
        parentCaseCategory.issueAgency ='parent agency';
        parentCaseCategory.locationAgency ='parent agency';
        caseCategorisations.add(parentCaseCategory);

        IssueItemisationPublisherAction_CX.CaseCategory firstChild=new IssueItemisationPublisherAction_CX.CaseCategory();
        Taxonomy_metadata__c child1CaseLocation=locationTaxonomies[1];
        Taxonomy_metadata__c child1CaseIssue=issueTaxonomies[1];
        firstChild.mode ='test';
        firstChild.location ='test';
        firstChild.issue ='test';
        firstChild.subject ='test';
        firstChild.parentIssue ='test';
        firstChild.parentlocation ='test';
        firstChild.grandIssue ='test';
        firstChild.grandlocation ='test';
        firstChild.issueKpi ='test';
        firstChild.issueDriver ='test';
        firstChild.issueAccountability ='test';
        firstChild.parent =parentCase.Id;
        firstChild.type ='test';
        firstChild.issueAgency ='child agency 1';
        firstChild.locationAgency ='child agency 1';
        firstChild.locationId=child1CaseLocation.Id;
        firstChild.issueId=child1CaseIssue.Id;
        caseCategorisations.add(firstChild);

        IssueItemisationPublisherAction_CX.CaseCategory secondChild=new IssueItemisationPublisherAction_CX.CaseCategory();
        Taxonomy_metadata__c child2CaseLocation=locationTaxonomies[2];
        Taxonomy_metadata__c child2CaseIssue=issueTaxonomies[2];
        secondChild.mode ='test';
        secondChild.location ='test';
        secondChild.issue ='test';
        secondChild.subject ='test';
        secondChild.parentIssue ='test';
        secondChild.parentlocation ='test';
        secondChild.grandIssue ='test';
        secondChild.grandlocation ='test';
        secondChild.issueKpi ='test';
        secondChild.issueDriver ='test';
        secondChild.issueAccountability ='test';
        secondChild.parent =parentCase.Id;
        secondChild.type ='test';
        secondChild.issueAgency ='child agency 1';
        secondChild.locationAgency ='child agency 1';
        secondChild.locationId=child2CaseLocation.Id;
        secondChild.issueId=child2CaseIssue.Id;
        caseCategorisations.add(secondChild);
        Test.startTest();

        IssueItemisationPublisherAction_CX.upsertCategories((String)parentCase.Id,caseCategorisations);
        Test.stopTest();
        Map<Id,Case> cases= new     Map<Id,Case>([ select Id,ParentId, Agency__c,modes__c, multiAgency__c,Taxonomy_Location__c, description,subject, Taxonomy_Symptom__c, Taxonomy_Location_Id__c,  Taxonomy_Symptom_Id__c,Type from Case]);
        system.assertEquals(3, cases.size());
        Case parentCaseRetrieved= cases.get(parentCase.Id);
        system.assertEquals(GlobalConstants.MULTI_ISSUE_TYPE,parentCaseRetrieved.Type);
        system.assertEquals(GlobalConstants.CASE_MULTIISSUE_MODE,parentCaseRetrieved.Modes__c);
        //system.assertEquals('parent agency',parentCaseRetrieved.Agency__c);

        system.assert(!parentCaseRetrieved.multiAgency__c);


    }

    @isTest
    static void testGetChildCaseIssues(){
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        List<Taxonomy_metadata__c> locationTaxonomies=insertLocationsTaxonomy( train);
        List<Taxonomy_metadata__c> issueTaxonomies= insertIssuesTaxonomy( train);
        Taxonomy_metadata__c parentCaseLocation=locationTaxonomies[0];
        Taxonomy_metadata__c parentCaseIssue=issueTaxonomies[0];
        Case parentCase=setupCase(parentCaseLocation,parentCaseIssue);
        insert parentCase;
        List<IssueItemisationPublisherAction_CX.CaseCategory>  caseCategorisations= new List<IssueItemisationPublisherAction_CX.CaseCategory> ();
        IssueItemisationPublisherAction_CX.CaseCategory parentCaseCategory= new IssueItemisationPublisherAction_CX.CaseCategory();
        parentCaseCategory.caseId=parentCase.Id;
        parentCaseCategory.mode ='';
        parentCaseCategory.location ='';
        parentCaseCategory.issue ='';
        parentCaseCategory.subject ='test';
        parentCaseCategory.parentIssue ='';
        parentCaseCategory.parentlocation ='';
        parentCaseCategory.grandIssue ='';
        parentCaseCategory.grandlocation ='';
        parentCaseCategory.issueKpi ='';
        parentCaseCategory.issueDriver ='';
        parentCaseCategory.issueAccountability ='';
        parentCaseCategory.parent =null;
        parentCaseCategory.type ='';
        parentCaseCategory.issueAgency ='';
        parentCaseCategory.locationAgency ='';
        caseCategorisations.add(parentCaseCategory);

        IssueItemisationPublisherAction_CX.CaseCategory firstChild=new IssueItemisationPublisherAction_CX.CaseCategory();
        Taxonomy_metadata__c child1CaseLocation=locationTaxonomies[1];
        Taxonomy_metadata__c child1CaseIssue=issueTaxonomies[1];
        firstChild.mode ='test';
        firstChild.location ='test';
        firstChild.issue ='test';
        firstChild.subject ='test';
        firstChild.parentIssue ='test';
        firstChild.parentlocation ='test';
        firstChild.grandIssue ='test';
        firstChild.grandlocation ='test';
        firstChild.issueKpi ='test';
        firstChild.issueDriver ='test';
        firstChild.issueAccountability ='test';
        firstChild.parent =parentCase.Id;
        firstChild.type ='test';
        firstChild.issueAgency ='test';
        firstChild.locationAgency ='test';
        firstChild.locationId=child1CaseLocation.Id;
        firstChild.issueId=child1CaseIssue.Id;
        caseCategorisations.add(firstChild);

        IssueItemisationPublisherAction_CX.CaseCategory secondChild=new IssueItemisationPublisherAction_CX.CaseCategory();
        Taxonomy_metadata__c child2CaseLocation=locationTaxonomies[2];
        Taxonomy_metadata__c child2CaseIssue=issueTaxonomies[2];
        secondChild.mode ='test';
        secondChild.location ='test';
        secondChild.issue ='test';
        secondChild.subject ='test';
        secondChild.parentIssue ='test';
        secondChild.parentlocation ='test';
        secondChild.grandIssue ='test';
        secondChild.grandlocation ='test';
        secondChild.issueKpi ='test';
        secondChild.issueDriver ='test';
        secondChild.issueAccountability ='test';
        secondChild.parent =parentCase.Id;
        secondChild.type ='test';
        secondChild.issueAgency ='test';
        secondChild.locationAgency ='test';
        secondChild.locationId=child2CaseLocation.Id;
        secondChild.issueId=child2CaseIssue.Id;
        caseCategorisations.add(secondChild);
        IssueItemisationPublisherAction_CX.upsertCategories((String)parentCase.Id,caseCategorisations);
        Test.startTest();
        List<IssueItemisationPublisherAction_CX.CaseCategory> retrievedCaseCategories=IssueItemisationPublisherAction_CX.getChildCaseIssues(parentCase.Id);
        Test.stopTest();
        system.assertEquals(3,retrievedCaseCategories.size());



    }
    
//parent case will be set multi issue mode
    @isTest
    static void testDeleteEx(){
        Case parentCase=setupCase(null,null);
        insert parentCase;
        IssueItemisationPublisherAction_CX.deleteEx(parentCase.Id);
        List<Case> cases=[select Id from case where Id=:parentCase.Id];
        system.assertEquals(0,cases.size());

    }

    @isTest
    static void testGetOnlyConfiguredModesForCFMCase(){
        CFMModes__c accessibleModes=new CFMModes__c(
            Name='default',
            CFM_Modes_del__c='Train');
        insert accessibleModes;
        Taxonomy_metadata__c bus= new Taxonomy_metadata__c(name='Bus',type__c='Mode');
        insert bus;
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode');
        insert train;
        Taxonomy_metadata__c locationParent = insertParentLocationsTaxonomy(insertGrandLocationsTaxonomy(train));
        Taxonomy_metadata__c issueParent= insertParentIssuesTaxonomy(insertGrandIssuesTaxonomy(train));

        Taxonomy_metadata__c issue=new Taxonomy_metadata__c(
                Parent_Id__c=issueParent.Id,
                name='issue',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issue;
        Taxonomy_metadata__c location=new Taxonomy_metadata__c(
                Parent_Id__c=locationParent.Id,
                name='location',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert location;
        Case thisCase=setupCase(location,issue);
        thisCase.modes__c='Train';
        insert thisCase;

        Test.startTest();
        List<IssueItemisationPublisherAction_CX.Node> modes=IssueItemisationPublisherAction_CX.getModes(thisCase.Id);

        Test.stopTest();
        IssueItemisationPublisherAction_CX.Node selectedMode;
        system.assertEquals(1,modes.size());
        for (IssueItemisationPublisherAction_CX.Node aNode:modes){
            if ('Train'==aNode.text) selectedMode=aNode;
        }
        system.assert(selectedMode.state.selected==true);


    }

//utility methods for populating the test data
    public static Taxonomy_metadata__c insertModeTaxonomy(){
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode',Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING);
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
            );
        insert locationParent;
        
        return locationParent;
    }
    public static Taxonomy_metadata__c insertGrandLocationsTaxonomy(Taxonomy_metadata__c mode){
        
        Taxonomy_metadata__c locationGrand=new Taxonomy_metadata__c(
                Parent_Id__c=mode.Id,

                name='locationgrand',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=GlobalConstants.TAXONOMY_TYPE_LOCATION
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
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
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issueGrand;
        return issueGrand;
    }
    public static Taxonomy_metadata__c insertParentIssuesTaxonomy(Taxonomy_metadata__c issueGrand){
        
        Taxonomy_metadata__c issueParent=new Taxonomy_metadata__c(
                Parent_Id__c=issueGrand.Id,

                name='issueparent',
                Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING ,
                Type__c=IssueItemisationPublisherAction_CX.ISSUE_TYPE
            );
        insert issueParent;
        
        return issueParent;
    }
    public static Taxonomy_metadata__c insertModeTrain(){
        
        Taxonomy_metadata__c train= new Taxonomy_metadata__c(name='Train',type__c='Mode',Status_Staff_Facing__c=GlobalConstants.TAXONOMY_STAFF_FACING);
        insert train;
        return train;
    }
    public static Case setupCase(Taxonomy_metadata__c location, Taxonomy_metadata__c issue){
    
        List<RecordType> caseTypes=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName != :GlobalConstants.MIN_CORRO_RECTYPE_NAME limit 1];
        RecordType CASE_REC_TYPE = caseTypes.size()==0?null:caseTypes[0];
        aCase=new Case(Subject='I was Injured because of the sharp metal jutting out',
                                Description='I was Injured because of the sharp metal jutting out',
                                RecordTypeId=CASE_REC_TYPE.Id,
                                Status='New',
                                Origin='Web',
                                Priority='Normal',
                                Modes__c='Test Mode',
                                Taxonomy_Location__c='Test Location',
                                Taxonomy_Symptom__c='Test Symptom',
                                Taxonomy_Location_Id__c=issue!=null?issue.Id:null,
                                Taxonomy_Symptom_Id__c=location!=null?location.Id:null
                                );

        return aCase;

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