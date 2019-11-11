@isTest
private class BusinessHoursUtil_Test
{
    @testSetup
    static void setup() {
        list <ActionPlanDueDateByAgency__c> cs =  new list <ActionPlanDueDateByAgency__c>();
        cs.add(new ActionPlanDueDateByAgency__c(Name = 'Default', BusinessHours__c = 64));
        cs.add(new ActionPlanDueDateByAgency__c(Name = 'RMSIndividual - Standard', BusinessHours__c = 102));
        cs.add(new ActionPlanDueDateByAgency__c(Name = 'RMSMP - Standard', BusinessHours__c = 80));
        insert cs;
    }
    
	@isTest//It should get multiple business hrs including the default
	static void testSetup() {
		BusinessHoursUtil.setup();
		system.assert(BusinessHoursUtil.agencyBusinessHrsMap.size()>0);
	}

	@isTest//It should get multiple business hrs including the default
	static void testGetBusinessHour() {
		Id def = BusinessHoursUtil.getBusinessHour('Default');
		system.assertNotEquals(def,null);
	}
      
    //Individual Standard calculations
    @isTest
    static void testDueDateIndividualStandard() {
        BusinessHoursUtil.setup();
        Action_Plan__c ap = new Action_Plan__c(Status__c = 'New',
                                               Due_Date__c =  null,
                                               Parent_Action_Plan__c = null,
                                               Agency__c = GlobalConstants.RMS_AGENCY,
                                               BusinessHours__c = BusinessHoursUtil.getBusinessHour(GlobalConstants.RMS_AGENCY),
                                               CasePriority__c = GlobalConstants.CASE_PRIORITY_INDIVIDUAL_STANDARD
                                              );
        ActionPlanUtility.stampDueDateOnActionPlan(new list <Action_Plan__c> {ap});
        system.assert(ap.Due_Date__c != null);
    }
    
    //MP Standard calculations
    @isTest
    static void testDueDateMpStandard() {
        BusinessHoursUtil.setup();
        Action_Plan__c ap = new Action_Plan__c(Status__c = 'New',
                                               Due_Date__c =  null,
                                               Parent_Action_Plan__c = null,
                                               Agency__c = GlobalConstants.RMS_AGENCY,
                                               BusinessHours__c = BusinessHoursUtil.getBusinessHour(GlobalConstants.RMS_AGENCY),
                                               CasePriority__c = GlobalConstants.CASE_PRIORITY_MP_STANDARD
                                              );
        ActionPlanUtility.stampDueDateOnActionPlan(new list <Action_Plan__c> {ap});
        system.assert(ap.Due_Date__c != null);
    }
    
    //MP Standard calculations
    @isTest
    static void testDueDateOtherThanRMS() {
        BusinessHoursUtil.setup();
        Action_Plan__c ap = new Action_Plan__c(Status__c = 'New',
                                               Due_Date__c =  null,
                                               Parent_Action_Plan__c = null,
                                               Agency__c = GlobalConstants.STA_AGENCY,
                                               BusinessHours__c = BusinessHoursUtil.getBusinessHour(GlobalConstants.STA_AGENCY),
                                               CasePriority__c = GlobalConstants.CASE_PRIORITY_MP_STANDARD
                                              );
        ActionPlanUtility.stampDueDateOnActionPlan(new list <Action_Plan__c> {ap});
        system.assert(ap.Due_Date__c != null);
    }
    
    @isTest
    static void testActualDaysOverdue() {
     	Action_Plan__c ap = new Action_Plan__c(Status__c = 'New',
                                               Due_Date__c =  Date.newInstance(2015, 10, 1),
                                               Parent_Action_Plan__c = null,
                                               Agency__c = GlobalConstants.STA_AGENCY,
                                               BusinessHours__c = BusinessHoursUtil.getBusinessHour(GlobalConstants.STA_AGENCY),
                                               CasePriority__c = GlobalConstants.CASE_PRIORITY_MP_STANDARD
                                              );   
        Decimal days = BusinessHoursUtil.getActionPlanActualDaysOverdue(ap.BusinessHours__c, ap.Due_Date__c, System.now());
        System.debug('-----Days-----' + days);
        system.assert(days > 0);
    }
}