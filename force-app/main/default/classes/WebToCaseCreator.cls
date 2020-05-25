/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    utility class for creating cases submitted from webform.
Inputs:         "caseRecord" - instance record populated with data filled in by user on webform
Test Class:     WebToCaseCreator_Test
History:
Ian F. TfNSW, Aug/23/2017  Concatenate User Agent field if > 255 chars
------------------------------------------------------------*/
public class WebToCaseCreator {

    private Case caseRecord;
    public WebToCaseCreator(Case caseRecord) {
        if(caseRecord == null) {
            throw new InvalidCaseException('Failed to create case. Invalid case details received.');
        }
        this.caseRecord = caseRecord;
    }
        
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Method inserts the case after populating category and location related fields onto case based on selected location and category
    Inputs:         
    Returns:        Case: inserted case record
    History:
    Ian F. TfNSW, Aug/23/2017  Concatenate User Agent field if > 255 chars
    ------------------------------------------------------------*/
    public Case insertCase() {    
        setCaseRecordType();
        populateCategoryRelatedFields();        
        selectCaseLocation();
        checkForSnswAgency();
        SNSWReferralEmailIdentifier snswReferralIdentifier = new SNSWReferralEmailIdentifier(new List<Case>{caseRecord});
        snswReferralIdentifier.populateSNSWReferral();
        
        //Added by Ian F. TfNSW, Aug/23/2017 
        //User Agent field is 255 in length
        if (caseRecord.User_agent__c!=null && caseRecord.User_agent__c.length()>255){
            caseRecord.User_agent__c = caseRecord.User_agent__c.left(255);
        }
        
        List<AssignmentRule> rules = [  SELECT id 
                                        FROM AssignmentRule 
                                        WHERE SobjectType = 'Case' 
                                            AND Active = true LIMIT 1];
        Database.DMLOptions dmlOpts = new Database.DMLOptions();        
        if (!rules.isEmpty()){                       
            dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].id;
            dmlOpts.assignmentRuleHeader.useDefaultRule = false;            
        }
        
        Database.SaveResult result = Database.insert( caseRecord, dmlOpts);     
        if(!result.isSuccess()) {       
            System.debug(LoggingLevel.ERROR, result);
            throw new InvalidCaseException('Failed to create case ' + result.getErrors());
        }
        
        
        return caseRecord;
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Function sets new case record type for multi issue.
    Inputs:         
    Returns:       
    History:
    ------------------------------------------------------------*/
    private void setCaseRecordType() {
        List<RecordType> rt = [ SELECT Id, Name 
                                FROM RecordType 
                                WHERE sObjectType = 'Case' 
                                    AND Name = :GlobalConstants.CASE_RECORD_TYPE_MULTI_ISSUE];
        if(!rt.isEmpty()) {
            caseRecord.recordtypeId = rt[0].Id;
        }       
    }
    
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Function populates case location type, area and accountability based on location selected by user on web form
    Inputs:         
    Returns:        
    History:
    ------------------------------------------------------------*/
    private void selectCaseLocation() {
        String strNodes = '';
        String caseAccountability = caseRecord.Taxonomy_Accountability__c;
        String caseAgency = caseRecord.Agency__c;
        System.debug('Agency from category: ' + caseRecord.Agency__c);
        System.debug('Description: ' + caseRecord.Description);
        if(!String.isBlank(caseRecord.Description) && caseRecord.Description.endsWith('#JustLine#')) {
            //strNodes = getLine();
            System.debug('Description ends with justline');
            caseRecord.Description = caseRecord.Description.replaceAll('#JustLine#','');
        } else {
            System.debug('Description does not end with justline');
            System.debug('Mode: ' + caseRecord.Modes__c);
            System.debug('Location: ' + caseRecord.Taxonomy_Location__c);
            //strNodes = getLocation();            
        }
        if(!String.isBlank(caseRecord.Modes__c) && !String.isBlank(caseRecord.Taxonomy_Location__c)) {
            List<Taxonomy_Metadata__c> locTaxonomy = [  SELECT Id, Name, Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Name, Issue_Accountability__c, Agency__c
                                                        FROM Taxonomy_Metadata__c
                                                        WHERE Customer_Value__c = :String.escapeSingleQuotes(caseRecord.Taxonomy_Location__c)
                                                            AND Parent_Id__r.Parent_Id__r.Parent_Id__r.Name = :String.escapeSingleQuotes(caseRecord.Modes__c)
                                                            AND Type__c = 'Location'];
            if(!locTaxonomy.isEmpty()) {
                for(Taxonomy_Metadata__c taxo : locTaxonomy) {
                    if(String.isBlank(caseRecord.Taxonomy_Location_Type__c) || caseRecord.Taxonomy_Location_Type__c == taxo.Parent_Id__r.Parent_Id__r.Name) {
                        caseRecord.Taxonomy_Location_Type__c = taxo.Parent_Id__r.Parent_Id__r.Name;
                        caseRecord.Taxonomy_Area__c = taxo.Parent_Id__r.Name;
                        caseRecord.Taxonomy_Accountability__c = taxo.Issue_Accountability__c;
                        caseRecord.Agency__c = taxo.Agency__c;
                        caseRecord.Taxonomy_Location_Id__c = taxo.Id;
                        caseRecord.Taxonomy_Location__c = taxo.Name;
                        caseRecord.Location_Level_3__c = taxo.Id;
                        System.debug('Agency from location: ' + caseRecord.Agency__c);
                        break;
                    }
                }
                
            }
        }
        
        if(!String.isBlank(caseAccountability)) {
            caseRecord.Taxonomy_Accountability__c = caseAccountability;
        }
        if(!String.isBlank(caseAgency)) {
            caseRecord.Agency__c = caseAgency;
        }
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    Function populates case location type, area and accountability based on location selected by user on web form
    Inputs:         
    Returns:        
    History: 
    ------------------------------------------------------------*/
    private void populateCategoryRelatedFields() {
        List<Taxonomy_Metadata__c> taxonomy = new List<Taxonomy_Metadata__c>();
        String selectedValue = '';
        if(!String.isBlank(caseRecord.Taxonomy_Symptom__c)) {
            selectedValue = caseRecord.Taxonomy_Symptom__c;
            taxonomy = [SELECT Id, Parent_Id__r.Parent_Id__r.Name, KPI__c, Driver__c, Issue_Accountability__c, Agency__c, Name, Parent_Id__r.Name 
                        FROM Taxonomy_Metadata__c
                        WHERE Customer_Value__c = :String.escapeSingleQuotes(selectedValue)
                            AND Type__c = 'Issue'
                            AND Parent_Id__r.Customer_Value__c = :String.escapeSingleQuotes(caseRecord.Taxonomy_Transaction__c)
                            AND Parent_Id__r.Parent_Id__r.Parent_Id__r.Name = :String.escapeSingleQuotes(caseRecord.Modes__c)];
            if(!taxonomy.isEmpty()) {
                caseRecord.Taxonomy_Moment__c = taxonomy[0].Parent_Id__r.Parent_Id__r.Name;
                caseRecord.KPI__c = taxonomy[0].KPI__c;
                caseRecord.Key_Driver__c = taxonomy[0].Driver__c;
                caseRecord.Taxonomy_Accountability__c = taxonomy[0].Issue_Accountability__c;
                caseRecord.Agency__c = taxonomy[0].Agency__c;
                caseRecord.Taxonomy_Symptom_Id__c = taxonomy[0].Id;
                caseRecord.Taxonomy_Transaction__c = taxonomy[0].Parent_Id__r.Name;
                caseRecord.Taxonomy_Symptom__c = taxonomy[0].Name;
            }
        } else {
            selectedValue = caseRecord.Taxonomy_Transaction__c;
            if(String.isBlank(selectedValue)) {
                return;
            }
            taxonomy = [SELECT Id, Parent_Id__r.Name, Name
                        FROM Taxonomy_Metadata__c
                        WHERE Customer_Value__c = :String.escapeSingleQuotes(selectedValue)
                            AND Type__c = 'Issue'
                            AND Parent_Id__r.Parent_Id__r.Name = :String.escapeSingleQuotes(caseRecord.Modes__c)];
            if(!taxonomy.isEmpty()) {
                caseRecord.Taxonomy_Moment__c = taxonomy[0].Parent_Id__r.Name;
                caseRecord.Taxonomy_Transaction__c = taxonomy[0].Name;
            }
        }
    }
    
    private void checkForSnswAgency() {
        if(!String.isBlank(caseRecord.Created_By_Email__c) 
                && caseRecord.Created_By_Email__c.contains(GlobalConstants.SNSW_EMAIL_DOMAIN) 
                && caseRecord.Agency__c == GlobalConstants.SNSW_AGENCY) {
            caseRecord.Agency__c = GlobalConstants.RMS_AGENCY;
        } else if(caseRecord.Agency__c == GlobalConstants.SNSW_AGENCY) {
            caseRecord.Status = GlobalConstants.CASE_SOFTCLOSED_STATUS;
        }
    }
    
    public class InvalidCaseException extends Exception {}
}