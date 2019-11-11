/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    Handler class for processing incoming response to SNSW referral email.
Inputs:         "caseVsSnswResponse" - map of case v/s email message (SNSW referral response)
Test Class:     SNSWResponseEmailProcessor_Test
History:
------------------------------------------------------------*/
public class SNSWResponseEmailProcessor {

    private Map<Id,EmailMessage> caseVsSnswResponse;
    public SNSWResponseEmailProcessor(Map<Id,EmailMessage> caseVsSnswResponse) {
        if(null == caseVsSnswResponse || caseVsSnswResponse.isEmpty()) {
            throw new InvalidSNSWResponseException('Failed to process SNSW response. SNSW response data not available');
        }
        this.caseVsSnswResponse = caseVsSnswResponse;
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Salesforce.com
    Description:    Function is responsible for processing incoming SNSW referral response and re-opens the case (if currently soft closed) 
                    otherwise creates a new case (if associated case is hard closed)
    Inputs:         
    Returns:        
    History:
    ------------------------------------------------------------*/
    public void processSnswResponses() {
        List<Case> cases = [SELECT Id, Status, Agency__c, Subject, Taxonomy_Moment__c,Taxonomy_Transaction__c, Taxonomy_Symptom__c,
                                     Taxonomy_Location_Type__c, OwnerId, Taxonomy_Area__c, Taxonomy_Location__c, Taxonomy_Accountability__c, Modes__c
                            FROM Case 
                            WHERE Id IN :caseVsSnswResponse.keySet()
                                AND Agency__c = :GlobalConstants.SNSW_AGENCY];
        if(cases.isEmpty()) {
            return;
        }
        List<Case> casesToUpdate = new List<Case>();
        List<Case> clonedCases = new List<Case>();
        for(Case caseRecord: cases) {
            if(caseRecord.status == GlobalConstants.CASE_SOFTCLOSED_STATUS) {
                caseRecord.Agency__c = GlobalConstants.RMS_AGENCY;
                caseRecord.status = GlobalConstants.REOPENED_CASE_STATUS_CUSTOMER_COMMUNICATION;
                casesToUpdate.add(caseRecord);
            } else if(caseRecord.status == GlobalConstants.CASE_CLOSED_STATUS) {
                String caseString = JSON.serialize(caseRecord);
                Case cloneCase = (Case)JSON.deserialize(caseString, Case.class);
                cloneCase.Id = null;
                cloneCase.ParentId = caseRecord.Id;
                cloneCase.Origin = GlobalConstants.CLONED_CASE_ORIGIN_CUSTOMER_COMMUNICATION;
                cloneCase.Status = GlobalConstants.CLONED_CASE_STATUS_CUSTOMER_COMMUNICATION;
                cloneCase.Description = caseVsSnswResponse.get(caseRecord.Id).TextBody;
                cloneCase.Agency__c = GlobalConstants.RMS_AGENCY;
                clonedCases.add(cloneCase);
            }
        }
        List<AssignmentRule> rules;
        Database.DMLOptions dmlOpts = new Database.DMLOptions();       
        
        if(!casesToUpdate.isEmpty()) {
            rules = [SELECT id 
                     FROM AssignmentRule 
                     WHERE SobjectType = 'Case' 
                         AND Active = true LIMIT 1];
            if (!rules.isEmpty()){                       
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].id;
                dmlOpts.assignmentRuleHeader.useDefaultRule = false;            
            }
            Database.update( casesToUpdate, dmlOpts);     
        }
        if(!clonedCases.isEmpty()) {
            rules = [SELECT id 
                     FROM AssignmentRule 
                     WHERE SobjectType = 'Case' 
                         AND Active = true LIMIT 1];
            if (!rules.isEmpty()){                       
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].id;
                dmlOpts.assignmentRuleHeader.useDefaultRule = false;            
            }
            Database.insert( clonedCases, dmlOpts);            
        }
    }
    
    public class InvalidSNSWResponseException extends Exception {}
}