public without sharing class ActionPlanUtility {
    public static set <String> skipStatuses = new set <String> {GlobalConstants.ACTION_PLAN_NEW_STATUS, 
                                                                 GlobalConstants.ACTION_PLAN_CLOSED_STATUS, 
                                                                 GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT};
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com 
    Description:  This method will return a map parent case and its no of 
                  child action plans which are not closed
    
    History
    01/06/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    public static map <Id, Integer> createCaseVsNoOfActionPlansMap(list <Action_Plan__c> actionPlans, set <Id> parent_CaseIds) {
        set <Id> parentCaseIds = new set <Id>();
        
        if(parent_CaseIds != null) {
            parentCaseIds.addAll(parent_CaseIds);
        }
        
        map <Id, Integer> parentVsChildCount = new map <Id, Integer>();
        if(actionPlans != null) {
            for(Action_plan__c anAp : actionPlans) {
                if(anAp.Parent_Case__c != null 
                    && anAp.RecordTypeId != Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME)) {
                    parentCaseIds.add(anAp.Parent_Case__c);
                }
             }
        }
         
         for(AggregateResult agResult : [Select COUNT(ID) childAps, Parent_Case__c parent 
                                         From Action_Plan__c 
                                         Where Parent_Case__c IN : parentCaseIds 
                                           And Status__c NOT IN: skipStatuses
                                         Group By Parent_Case__c] ) {
            parentVsChildCount.put((Id) agResult.get('parent'), 
                                    Integer.valueOf(agResult.get('childAps')));
         }
         system.debug('-------parentVsChildCount1--------' + parentVsChildCount);
         return parentVsChildCount;
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:  This method will return a map parent Action Plan and its no of 
                  child action plans which are not closed
    
    History
    01/06/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    public static map <Id, Integer> createApVsNoOfChildActionPlansMap(list <Action_Plan__c> actionPlans, set <Id> parent_ActionPlanIds) {
        set <Id> parentActionPlanIds = new set <Id>();
        
        if(parent_ActionPlanIds != null) {
            parentActionPlanIds.addAll(parent_ActionPlanIds);
        }
        
        map <Id, Integer> parentVsChildCount = new map <Id, Integer>();
        if(actionPlans != null) {
            for(Action_plan__c anAp : actionPlans) {
                if(anAp.Parent_Action_Plan__c != null 
                    && anAp.RecordTypeId != Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME)) {
                    parentActionPlanIds.add(anAp.Parent_Action_Plan__c);
                }
             }
        }
         
         for(AggregateResult agResult : [Select COUNT(ID) childAps, Parent_Action_Plan__c parent 
                                         From Action_Plan__c 
                                         Where Parent_Action_Plan__c IN : parentActionPlanIds 
                                           And Status__c NOT IN: skipStatuses
                                         Group By Parent_Action_Plan__c] ) {
            parentVsChildCount.put((Id) agResult.get('parent'), 
                                    Integer.valueOf(agResult.get('childAps')));
         }
         system.debug('-------parentVsChildCount2--------' + parentVsChildCount);
         return parentVsChildCount;
    }

    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com 
    Description:  This method will return a map parent case and its no of 
                  child action plans which are not closed
    
    History
    01/06/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    public static map <Id, Integer> createCaseVsNoOfActionPlansMap(list <Action_Plan__c> actionPlans) {
        set <Id> parentCaseIds = new set <Id>();
        map <Id, Integer> parentVsChildCount = new map <Id, Integer>();
        if(actionPlans != null) {
            for(Action_plan__c anAp : actionPlans) {
                if(anAp.Parent_Case__c != null 
                    && anAp.RecordTypeId != Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME)) {
                    parentCaseIds.add(anAp.Parent_Case__c);
                }
             }
        }
         
        for(AggregateResult agResult : [Select COUNT(ID) childAps, Parent_Case__c parent 
                                        From Action_Plan__c 
                                        Where Parent_Case__c IN : parentCaseIds 
                                        And Status__c NOT IN: skipStatuses
                                        Group By Parent_Case__c] ) {
            parentVsChildCount.put((Id) agResult.get('parent'), Integer.valueOf(agResult.get('childAps')));
        }
        
        if(actionPlans != null) {
            for(Action_plan__c anAp : actionPlans) {
                if(anAp.Parent_Case__c != null 
                    && anAp.RecordTypeId != Action_PlanTriggerDispatcher.actionPlanRecordTypes.get(GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME)
                    && !parentVsChildCount.containsKey(anAp.Parent_Case__c)) {
                    parentVsChildCount.put(anAp.Parent_Case__c, 0);
                }
             }
        }
            
        system.debug('-------parentVsChildCount3--------' + parentVsChildCount);
        return parentVsChildCount;
    }
    
    /*------------------------------------------------------------
    Author:      Manish Damle
    Company:     Arxxus.com 
    Description: This method will calculate the due date on the action plan.
                 Agency = RMS 
                 Priority = Individual 
                 Due Date : 13 days : Action Plan created date(incl) + 13 
                 Priority = MP 
                 Due Date : 10 days : Action Plan created date + 10 
                
                All other agency/division : Action Plan created date + 8 days    
                
    History
    13/10/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    public static void stampDueDateOnActionPlan(list <Action_Plan__c> actionPlans) {
        if(actionPlans == null)
            return;
        
        for(Action_Plan__c ap: actionPlans) {
            if(ap.Parent_Action_Plan__c != null)
                continue;
            Decimal bh; 
            System.debug('---@Due Date Calculation Agency---' + ap.Agency__c);
            System.debug('---@Due Date Calculation Priority---' + ap.CasePriority__c);
            if(ap.Agency__c == GlobalConstants.RMS_AGENCY) {
                if(ap.CasePriority__c == GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD) {
                    bh = BusinessHoursUtil.getActionPlanDueDateBh(GlobalConstants.RMS_PRIORITY_INDIVIDUAL_STANDARD);
                } else if(ap.CasePriority__c == GlobalConstants.CASE_PRIORITY_MP_STANDARD) {
                    bh = BusinessHoursUtil.getActionPlanDueDateBh(GlobalConstants.RMS_PRIORITY_MP_STANDARD);
                } else {
                    //ap.Due_Date__c = null;
                    bh = null;
                }
            } else {
                bh = BusinessHoursUtil.getActionPlanDueDateBh(GlobalConstants.DEFAULTBH);
            }
            System.debug('---@Due Date Calculation Business Hours---' + bh);
            if(bh != null) {
                ap.Due_Date__c = ap.Due_Date__c == null ? BusinessHoursUtil.getActionPlanDueDate(ap.BusinessHours__c, 
                                                                                             (ap.Id != null ? ap.CreatedDate.date() : Date.today()),
                                                                                             bh) : ap.Due_Date__c;
            }
            System.debug('---@Due Date Calculation Date Stamped---' + ap.Due_Date__c);
        }
    }
}