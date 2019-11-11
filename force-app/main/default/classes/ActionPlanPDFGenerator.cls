/*------------------------------------------------------------
Author:        Vishnu Belkone
Company:       Arxxus.com
Description:   This class is responsible for creating pdf with actionPlanPDF fieldset values
                and attach to parent case.

Test Class:    ActionPlanPDFGenerator_Test
History
04/05/2015     Vishnu Belkone       Created
20/05/2015     Manish Damle         Added try - catch in generateActionPlanPDF
                                    Added check for CFM record type.
02/05/2017     Ian Fitzgerald       Reduce two queries to RecordType to one.  Move from Constructor to static block
------------------------------------------------------------*/
public without sharing class ActionPlanPDFGenerator { 
    public static final String CONTENT_PDF='application/pdf';  
    List<Schema.FieldSetMember> getFields;
    private static set <Id> attachmentsGenerated = new set <Id>();
    private static Id attachmentRecordTypeId;
    private static Id cfmActionPlanRecordTypeId;
    private map <Id, Case> casesIdsVsCases;
    
    //Added by Ian Fitzgerald, 02/05/2017  Reduce two queries to RecordType to one, move to static block
    //Initialise the recordType vars
    static {
        List<RecordType> recTypes = [Select Id, DeveloperName From RecordType Where DeveloperName =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT
                                                               Or DeveloperName =: GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME];
        for (RecordType rt: recTypes){
            if (rt.DeveloperName==GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT){
                attachmentRecordTypeId = rt.Id;
            }
            if (rt.DeveloperName==GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME){
                cfmActionPlanRecordTypeId = rt.Id;
            }
        }
    }
    //END - Added by Ian Fitzgerald 02/05/2017
    
    public ActionPlanPDFGenerator() {       
        getFields = SObjectType.Action_Plan__c.FieldSets.ActionPlanToPDF.getFields();
       // attachmentRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT limit 1].Id;
       // cfmActionPlanRecordTypeId = [Select Id From RecordType Where DeveloperName =: GlobalConstants.ACTION_PLAN_CFM_RECORDTYPE_NAME limit 1].Id; 
    }
    
    public static final String FORM_HTML_START = '<HTML><BODY>';
    public static final String FORM_HTML_END = '</BODY></HTML>';
    
    public void generateActionPlanPDF(TriggerParameters tp){    
        try {
            set <Id> parentCaseIds =  new set <Id>();
            list <Action_Plan__c> pfdsToBeGenerated = new list <Action_Plan__c>();
            //create a set of parent case ids
            for(Action_Plan__c ap : (list <Action_Plan__c>) tp.newList) {
                if(ap.Parent_Case__c != null)
                    parentCaseIds.add(ap.Parent_Case__c);
            }

            //fetch the case records
            casesIdsVsCases = new map <Id, Case> ([Select Id, CaseNumber, OwnerId from Case Where Id IN: parentCaseIds]);
            if(tp != null && tp.oldMap != null) {
                for(Action_Plan__c ap : (list <Action_Plan__c>) tp.newList) {
                    Action_Plan__c newAp = (Action_Plan__c) tp.newMap.get(ap.Id);
                    Action_Plan__c oldAp = (Action_Plan__c) tp.oldMap.get(ap.Id);
                    
                    if(ap.RecordTypeId == cfmActionPlanRecordTypeId) continue; //Skip the CFM action plans
    
                    if(oldAp.Status__c != newAp.Status__c && newAp.Status__c == GlobalConstants.ACTION_PLAN_CLOSED_STATUS) {
                        pfdsToBeGenerated.add(newAp);
                    }
                }
                generatePDF(pfdsToBeGenerated);
            } 
            
        }catch(Exception e) {
            system.debug('Exception in Action Plan PDF Generator' + e.getMessage() + '---LINE---' + e.getLineNumber());
        }
    }
    
    public boolean callFromButton(Id actionPlanId){
        try {
            String query = 'SELECT ';
            for(Schema.FieldSetMember fieldsetMember : this.getFields ){
                query += fieldsetMember.getFieldPath() + ',' ;     
            }
            query += 'Id FROM Action_Plan__c WHERE Id = \''+actionPlanId+'\'';
            Action_Plan__c actionPlan = Database.query(query);
            casesIdsVsCases = new map <Id, Case> ([Select Id, CaseNumber, OwnerId From Case Where Id =: actionPlan.Parent_Case__c]);
            generatePDF(new list <Action_Plan__c> { actionPlan });
        } catch(Exception e) {
            system.debug('-----Error Occured While Generating PDF From Button-------' + e.getMessage() + '--LINE--' +  e.getLineNumber());
            return false;
        }
        return true;
    }

    public void generatePDF(list <Action_Plan__c> pfdsToBeGenerated) {
        map <String, NoteOrAttachment__c> noteOrAttachments = new map <String, NoteOrAttachment__c>();
        map <String, Attachment> actionPlanAttachments = new map <String, Attachment>();

        for(Action_Plan__c actionPlan : pfdsToBeGenerated) {
            
            if(attachmentsGenerated.contains(actionPlan.Id)) continue;

            String ownerId = actionPlan.Parent_Case__c != null && casesIdsVsCases.containsKey(actionPlan.Parent_Case__c) ? casesIdsVsCases.get(actionPlan.Parent_Case__c).OwnerId : UserInfo.getUserId();
            String pdfContent = '' + FORM_HTML_START;       
            pdfContent = '' + FORM_HTML_START;
            pdfContent = pdfContent + '<H2 style="text-align:center;">ActionPlan Information</H2><br />';
            for(Schema.FieldSetMember fieldmap : this.getFields){
                String value = '';
                DisplayType t = fieldmap.getType();
                if(t == DisplayType.Date) {
                    Date d = (Date) actionPlan.get(fieldmap.getFieldPath());
                    value = d != null ? (d.day() + '/' + d.month() + '/' + d.year()) : '';
                } else if(fieldmap.getLabel() == 'Parent Case') {
                    value = casesIdsVsCases.containsKey((Id) actionPlan.get(fieldmap.getFieldPath())) ? casesIdsVsCases.get((Id) actionPlan.get(fieldmap.getFieldPath())).CaseNumber : actionPlan.get(fieldmap.getFieldPath()) + '';
                } else {
                    value = actionPlan.get(fieldmap.getFieldPath()) != null ? actionPlan.get(fieldmap.getFieldPath()) + '' : '';
                }
                if(value != ''){
                    value = value.remove('font-family');
                    value = value.remove('font-size:');
                }
                //pdfContent = pdfContent + '<div style="margin-left:60px;"><b>' + fieldmap.getLabel() + '</b>: ' + value + '</div><br />';
                if (('Comments').equalsIgnoreCase(fieldmap.getLabel())){
                    pdfContent = pdfContent + '<div style="margin-left:60px;"><b>' + 'Comments – not to be included in response </b>: ' + value + '</div><br />';
                }
                else pdfContent = pdfContent + '<div style="margin-left:60px;"><b>' + fieldmap.getLabel() + '</b>: ' + value + '</div><br />';
                
            }

            pdfContent = pdfContent + FORM_HTML_END;
            noteOrAttachments.put(actionPlan.Name, new NoteOrAttachment__c(Name = actionPlan.Name,
                                                                           Case__c = actionPlan.Parent_Case__c,
                                                                           RecordTypeId = attachmentRecordTypeId,
                                                                           ContentType__c = CONTENT_PDF,
                                                                           OwnerId = ownerId));

            actionPlanAttachments.put(actionPlan.Name, new Attachment(Name = actionPlan.Name + '.pdf',
                                                                      ContentType = CONTENT_PDF,
                                                                      body = Blob.toPDF(pdfContent)));
            attachmentsGenerated.add(actionPlan.Id);
        }

        //insert custom note or attachments
        insert noteOrAttachments.values();

        for(String apName : actionPlanAttachments.keySet()) {
            if(noteOrAttachments.containsKey(apName) 
                && noteOrAttachments.get(apName) != null 
                && noteOrAttachments.get(apName).Id != null) {
                actionPlanAttachments.get(apName).ParentId = noteOrAttachments.get(apName).Id;
            }
        }

        //insert standard attachments with parent id as custom note or attachment
        insert actionPlanAttachments.values();

        for(String apName : noteOrAttachments.keySet()) {
            if( actionPlanAttachments.containsKey(apName) 
                && actionPlanAttachments.get(apName) != null 
                && actionPlanAttachments.get(apName).Id != null) {
                noteOrAttachments.get(apName).Attachment__c = actionPlanAttachments.get(apName).Id;
            }
        }

        //Update custom note or attachments
        update noteOrAttachments.values();
    }
}