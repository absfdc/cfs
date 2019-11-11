/*
Date        :December 2017 
Description :Update Case status to DFSI whenever Case is Closed in transportnsw org
*/
// changes made by Ishu Jain, 8 March 18 for FA1.2. 
//Added status, type and reason to be sent to DFSI
//Included the custom metadata which manages the mapping of values between CFS and DFSI
 
public class DFSIUpdateCaseFutureCallout implements Queueable,Database.AllowsCallouts {
    
    //local contants  
    private final string GETCASES = 'getCases'; 
    private final string DFSIcontentType='application/json; charset=UTF-8';
    	private static final String tfnsw = 'tfnsw';
	private static final String NSWTrains = 'NSW Trains';
	private static final String rmsWebsite = 'RMS Website';
	private static final String infoURL = 'https://transportnsw.info';
	private static final String rmsURL = 'www.rms.nsw.gov.au';
	private static final String FeedbackAssistCorporate='Feedback Assist Corporate';
    
    
    private List<ID> CaseIds;
    
    public DFSIUpdateCaseFutureCallout(List<Id> CaseIds){//constuructor
        this.CaseIds=CaseIds; 
    }  
    
    public void execute(QueueableContext context) {//Queueable Batch Job
        try{
            String JSONBody= '{"cases":'+generateCaseJSONPayload(CaseIds)+'}';//Cases need to be in JSON format
            system.debug('jsonbody '+JSONBody);
            HTTPResponse res=DFSICoreService.doDFSICallout(DFSICoreService.getDFSIMethodURL(GETCASES),'PUT',DFSIcontentType,JSONBody);
            system.debug('update response is'+res);
        }
        catch(Exception e){
            DFSICoreService.writeToApplicationLog('DFSIUpdateCaseFutureCallout', //write to application log, stacktrace
                                                  'execute',
                                                  e.getMessage(),
                                                  e,
                                                  'Error');
            
        }
    }
    
    
    
    //generate Case update as JSON for callout
    private string generateCaseJSONPayload(List<Id> CaseIds){
		DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForRMS = new DFSI_Case_Owner_And_RecordType_Ids__c();
		DFSI_Case_Owner_And_RecordType_Ids__c objCustomSettingForTransport = new DFSI_Case_Owner_And_RecordType_Ids__c();
		objCustomSettingForRMS = [select name, Owner_Id__c, RecordTypeId__c
									from DFSI_Case_Owner_And_RecordType_Ids__c
									where name = 'RMS' limit 1];
		objCustomSettingForTransport = [select name, Owner_Id__c, RecordTypeId__c
										from DFSI_Case_Owner_And_RecordType_Ids__c
										where name = 'Transport' limit 1];
    		
        List<DFSICase> dList=new List<DFSICase>();
        List<DFSI_Case_Sync__mdt> lstDFSICaseSyncyMetadata = new list<DFSI_Case_Sync__mdt>();
        list<DFSI_Case_Status_Mapping_SNSW__mdt> partnerCaseStatusMapping = new list<DFSI_Case_Status_Mapping_SNSW__mdt>();
        
        List<Case> CaseList = [SELECT Id, DFSICaseID__c,Status, Reason, Type, Response_Requested__c, isFeedbackAssist__c,
                                OwnerAgency__c, Agency__c, Origin_Details__c, Partner_Case_Status__c,Responsible_Party__c
                                FROM Case
                                WHERE Id IN :CaseIds AND DFSICaseID__c!=NULL];
        
        lstDFSICaseSyncyMetadata = [ select CFS_Value__c, DFSI_Value__c, Field_Name__c, MasterLabel, DeveloperName  // Query the metadata for FA 1.2 Enhancements
                                        from  DFSI_Case_Sync__mdt
                                        where Field_Name__c IN ('Reason','Status','Type')];
		
		partnerCaseStatusMapping = [select CFS_Case_Status__c, CFS_Partner_Case_Status__c, DFSI_Case_Status__c
									from DFSI_Case_Status_Mapping_SNSW__mdt];
                                             
        map<String, String> mapCFSValueToDFSIValue = new map<string, string>();
        map<String, String> mapCFSStatusAndPartnerStatusToDFSIStatus = new map<string, string>();
        
        if(lstDFSICaseSyncyMetadata.size() >0)
        for(DFSI_Case_Sync__mdt C : lstDFSICaseSyncyMetadata)
        {
            mapCFSValueToDFSIValue.put(C.Field_Name__c +C.CFS_Value__c, C.DFSI_Value__c);
        }
        
        if(partnerCaseStatusMapping.size() >0)
        for(DFSI_Case_Status_Mapping_SNSW__mdt D : partnerCaseStatusMapping)
        {
            mapCFSStatusAndPartnerStatusToDFSIStatus.put(D.CFS_Case_Status__c + D.CFS_Partner_Case_Status__c, D.DFSI_Case_Status__c);
        }
        
        if(CaseList.size() >0)
        {
                string reason = '';
                string status = '';
                string type = '';
                string recordtypeId = '';
                string ownerId = '';
                
            for(Case c:CaseList) // logic to find the DFSI vlaue based on the vlaue stored in CFS 
            {
            		system.debug('casetype'+c.type);
                if(c.type != '' && c.type!= null && string.isNotEmpty(c.type))
                type = mapCFSValueToDFSIValue.get('Type' + c.type);
                
                system.debug('Responsible_Party**'+c.Responsible_Party__c);
                if(c.Responsible_Party__c != 'SNSW')
                {
                		status = mapCFSValueToDFSIValue.get('Status' + c.status);
                }
                else
                {
					status =   mapCFSStatusAndPartnerStatusToDFSIStatus.get(C.status+C.Partner_Case_Status__c);
                }
				system.debug('status**'+status);
                if(status == 'Closed')
                {
                    if(c.type == 'Complaint' && c.Response_Requested__c == 'No') // additional logic if the type is complaint and response requested is No
                    {
                        reason = mapCFSValueToDFSIValue.get('ReasonComplaint No');
                    }
                    else
                    if(c.type == 'Complaint' && c.Response_Requested__c == 'Yes') // additional logic if the type is complaint and response requested is Yes
                    {
                        reason = mapCFSValueToDFSIValue.get('ReasonComplaint Yes');
                    }
                    
                    else
                    {
                        reason = mapCFSValueToDFSIValue.get('Reason'+c.Type);
                    }
                }
                system.debug('c.isFeedbackAssist__c**'+c.isFeedbackAssist__c);
                // set ownerId and recordtypeId in DFSI for cases coming into CFS first
            		system.debug('c.OwnerAgency__c**'+c.OwnerAgency__c);
            		system.debug('c.Agency__c**'+c.Agency__c);
				if(c.OwnerAgency__c == '' || String.IsBlank(c.OwnerAgency__c) || String.isEmpty(c.OwnerAgency__c) || c.OwnerAgency__c == null)
				{
					if(c.Agency__c == GlobalConstants.RMS_AGENCY || c.Agency__c == GlobalConstants.SNSW_AGENCY)
					{
						recordtypeId = objCustomSettingForRMS.RecordTypeId__c;
						ownerId = objCustomSettingForRMS.Owner_Id__c;					
					}
					else
					{
						recordtypeId = objCustomSettingForTransport.RecordTypeId__c;
						ownerId = objCustomSettingForTransport.Owner_Id__c;										
					}
				}
				else
				{
					if(c.OwnerAgency__c == GlobalConstants.RMS_AGENCY || c.OwnerAgency__c == GlobalConstants.SNSW_AGENCY)
					{
						recordtypeId = objCustomSettingForRMS.RecordTypeId__c;
						ownerId = objCustomSettingForRMS.Owner_Id__c;
					}
					else
					{
						recordtypeId = objCustomSettingForTransport.RecordTypeId__c;
						ownerId = objCustomSettingForTransport.Owner_Id__c;					
					}
				}

                system.debug('recordtypeId**'+recordtypeId);
                system.debug('ownerId**'+ownerId);
                DFSICase d;
                if(type == '')
                {
            			d=new DFSICase(c.DFSICaseID__c, status, reason, recordtypeId, ownerId); // with owner id
                }
                else
                {
            			d=new DFSICase(c.DFSICaseID__c, status, reason, type, recordtypeId, ownerId); // with owner id
                }         
                
                dList.add(d);
            }
        }
        
		string jsonString =  JSON.serialize(dList);
        jsonString = jsonString.replace('"Type":null,','');
        jsonString = jsonString.replace('"OwnerId":null,','');
        jsonString = jsonString.replace('"RecordTypeId":null,','');
        system.debug('jsonString**'+jsonString);
        return jsonString;
    }
    
    //wrapper class for sending request to DFSI. // Changed the wrapper class to add type and reason for FA 1.2 
    class DFSICase {
        String Id;
        String Status;
        String Reason;
        String Type;
        String RecordTypeId;
        String OwnerId; 
        DFSICase(String DFSIId, String Status, String Reason, String Type, String RecordTypeId, String OwnerId ) {
            this.Id = DFSIId;
            this.Status = Status;
            this.Reason = Reason;
            this.Type = Type;
            this.RecordTypeId = RecordTypeId;
            this.OwnerId = OwnerId;
        }
        
        DFSICase(String DFSIId, String Status, String Reason, String RecordTypeId, String OwnerId ) {
            this.Id = DFSIId;
            this.Status = Status;
            this.Reason = Reason;
            this.RecordTypeId = RecordTypeId;
            this.OwnerId = OwnerId;
        }
        
    }
}