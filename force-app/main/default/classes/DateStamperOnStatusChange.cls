public with sharing class DateStamperOnStatusChange {

    private List<Action_Plan__c> newActionPlans;
    private Map<Id, Action_Plan__c> oldActionPlanMap;
    
    public DateStamperOnStatusChange(List<Action_Plan__c> newActionPlans, Map<Id, Action_Plan__c> oldActionPlanMap) {
        if(newActionPlans == null || newActionPlans.isEmpty() || oldActionPlanMap == null || oldActionPlanMap.isEmpty()) {
            throw new InvalidDataException('Failed to stamp date on status change. Action plan details missing');
        }
        this.newActionPlans = newActionPlans;
        this.oldActionPlanMap = oldActionPlanMap;
    }
    
    public void stampDate() {
        for(Action_Plan__c ap : newActionPlans) {
            if(isStatusChanged(ap)) {
                if(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(ap.Status__c)) {
                    ap.Date_stamp_on_Action_Plan_Assigned__c = System.now();
                } else if(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(ap.Status__c)) {
                    ap.Date_stamp_on_Action_Plan_in_Progress__c = System.now();
                } else if(GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(ap.Status__c)) {
                    ap.Date_stamp_on_Action_Plan_in_Review__c = System.now();
                } else if(GlobalConstants.ACTION_PLAN_WAITING_APPROVAL.equalsIgnoreCase(ap.Status__c)) {
                    ap.Date_stamp_on_Awaiting_Approval__c = System.now();
                } else if(GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG.equalsIgnoreCase(ap.Status__c) && ap.Date_stamp_on_Awaiting_Signature__c == null) {
                    ap.Date_stamp_on_Awaiting_Signature__c = System.now();
                } else if(GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT.equalsIgnoreCase(ap.Status__c)) {
                    ap.Date_stamp_on_Incorrect_Assignment__c = System.now();
                } else if(GlobalConstants.ACTION_PLAN_STATUS_READY_FOR_PRINT.equalsIgnoreCase(ap.Status__c)) {
                    ap.Date_stamp_on_Ready_for_Printing__c = System.now();
                } else if (GlobalConstants.ACTION_PLAN_CLOSED_STATUS.equalsIgnoreCase(ap.Status__c)) {
                    ap.Date_stamp_on_Completed__c = System.now();
                    if (ap.Date_stamp_on_First_Completed__c == null) {                // only set First Completed if null
                        ap.Date_stamp_on_First_Completed__c = ap.Date_stamp_on_Completed__c;
                        ap.ActualDaysOverdue__c = BusinessHoursUtil.getActionPlanActualDaysOverdue(ap.BusinessHours__c, 
                                                                                               	   ap.Due_Date__c,
                                                                                               	   ap.Date_stamp_on_First_Completed__c);
                        system.debug('---@AtualDaysOverdue--Stamped---' + ap.ActualDaysOverdue__c);
                    }
                }
                ap.Status_Date_Last_Stamped__c = System.now();
            }
        }
    }
    
    private Boolean isStatusChanged(Action_Plan__c ap) {
        Boolean flag = false;
        if(ap.Status__c != oldActionPlanMap.get(ap.Id).Status__c) {
            flag = true;
        }       
        return flag;
    }
    
    public class InvalidDataException extends Exception {}

}