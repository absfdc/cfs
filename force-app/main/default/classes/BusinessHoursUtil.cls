/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    BusinessHoursUtil_Test
History
04/05/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public class BusinessHoursUtil {
	@TestVisible
	public static Map<String,Id> agencyBusinessHrsMap{get;set;}
	public static Map<String,Decimal> actionPlanDueDateByAgencyMap{get;set;}
    private static map<Id,map <String,Time>> businessHoursVsEndTime;
    
    static {
    	businessHoursVsEndTime = new map<Id,map <String,Time>>();
        for(BusinessHours abh:[Select  WednesdayEndTime,TuesdayEndTime, ThursdayEndTime, 
                               		   SundayEndTime, SaturdayEndTime, MondayEndTime, Id, FridayEndTime 
                               From BusinessHours 
                               Where IsActive = true limit 100]){
			map <String,Time> dayVsEndTime = new map <String,Time> ();
			dayVsEndTime.put('Sunday',abh.SundayEndTime);
            dayVsEndTime.put('Monday',abh.MondayEndTime);
            dayVsEndTime.put('Tuesday',abh.TuesdayEndTime);
            dayVsEndTime.put('Wednesday',abh.WednesdayEndTime);
            dayVsEndTime.put('Thursday',abh.ThursdayEndTime);
            dayVsEndTime.put('Friday',abh.FridayEndTime);
            dayVsEndTime.put('Saturday',abh.SaturdayEndTime);
            businessHoursVsEndTime.put(abh.Id,dayVsEndTime);
        }
    }
    
	public static void setup(){
		if (agencyBusinessHrsMap==null){
			agencyBusinessHrsMap = new Map<String,Id>();
			for(BusinessHours abh:[select id,Name from BusinessHours limit 100]){
				agencyBusinessHrsMap.put(abh.Name,abh.id);
			}
		}
	}

	public static void setupActionPlanDueDateByAgency(){
		if(actionPlanDueDateByAgencyMap==null){
			actionPlanDueDateByAgencyMap= new Map<String,Decimal>();
			for(ActionPlanDueDateByAgency__c actionPlanDueDateByAgency :ActionPlanDueDateByAgency__c.getall().values()){
				actionPlanDueDateByAgencyMap.put(actionPlanDueDateByAgency.Name,actionPlanDueDateByAgency.BusinessHours__c);
			}
		}
	}

	public static Id getBusinessHour(String agency){
		if (agencyBusinessHrsMap==null) setup();
		Id bhId = agencyBusinessHrsMap.get(GlobalConstants.DEFAULTBH);
		if (agencyBusinessHrsMap.containsKey(agency)){
			bhId = agencyBusinessHrsMap.get(agency);
		}
		return bhId;
	}

	public static Decimal getActionPlanDueDateBh(String agencyPriority){
		if (actionPlanDueDateByAgencyMap==null) setupActionPlanDueDateByAgency();
		Decimal bh = actionPlanDueDateByAgencyMap.get(GlobalConstants.DEFAULTBH);
		if (actionPlanDueDateByAgencyMap.containsKey(agencyPriority)){
			bh = actionPlanDueDateByAgencyMap.get(agencyPriority);
		}
		return bh;
	}
    
    public static Date getActionPlanDueDate(Id BusinessHoursId, Date createdDate, Decimal bh){
        Long miliSeconds = (60 * 60 * 1000) * (bh.longValue());
        System.debug('---@Due Date Calculation Miliseconds---' + miliSeconds + '-BH-' + BusinessHoursId);
        DateTime tempDueDate = BusinessHours.add(BusinessHoursId, createdDate, miliSeconds );
        System.debug('---@Due Date Calculation Temp Due Date---' + tempDueDate);
        return tempDueDate != null? tempDueDate.date() : null;
    }
    
    @testVisible
    public static Decimal getActionPlanActualDaysOverdue(Id BusinessHoursId, Date dueDate, DateTime firstCompletedDate) {
        System.debug('----@Actual Days Overdue--Fix---' + dueDate + '-' + firstCompletedDate);
        Long diff = 0;
        Decimal days = 0;
        Time endTime = Time.newInstance(17, 0, 0, 0);
        
        if(dueDate == null)
            return 0;
        
		Datetime dt = (DateTime) dueDate;
		String dayOfWeek = dt.format('EEEE');
        System.debug('----@Actual Days Overdue--dayOfWeek---' + dayOfWeek);
        if(businessHoursVsEndTime.containsKey(BusinessHoursId) && businessHoursVsEndTime.get(BusinessHoursId) != null) {
            if(businessHoursVsEndTime.get(BusinessHoursId).containsKey(dayOfWeek) && businessHoursVsEndTime.get(BusinessHoursId).get(dayOfWeek) != null) {
                endTime = businessHoursVsEndTime.get(BusinessHoursId).get(dayOfWeek);
            } 
        }
        System.debug('----@Actual Days Overdue--End Time---' + endTime);
        diff = BusinessHours.diff(BusinessHoursId, DateTime.newInstance(dueDate, endTime), firstCompletedDate);
        days = (Decimal) diff / (1000*60*60* GlobalConstants.WORKING_HOURS_PER_DAY);
        return days;
    }
}