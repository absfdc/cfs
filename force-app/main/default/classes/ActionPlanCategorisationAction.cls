/*------------------------------------------------------------
Author:        Vishnu Belkone
Company:       Arxxus.com
Description:   A Action_Plan__c controller extension for Action_Plan__c categorisation publisher action

Test Class:    EmailMessageTriggerDispatcher_Test
History
13 May 2015      Vishnu Belkone     created
------------------------------------------------------------*/
global with sharing class ActionPlanCategorisationAction {
    global static Final string LOCATION_TYPE='Location';
    global static Final string ISSUE_TYPE='Issue';
    global static Final string STAFF_FACING='Active';
    global static Final string ROOT_PARENT='#';
    global static Final string MODE_TYPE='Mode';
    global static Final string APOSTROPHE = '&#39;';
    public Action_Plan__c actionPlan{get;set;}
    public string caseDescription{get;set;}
    public ActionPlanCategorisationAction (ApexPages.StandardController controller){
        if(!test.isRunningTest()) controller.addFields(new List<String>{'Case_Description__c'});
         actionPlan = (Action_Plan__c) controller.getRecord();
       
        actionPlan = [select id,name,Case_Description__c from action_plan__c where id = :actionPlan.Id ];
        
        system.debug('#actionPlan.Case_Description__c'+actionPlan.Case_Description__c);
        system.debug('#Decoded actionPlan.Case_Description__c'+actionPlan.Case_Description__c);
        
        if(actionPlan.Case_Description__c != NULL){
            caseDescription = HTMLRemover.remove(actionPlan.Case_Description__c);
            system.debug('#caseDescription'+caseDescription);
            
            caseDescription = caseDescription.replace(APOSTROPHE,'\'');
            system.debug('#current Reccord'+actionPlan);
        }
    }
    
   
    
    /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   This method returns the list of modes of transport

    History
    13 May 2015       Vishnu Belkone     created
    ------------------------------------------------------------*/

    @RemoteAction
    global static List<Node> getModes(string actionPlaId) {
        StateChecker locater;
        if(null!=actionPlaId && actionPlaId.length()>=15){
             actionPlaId=String.escapeSingleQuotes(actionPlaId);
            Action_Plan__c actionPlan=[select Id, Mode__c,Parent_Case__c from Action_Plan__c where Id=:actionPlaId];
            locater= new ModeChecker(actionPlan);
        }
        List<Taxonomy_Metadata__c> modes=[select Id,Parent_Id__c,Status_Staff_Facing__c, name, Parent_Id__r.Type__c from  Taxonomy_Metadata__c where Status_Staff_Facing__c=:STAFF_FACING and Type__c=:MODE_TYPE ];
        if (null==modes) return null;
        return getNodes(modes,locater);

    }
     /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   Inner bean class represents the data for a Node

    History
    13 May 2015       Vishnu Belkone     created
    ------------------------------------------------------------*/
    global class Node{
        public String id {get;set;}//every node is given an unique id
        public String parent {get;set;}// will be used for placement within hierarchy
        public String text {get;set;}//what will be displayed on the UI
        public State state{get;set;}//selected etc

    }
     /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   Inner bean class represents the state of a Node

    History
    13 May 2015       Vishnu Belkone     created
    ------------------------------------------------------------*/
    global class State{
        public Boolean selected {get;set;}
        public Boolean opened {get;set;}
    }
    /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   Interface for checking and obtaining the state
                    of the node, based on past selections, persisted on case

    History
    13 May 2015       Vishnu Belkone     created
    ------------------------------------------------------------*/
    @TestVisible
    interface StateChecker{
        State getState(Taxonomy_metadata__c taxonomy);
    }
     /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   This method returns the list of type picklist entry from the Taxonomy metadata

    History
    13 May 2015       Vishnu Belkone     created
    ------------------------------------------------------------*/
    
    @TestVisible
    class LocationChecker implements StateChecker{
        Action_Plan__c thisAp;
        public LocationChecker(Action_Plan__c thisAp){
            this.thisAp=thisAp;
        }
        public virtual State getState (Taxonomy_metadata__c taxonomy){
            State thisState;
            if (thisAp!=null ){
                
                if (thisAp.Location_Level_3_Id__c!=null && taxonomy.id==thisAp.Location_Level_3_Id__c){
                    thisState= new State();
                    thisState.selected=true;
                }else if(thisAp.Location_Level_3_Id__c==null ){
                    if(thisAp.Location_Level_2__c!=null && !String.isEmpty(thisAp.Location_Level_2__c) && taxonomy.name.equalsIgnoreCase(thisAp.Location_Level_2__c)){
                        thisState= new State();
                        thisState.selected=false;
                        thisState.opened=true;
                    }else if (thisAp.Location_Level_2__c==null ||String.isEmpty(thisAp.Location_Level_2__c)){
                        if(thisAp.Location_Level_1__c!=null && !String.isEmpty(thisAp.Location_Level_1__c) && taxonomy.name.equalsIgnoreCase(thisAp.Location_Level_1__c)){
                            thisState= new State();
                            thisState.selected=false;
                            thisState.opened=true;
                        }else if(thisAp.Location_Level_1__c==null || String.isEmpty(thisAp.Location_Level_1__c)){
                            if(thisAp.mode__c!=null && !String.isEmpty(thisAp.mode__c) && taxonomy.name.equalsIgnoreCase(thisAp.mode__c)){
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
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   Concrete implementation for checking and obtaining the state
                    of any issue, based on past selections, persisted on case

    History
    9 Apr 2015      Vishnu Belkone     created
    ------------------------------------------------------------*/
    @TestVisible
    class IssueChecker implements StateChecker{
        Action_Plan__c thisAp;
        public IssueChecker(Action_Plan__c thisAp){
            this.thisAp=thisAp;
        }
        public virtual State getState(Taxonomy_metadata__c taxonomy){
            State thisState;
            if (thisAp!=null && thisAp.Issue_Level_3_Id__c!=null && taxonomy.id==thisAp.Issue_Level_3_Id__c){
                thisState= new State();
                thisState.selected=true;

            }else if(thisAp.Issue_Level_3_Id__c==null ){
                if(thisAp.Issue_Level_2__c!=null && !String.isEmpty(thisAp.Issue_Level_2__c) && taxonomy.name.equalsIgnoreCase(thisAp.Issue_Level_2__c)){
                    thisState= new State();
                    thisState.selected=false;
                    thisState.opened=true;
                }else if (thisAp.Issue_Level_2__c==null ||String.isEmpty(thisAp.Issue_Level_2__c)){
                    if(thisAp.Issue_Level_1__c!=null && !String.isEmpty(thisAp.Issue_Level_1__c) && taxonomy.name.equalsIgnoreCase(thisAp.Issue_Level_1__c)){
                        thisState= new State();
                        thisState.selected=false;
                        thisState.opened=true;
                    }else if(thisAp.Issue_Level_1__c==null || String.isEmpty(thisAp.Issue_Level_1__c)){
                        if(thisAp.mode__c!=null && !String.isEmpty(thisAp.mode__c) && taxonomy.name.equalsIgnoreCase(thisAp.mode__c)){
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
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   Concrete implementation for checking and obtaining the state
                    of any mode, based on past selections, persisted on case

    History
    9 Apr 2015      Vishnu Belkone     created
    ------------------------------------------------------------*/
    @TestVisible
    class ModeChecker implements StateChecker{
        Action_Plan__c thisAp;
        public ModeChecker(Action_Plan__c thisAp){
            this.thisAp=thisAp;
        }
        public virtual State getState(Taxonomy_metadata__c taxonomy){
            State thisState;
            if (thisAp!=null && thisAp.Mode__c!=null && !String.isEmpty(thisAp.Mode__c) && taxonomy.name.equalsIgnoreCase(thisAp.Mode__c) ){
                thisState= new State();
                thisState.selected=true;

            }
            return thisState;
        }
    }

   

    /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   remoteaction to obtain the list of Locations
                    caseid used to check if some issue was already persisted
                    mode based on which the Locations are fetched

    History
    9 Apr 2015      Vishnu Belkone     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static List<Node> getLocations(string actionPlanId,String modeId) {
        StateChecker locater;
        modeId=String.escapeSingleQuotes(modeId);

        if(null!=actionPlanId && actionPlanId.length()>=15){
            actionPlanId=String.escapeSingleQuotes(actionPlanId);
             Action_Plan__c actionPlan=[select Id,Case_Description__c,mode__c,Issue_Level_1__c,Issue_Level_2__c,Issue_Level_3__c,Issue_Level_3_Id__c,Location_Level_1__c,Location_Level_2__c,Location_Level_3__c,Location_Level_3_Id__c from Action_Plan__c where id =:actionPlanId];
            locater= new LocationChecker(actionPlan);

        }

        
        List<Taxonomy_Metadata__c> locations=[select Id,name,Parent_Id__c,Status_Staff_Facing__c,Parent_Id__r.Type__c,Agency__c from  Taxonomy_Metadata__c where Status_Staff_Facing__c=:STAFF_FACING and Type__c=:LOCATION_TYPE 
                                                and (Parent_Id__r.Parent_Id__r.Parent_Id__c=:modeId or
                                                Parent_Id__r.Parent_Id__c=:modeId or Parent_Id__c=:modeId) Limit 10000];
        if (null==locations) return null;
        return getNodes(locations,locater);

    }

    /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   This method returns the list of nodes taking
    Inputs:        List of taxonomy be it Location or issue
                    and the corresponding checker

    History
    9 Apr 2015      Vishnu Belkone     created
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
            if (aTaxonomy.Parent_Id__c==null || aTaxonomy.Parent_Id__r.Type__c==MODE_TYPE) {
                
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
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   This method returns the list of Issues
    Inputs:        caseid used to check if some issue was already persisted
                    mode based on which the Issues are fetched

    History
    9 Apr 2015      Vishnu Belkone     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static List<Node> getIssues(string actionPlanId,String modeId) {
        modeId=String.escapeSingleQuotes(modeId);
        StateChecker issueCheck;
        if(null!=actionPlanId  && actionPlanId.length()>=15){
            actionPlanId=String.escapeSingleQuotes(actionPlanId);
             Action_Plan__c actionPlan=[select Id,Case_Description__c,mode__c,Issue_Level_1__c,Issue_Level_2__c,Issue_Level_3__c,Issue_Level_3_Id__c,Location_Level_1__c,Location_Level_2__c,Location_Level_3__c,Location_Level_3_Id__c from Action_Plan__c where id =:actionPlanId];
            issueCheck= new IssueChecker(actionPlan);

        }
        List<Taxonomy_Metadata__c> issues=[select Id,name,Parent_Id__c,Status_Staff_Facing__c,Parent_Id__r.Type__c,Agency__c from  Taxonomy_Metadata__c where Status_Staff_Facing__c=:STAFF_FACING and Type__c=:ISSUE_TYPE and (Parent_Id__r.Parent_Id__r.Parent_Id__c=:modeId or
                                                Parent_Id__r.Parent_Id__c=:modeId or Parent_Id__c=:modeId) Limit 10000];
        if (null==issues) return null;
        return getNodes(issues,issueCheck);
    }

    /*------------------------------------------------------------
    Author:        Vishnu Belkone
    Company:       Arxxus.com
    Description:   This method updates the case
    Inputs:        caseid, description,mode,location,issue

    History
    9 Apr 2015      Vishnu Belkone     created
    ------------------------------------------------------------*/
    @RemoteAction
    global static void updateEx(string actionPlanId,String description,String mode,String location,String locationId,String issue,String issueId,String parentIssue,String parentLocation,String grandIssue,String grandLocation, String type) {
        List<ApplicationLogMessage> lms = new List<ApplicationLogMessage>();
        try{
            actionPlanId=String.escapeSingleQuotes(actionPlanId);
            Action_Plan__c actionPlan = [select Id,Case_Description__c,mode__c,Issue_Level_1__c,Issue_Level_2__c,Issue_Level_3__c,Issue_Level_3_Id__c,Location_Level_1__c,Location_Level_2__c,Location_Level_3__c,Location_Level_3_Id__c,Type__c from Action_Plan__c where id =:actionPlanId];
            
            if(description==null && mode==null && location==null && issue==null && type==null ) return;
            if( description==actionPlan.Case_Description__c && mode==actionPlan.Mode__c && location==actionPlan.Location_Level_3__c && issue==actionPlan.Issue_Level_3__c  ) return;
            actionPlan.Case_Description__c=description;
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
            system.debug('taxomyIds - '+taxomyIds);
            if (taxomyIds.size()>0){
                taxonomies=[SELECT Agency__c,Type__c,Id, Name, Parent_Id__c, KPI__c, Driver__c, Status_Staff_Facing__c,  Issue_Accountability__c, 
                            Parent_Id__r.Agency__c,Parent_Id__r.Type__c,Parent_Id__r.Id, Parent_Id__r.Name, Parent_Id__r.Parent_Id__c, Parent_Id__r.KPI__c, Parent_Id__r.Driver__c, Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Issue_Accountability__c,
                            Parent_Id__r.Parent_Id__r.Agency__c,Parent_Id__r.Parent_Id__r.Type__c,Parent_Id__r.Parent_Id__r.Id, Parent_Id__r.Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Parent_Id__c, Parent_Id__r.Parent_Id__r.KPI__c, Parent_Id__r.Parent_Id__r.Driver__c, Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Parent_Id__r.Issue_Accountability__c,
                            Parent_Id__r.Parent_Id__r.Parent_Id__r.Agency__c,Parent_Id__r.Parent_Id__r.Parent_Id__r.Type__c,Parent_Id__r.Parent_Id__r.Parent_Id__r.Id, Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Parent_Id__r.Parent_Id__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.KPI__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Driver__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Status_Staff_Facing__c, Parent_Id__r.Parent_Id__r.Parent_Id__r.Issue_Accountability__c
                            FROM Taxonomy_Metadata__c where Id=:taxomyIds];
                for (Taxonomy_Metadata__c taxonomy:taxonomies){
                    Taxonomy_Metadata__c parent=taxonomy.Parent_Id__r;
                    Taxonomy_Metadata__c grand=parent.Parent_Id__r;
                    Taxonomy_Metadata__c modeMetadata;
                    if(grand.Parent_Id__r!=null ){
                        modeMetadata=grand.Parent_Id__r;
                    }else{
                        modeMetadata=parent.Parent_Id__r;
                    }
                    system.debug('parent - '+parent);
                    system.debug('grand - '+grand);
                    system.debug('mode - '+modeMetadata);


                    if (taxonomy.Type__c==LOCATION_TYPE) {
                        locationTaxonomy=taxonomy;
                        grandLocation=grand.name;
                        parentLocation=parent.name;

                        locationAccountability=locationTaxonomy.Issue_Accountability__c;
                        locationAgency=locationTaxonomy.Agency__c;
                    }else if (taxonomy.Type__c==ISSUE_TYPE){
                        issueTaxonomy=taxonomy;
                        grandIssue=grand.name;
                        parentIssue=parent.name;
                        issueAccountability=issueTaxonomy.Issue_Accountability__c;
                        issueKpi=issueTaxonomy.KPI__c;
                        issueDriver=issueTaxonomy.Driver__c;
                        issueAgency=issueTaxonomy.Agency__c;

                    } 
                    actionPlan.Mode__c=modeMetadata.name;
                }

            }
            
            
            

            actionPlan.Location_Level_1__c=grandLocation;
            actionPlan.Location_Level_2__c=parentLocation;
            actionPlan.Issue_Level_1__c=grandIssue;
            actionPlan.Issue_Level_2__c=parentIssue;
            if (!String.isEmpty(issueId)) actionPlan.Issue_Level_3_Id__c=issueId;

            if (!String.isEmpty(locationId)) actionPlan.Location_Level_3_Id__c=locationId;
            //actionPlan.KPI__c=issueKpi;
            //actionPlan.Key_Driver__c=issueDriver;
            actionPlan.Location_Level_3__c=location;
            actionPlan.Issue_Level_3__c=issue;
           
    //      actionPlan.Taxonomy_Accountability__c=issueAccountability!=NULL ? issueAccountability : locationAccountability;
            //actionPlan.Agency__c=issueAgency!=NULL ? issueAgency : locationAgency;

            update actionPlan;
            ApplicationLogMessage lm = new ApplicationLogMessage();
                lm.source='ActionPlanCategorisationAction';
                lm.sourceFunction='updateEx';
                
                lm.logMessage='updated ation plan  category Id- '+actionPlanId+'  \r\n description- '+description+'  \r\n mode- '+mode+'  \r\n location- '+location+'  \r\n issue- '+issue;
               
                lm.debugLevel=GlobalConstants.DEBUG;
                
                lms.add(lm);
           
            }catch(Exception e){
                ApplicationLogMessage lm = new ApplicationLogMessage();
                lm.source='ActionPlanCategorisationAction';
                lm.sourceFunction='updateEx';
                
                lm.logMessage=e.getMessage();
                lm.ex=e;
                lm.debugLevel=GlobalConstants.ERROR;
                
                lms.add(lm);
                throw e;
            }finally{
                ApplicationLogUtility.logMessage(lms);
            }
    }
}