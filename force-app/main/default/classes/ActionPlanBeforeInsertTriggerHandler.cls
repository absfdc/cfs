/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    Action_PlanTriggerDispatcher_Test
History
26/05/2015     Manish Damle       Created
13/01/2017     Arxxus             Updated - to include new Minister_User__c field
------------------------------------------------------------*/
public without sharing class ActionPlanBeforeInsertTriggerHandler extends TriggerHandlerBase {
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    
    //SFCOE-8 - Start    
    private static Map<String,Decimal> actionPlanDueDateByAgencyMap;
    static{
        actionPlanDueDateByAgencyMap = new Map<String,Decimal>();
        for(ActionPlanDueDateByAgency__c actionPlanDueDateByAgency :ActionPlanDueDateByAgency__c.getall().values()){
            actionPlanDueDateByAgencyMap.put(actionPlanDueDateByAgency.Name,actionPlanDueDateByAgency.BusinessHours__c);
        }
        //Schema.Sobjecttype.Action_Plan__c.getRecordTypeInfosByName().get('CFM Action Plan').getRecordTypeId();
        
    }
    //SFCOE-8 - End    
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Handler function to copying all the child cases taxonomy details in
Instructions field.

History
26/05/2015     Manish Damle       Created
------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try {
            for (Action_plan__c anAp:(List<Action_plan__c>)tp.newList){                
                if(anAp.RecordTypeId == Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME) 
                   && anAp.AssignedSme__c != null ) {
                       anAp.ownerId = anAp.AssignedSme__c;
                       anAp.TempAssignedSme__c = anAp.AssignedSme__c;
                       anAp.AssignedSme__c = null;
                   }
                //set the business hrs if agency is populated
                if(anAp.Agency__c != null) anAp.BusinessHours__c = BusinessHoursUtil.getBusinessHour(anAp.Agency__c);
            }
            
            system.debug('---ActionPlanBeforeInsertTriggerHandler---');
            
            set <Id> parentCaseIds = new set <Id> ();
            for(Action_Plan__c ap : (list <Action_Plan__c>) tp.newList) {
                if(ap.Parent_Case__c != null) {
                    parentCaseIds.add(ap.Parent_Case__c );
                }
            }
            
            map <Id, Case> parentCases = new map <Id, Case>([Select Id, OwnerAgency__c, Child_Cases_Count__c, 
                                                             Taxonomy_Moment__c,Taxonomy_Transaction__c, 
                                                             Taxonomy_Location_Type__c, Taxonomy_Symptom__c, 
                                                             Taxonomy_Location__c, Taxonomy_Area__c ,
                                                             (Select Id, Child_Cases_Count__c, CaseNumber, 
                                                              Taxonomy_Moment__c,Taxonomy_Transaction__c, 
                                                              Taxonomy_Location_Type__c, Taxonomy_Symptom__c, 
                                                              Taxonomy_Location__c, Taxonomy_Area__c 
                                                              From Cases)
                                                             From Case 
                                                             Where Id In: parentCaseIds And RecordTypeId IN: CaseTriggerDispatcher.recordTypesMinCorro]);

            for(Action_Plan__c ap : (list <Action_Plan__c>) tp.newList) {
                if(ap.Parent_Case__c != null && parentCases.containsKey(ap.Parent_Case__c) && ap.Agency__c != GlobalConstants.RMS_AGENCY) {
                    list <Case> childCases = parentCases.get(ap.Parent_Case__c).cases;
                    if(childCases != null && childCases.size() > 0){
                        //Multi Issue Case Found
                        ap.Instructions__c = ap.Instructions__c == null ? '<b>MAGS Ministerial Correspondence Case Categorisation:</b><br/>' : ap.Instructions__c + '<br/><b>MAGS Ministerial Correspondence Case Categorisation:</b><br/>';
                        for(Case c: childCases) {
                            ap.Instructions__c += '<b>[' + c.CaseNumber + ']</b> ' + getTaxonomyData(c);
                        }
                    } else {
                        //Single issue case found
                        ap.Instructions__c = ap.Instructions__c == null ? ' <b>MAGS Ministerial Correspondence Case Categorisation:</b><br/>' : ap.Instructions__c + '<br/><b>MAGS Ministerial Correspondence Case Categorisation:</b>';
                        ap.Instructions__c += getTaxonomyData(parentCases.get(ap.Parent_Case__c));
                    }
                }
            }
            
            copyCategorisationFromParentAPToChildAP(tp);
            
            Map<Id, Case> parentCasesForCfm = new Map<Id, Case>([Select Id, Taxonomy_Moment__c,Taxonomy_Transaction__c, Taxonomy_Symptom_Id__c, Taxonomy_Location_Id__c, Agency__c,
                                                                 Taxonomy_Location_Type__c, Taxonomy_Symptom__c, Taxonomy_Location__c, Taxonomy_Area__c, Modes__c, IsMinCorroCase__c
                                                                 From Case
                                                                 Where Id In: parentCaseIds 
                                                                 And RecordTypeId Not IN: CaseTriggerDispatcher.recordTypesMinCorro]);
            
            if(!parentCasesForCfm.isEmpty()) {
                ActionPlanCategorizationForCfm categorizationSelector = new ActionPlanCategorizationForCfm ((List<Action_plan__c>) tp.newList, parentCasesForCfm);
                categorizationSelector.populateCategorizationDetails();
            }
            
            if(Action_PlanTriggerDispatcher.magsAndCrgsAdminRoles.containsKey(UserInfo.getUserRoleId())) {
                ActionPlanUtility.stampDueDateOnActionPlan((list <Action_plan__c>) tp.newList);
            }
            CaseAmendmentChecker amendmentChecker = new CaseAmendmentChecker((List<Action_Plan__c>) tp.newList);
            amendmentChecker.checkForAmendment();
            
            
            //SFCOE-1314 Populate Parent Case/AP Description if it exceeds 7000 characters - Start
            populateAPDescription(tp);
            //SFCOE-1314 - End
            
            //SFCOE-8 - 10-04-2018 - Set Default Due Date on Action Plan, If Record type = CFM Action Plan AND Agency = TfNSW, add 5 working days (not 8) for automatic Due Date - Start            
            updateDueDateOnTfNSWcfsAPs(tp.newList, parentCaseIds);
            //SFCOE-8 - End
            
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanBeforeInsertTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.oldMap!=null)  message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel='Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear(); 
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
    
    //SFCOE-8 - 10-04-2018 - Set Default Due Date on Action Plan, If Record type = CFM Action Plan AND Agency = TfNSW, add 5 working days (not 8) for automatic Due Date - Start
    private void updateDueDateOnTfNSWcfsAPs(List<Action_Plan__c> allAps, set <Id> parentCaseIds) {

        map <Id, Case> parentCases = new map <Id, case> ([Select Id, ownerAgency__c From case Where Id IN: parentCaseIds]);

        for(Action_Plan__c aAP:allAps){
            Case aparentCase;
            
            System.debug('aAp.RecordTypeId: ' + aAp.RecordTypeId);
            if(aAp.RecordTypeId == Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME)) {
                System.debug('ACTION_PLAN is CFM_Action_Plan.');
                System.debug('aAP.Parent_Case__c: ' + aAP.Parent_Case__c);
                if(aAP.Parent_Case__c != null && parentCases.containsKey(aAP.Parent_Case__c)) {
                    aparentCase = parentCases.get(aAP.Parent_Case__c);
                    if (aparentCase != null && aparentCase.OwnerAgency__c.equalsIgnoreCase(GlobalConstants.AGENCY_TFNSW)){
                        System.debug('Owner Agency on Parent Case is TFNSW.');
                        Id businessHourIdTfNSWId = BusinessHoursUtil.getBusinessHour(GlobalConstants.AGENCY_TFNSW);                    
                        Decimal bh = actionPlanDueDateByAgencyMap.get('TfNSWAP');

                        if(aAp.Due_Date__c == null){
                            aAp.Due_Date__c = BusinessHoursUtil.getActionPlanDueDate(businessHourIdTfNSWId, Date.today(), bh);
                            System.debug('aAp.Due_Date__c after update' + aAp.Due_Date__c);
                        }
                    } else {System.debug('Owner Agency is Not TfNSW.');}
                } else {System.debug('No parent case found.');}
                //if(aAp.Agency__c != null && aAp.Agency__c.equalsIgnoreCase(GlobalConstants.AGENCY_TFNSW)){
                //aAp.Due_Date__c = BusinessHoursUtil.getActionPlanDueDate(businessHourIdTfNSWId, aAp.Due_Date__c == null? Date.today():aAP.Due_Date__c, bh);
                //  }
            }  
        }
    }
    //SFCOE-8 - End
    
    private String getTaxonomyData(Case caseRecord) {
        String taxonomy = '';
        taxonomy += caseRecord.Taxonomy_Moment__c == null ? ' > ' : caseRecord.Taxonomy_Moment__c + ' > ';
        taxonomy += caseRecord.Taxonomy_Transaction__c == null ? ' > ' : caseRecord.Taxonomy_Transaction__c + ' > ';
        taxonomy += caseRecord.Taxonomy_Symptom__c == null? '' : caseRecord.Taxonomy_Symptom__c;
        return taxonomy + '<br/>';
    }
    
    /*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Copy parent action plan categorisation to the child action plan.

History
01/06/2015     Manish Damle       Created
------------------------------------------------------------*/    
    private void copyCategorisationFromParentAPToChildAP(TriggerParameters tp) {
        set <Id> parentActionPlanIds = new set <Id>();
        for (Action_plan__c anAp :(List<Action_plan__c>) tp.newList){
            if(anAp.Parent_Action_Plan__c != null)
                parentActionPlanIds.add(anAp.Parent_Action_Plan__c);                
        }
        
        map <Id, Action_Plan__c> parentActionPlans = new map <Id, Action_Plan__c> ([Select Id, Issue_Level_1__c,Issue_Level_2__c,Issue_Level_3__c,Product_Type__c,Agency__c,Divisions__c,Branch__c,
                                                                                    Mode__c, Location_Level_1__c,Location_Level_2__c, Location_Level_3__c,Minister__c, Minister_User__c, CasePriority__c,     
                                                                                    Customer__c,Referring_Mp__c,Classification__c, Case_Subject__c, Case_Description__c, OBO__c, MO_Instructions__c, Case_Creation_Date__c
                                                                                    From Action_Plan__c 
                                                                                    Where Id IN: parentActionPlanIds]);
        for (Action_plan__c anAp :(List<Action_plan__c>) tp.newList){
            if(anAp.Parent_Action_Plan__c != null && parentActionPlans.containsKey(anAp.Parent_Action_Plan__c)) {
                Action_plan__c parentAP = parentActionPlans.get(anAp.Parent_Action_Plan__c);
                anAp.Mode__c = parentAP.Mode__c;
                anAp.Issue_Level_1__c = parentAP.Issue_Level_1__c;
                anAp.Issue_Level_2__c = parentAP.Issue_Level_2__c;
                anAp.Issue_Level_3__c = parentAP.Issue_Level_3__c;
                anAp.Location_Level_1__c = parentAP.Location_Level_1__c;
                anAp.Location_Level_2__c = parentAP.Location_Level_2__c;
                anAp.Location_Level_3__c = parentAP.Location_Level_3__c;
                anAp.Product_Type__c = parentAP.Product_Type__c;
                anAp.Customer__c = parentAP.Customer__c;
                anAp.Referring_Mp__c = parentAP.Referring_Mp__c;
                anAp.Agency__c = parentAP.Agency__c;
                anAp.Minister__c = parentAP.Minister__c;
                anAp.Minister_User__c = parentAP.Minister_User__c;
                anAp.Divisions__c = parentAP.Divisions__c;
                anAp.Branch__c = parentAP.Branch__c;
                anAp.Classification__c = parentAP.Classification__c;
                anAp.Case_Subject__c = parentAp.Case_Subject__c;
                anAp.Case_Description__c = parentAp.Case_Description__c;
                anAp.CasePriority__c = parentAp.CasePriority__c;
                anAp.OBO__c = parentAp.OBO__c; 
                anAp.MO_Instructions__c = parentAp.MO_Instructions__c;
                anAp.Parent_Case_Creation_Date__c = parentAp.Case_Creation_Date__c;
            }
        }
    }
    
    
    
    
    
    //SFCOE-1314 Populate Parent Case/AP Description if it exceeds 7000 characters - Start
    //Check whether Parent is a case or an action plan, accordingly populate Description as required    
    private void populateAPDescription(TriggerParameters tp) {
        set <Id> parentActionPlanIds = new set <Id>();
        set <Id> parentCaseIds = new set <Id>();
        
        for (Action_plan__c anAp :(List<Action_plan__c>) tp.newList){
            if(anAp.Parent_Action_Plan__c != null)
                parentActionPlanIds.add(anAp.Parent_Action_Plan__c);                
        }
        
        for (Action_plan__c aAp :(List<Action_plan__c>) tp.newList){
            if(aAp.Parent_Case__c != null)
                parentCaseIds.add(aAp.Parent_Case__c);                
        }
        
        
        
        map <Id, Action_Plan__c> parentActionPlans = new map <Id, Action_Plan__c> ([Select Id, Case_Description__c From Action_Plan__c Where Id IN: parentActionPlanIds]);
        for (Action_plan__c anAp :(List<Action_plan__c>) tp.newList){
            System.debug('anAp.Case_Description__c:: ' + anAp.Case_Description__c);
            
            if(Label.Field_size_is_too_large.EqualsIgnoreCase(anAp.Case_Description__c)){
                if(anAp.Parent_Action_Plan__c != null && parentActionPlans.containsKey(anAp.Parent_Action_Plan__c)) {
                    Action_plan__c parentAP = parentActionPlans.get(anAp.Parent_Action_Plan__c);
                    anAp.Case_Description__c = parentAP.Case_Description__c;
                }
            }
        }//for
        
        
        map <Id, Case> parentCases = new map <Id, case> ([Select Id, description From case Where Id IN: parentCaseIds]);
        for (Action_plan__c anAp :(List<Action_plan__c>) tp.newList){
            System.debug('anAp.Case_Description__c:: ' + anAp.Case_Description__c);
            
            if(Label.Field_size_is_too_large.EqualsIgnoreCase(anAp.Case_Description__c)){
                if(anAp.Parent_Case__c != null && parentCases.containsKey(anAp.Parent_Case__c)) {
                    Case parentCase = parentCases.get(anAp.Parent_Case__c);
                    anAp.Case_Description__c = parentCase.description;
                }
            }
        }//for
        
        
        
    }
    
    //SFCOE-1314 - End
    
}