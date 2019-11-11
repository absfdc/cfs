/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   Create a map of case agency vs case record type used for record type fliping

History
10/07/2017       Pawan Tiwari        Created   
26/06/2018       Ian Fitzgerald      Added On Demand logic   
------------------------------------------------------------*/
public class PORecordTypeFlip {
	public Static Map<String,Id> agencyVsRTId;
    public Static Set<Id> pboQueueIds;
    public void setPORecType() {
		
        if(pboQueueIds == NULL) {
            pboQueueIds = new Set<Id>();
            for(Group grp : [select Id, Name FROM Group WHERE Type = 'Queue' AND Name like 'PBO%']) {
                pboQueueIds.add(grp.Id);
            }
        }
        if(agencyVsRTId == null ){
            agencyVsRTId = new Map<String,Id>();
            Set<String> poRecordTypes = new Set<String>{'Private_Operators','Light_Rail', 'On Demand'}; 
            for(RecordType rt :  [ SELECT Id,DeveloperName, Name FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName IN :poRecordTypes]) {
                if(rt.DeveloperName == 'Private_Operators' || rt.DeveloperName == 'On Demand'){
                	agencyVsRTId.put('PBO', rt.Id);                        
                }else{
                    agencyVsRTId.put('LRO', rt.Id);
                }
            }
            System.debug('agencyVsRTId: '+agencyVsRTId);
        }
      
    }
}