/**
* @author Hari Krishnan
* @date 07/16/2013
* @description This class has helper methods.
*/

public with sharing class UtilityClass {
    
    public static Map<String,Decimal> priorityVsBusniessDays;
	
    public static void setup() {
        priorityVsBusniessDays = new Map<String,Decimal>();
        for(Case_Due_Date_By_Priority__mdt casePriorityAndBH : [SELECT label, Number_of_Business_Days__c FROM Case_Due_Date_By_Priority__mdt]){
            priorityVsBusniessDays.put(casePriorityAndBH.label, casePriorityAndBH.Number_of_Business_Days__c);
        }
    }
    
	/**
	* @author Hari Krishnan
	* @date 07/16/2013
	* @description Gets the type name of the SObject.
	* @param SObject The SObject for which the name to be obtained.
	* @return String - The type name.
	*/
	public static String getSObjectTypeName(SObject so) {
		return so.getSObjectType().getDescribe().getName();
	}


    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
         
        String selects = '';
         
        if (whereClause == null || whereClause == ''){ return null; }
         
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        system.debug('all fields - '+ fMap);
        system.debug('fMap size - '+fMap.size());
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }else{
                    system.debug(fd.getName()+ ' is not creatable ');
                }
            }
        }
        system.debug('selected fields - '+ selectFields);

        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
             
        }else{
            selects='ContactId,AccountId,ParentId,SuppliedName,SuppliedEmail,SuppliedPhone,SuppliedCompany,Type,RecordTypeId,Status,Reason,Origin,Subject,Priority,Description,IsEscalated,OwnerId,Agency__c,Private_Notes_Count__c,Assigned_SME__c,Initial_Advice_Request_Sent_On__c,Date_Time_of_Incident__c,Response_Requested__c,Active__c,Created_By_Email__c,Direction_of_Travel__c,Key_Driver__c,KPI__c,STA_Employee_Number__c,PNR_Number__c,Vehicle_Registration__c,Disability__c,Disability_Category__c,ATSI__c,LOTE__c,STA_Insurance_360_Number__c,Request_for_Action__c,Type_of_Hazard__c,Type_of_Infrastructure__c,Project__c,E_Toll_Account_Number__c,License_Photo_Card_Number__c,GPS_Incident_Location__Latitude__s,GPS_Incident_Location__Longitude__s,External_Agency__c,Location_of_Incident__c,Bus_Number__c,Taxonomy_Moment__c,Taxonomy_Location__c,Taxonomy_Transaction__c,Taxonomy_Symptom__c,Taxonomy_Location_Type__c,Taxonomy_Area__c,Last_Queue_Assigned__c,Secondary_Contact__c,Supplied_Address__c,Case_Reference_Number__c,Case_Resolution_Date__c,Modes__c,User_have_raised_the_issue_previously__c,Taxonomy_Accountability__c,Reopen_Till_Date__c,Auto_Assign_Case__c,Origin_Details__c,Referrer_URL__c,User_agent__c,Users_Ip_address__c,RFS_Region__c,Product_Type__c,Signatory__c,Taxonomy_Symptom_Id__c,Taxonomy_Location_Id__c,Child_Cases_Count__c,Portfolio__c,Response_Priority__c,Date_Triage__c,MO_Instructions__c,Response_Type__c,Acknowledgement_Required__c,Date_received_at_MO__c,Date_of_correspondance__c,Date_On_Hold__c,Other_Signatory__c,Minister__c,Serco_handled__c,Referring_Minister__c,Due_date__c,Date_Escalated__c,Customer_Win__c,Date_Resolved__c,Date_Closed__c,Date_Reopened__c,Date_Registration__c,Date_Allocation__c,Date_Awaiting_Advice__c,Potential_duplicates__c,Potential_duplicate_contacts__c,Customer_Facing_Response__c,MO_Contact__c,Dot_Points__c,Contact_Emailed_Timestamp__c,PBLROperator_Email_Address__c,categorisation_count__c,Response_Method__c,Use_Contact_Details__c,Amendment_Reason__c,Date_Draft_Response_in_Progress__c,Amendment_Count__c,IsGetNext__c,Supplied_Referrer__c,Classification__c,Branch__c,Section__c,Last_Reopen_Date__c,Returned_to_Queue_Count__c,SNSW_referral_sent__c,Respond_To__c,STA_Results_of_Investigation__c,MultiAgency__c,Date_Senior_Review__c,Date_Editor_Review__c,Date_Manager_Review__c,Date_Ready_For_Printing__c,Date_Awaiting_Signature__c,OBO__c,OBO_Email__c,SNSW_Referral_Email__c,Bus_driver_identification__c,Date_Assigned_to_Agency__c,Contact_Attempted_Timestamp__c,Contact_Made_Timestamp__c,OBO_Street__c,OBO_City__c,OBO_Post_Code__c,OBO_State__c,Contact_Street__c,Contact_City__c,Contact_State__c,Contact_Post_Code__c,NoOfActiveActionPlans__c,Reject_Reason__c,Draft_Rejection_Count__c,Amendment__c,Responsible_Team__c,Responsible_MAGS_Officer__c,Case_Registered_By__c,Alternate_Email__c,Alternative_Postal_Address__c,RMS_Vehicle_registration__c';
        }
        system.debug('selected fields - '+ selects);
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
         
    }

    /**
    * @author Dipankar Barman
    * @date 07/16/2013
    * @description Gets the fakeid given an SObjectType.
    * @param SObjectType.
    * @return fake Id for teh sObjectType 
    */
    static Integer s_num = 1;
    public static String getFakeId(Schema.SObjectType sot)
    {
      String result = String.valueOf(s_num++);
      return sot.getDescribe().getKeyPrefix() + 
         '0'.repeat(12-result.length()) + result;
    }

    /* 25/08/2017: Added By arxxus
       Public Holidays and weekends should be considered in Due Date
       This method is invoked form CaseBeforeInsertTriggerHandler and CaseBeforeUpdateTriggerHandler
    */
    public static Date getDueDate(String priority,DateTime currentDateTime,BusinessHours stdBusinessHrs){
        if(priorityVsBusniessDays == NULL) setup();
        DateTime duedateTime ;
        if(priorityVsBusniessDays.containsKey(priority)){
	        duedateTime = addBusinessDays(currentDateTime,priorityVsBusniessDays.get(priority),stdBusinessHrs);
        }
        return (duedateTime !=null)? duedateTime.date():null;
    }

    /* 25/08/2017: Added By arxxus
       Add BusinessDays to calculate the due date
    */
    public static Datetime addBusinessDays(Datetime dueDateTimeValue, Decimal days, BusinessHours stdBusinessHrs){
        Long miliSeconds = (60 * 60 * 1000) * (GlobalConstants.numberOfBusinessHrsInADay * days.longValue());
        System.debug('--Case Due Date Calculation Miliseconds---' + miliSeconds + '-BH-' + stdBusinessHrs);
        DateTime tempDueDate = BusinessHours.add(stdBusinessHrs.Id, dueDateTimeValue, miliSeconds );
        System.debug('--Case Due Date Calculation Temp Due Date---' + tempDueDate);
        return tempDueDate;
    }

}