public with sharing class ActionPlanCategorizationForCfm {

    private Map<Id, Case> caseDetails;
    private List<Action_Plan__c> actionPlans;
    
    public ActionPlanCategorizationForCfm(List<Action_Plan__c> actionPlans, Map<Id, Case> caseDetails) {
        if(caseDetails == null || actionPlans == null || actionPlans.isEmpty() || caseDetails.isEmpty()) {
            throw new InvalidDataException('Failed to populate categorization details on action plan. Either case or action plan details missing');
        }
        this.caseDetails = caseDetails;
        this.actionPlans = actionPlans;
    }
    
    public void populateCategorizationDetails() {
        Case caseRecord;
        for(Action_Plan__c ap: actionPlans) {
            System.debug(LoggingLevel.INFO, ap.Parent_Case__c);
            if(ap.Parent_Case__c != null && caseDetails.containsKey(ap.Parent_Case__c) && !caseDetails.get(ap.Parent_Case__c).IsMinCorroCase__c) {
                caseRecord = caseDetails.get(ap.Parent_Case__c);
                ap.Agency__c = caseRecord.Agency__c;
                ap.Issue_Level_1__c = caseRecord.Taxonomy_Moment__c;
                ap.Issue_Level_2__c = caseRecord.Taxonomy_Transaction__c;
                ap.Issue_Level_3__c = caseRecord.Taxonomy_Symptom__c;
                ap.Issue_Level_3_Id__c = caseRecord.Taxonomy_Symptom_Id__c;
                ap.Location_Level_1__c = caseRecord.Taxonomy_Location_Type__c;
                ap.Location_Level_2__c = caseRecord.Taxonomy_Area__c;
                ap.Location_Level_3__c = caseRecord.Taxonomy_Location__c;
                ap.Location_Level_3_Id__c = caseRecord.Taxonomy_Location_Id__c;
                ap.Mode__c = caseRecord.Modes__c;
            }
        }        
    }
    
    public class InvalidDataException extends Exception {}
}