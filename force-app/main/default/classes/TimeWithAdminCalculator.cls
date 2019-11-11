public without sharing class TimeWithAdminCalculator {
    
    private static final Integer MILLISECONDS_IN_SEC = 1000;
    private static final Integer SECS_IN_MIN = 60;
    private static final Integer MIN_IN_HR = 60;
    private static final Integer DAYS_IN_A_WEEK = 7;
    private static final Integer HOURS_IN_DAY = 24;
    private static final Integer DAYS_IN_WEEKEND = 2;
    
    private Set<Id> parentCaseIds;
    
    public TimeWithAdminCalculator(Set<Id> parentCaseIds) {
        if(parentCaseIds == null || parentCaseIds.isEmpty()) {
            throw new InvalidDataException('Failed to calculate time with admin. Parent case details missing');
        }
        this.parentCaseIds = parentCaseIds;
    }
    
    public void calculate() {
        List<Case> parentCases = [  SELECT Id, Datetime_last_assigned_queue__c, Time_with_Admin__c, BusinessHoursId
                                    FROM Case 
                                    WHERE Id IN :parentCaseIds
                                        AND Time_with_Admin__c = NULL
                                        AND Datetime_last_assigned_queue__c != NULL
                                        AND BusinessHoursId != NULL
                                        AND Last_Queue_Assigned__c = :GlobalConstants.GIS_ADMIN_QUEUE];
        if(parentCases.isEmpty()) {
            return;
        }
        for(Case parentCase : parentCases) {        
            parentCase.Time_with_Admin__c = Integer.valueOf(BusinessHours.diff(parentCase.BusinessHoursId, parentCase.Datetime_last_assigned_queue__c, System.now())/(MILLISECONDS_IN_SEC * SECS_IN_MIN * MIN_IN_HR));
        }
        update parentCases;
    }   
    
    public class InvalidDataException extends Exception {}
}