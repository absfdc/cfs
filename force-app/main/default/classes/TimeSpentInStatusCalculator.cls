public without sharing class TimeSpentInStatusCalculator {

    private static final Integer DAYS_IN_A_WEEK = 7;
    private static final Integer MILLISECONDS_IN_SEC = 1000;
    private static final Integer SECS_IN_MIN = 60;
    private static final Integer MIN_IN_HR = 60;
    private static final Integer HOURS_IN_DAY = 24;
    private List<Action_Plan__c> actionPlans;
    private Map<Id, Action_Plan__c> oldActionPlansMap;
    public static Set<Id> processedAp;
    
    public TimeSpentInStatusCalculator(List<Action_Plan__c> newActionPlans, Map<Id, Action_Plan__c> oldAPMap) {
        if(newActionPlans == null || newActionPlans.isEmpty() || oldAPMap == null || oldAPMap.isEmpty()) {
            throw new InvalidDataException('Failed to stamp time spend in status on action plan. Action plan details missing');
        }
        
        for(Action_Plan__c ap : newActionPlans) {
            if(!oldAPMap.containsKey(ap.Id)) {
                throw new InvalidDataException('Failed to stamp time spend in status on action plan. Invalid old action plan map received');
            }
        }
        this.actionPlans = newActionPlans;
        this.oldActionPlansMap = oldAPMap;
        if(processedAp == null) {
            processedAp = new Set<Id>();
        }
    }
    
    public void stampTimeSpent() {
        for(Action_Plan__c ap : actionPlans) {
            if(!System.Test.isRunningTest() && (ap.Status__c == oldActionPlansMap.get(ap.Id).Status__c || processedAp.contains(ap.Id))) {
                continue;
            }
            
            if(GlobalConstants.ACTION_PLAN_NEW_STATUS.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_New__c == null) {
                    ap.Time_spent_in_New__c = 0;
                }
                ap.Time_spent_in_New__c = ap.Time_spent_in_New__c + calculateTimeSpent(ap.CreatedDate, ap.BusinessHours__c);
                
            } else if(GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_Incorrect_Assignment__c == null) {
                    ap.Time_spent_in_Incorrect_Assignment__c = 0;
                }               
                ap.Time_spent_in_Incorrect_Assignment__c = ap.Time_spent_in_Incorrect_Assignment__c + calculateTimeSpent(ap.Date_stamp_on_Incorrect_Assignment__c, ap.BusinessHours__c);
                
            } else if(GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_Awaiting_Signature__c == null) {
                    ap.Time_spent_in_Awaiting_Signature__c = 0;
                }           
                ap.Time_spent_in_Awaiting_Signature__c = ap.Time_spent_in_Awaiting_Signature__c + calculateTimeSpent(ap.Date_stamp_on_Awaiting_Signature__c, ap.BusinessHours__c);
                
            } else if(GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_Ready_for_Printing__c == null) {
                    ap.Time_spent_in_Ready_for_Printing__c = 0;
                }           
                ap.Time_spent_in_Ready_for_Printing__c = ap.Time_spent_in_Ready_for_Printing__c + calculateTimeSpent(ap.Date_stamp_on_Ready_for_Printing__c, ap.BusinessHours__c);
                
            } else if(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_Action_Plan_in_Progress__c == null) {
                    ap.Time_spent_in_Action_Plan_in_Progress__c = 0;
                }           
                ap.Time_spent_in_Action_Plan_in_Progress__c = ap.Time_spent_in_Action_Plan_in_Progress__c + calculateTimeSpent(ap.Date_stamp_on_Action_Plan_in_Progress__c, ap.BusinessHours__c);
                
            } else if(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_Action_Plan_Assigned__c == null) {
                    ap.Time_spent_in_Action_Plan_Assigned__c = 0;
                }           
                ap.Time_spent_in_Action_Plan_Assigned__c = ap.Time_spent_in_Action_Plan_Assigned__c + calculateTimeSpent(ap.Date_stamp_on_Action_Plan_Assigned__c, ap.BusinessHours__c);
                
            } else if(GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_Action_Plan_in_Review__c == null) {
                    ap.Time_spent_in_Action_Plan_in_Review__c = 0;
                }           
                ap.Time_spent_in_Action_Plan_in_Review__c = ap.Time_spent_in_Action_Plan_in_Review__c + calculateTimeSpent(ap.Date_stamp_on_Action_Plan_in_Review__c, ap.BusinessHours__c);
                
            } else if(GlobalConstants.ACTION_PLAN_WAITING_APPROVAL.equalsIgnoreCase(oldActionPlansMap.get(ap.Id).Status__c)) {
                if(ap.Time_spent_in_Awaiting_Approval__c == null) {
                    ap.Time_spent_in_Awaiting_Approval__c = 0;
                }           
                ap.Time_spent_in_Awaiting_Approval__c = ap.Time_spent_in_Awaiting_Approval__c + calculateTimeSpent(ap.Date_stamp_on_Awaiting_Approval__c, ap.BusinessHours__c);
                
            }
        }
    }
    
    private Double calculateTimeSpent(DateTime startTime, Id businessHrId) {
        System.debug(LoggingLevel.INFO, 'Business Hr: ' + businessHrId);
        System.debug(LoggingLevel.INFO, 'Start Time: ' + startTime);
        if(businessHrId == null || startTime == null) {
            return 0;
        }
        
        DateTime endTime = System.now();
        Double retVal = Double.valueOf(BusinessHours.diff(businessHrId, startTime, endTime)/(1.0 * MILLISECONDS_IN_SEC * SECS_IN_MIN * MIN_IN_HR));
        System.debug(LoggingLevel.INFO, 'Calculated Difference: ' + retVal);
        
        //SFCOE-2664 - 24/10/2018 - Start
        //return retVal;
        System.debug('BusinessHours Diff is: ' + retVal);
        
        Decimal rounded = retVal;
        System.debug('New BusinessHours Diff is: ' + Double.valueOf(rounded.setScale(2)));

        return Double.valueOf(rounded.setScale(2));
        //SFCOE-2664 - 24/10/2018 - End
    }
    
    public class InvalidDataException extends Exception {}

}