/*------------------------------------------------------------
Author:        Arxxus
Description:   class to get attachments based on category.
Test Class:     AttachmentInformation_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
08-FEB-2017   Arxxus          Comments and cleanup
09-MAY-2017   Arxxus          Updated. Limit the total number of previous corro document to the count 
                              mentioned in 'PreviousCorro Document Count' custom setting  
------------------------------------------------------------*/
global with sharing class AttachmentInformation {    

    public Static Integer numberOfAttachment {get; set;}

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   class to get attachments based on category.
    Input:         caseid and note or attachment category. 
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    09-MAY-2017   Arxxus             Comment added.This method get all the attachment with category as 'Incoming' 
    ------------------------------------------------------------*/
    global static Map<Id,AttachmentInfo> getIncomingAttachment(String caseId, String attachmentCategory){
        
        Map<Id,AttachmentInfo> noteOrAttachmentMap = new Map<Id,AttachmentInfo>();
        Map<Id,Attachment> incomingAttachmentMap = new Map<Id,Attachment>();
        Map<Id,NoteOrAttachment__c> customAttachmentIdMap = new Map<Id,NoteOrAttachment__c>();

        for(NoteOrAttachment__c getNotesAndAttachment: [Select Id, Case__r.CaseNumber, Attachment_Id__c
                                                            FROM NoteOrAttachment__c
                                                            Where Case__c = : caseId
                                                            AND(ContentType__c = 'application/pdf'
                                                                OR ContentType__c = 'binary/octet-stream')
                                                            AND Attachment_Id__c != NULL
                                                            AND Category__c = : attachmentCategory
                                                            ORDER BY CreatedDate ASC ]) {
            
            customAttachmentIdMap.put(getNotesAndAttachment.Attachment_Id__c, getNotesAndAttachment);
        
        }

        System.debug('customAttachmentIdMap :: ' + customAttachmentIdMap);

        for(Attachment getSfAttachment : [ Select Id,Name,CreatedBy.Name,CreatedDate
                                                            FROM Attachment
                                                            WHERE Id IN: customAttachmentIdMap.keySet() ]) {
            incomingAttachmentMap.put(getSfAttachment.Id, getSfAttachment);
        }
        System.debug('incomingAttachmentMap :: ' + incomingAttachmentMap);

        if(incomingAttachmentMap.size() > 0)
            numberOfAttachment = incomingAttachmentMap.size();

        for(Id getId : incomingAttachmentMap.keySet()){
            if(incomingAttachmentMap.containsKey(getId)){
                AttachmentInfo newAttachmentInfo = new AttachmentInfo();
                newAttachmentInfo.attachmentId = incomingAttachmentMap.get(getId).Id;
                newAttachmentInfo.name = incomingAttachmentMap.get(getId).Name;
                newAttachmentInfo.createdBy = incomingAttachmentMap.get(getId).CreatedBy.Name;
                newAttachmentInfo.caseNumber = customAttachmentIdMap.get(getId).Case__r.CaseNumber;
                newAttachmentInfo.createdDate = Date.newInstance(
                                                    (incomingAttachmentMap.get(getId).CreatedDate).year(), 
                                                    (incomingAttachmentMap.get(getId).CreatedDate).month(), 
                                                    (incomingAttachmentMap.get(getId).CreatedDate.day()) );
                newAttachmentInfo.totalCount = numberOfAttachment;
                System.debug('newAttachmentInfo :: ' + newAttachmentInfo);
                noteOrAttachmentMap.put(newAttachmentInfo.attachmentId,newAttachmentInfo);
            }
        }   
        System.debug('noteOrAttachmentMap :: ' + noteOrAttachmentMap);
        return noteOrAttachmentMap;                                                     

    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   class to get attachments based on category.
    Input:         caseId 
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    09-MAY-2017   Arxxus             Comment added. This method get all the advice attachment with 
                                     category as 'Advice' or name starts with 'APN' 
    ------------------------------------------------------------*/
    global static Map<Id, AttachmentInfo> getAdviceAttachment(String caseId){

        Map<Id,AttachmentInfo> noteOrAttachmentMap = new Map<Id,AttachmentInfo>();
        Map<Id,NoteOrAttachment__c> customAttachmentIdMap = new Map<Id,NoteOrAttachment__c>();
        Map<Id,Attachment> actionPlanAttachmentMap = new Map<Id,Attachment>();

        for(NoteOrAttachment__c getNotesAndAttachment: [Select Id, Attachment_Id__c, Case__r.CaseNumber
                                                            FROM NoteOrAttachment__c
                                                            WHERE Case__c = : caseId
                                                            AND ContentType__c = 'application/pdf'
                                                            AND Name LIKE 'APN%'
                                                            AND Category__c = NULL
                                                            AND Attachment_Id__c != NULL
                                                            ORDER BY CreatedDate DESC ]) {
            customAttachmentIdMap.put(getNotesAndAttachment.Attachment_Id__c, getNotesAndAttachment);
        }

        for(NoteOrAttachment__c getNotesAndAttachment: [Select Id, Attachment_Id__c, Case__r.CaseNumber
                                                        FROM NoteOrAttachment__c
                                                        WHERE Case__c = : caseId
                                                        AND(ContentType__c = 'application/pdf'
                                                            OR ContentType__c = 'binary/octet-stream')
                                                        AND Category__c = : GlobalConstants.ATTACHMENT_CATEGORY_ADVICE
                                                        AND Attachment_Id__c != NULL
                                                        ORDER BY CreatedDate DESC ]) {
            customAttachmentIdMap.put(getNotesAndAttachment.Attachment_Id__c, getNotesAndAttachment);
        }

        System.debug('customAttachmentIdMap :: ' + customAttachmentIdMap);

        for(Attachment getSfAttachment : [ Select Id,Name,CreatedBy.Name,CreatedDate
                                                            FROM Attachment
                                                            WHERE Id IN: customAttachmentIdMap.keySet() ]) {
            actionPlanAttachmentMap.put(getSfAttachment.Id, getSfAttachment);
        }
        System.debug('actionPlanAttachmentMap :: ' + actionPlanAttachmentMap);

        if(actionPlanAttachmentMap.size() > 0)
            numberOfAttachment = actionPlanAttachmentMap.size();

        for(Id getId : actionPlanAttachmentMap.keySet()){
            if(actionPlanAttachmentMap.containsKey(getId)){
                AttachmentInfo newAttachmentInfo = new AttachmentInfo();
                newAttachmentInfo.attachmentId = actionPlanAttachmentMap.get(getId).Id;
                newAttachmentInfo.name = actionPlanAttachmentMap.get(getId).Name;
                newAttachmentInfo.createdBy = actionPlanAttachmentMap.get(getId).CreatedBy.Name;
                newAttachmentInfo.caseNumber = customAttachmentIdMap.get(getId).Case__r.CaseNumber;
                newAttachmentInfo.createdDate = Date.newInstance(
                                                    (actionPlanAttachmentMap.get(getId).CreatedDate).year(), 
                                                    (actionPlanAttachmentMap.get(getId).CreatedDate).month(), 
                                                    (actionPlanAttachmentMap.get(getId).CreatedDate.day()) );
                newAttachmentInfo.totalCount = numberOfAttachment;
                System.debug('newAttachmentInfo :: ' + newAttachmentInfo);
                noteOrAttachmentMap.put(newAttachmentInfo.attachmentId,newAttachmentInfo);
            }
        }
        System.debug('noteOrAttachmentMap :: ' + noteOrAttachmentMap);
        return noteOrAttachmentMap;
    }

    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   class to get attachments based on category.
    Input:         caseId 
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    09-MAY-2017   Arxxus             Comment added. This method get all the signed response attachment for cases mentioned as precedent.
    ------------------------------------------------------------*/
    global static Map<Id, AttachmentInfo> getPrecedentAttachment(String caseId){
        
        Set<String> precedentCaseIdSet = new Set<String>();
        Set<String> attachmentIdSet = new Set<String>();

        Map<String,String> caseNumberWithCaseId = new Map<String,String>();
        Map<Id,AttachmentInfo> noteOrAttachmentMap = new Map<Id,AttachmentInfo>();
        Map<Id,Attachment> precedentAttachmentMap = new Map<Id,Attachment>();
        Map<Id,NoteOrAttachment__c> customAttachmentidMap = new Map<Id,NoteOrAttachment__c>();

        for(Case getCase: [Select Id, CaseNumber FROM Case
                             WHERE Id = : caseId ]) {
            caseNumberWithCaseId.put(getCase.Id, getCase.CaseNumber);
        }

        // create a set of all precedent case Ids
        for(Precedent__c getPrecedent: [Select Id, Precedent_Case__c, Related_Case__c, Precedent_Case__r.CaseNumber
                                            FROM Precedent__c
                                            WHERE Related_Case__c != NULL AND
                                            Related_Case__r.CaseNumber = : caseNumberWithCaseId.values() ]) {
            precedentCaseIdSet.add(getPrecedent.Precedent_Case__r.CaseNumber);
        }

        System.debug('precedentCaseIdSet :: ' + precedentCaseIdSet);
        Map<Id,NoteOrAttachment__c> uniqueAttachmentMap = new Map<Id,NoteOrAttachment__c>();
        // get Ids of custom attachments for precedent cases having 'Signed Response'
        for(NoteOrAttachment__c getAttachment: [Select Id, Case__r.CaseNumber, Attachment_Id__c,Case__c
                                                    FROM NoteOrAttachment__c
                                                    WHERE Case__r.CaseNumber IN: precedentCaseIdSet
                                                    AND ContentType__c = : GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF
                                                    AND Category__c = : GlobalConstants.SIGNED_RESPONSE
                                                    AND Attachment_Id__c != NULL
                                                    ORDER BY CreatedDate ASC ]) {
          
            uniqueAttachmentMap.put(getAttachment.Case__c,getAttachment);
            customAttachmentidMap.put(getAttachment.Attachment_Id__c, getAttachment);
        }

        Set<Id> uniqueAttachmentSet = new Set<Id>();
        for(Id tempCaseId : uniqueAttachmentMap.keySet()){
            if(uniqueAttachmentMap.containsKey(tempCaseId))
                uniqueAttachmentSet.add(uniqueAttachmentMap.get(tempCaseId).Attachment_Id__c);
        }

        System.debug('customAttachmentidMap :: ' + customAttachmentidMap);

        for(Attachment getSfAttachment : [ Select Id,Name,CreatedBy.Name,CreatedDate
                                                            FROM Attachment
                                                            WHERE Id IN: uniqueAttachmentSet
                                                            ORDER BY CreatedDate DESC  ]) {
            precedentAttachmentMap.put(getSfAttachment.Id, getSfAttachment);
        }
        System.debug('precedentAttachmentMap :: ' + precedentAttachmentMap);


        if(precedentAttachmentMap.size() > 0)
            numberOfAttachment = precedentAttachmentMap.size();

        for(Id getId : precedentAttachmentMap.keySet()){
            if(precedentAttachmentMap.containsKey(getId)){
                AttachmentInfo newAttachmentInfo = new AttachmentInfo();
                newAttachmentInfo.attachmentId = precedentAttachmentMap.get(getId).Id;
                newAttachmentInfo.name = precedentAttachmentMap.get(getId).Name;
                newAttachmentInfo.createdBy = precedentAttachmentMap.get(getId).CreatedBy.Name;
                newAttachmentInfo.caseNumber = customAttachmentidMap.get(getId).Case__r.CaseNumber;
                newAttachmentInfo.createdDate = Date.newInstance(
                                                    (precedentAttachmentMap.get(getId).CreatedDate).year(), 
                                                    (precedentAttachmentMap.get(getId).CreatedDate).month(), 
                                                    (precedentAttachmentMap.get(getId).CreatedDate).day() );
                newAttachmentInfo.totalCount = numberOfAttachment;

                if(caseNumberWithCaseId.containsKey(caseId))
                    newAttachmentInfo.currentCaseNumber = caseNumberWithCaseId.get(caseId);
                System.debug('newAttachmentInfo :: ' + newAttachmentInfo);
                noteOrAttachmentMap.put(newAttachmentInfo.attachmentId,newAttachmentInfo);
            }
        }
        System.debug('noteOrAttachmentMap :: ' + noteOrAttachmentMap);
        return noteOrAttachmentMap;

    }
    /*------------------------------------------------------------
    Author:        Arxxus
    Description:   class to get attachments based on category.
    Input:         caseId 
    History
    <Date>        <Authors Name>     <Brief Description of Change>
    09-MAY-2017   Arxxus             Comment added. This method get all the signed response 
                                    attachment for OBO or contact on current case.
                                    Number of document will depend on the count mentioned in 'PreviousCorro Document Count'
    ------------------------------------------------------------*/
    global static Map<Id, AttachmentInfo> getPreviousCorroAttachment(String caseId){

        String contactId = '';
        Set<Id> caseIdSet = new Set<Id>();

        Map<String,String> caseNumberWithCaseId = new Map<String,String>();
        Map<Id,AttachmentInfo> noteOrAttachmentMap = new Map<Id,AttachmentInfo>();
        Map<Id,NoteOrAttachment__c> customAttachmentidMap = new Map<Id,NoteOrAttachment__c>();
        Map<Id,Attachment> previousCorroAttachmentMap = new Map<Id,Attachment>();

        List<Case> getCurrentCaseDetail = [Select Id,CaseNumber,OBO__c,Contact.Id FROM Case
                                                WHERE Id = : caseId 
                                                AND (Contact.Id != NULL OR OBO__c != NULL) ];
                                                
        if(getCurrentCaseDetail.size() > 0) {

            caseNumberWithCaseId.put(getCurrentCaseDetail[0].Id, getCurrentCaseDetail[0].CaseNumber);

            if(getCurrentCaseDetail[0].OBO__c != NULL){
                contactId = getCurrentCaseDetail[0].OBO__c;
            }else if(getCurrentCaseDetail[0].Contact.Id != NULL)   {
                contactId = getCurrentCaseDetail[0].Contact.Id;
            }

            for(Case getCase: [Select Id, Contact.Id FROM Case
                                    WHERE ( Contact.Id = : contactId OR OBO__c =: contactId )
                                    AND Id !=: caseId]) {
                caseIdSet.add(getCase.Id);
            }    

        }

        System.debug('Previous corro case idSet :: ' + caseIdSet );

        Map<String, PreviousCorro_Document_Count__c> previousCorroDocumentMap = PreviousCorro_Document_Count__c.getAll();
        Integer getCount;

        if(previousCorroDocumentMap.containsKey('Previous Corro'))
            getCount = (previousCorroDocumentMap.get('Previous Corro').Count__c).intValue();

        Map<Id,NoteOrAttachment__c> uniqueAttachmentMap = new Map<Id,NoteOrAttachment__c>();
        
        if(caseIdSet.size() > 0) {

            for(NoteOrAttachment__c getNotesAndAttachment: [Select Id, Case__r.CaseNumber, Attachment_Id__c,Case__c
                                                                FROM NoteOrAttachment__c
                                                                WHERE Case__c IN: caseIdSet
                                                                AND ContentType__c = : GlobalConstants.ATTACHMENT_CONTENT_TYPE_PDF
                                                                AND Category__c = : GlobalConstants.SIGNED_RESPONSE
                                                                AND Attachment_Id__c != NULL
                                                                ORDER BY CreatedDate ASC 
                                                            ]) {
                    uniqueAttachmentMap.put(getNotesAndAttachment.Case__c,getNotesAndAttachment);
                    customAttachmentidMap.put(getNotesAndAttachment.Attachment_Id__c,getNotesAndAttachment);
            }
            System.debug('customAttachmentidMap :: ' + customAttachmentidMap);

            Set<Id> uniqueAttachmentSet = new Set<Id>();
            for(Id tempCaseId : uniqueAttachmentMap.keySet()){
                if(uniqueAttachmentMap.containsKey(tempCaseId))
                    uniqueAttachmentSet.add(uniqueAttachmentMap.get(tempCaseId).Attachment_Id__c);
            }
            System.debug('uniqueAttachmentMap :: ' + uniqueAttachmentMap);
            
            // limit the number of previous corro attachment mentioned in Previouscorro Document count custom setting
            for(Attachment getSfAttachment : [ Select Id,Name,CreatedBy.Name,CreatedDate
                                                FROM Attachment
                                                WHERE Id IN: uniqueAttachmentSet
                                                ORDER BY CreatedDate DESC ]) {
                
                if(previousCorroAttachmentMap.size() < getCount) {
                    previousCorroAttachmentMap.put(getSfAttachment.Id, getSfAttachment);
                }
                
            }
            System.debug('previousCorroAttachmentMap :: ' + previousCorroAttachmentMap);
        }

        if(previousCorroAttachmentMap.size() > 0)
            numberOfAttachment = previousCorroAttachmentMap.size();

        for(Id getId : previousCorroAttachmentMap.keySet()){
            if(previousCorroAttachmentMap.containsKey(getId)){
                AttachmentInfo newAttachmentInfo = new AttachmentInfo();
                newAttachmentInfo.attachmentId = previousCorroAttachmentMap.get(getId).Id;
                newAttachmentInfo.name = previousCorroAttachmentMap.get(getId).Name;
                newAttachmentInfo.createdBy = previousCorroAttachmentMap.get(getId).CreatedBy.Name;
                newAttachmentInfo.caseNumber = customAttachmentidMap.get(getId).Case__r.CaseNumber;
                newAttachmentInfo.createdDate = Date.newInstance(
                                                    (previousCorroAttachmentMap.get(getId).CreatedDate).year(), 
                                                    (previousCorroAttachmentMap.get(getId).CreatedDate).month(), 
                                                    (previousCorroAttachmentMap.get(getId).CreatedDate).day() );
                newAttachmentInfo.totalCount = numberOfAttachment;

                if(caseNumberWithCaseId.containsKey(caseId))
                    newAttachmentInfo.currentCaseNumber = caseNumberWithCaseId.get(caseId);
                System.debug('newAttachmentInfo :: ' + newAttachmentInfo);
              
                noteOrAttachmentMap.put(newAttachmentInfo.attachmentId,newAttachmentInfo);
            }
        }
        System.debug('noteOrAttachmentMap :: ' + noteOrAttachmentMap);
        return noteOrAttachmentMap;


    }
}