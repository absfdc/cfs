/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A case controller extension for case categorisation publisher action

Test Class:    IssueItemisationPublisherAction_Test
History
9 Apr 2015      Dipankar Barman     created
13 Nov 2017		Arxxus 				Auto trigae: added all new fields created on case for auto triage 
									in parentCase query in method- upsertCategories
------------------------------------------------------------*/
global with sharing class IssueItemisationPublisherAction_CX {
    global static Final string ISSUE_TYPE='Issue';
    global static Final string ROOT_PARENT='#';
    
    public Case thisCase{get;set;}
    public String RecordTypeName {get;set;}
    public Taxonomy_metadata__c MAGS{get;set;}
    public IssueItemisationPublisherAction_CX(final ApexPages.StandardController std) {
        if(!test.isRunningTest()) std.addFields(new List<String>{'description','ParentId','subject'});
        thisCase=(Case)std.getRecord();
        List<RecordType> recorTypes= [SELECT DeveloperName FROM RecordType where Id =:thisCase.RecordTypeId];
        if(recorTypes!=null) RecordTypeName=recorTypes[0].DeveloperName;
        list<Taxonomy_Metadata__c> MAGSCodes = [select Id,Parent_Id__c,Status_Staff_Facing__c, name, Parent_Id__r.Type__c from  Taxonomy_Metadata__c where  Name =:GlobalConstants.MIN_CORRO_MODE_NAME and Status_Staff_Facing__c=:GlobalConstants.TAXONOMY_STAFF_FACING and Type__c=:GlobalConstants.TAXONOMY_MODE_TYPE];
        if (MAGSCodes!=null && MAGSCodes.size()>0) MAGS=MAGSCodes[0];
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method returns the list of Types of cases
    Inputs:        caseid

    History
    30 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static List<Node> getTypes(string caseId) {
        caseId=String.escapeSingleQuotes(caseId);
        List<Case> thisCases;
        if (caseId!=null && caseId.length()>=15) thisCases=[select Id,Type from Case where Id=:caseId];


        List<Schema.PicklistEntry> entries=getTypePicklistOptions();
        if (null==entries) return null;
        List<Node> nodes= new List<Node>();
        for (Schema.PicklistEntry anEntry: entries){
            if(anEntry.isActive()==true){
                Node aNode=new Node();
                aNode.id=anEntry.getValue();
                aNode.text=anEntry.getLabel();
                aNode.parent=ROOT_PARENT;
                if (thisCases!=null && thisCases.size()>0 && thisCases[0].Type!=null && !String.isEmpty(thisCases[0].Type) && anEntry.getLabel().equalsIgnoreCase(thisCases[0].Type) ){ 
                    State nodeState= new State();
                    nodeState.selected=true;
                    aNode.state=nodeState;
                }
                nodes.add(aNode);
            }

        }
        return nodes;
    }
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method returns the list of type picklist entry from the Taxonomy metadata

    History
    30 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    static List<Schema.PicklistEntry>  getTypePicklistOptions(){
        Schema.DescribeFieldResult fieldResult=null;
        List<Schema.PicklistEntry> entries;
        try{
            fieldResult=Case.Type.getDescribe();
            if (null != fieldResult) entries=fieldResult.getPicklistValues();
        } catch(Exception e){
            system.debug('Type not set on taxonomy metadata');
        }
        return entries;
    }
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method returns the list of modes of transport
    Inputs:        caseid

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static List<Node> getModes(string caseId) {
        StateChecker locater;
        Set<String> accessibleModes= new Set<String> ();
        List<Taxonomy_Metadata__c> modes;
        if(null!=caseId && caseId.length()>=15){
            caseId=String.escapeSingleQuotes(caseId);
            Case thisCase=[select Id,IsMinCorroCase__c, Modes__c,Taxonomy_Location_Type__c,Taxonomy_Area__c,Taxonomy_Location__c from Case where Id=:caseId];
            
            locater= new ModeChecker(thisCase);
            if (thisCase.IsMinCorroCase__c==false){
                CFMModes__c modeConf=CFMModes__c.getInstance(GlobalConstants.CFM_MODES_CONFIG_NAME);
                if (modeConf!=null){
                    String configuredModes= modeConf.CFM_Modes_del__c;
                    for (String aMode:configuredModes.split(',',0)){
                        accessibleModes.add(aMode);
                    }
                    modes=[select Id,Parent_Id__c,Status_Staff_Facing__c, name, Parent_Id__r.Type__c,School_Route__c from  Taxonomy_Metadata__c where Status_Staff_Facing__c=:GlobalConstants.TAXONOMY_STAFF_FACING and Type__c=:GlobalConstants.TAXONOMY_MODE_TYPE and Name in:accessibleModes];

                }
                
            }else{
                modes=[select Id,Parent_Id__c,Status_Staff_Facing__c, name, Parent_Id__r.Type__c,School_Route__c from  Taxonomy_Metadata__c where Status_Staff_Facing__c=:GlobalConstants.TAXONOMY_STAFF_FACING and Type__c=:GlobalConstants.TAXONOMY_MODE_TYPE and Name !=:GlobalConstants.MIN_CORRO_MODE_NAME];
            }

        }

        if (null==modes) return null;
        return getNodes(modes,locater);

    }

    
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Inner bean class represents the data for a Node

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    global class Node{
        public String id {get;set;}//every node is given an unique id
        public String parent {get;set;}// will be used for placement within hierarchy
        public String text {get;set;}//what will be displayed on the UI
        public State state{get;set;}//selected etc
        public a_attr a_attr{get;set;}//style etc
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Inner bean class represents the state of a Node

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    global class State{
        public Boolean selected {get;set;}
        public Boolean opened {get;set;}
    }

    /*------------------------------------------------------------
    Author:       Abhi
    Company:       
    Description:   Inner bean class represents the a_attr of a Node

    History
    ------------------------------------------------------------*/
    global class a_attr{
        public String style {get;set;}
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Interface for checking and obtaining the state
                    of the node, based on past selections, persisted on case

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @TestVisible
    interface StateChecker{
        State getState(Taxonomy_metadata__c taxonomy);
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Concrete implementation for checking and obtaining the state
                    of any Location, based on past selections, persisted on case

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @TestVisible
    class LocationChecker implements StateChecker{
        case thisCase;
        public LocationChecker(Case thisCase){
            this.thisCase=thisCase;
        }
        public virtual State getState (Taxonomy_metadata__c taxonomy){
            State thisState;
            if (thisCase!=null ){
                
                if (thisCase.Taxonomy_Location_Id__c!=null  && taxonomy.id==thisCase.Taxonomy_Location_Id__c){
                    thisState= new State();
                    thisState.selected=true;
                }else if(thisCase.Taxonomy_Location_Id__c==null || String.isEmpty(thisCase.Taxonomy_Location_Id__c)){
                    if(thisCase.Taxonomy_Area__c!=null && !String.isEmpty(thisCase.Taxonomy_Area__c) && taxonomy.name.equalsIgnoreCase(thisCase.Taxonomy_Area__c)){
                        thisState= new State();
                        thisState.selected=false;
                        thisState.opened=true;
                    }else if (thisCase.Taxonomy_Area__c==null ||String.isEmpty(thisCase.Taxonomy_Area__c)){
                        if(thisCase.Taxonomy_Location_Type__c!=null && !String.isEmpty(thisCase.Taxonomy_Location_Type__c) && taxonomy.name.equalsIgnoreCase(thisCase.Taxonomy_Location_Type__c)){
                            thisState= new State();
                            thisState.selected=false;
                            thisState.opened=true;
                        }else if(thisCase.Taxonomy_Location_Type__c==null || String.isEmpty(thisCase.Taxonomy_Location_Type__c)){
                            if(thisCase.modes__c!=null && !String.isEmpty(thisCase.modes__c) && taxonomy.name.equalsIgnoreCase(thisCase.modes__c)){
                                thisState= new State();
                                thisState.selected=false;
                                thisState.opened=true;
                            }
                        }
                    }
                }
                
            }
            return thisState;
        }
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Concrete implementation for checking and obtaining the state
                    of any issue, based on past selections, persisted on case

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @TestVisible
    class IssueChecker implements StateChecker{
        case thisCase;
        public IssueChecker(Case thisCase){
            this.thisCase=thisCase;
        }
        public virtual State getState(Taxonomy_metadata__c taxonomy){
            State thisState;
            if (thisCase!=null && thisCase.Taxonomy_Symptom_Id__c!=null  && taxonomy.Id==thisCase.Taxonomy_Symptom_Id__c ){
                thisState= new State();
                thisState.selected=true;

            }else if(thisCase.Taxonomy_Symptom_Id__c==null || String.isEmpty(thisCase.Taxonomy_Symptom_Id__c)){
                if(thisCase.Taxonomy_Transaction__c!=null && !String.isEmpty(thisCase.Taxonomy_Transaction__c) && taxonomy.name.equalsIgnoreCase(thisCase.Taxonomy_Transaction__c)){
                    thisState= new State();
                    thisState.selected=false;
                    thisState.opened=true;
                }else if (thisCase.Taxonomy_Transaction__c==null ||String.isEmpty(thisCase.Taxonomy_Transaction__c)){
                    if(thisCase.Taxonomy_Moment__c!=null && !String.isEmpty(thisCase.Taxonomy_Moment__c) && taxonomy.name.equalsIgnoreCase(thisCase.Taxonomy_Moment__c)){
                        thisState= new State();
                        thisState.selected=false;
                        thisState.opened=true;
                    }else if(thisCase.Taxonomy_Moment__c==null || String.isEmpty(thisCase.Taxonomy_Moment__c)){
                        if(thisCase.modes__c!=null && !String.isEmpty(thisCase.modes__c) && taxonomy.name.equalsIgnoreCase(thisCase.modes__c)){
                            thisState= new State();
                            thisState.selected=false;
                            thisState.opened=true;
                        }
                    }
                }
            }
            return thisState;
        }
    }


    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Concrete implementation for checking and obtaining the state
                    of any mode, based on past selections, persisted on case

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @TestVisible
    class ModeChecker implements StateChecker{
        case thisCase;
        public ModeChecker(Case thisCase){
            this.thisCase=thisCase;
        }
        public virtual State getState(Taxonomy_metadata__c taxonomy){
            State thisState;
            if (thisCase!=null && thisCase.Modes__c!=null && !String.isEmpty(thisCase.Modes__c) && taxonomy.name.equalsIgnoreCase(thisCase.Modes__c) ){
                thisState= new State();
                thisState.selected=true;

            }
            return thisState;
        }
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   caseCategory bean for the child cases

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @TestVisible
    global class CaseCategory {
            public String modeId{get;set;}
            public String mode {get;set;}
            public String location {get;set;}
            public String issue {get;set;}
            public String caseId {get;set;}
            public String locationId {get;set;}
            public String issueId {get;set;}
            public String subject {get;set;}
            public String parentIssue {get;set;}
            public String parentIssueId {get;set;}
            public String parentlocation {get;set;}
            public String parentlocationId {get;set;}
            public String grandIssue {get;set;}
            public String grandlocation {get;set;}
            public String issueKpi {get;set;}
            public String issueDriver {get;set;}
            public String issueAccountability {get;set;}
            public String parent {get;set;}
            public String type {get;set;}
            public String issueAgency {get;set;}
            public String locationAgency {get;set;}
            public Boolean cloned{get;set;}
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   remoteaction to obtain the list of Locations
                    caseid used to check if some issue was already persisted
                    mode based on which the Locations are fetched

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/

    @RemoteAction
    global static List<Node> getLocations(string caseId,String modeId) {
        StateChecker locater;
        modeId=String.escapeSingleQuotes(modeId);

        if(null!=caseId && caseId.length()>=15){
            caseId=String.escapeSingleQuotes(caseId);
            Case thisCase=[select Id,Modes__c,Taxonomy_Location_Type__c,Taxonomy_Area__c,Taxonomy_Location__c, Taxonomy_Location_Id__c from Case where Id=:caseId];
            locater= new LocationChecker(thisCase);

        }

        List<Taxonomy_Metadata__c> locations = [select Id,name,Parent_Id__c,Status_Staff_Facing__c,Parent_Id__r.Type__c,Agency__c,School_Route__c from  Taxonomy_Metadata__c where Status_Staff_Facing__c=:GlobalConstants.TAXONOMY_STAFF_FACING and Type__c=:GlobalConstants.TAXONOMY_TYPE_LOCATION 
                                                and ((Parent_Id__r.Parent_Id__r.Parent_Id__c=:modeId)
                                                or Parent_Id__r.Parent_Id__c=:modeId or Parent_Id__c=:modeId) ORDER BY Length_of_name__c ASC Limit 50000];
        if (null==locations) return null;
        
        return getNodes(locations,locater);

    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method returns the list of nodes taking
    Inputs:        List of taxonomy be it Location or issue
                    and the corresponding checker

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @TestVisible
    static List<Node> getNodes(List<Taxonomy_Metadata__c> taxonomies, StateChecker checker ){
        MAP<String,Node> nodes= new MAP<String,Node>();//node id vs Node
        Node selected;
        for (Taxonomy_Metadata__c aTaxonomy: taxonomies){

            Node aNode=new Node();
            if (null!=checker){
                aNode.state=checker.getState(aTaxonomy);
                if (null !=aNode.state) selected=aNode;
            }
            aNode.id=aTaxonomy.Id;
            aNode.text=aTaxonomy.name;
            if(aTaxonomy.School_Route__c){
                a_attr attr = new a_attr();
                attr.style = 'color:darkorange;font-weight:bold';
                aNode.a_attr = attr;
            }
                
            if (aTaxonomy.Parent_Id__c==null || aTaxonomy.Parent_Id__r.Type__c==GlobalConstants.TAXONOMY_MODE_TYPE) {
                aNode.parent=ROOT_PARENT;
            }else{
                aNode.parent=aTaxonomy.Parent_Id__c;
            }
            
            nodes.put(aNode.id,aNode);
        }
        if (selected!=null){
            openParent(selected,nodes);
        }

        return nodes.values();
    }
    //recursively open the parents if selected
    static void openParent(Node selected, MAP<String,Node>nodes){
        
            if (selected.state==null){
                selected.state=new State();
            }
            selected.state.opened=true;
            if (selected.parent!=ROOT_PARENT){
                openParent(nodes.get(selected.parent),nodes);
            }
    }
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method returns the list of Issues
    Inputs:        caseid used to check if some issue was already persisted
                    mode based on which the Issues are fetched

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static List<Node> getIssues(string caseId,String modeId) {
        modeId=String.escapeSingleQuotes(modeId);
        StateChecker issueCheck;
        if(null!=caseId  && caseId.length()>=15){
            caseId=String.escapeSingleQuotes(caseId);
            Case thisCase=[select Id,Modes__c,Taxonomy_Moment__c,Taxonomy_Transaction__c,Taxonomy_Symptom__c,Taxonomy_Symptom_Id__c from Case where Id=:caseId];
            issueCheck= new IssueChecker(thisCase);

        }
        List<Taxonomy_Metadata__c> issues=[select Id,name,Parent_Id__c,Status_Staff_Facing__c,Parent_Id__r.Type__c,Agency__c,School_Route__c from  Taxonomy_Metadata__c where Status_Staff_Facing__c=:GlobalConstants.TAXONOMY_STAFF_FACING and Type__c=:GlobalConstants.TAXONOMY_TYPE_ISSUE and (Parent_Id__r.Parent_Id__r.Parent_Id__c=:modeId or
                                                Parent_Id__r.Parent_Id__c=:modeId or Parent_Id__c=:modeId) Limit 10000];
        if (null==issues) return null;
        return getNodes(issues,issueCheck);
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method updates the case
    Inputs:        caseid, description,mode,location,issue

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static void updateEx(string caseId,String subject,String mode,String location,String locationId,String issue,String issueId,String parentIssue,String parentLocation,String grandIssue,String grandLocation, String type) {
        system.debug('---@Categorisation UpdateEx Method Called----');
        List<ApplicationLogMessage> lms = new List<ApplicationLogMessage>();
        try{
            caseId=String.escapeSingleQuotes(caseId);
            Case thisCase=[select Id,Agency__c,Type,Modes__c,subject,Taxonomy_Location_Type__c,Taxonomy_Area__c,Taxonomy_Location__c,Taxonomy_Location_Id__c,Taxonomy_Moment__c,Taxonomy_Transaction__c,Taxonomy_Symptom__c,Taxonomy_Symptom_Id__c,Taxonomy_Accountability__c,RecordTypeId,KPI__c,Key_Driver__c,(select Id from cases) from Case where Id=:caseId];
            if(thisCase.cases.size()>0) {
                throw new TriggerException(':first error: Cannot use this action as this case has child issues. Use the categorise Case button on detail view:');
            }
            if(subject==null && mode==null && location==null && issue==null && type==null ) return;
            if(subject==thisCase.subject && mode==thisCase.Modes__c && locationId==thisCase.Taxonomy_Location_Id__c && issueId==thisCase.Taxonomy_Symptom_Id__c && type== thisCase.Type ) return;
            
            if(locationId!=thisCase.Taxonomy_Location_Id__c || issueId != thisCase.Taxonomy_Symptom_Id__c) thisCase.Section__c=null;
            thisCase.subject=subject;
            thisCase.Type=type;
            List<Id> taxomyIds= new List<Id>();
            if (!String.isEmpty(locationId)) taxomyIds.add((Id)locationId);
            if (!String.isEmpty(issueId)) taxomyIds.add((Id)issueId);
            List<Taxonomy_Metadata__c> taxonomies;
            Taxonomy_Metadata__c locationTaxonomy;
            Taxonomy_Metadata__c issueTaxonomy;
            String locationAccountability;
            String issueAccountability;
            String locationAgency;
            String issueAgency;
            String issueKpi;
            String issueDriver;
            if (taxomyIds.size()>0){
                taxonomies=[SELECT Agency__c,Type__c,Id, Name, Parent_Id__c, KPI__c, Driver__c, Status_Staff_Facing__c,  Issue_Accountability__c, 
                            Parent_Id__r.Agency__c,Parent_Id__r.Type__c,Parent_Id__r.Id, Parent_Id__r.Name, Parent_Id__r.Parent_Id__c, Parent_Id__r.KPI__c, Parent_Id__r.Driver__c, Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Issue_Accountability__c,
                            Parent_Id__r.Parent_Id__r.Agency__c,Parent_Id__r.Parent_Id__r.Type__c,Parent_Id__r.Parent_Id__r.Id, Parent_Id__r.Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Parent_Id__c, Parent_Id__r.Parent_Id__r.KPI__c, Parent_Id__r.Parent_Id__r.Driver__c, Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Parent_Id__r.Issue_Accountability__c,
                            Parent_Id__r.Parent_Id__r.Parent_Id__r.Agency__c,Parent_Id__r.Parent_Id__r.Parent_Id__r.Type__c,Parent_Id__r.Parent_Id__r.Parent_Id__r.Id, Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                            FROM Taxonomy_Metadata__c where Id=:taxomyIds];
                for (Taxonomy_Metadata__c taxonomy:taxonomies){
                    Taxonomy_Metadata__c parent=taxonomy.Parent_Id__r;
                    Taxonomy_Metadata__c grand=parent.Parent_Id__r;
                    Taxonomy_Metadata__c modeMetadata=grand.Parent_Id__r;

                    if (taxonomy.Type__c==GlobalConstants.TAXONOMY_TYPE_LOCATION) {
                        locationTaxonomy=taxonomy;
                        grandLocation=grand.name;
                        parentLocation=parent.name;

                        locationAccountability=locationTaxonomy.Issue_Accountability__c;
                        locationAgency=locationTaxonomy.Agency__c;
                    }else if (taxonomy.Type__c==GlobalConstants.TAXONOMY_TYPE_ISSUE){
                        issueTaxonomy=taxonomy;
                        grandIssue=grand.name;
                        parentIssue=parent.name;
                        issueAccountability=issueTaxonomy.Issue_Accountability__c;
                        issueKpi=issueTaxonomy.KPI__c;
                        issueDriver=issueTaxonomy.Driver__c;
                        issueAgency=issueTaxonomy.Agency__c;

                    } 
                    thisCase.Modes__c=modeMetadata.name;
                }

            }
            
            
            

            thisCase.Taxonomy_Location_Type__c=grandLocation;
            thisCase.Taxonomy_Area__c=parentLocation;
            thisCase.Taxonomy_Moment__c=grandIssue;
            thisCase.Taxonomy_Transaction__c=parentIssue;
            thisCase.KPI__c=issueKpi;
            thisCase.Key_Driver__c=issueDriver;
            thisCase.Taxonomy_Location__c=location;
            thisCase.Taxonomy_Symptom__c=issue;
            if (!String.isEmpty(issueId)) thisCase.Taxonomy_Symptom_Id__c=issueId;

            if (!String.isEmpty(locationId)) thisCase.Taxonomy_Location_Id__c=locationId;
            thisCase.Taxonomy_Accountability__c=issueAccountability!=NULL ? issueAccountability : locationAccountability;
            thisCase.Agency__c=issueAgency!=NULL ? issueAgency : locationAgency;

            

            update thisCase;
            ApplicationLogUtility.logMessage(GlobalConstants.DEBUG,
                                    'IssueItemisationPublisherAction_CX',
                                    'updateEx',
                                    'updated case category',
                                    'caseId- '+caseId+'  \r\n subject- '+subject+'  \r\n mode- '+mode+'  \r\n location- '+location+'  \r\n issue- '+issue,
                                    null,
                                    null,
                                    null,
                                    caseId,
                                    null);
        }catch(Exception e){
            ApplicationLogMessage lm = new ApplicationLogMessage();
            lm.source='IssueItemisationPublisherAction_CX';
            lm.sourceFunction='updateCategories';
            
            lm.logMessage=e.getMessage();
            lm.ex=e;
            lm.debugLevel=GlobalConstants.ERROR;
            
            lms.add(lm);
            throw e;
        }finally{
            ApplicationLogUtility.logMessage(lms);
        }
        
    }
    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method updates multiple related  cases upto one step down the hierarchy
    Inputs:        caseid, description,mode,location,issue

    History
    9 Apr 2015      Dipankar Barman     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static void upsertCategories(String parentCaseId,List<CaseCategory> categories) {
        List<ApplicationLogMessage> lms = new List<ApplicationLogMessage>();
        try{
            if(categories==null || categories.size()<1) return;
            Map<Id,CaseCategory>caseCategoriesForUpdate=new Map<Id,CaseCategory>();
            List<Case>caseForInsert= new List<Case>();
            RecordType multiType=[SELECT ID FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName =:GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE_DEV limit 1];
            List<Id> taxomyIds= new List<Id>();
            Case parentCase;
            system.debug('---@Categorisation UpsertCategories---Parent Case Id-' + parentCaseId);
            system.debug('---@Categorisation UpsertCategories---Categories-' + categories);
            for(CaseCategory aCaseCategory:categories){
                if(aCaseCategory.caseId==parentCaseId){
                    parentCase = [Select id, Bus_driver_identification__c,Response_Requested__c,categorisation_count__c,assigned_SME__c,ContactId,AccountId,ParentId,
                                  SuppliedName,SuppliedEmail,SuppliedPhone,SuppliedCompany,Type,RecordTypeId,Status,Reason,Origin,
                                  Subject,Priority,Description,IsEscalated,OwnerId,Taxonomy_Moment__c,Taxonomy_Location__c,Taxonomy_Transaction__c,
                                  Taxonomy_Symptom__c,Taxonomy_Location_Type__c,Taxonomy_Area__c,Secondary_Contact__c,Supplied_Address__c,
                                  Case_Reference_Number__c,Modes__c,User_have_raised_the_issue_previously__c,Taxonomy_Accountability__c,
                                  Origin_Details__c,Referrer_URL__c,User_agent__c,Users_Ip_address__c,RFS_Region__c,Product_Type__c,
                                  Signatory__c,Taxonomy_Symptom_Id__c,Taxonomy_Location_Id__c,Acknowledgement_Required__c,Use_Contact_Details__c,
                                  Case_Registered_By__c,Alternate_Email__c,Alternative_Postal_Address__c,PNR_Number__c, Date_Time_of_Incident__c, 
                                  Request_for_Action__c,Location_of_Incident__c,Direction_of_Travel__c,STA_Event_ID__c,STA_Employee_Number__c,
                                  STA_Insurance_360_Number__c,Vehicle_Registration__c,External_Agency__c,Disability__c,ATSI__c,Disability_Category__c, Original_Description__c, CaseIsFiltered__c, SecurityThreatScore__c, BusinessPriorityScore__c, 
                                  LOTE__c 
                                  From case 
                                  Where id=: parentcaseId];
                    
                }
                
                if (!String.isEmpty(aCaseCategory.locationId)) taxomyIds.add((Id)aCaseCategory.locationId);
                if (!String.isEmpty(aCaseCategory.issueId)) taxomyIds.add((Id)aCaseCategory.issueId);
            }

            Map<Id,Taxonomy_Metadata__c> taxonomies;

            if (taxomyIds.size()>0){
                taxonomies= new Map<Id,Taxonomy_Metadata__c> ([SELECT Agency__c,Type__c,Id, Name, Parent_Id__c, KPI__c, Driver__c, Status_Staff_Facing__c,  Issue_Accountability__c, 
                        Parent_Id__r.Agency__c,Parent_Id__r.Type__c,Parent_Id__r.Id, Parent_Id__r.Name, Parent_Id__r.Parent_Id__c, Parent_Id__r.KPI__c, Parent_Id__r.Driver__c, Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Issue_Accountability__c,
                        Parent_Id__r.Parent_Id__r.Agency__c,Parent_Id__r.Parent_Id__r.Type__c,Parent_Id__r.Parent_Id__r.Id, Parent_Id__r.Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Parent_Id__c, Parent_Id__r.Parent_Id__r.KPI__c, Parent_Id__r.Parent_Id__r.Driver__c, Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Parent_Id__r.Issue_Accountability__c,
                        Parent_Id__r.Parent_Id__r.Parent_Id__r.Agency__c,Parent_Id__r.Parent_Id__r.Parent_Id__r.Type__c,Parent_Id__r.Parent_Id__r.Parent_Id__r.Id, Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        FROM Taxonomy_Metadata__c where Id=:taxomyIds]);
            }

            List<Case> unmodifiedParent = [ SELECT Id, Taxonomy_Moment__c, Taxonomy_Transaction__c, Taxonomy_Symptom__c, 
                                                Taxonomy_Location_Type__c, Taxonomy_Area__c, Taxonomy_Location__c 
                                            FROM Case WHERE Id = :parentCase.Id];

            system.debug('---@Categorisation UpsertCategories---Unmodified Parent-' + unmodifiedParent);                                           
            for (CaseCategory cc:categories) {
                if (cc.caseId!=null && cc.caseId.length()>=15){

                    caseCategoriesForUpdate.put(String.escapeSingleQuotes(cc.caseId),cc);

                }else{
                    Taxonomy_Metadata__c thisIssueTaxo;
                    Taxonomy_Metadata__c thisLocationTaxo;
                    String kpi;
                    String driver;
                    String accountability;
                    String agency;

                    
                    
                    if (cc.issueId!=null && cc.issueId.length()>=15){
                        thisIssueTaxo=taxonomies.get(cc.issueId);
                        kpi=thisIssueTaxo.KPI__c ;
                        driver=thisIssueTaxo.Driver__c;
                        accountability=thisIssueTaxo.Issue_Accountability__c;
                        
                    }else{
                        kpi= cc.issueKpi;
                        driver=cc.issueDriver;
                        accountability=cc.issueAccountability;
                    }
                    if (cc.locationId!=null && cc.locationId.length()>=15) thisLocationTaxo=taxonomies.get(cc.locationId);

                    if (thisIssueTaxo!=null && thisIssueTaxo.Agency__c!=null && thisIssueTaxo.Agency__c.length()>1){
                        agency=thisIssueTaxo.Agency__c;
                    }else if (thisLocationTaxo !=null && thisLocationTaxo.Agency__c!=null && thisLocationTaxo.Agency__c.length()>1){
                        agency=thisLocationTaxo.Agency__c;
                    }else if (thisIssueTaxo==null && thisLocationTaxo==null && cc.issueAgency!=null && cc.issueAgency.length()>1){
                        agency=cc.issueAgency;
                    }else if (thisIssueTaxo==null && thisLocationTaxo==null && cc.locationAgency!=null && cc.locationAgency.length()>1){
                        agency=cc.locationAgency;
                    }
                    Case newCase= parentCase.clone();
                    newCase.subject=cc.subject;
                    newCase.parentId=parentCase.Id;
                    newCase.OwnerId=parentCase.OwnerId;
                    newCase.Taxonomy_Location_Type__c=cc.grandlocation;
                    newCase.Taxonomy_Area__c=cc.parentlocation;
                    newCase.Taxonomy_Moment__c=cc.grandIssue;
                    newCase.Taxonomy_Transaction__c=cc.parentIssue;
                    newCase.ParentId=cc.parent;
                    newCase.Taxonomy_Symptom__c=cc.issue;
                    newCase.Taxonomy_Symptom_Id__c=String.isEmpty(cc.issueId)?NULL:cc.issueId;
                    newCase.Taxonomy_Location__c=cc.location;
                    newCase.Taxonomy_Location_Id__c=String.isEmpty(cc.locationId)?NULL:cc.locationId;
                    newCase.Modes__c=cc.mode;
                    newCase.KPI__c=kpi;
                    newCase.Key_Driver__c=driver;
                    newCase.Taxonomy_Accountability__c=accountability;
                    newCase.Type=cc.type;
                    newCase.Agency__c=agency;
                    newCase.Response_Requested__c=parentCase.Response_Requested__c;
                    system.debug('---Case Object Cloned---' + newCase);
                    if (cc.cloned==true){
                        newCase.assigned_SME__c= parentCase.assigned_SME__c;
                        newCase.categorisation_count__c= parentCase.categorisation_count__c;
                        if(!unmodifiedParent.isEmpty() && (unmodifiedParent[0].Taxonomy_Location__c != newCase.Taxonomy_Location__c
                            || unmodifiedParent[0].Taxonomy_Area__c != newCase.Taxonomy_Area__c
                            || unmodifiedParent[0].Taxonomy_Location_Type__c != newCase.Taxonomy_Location_Type__c
                            || unmodifiedParent[0].Taxonomy_Moment__c != newCase.Taxonomy_Moment__c
                            || unmodifiedParent[0].Taxonomy_Transaction__c != newCase.Taxonomy_Transaction__c
                            || unmodifiedParent[0].Taxonomy_Symptom__c != newCase.Taxonomy_Symptom__c)) {
                            newCase.categorisation_count__c = newCase.categorisation_count__c + 1;
                            System.debug('Categorization incremented to ' + newCase.categorisation_count__c);
                        }
                    }else{
                        newCase.assigned_SME__c=null;
                        newCase.categorisation_count__c=0;
                        newCase.status=GlobalConstants.CASE_STATUS_NEW;//newly created cases in status New
                    }

                    newCase.multiAgency__c=false;
                    caseForInsert.add(newCase);
                }
            }

            system.debug('---@Categorisation UpsertCategories---Case For Insert-' + caseForInsert);       
            Map<Id,Case> updateCases;
            if (caseCategoriesForUpdate.size()>0) updateCases=new Map<Id,Case> ([select Id,Modes__c,Agency__c,subject,Taxonomy_Location_Type__c,Type,Assigned_SME__c,
                                                                                    Taxonomy_Area__c,Taxonomy_Location__c,Taxonomy_Location_Id__c,Taxonomy_Moment__c,
                                                                                    Taxonomy_Transaction__c,Taxonomy_Symptom__c,Taxonomy_Symptom_Id__c,Taxonomy_Accountability__c,
                                                                                    RecordTypeId,KPI__c,Key_Driver__c from Case where Id in:caseCategoriesForUpdate.keySet()]);
            system.debug('received categories- '+JSON.serialize(categories));
            if(updateCases!=null && updateCases.size()>0){
                system.debug('---@Categorisation To be Updated cases- '+ JSON.serialize(updateCases.values()));
                system.debug('---@Categorisation Taxonomies From Database- '+ JSON.serialize(taxonomies.values()));

                for (Id aCaseId:updateCases.keySet()){
                    Case thisCase=updateCases.get(aCaseId);
                    CaseCategory thisCaseCategory=caseCategoriesForUpdate.get(aCaseId);
                    Taxonomy_Metadata__c thisIssueTaxo;
                    Taxonomy_Metadata__c thisLocationTaxo;
                    String kpi;
                    String driver;
                    String accountability;
                    String agency;

                    if(thisCaseCategory.locationId !=thisCase.Taxonomy_Location_Id__c || thisCaseCategory.issueId !=thisCase.Taxonomy_Symptom_Id__c) thisCase.Section__c=null;
                    
                    if (thisCaseCategory.issueId!=null && thisCaseCategory.issueId.length()>=15){
                        thisIssueTaxo=taxonomies.get(thisCaseCategory.issueId);
                        kpi=thisIssueTaxo.KPI__c ;
                        driver=thisIssueTaxo.Driver__c;
                        accountability=thisIssueTaxo.Issue_Accountability__c;
                        
                    }else{
                        kpi= thisCaseCategory.issueKpi;
                        driver=thisCaseCategory.issueDriver;
                        accountability=thisCaseCategory.issueAccountability;
                    }
                    if (thisCaseCategory.locationId!=null && thisCaseCategory.locationId.length()>=15) thisLocationTaxo=taxonomies.get(thisCaseCategory.locationId);
                    if (thisIssueTaxo!=null && thisIssueTaxo.Agency__c!=null && thisIssueTaxo.Agency__c.length()>1){
                        agency=thisIssueTaxo.Agency__c;
                    }else if (thisLocationTaxo !=null && thisLocationTaxo.Agency__c!=null && thisLocationTaxo.Agency__c.length()>1){
                        agency=thisLocationTaxo.Agency__c;
                    }else if (thisIssueTaxo==null && thisLocationTaxo==null && thisCaseCategory.issueAgency!=null && thisCaseCategory.issueAgency.length()>1){
                        agency=thisCaseCategory.issueAgency;
                    }else if (thisIssueTaxo==null && thisLocationTaxo==null && thisCaseCategory.locationAgency!=null && thisCaseCategory.locationAgency.length()>1){
                        agency=thisCaseCategory.locationAgency;
                    }
                    if( thisCaseCategory.mode.equals(GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE)){
                        thisCase.assigned_SME__c=null;//deleting sme accountability in multi issue parent
                        agency=null;
                        thisCase.Agency__c= null;
                    }
                    
                    if(thisCaseCategory.subject==null && thisCaseCategory.mode==null && thisCaseCategory.location==null && thisCaseCategory.issue==null && thisCaseCategory.type==null) continue;
                    if(thisCaseCategory.subject==thisCase.subject && thisCaseCategory.mode==thisCase.Modes__c && thisCaseCategory.locationId==thisCase.Taxonomy_Location_Id__c && thisCaseCategory.issueId==thisCase.Taxonomy_Symptom_Id__c && thisCaseCategory.type==thisCase.Type) continue;
                    thisCase.subject=thisCaseCategory.subject;
        
                    thisCase.Taxonomy_Location_Type__c=thisCaseCategory.grandlocation;
                    thisCase.Taxonomy_Area__c=thisCaseCategory.parentlocation;
                    thisCase.Taxonomy_Moment__c=thisCaseCategory.grandIssue;
                    thisCase.Taxonomy_Transaction__c=thisCaseCategory.parentIssue;
                    
                    thisCase.Taxonomy_Symptom__c=thisCaseCategory.issue;
                    thisCase.Taxonomy_Symptom_Id__c=(thisCaseCategory.issueId!=null && thisCaseCategory.issueId.length()>=15)?thisCaseCategory.issueId:NULL;
                    thisCase.Taxonomy_Location__c=thisCaseCategory.location;

                    thisCase.Taxonomy_Location_Id__c=(thisCaseCategory.locationId!=null && thisCaseCategory.locationId.length()>=15)?thisCaseCategory.locationId:NULL;
                    thisCase.Modes__c=thisCaseCategory.mode;

                    thisCase.KPI__c=kpi;
                    thisCase.Key_Driver__c=driver;
                    thisCase.Taxonomy_Accountability__c=accountability;
                    thisCase.Type=thisCaseCategory.type;
                    thisCase.Agency__c=agency ;
                    thisCase.Is_Reassigned__c = false;
                }

                if((updateCases.size()+caseForInsert.size())>1){
                    Case pc=updateCases.get(parentcase.id);
                    if (pc!=null) {
                        pc.Modes__c=GlobalConstants.CASE_MULTIISSUE_MODE;
                        pc.Type= GlobalConstants.MULTI_ISSUE_TYPE;
                    }
                }else{
                    for (Case aCase:updateCases.values()) aCase.multiAgency__c=false;
                    for (Case aCase:caseForInsert) aCase.multiAgency__c=false;
                }

                system.debug('---@Categorisation Updated Cases- '+JSON.serialize(updateCases.values()));
                update updateCases.values();
            }

            if (caseForInsert.size()>0) {

                system.debug('---@Categorisation Inserted Cases- '+JSON.serialize(caseForInsert));
                //Parent case updated before this also invokes CaseCustomRollUpImpl before hand and turns flag counterUpdated on
                CaseCustomRollUpImpl.counterUpdated=false;
                insert caseForInsert;
                
            }
            ApplicationLogUtility.logMessage(GlobalConstants.DEBUG,
                                    'IssueItemisationPublisherAction_CX',
                                    'updateCategories',
                                    'updated case categories',
                                    null,
                                    null,
                                    null,
                                    null,
                                    null,
                                    null);
        }catch (Exception e){
            system.debug('caught exception'+e.getMessage()+e.getStackTraceString());
            ApplicationLogMessage lm = new ApplicationLogMessage();
            lm.source='IssueItemisationPublisherAction_CX';
            lm.sourceFunction='updateCategories';
            
            lm.logMessage=e.getMessage();
            lm.ex=e;
            lm.debugLevel=GlobalConstants.ERROR;
            
            lms.add(lm);
            throw e;
        }finally{
            ApplicationLogUtility.logMessage(lms);
        }
        
    }

    @RemoteAction
    global static void deleteEx(string caseId){
        Set<String> agencies=new Set<String> ();
        Case deleted=[select Id , multiAgency__c, Agency__c,parent.Id,parent.multiAgency__c , parent.Child_Cases_Count__c,parent.Agency__c from Case where Id=:caseId ];
        delete deleted;
        system.debug('---@Categorisation DeleteEx----' + deleted.Id);
    }

    @RemoteAction
    global static List<CaseCategory> getChildCaseIssues(string parentCaseId){
        system.debug('---@Categorisation Get Child Case Issues Method Called----');
        List<CaseCategory> result= new List<CaseCategory>();
        List<Case> resultCases= new List<Case> ();
        resultCases.add([select Id,ParentId, Agency__c,modes__c, Taxonomy_Location__c, subject, Taxonomy_Symptom__c, Taxonomy_Location_Id__c,  Taxonomy_Symptom_Id__c,Type 
                        , Taxonomy_Symptom_Id__r.Id, Taxonomy_Symptom_Id__r.Name,  Taxonomy_Symptom_Id__r.Parent_Id__c,   Taxonomy_Symptom_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Status_Staff_Facing__c,  Taxonomy_Symptom_Id__r.Issue_Accountability__c, Taxonomy_Symptom_Id__r.Type__c
                        ,Taxonomy_Symptom_Id__r.Parent_Id__r.Id, Taxonomy_Symptom_Id__r.Parent_Id__r.Name, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Symptom_Id__r.Parent_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        
                        , Taxonomy_Location_Id__r.Id, Taxonomy_Location_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.KPI__c, Taxonomy_Location_Id__r.Driver__c, Taxonomy_Location_Id__r.Status_Staff_Facing__c,  Taxonomy_Location_Id__r.Issue_Accountability__c, Taxonomy_Location_Id__r.Type__c
                        ,Taxonomy_Location_Id__r.Parent_Id__r.Id, Taxonomy_Location_Id__r.Parent_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.Parent_Id__r.KPI__c, Taxonomy_Location_Id__r.Parent_Id__r.Driver__c, Taxonomy_Location_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Location_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        
                        from Case where Id=:parentCaseId]);
        
        system.debug('---@Categorisation Result Case----' + resultCases.size());

        resultCases.addAll([select Id,ParentId,Agency__c, modes__c, Taxonomy_Location__c, subject, Taxonomy_Symptom__c, Taxonomy_Location_Id__c,  Taxonomy_Symptom_Id__c ,Type
                        , Taxonomy_Symptom_Id__r.Id, Taxonomy_Symptom_Id__r.Name,  Taxonomy_Symptom_Id__r.Parent_Id__c,   Taxonomy_Symptom_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Status_Staff_Facing__c,  Taxonomy_Symptom_Id__r.Issue_Accountability__c, Taxonomy_Symptom_Id__r.Type__c
                        ,Taxonomy_Symptom_Id__r.Parent_Id__r.Id, Taxonomy_Symptom_Id__r.Parent_Id__r.Name, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Symptom_Id__r.Parent_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Symptom_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        
                        , Taxonomy_Location_Id__r.Id, Taxonomy_Location_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.KPI__c, Taxonomy_Location_Id__r.Driver__c, Taxonomy_Location_Id__r.Status_Staff_Facing__c,  Taxonomy_Location_Id__r.Issue_Accountability__c, Taxonomy_Location_Id__r.Type__c
                        ,Taxonomy_Location_Id__r.Parent_Id__r.Id, Taxonomy_Location_Id__r.Parent_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.Parent_Id__r.KPI__c, Taxonomy_Location_Id__r.Parent_Id__r.Driver__c, Taxonomy_Location_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Location_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        ,Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Id, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Taxonomy_Location_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                        
                        from Case where ParentId=:parentCaseId]);

        system.debug('---@Categorisation Result Case----' + resultCases.size());

        for(Case child:resultCases){

            CaseCategory childCategory= new CaseCategory();

            Taxonomy_Metadata__c metaLocation;
            Taxonomy_Metadata__c metaLocationParent;
            Taxonomy_Metadata__c metaLocationGrand;
            childCategory.type=child.Type==null?'':child.Type;
            childCategory.issueAgency=child.Agency__c==null?'': child.Agency__c;
            childCategory.locationAgency=child.Agency__c==null?'': child.Agency__c;

            Taxonomy_Metadata__c metaMode;
            if (null!=child.Taxonomy_Location_Id__r){
                metaLocation=child.Taxonomy_Location_Id__r;
                childCategory.locationId = metaLocation.Id;

                if(metaLocation.Parent_Id__r!=null) {
                    metaLocationParent=metaLocation.Parent_Id__r;
                    childCategory.parentlocation =metaLocationParent.name ;
                    childCategory.parentlocationId =metaLocationParent.Id;
                    if(metaLocationParent.Parent_Id__r!=null){
                        metaLocationGrand=metaLocationParent.Parent_Id__r;
                        childCategory.grandlocation =metaLocationGrand.name ;

                        if (metaLocationGrand.Parent_Id__r!=null) {
                            metaMode=metaLocationGrand.Parent_Id__r;
                            childCategory.modeId=metaMode.Id;

                        }else{
                            childCategory.modeId='';
                        }

                    }else{
                        childCategory.grandlocation ='';

                    } 
                }else{
                    childCategory.parentlocation ='' ;
                    childCategory.parentlocationId ='';
                }
            }else{
                childCategory.locationId = '';
            }

            Taxonomy_Metadata__c metaIssue;
            Taxonomy_Metadata__c metaIssueParent;
            Taxonomy_Metadata__c metaIssueGrand;
            if (null!=child.Taxonomy_Symptom_Id__r){
                metaIssue=child.Taxonomy_Symptom_Id__r;
                childCategory.issueId =metaIssue.Id;
                childCategory.issueKpi =metaIssue.KPI__c ;
                childCategory.issueDriver =metaIssue.Driver__c ;
                childCategory.issueAccountability =metaIssue.Issue_Accountability__c ;
                if(metaIssue.Parent_Id__r!=null) {
                    metaIssueParent=metaIssue.Parent_Id__r;
                    childCategory.parentIssue =metaIssueParent.name ;
                    childCategory.parentIssueId =metaIssueParent.Id  ;
                    if(metaIssueParent.Parent_Id__r!=null) {
                        metaIssueGrand=metaIssueParent.Parent_Id__r;
                        childCategory.grandIssue =metaIssueGrand.name ;

                    }else{
                        childCategory.grandIssue ='' ;

                    }
                }else{
                    childCategory.parentIssue ='';
                    childCategory.parentIssueId =''  ;
                }
            }else{
                childCategory.issueId ='';
                childCategory.issueKpi ='';
                childCategory.issueDriver ='';
                childCategory.issueAccountability ='';
            }
            
            childCategory.mode = child.modes__c==null?'':child.modes__c;
            childCategory.location = child.Taxonomy_Location__c==null?'':child.Taxonomy_Location__c;
            childCategory.issue = child.Taxonomy_Symptom__c==null?'':child.Taxonomy_Symptom__c;
            childCategory.caseId = child.Id==null?'':child.Id;
            childCategory.subject = child.subject==null?'':child.subject;
            childCategory.parent = child.ParentId==null?'':child.ParentId;
       
            result.add(childCategory);
        }
        return result;
    }
}