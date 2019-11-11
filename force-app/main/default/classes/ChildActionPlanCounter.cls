public without sharing class ChildActionPlanCounter {

    private List<Action_Plan__c> childActionPlans;
    
    public ChildActionPlanCounter(List<Action_Plan__c> childActionPlans) {
        if(childActionPlans == null || childActionPlans.isEmpty()) {
            throw new InvalidDataException('Failed to count child action plan. Action Plan details missing');
        }
        this.childActionPlans = childActionPlans;
    }
    
    public void updateChildActionPlanCounter() {
        Map<Id, Action_Plan__c> parentIdVsActionPlan = retrieveParentActionPlan();
                
        List<AggregateResult> results = [   SELECT COUNT(Id) childCount, Parent_Action_Plan__c parent 
                                            FROM Action_Plan__c 
                                            WHERE Parent_Action_Plan__c IN :parentIdVsActionPlan.keySet()
                                            GROUP BY Parent_Action_Plan__c];
                                            
        for(AggregateResult result : results) {
            Action_Plan__c parent = parentIdVsActionPlan.get((Id) result.get('parent'));
            parent.Child_Action_Plans__c = Integer.valueOf(result.get('childCount'));
            parentIdVsActionPlan.put(parent.Id, parent);
        }
        
        List<AggregateResult> completedResults = [  SELECT COUNT(Id) childCount, Parent_Action_Plan__c parent 
                                                    FROM Action_Plan__c 
                                                    WHERE Parent_Action_Plan__c IN :parentIdVsActionPlan.keySet()
                                                        AND Status__c = :GlobalConstants.ACTION_PLAN_CLOSED_STATUS
                                                    GROUP BY Parent_Action_Plan__c];
                                            
        for(AggregateResult result : completedResults) {
            Action_Plan__c parent = parentIdVsActionPlan.get((Id) result.get('parent'));
            parent.Completed_Child_Action_Plans__c = Integer.valueOf(result.get('childCount'));
            parentIdVsActionPlan.put(parent.Id, parent);
        }
        
        if(!parentIdVsActionPlan.isEmpty()) {
            update parentIdVsActionPlan.values();
        }
    }   
    
    private Map<Id, Action_Plan__c> retrieveParentActionPlan() {        
        Map<Id, Action_Plan__c> parentIdVsActionPlan = new Map<Id, Action_Plan__c>();
        
        for(Action_Plan__c childActionPlan : childActionPlans) {
            if(!String.isBlank(childActionPlan.Parent_Action_Plan__c)) {
                parentIdVsActionPlan.put(childActionPlan.Parent_Action_Plan__c, new Action_Plan__c(Id = childActionPlan.Parent_Action_Plan__c, Child_Action_Plans__c = 0, Completed_Child_Action_Plans__c = 0));
            }
        }
        return parentIdVsActionPlan;
    }
    
    public class InvalidDataException extends Exception {}
}