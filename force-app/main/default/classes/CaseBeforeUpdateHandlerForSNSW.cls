public without sharing class CaseBeforeUpdateHandlerForSNSW extends TriggerHandlerBase {
    private static Id sharedCaseOwner;
    private Map<Id,Contact> contacts;
    private Boolean invokedBySNSW;
    public static string descriptionForSNSW = 'This case was received via the Feedback Assist widget';
    
    public CaseBeforeUpdateHandlerForSNSW() {
        this(false);
    }
    
    public CaseBeforeUpdateHandlerForSNSW(Boolean invokedBySNSW) {
        this.invokedBySNSW = invokedBySNSW;
    }
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {

    }

    private void process(TriggerParameters tp) {
        try {
            if(invokedBySNSW) {
                processIncomingCases(tp);
            } else {
                processOutgoingCases(tp);
            }            
        }catch(Exception e){
            System.debug(e);
            list<ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'CaseBeforeUpdateHandlerForSNSW';
            message.sourceFunction = 'process';
            if (tp!=null && tp.newMap!=null) message.referenceInfo = JSON.serialize(tp.newMap.keySet());
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
    
    private void processIncomingCases(TriggerParameters tp) {
        IncomingSnswToRmsCaseProcessor incomingCaseProcessor = new IncomingSnswToRmsCaseProcessor((Map<Id,Case>) tp.newMap, (Map<Id,Case>) tp.oldMap);
        incomingCaseProcessor.processCases();
    }
    
    private void processOutgoingCases(TriggerParameters tp) {
        if(sharedCaseOwner == null) {
            retrieveQueueId();
        }
        //SFCOE-3175
        determineLastAssignedQueue(tp);

        List<Case> cases = (List<Case>) tp.newList;
        updateContactDetails(cases);
        
        Map<Id,Case> oldMap = (Map<Id, Case>) tp.oldMap;
        for(Case caseRecord : (List<Case>) tp.newList) {
            if(GlobalConstants.RESPONSIBLE_PARTY_SNSW.equalsIgnoreCase(caseRecord.Responsible_Party__c) 
                    && !GlobalConstants.RESPONSIBLE_PARTY_SNSW.equalsIgnoreCase(oldMap.get(caseRecord.Id).Responsible_Party__c)
                    && !caseRecord.Shared__c) {
                if(!caseRecord.Contact_and_POI_shared__c) {
                    populateContactAndPoiInfo(caseRecord);
                    caseRecord.Contact_and_POI_shared__c = true;
                }
                caseRecord.Shared__c = true;
                caseRecord.Agency__c = GlobalConstants.SNSW_AGENCY;
                caseRecord.OwnerAgency__c = GlobalConstants.SNSW_AGENCY;
                system.debug('caseRecord.isFeedbackAssist__c***'+caseRecord.isFeedbackAssist__c);
                
                if(caseRecord.isFeedbackAssist__c!=null && caseRecord.isFeedbackAssist__c == true)
                	caseRecord.Description = caseRecord.Description + '\n' + '\n' + descriptionForSNSW;
                
                if(sharedCaseOwner != null) {
                    caseRecord.OwnerId = sharedCaseOwner;
                }
            }
        }
    }
    
    private void updateContactDetails(List<Case> cases) {
        Set<Id> contactIds = new Set<Id>();
        for(Case caseRecord : cases) {
            contactIds.add(caseRecord.ContactId);
        }
        if(contactIds.isEmpty()) {
            return;
        }
        contacts = new Map<Id, Contact> ([  SELECT Id, Name, Phone, MobilePhone, OtherPhone, Email, MailingStreet, 
                                                MailingCity, MailingState, MailingPostalCode, MailingCountry
                                            FROM Contact WHERE Id IN :contactIds]);
                
        for(Case caseRecord : cases) {
            if(contacts.get(caseRecord.ContactId) == null) {
                continue;
            }
            caseRecord.SuppliedName = contacts.get(caseRecord.ContactId).Name;
            caseRecord.SuppliedEmail = contacts.get(caseRecord.ContactId).Email;
            
            caseRecord.Supplied_Address__c = '';
            if(contacts.get(caseRecord.ContactId).MailingStreet != null) {
                caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contacts.get(caseRecord.ContactId).MailingStreet + ' ';
            }
            if(contacts.get(caseRecord.ContactId).MailingCity != null) {
                caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contacts.get(caseRecord.ContactId).MailingCity + ' ';
            }
            if(contacts.get(caseRecord.ContactId).MailingState != null) {
                caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contacts.get(caseRecord.ContactId).MailingState + ' ';
            }
            if(contacts.get(caseRecord.ContactId).MailingPostalCode != null) {
                caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contacts.get(caseRecord.ContactId).MailingPostalCode + ' ';
            }
            if(contacts.get(caseRecord.ContactId).MailingCountry != null) {
                caseRecord.Supplied_Address__c = caseRecord.Supplied_Address__c + contacts.get(caseRecord.ContactId).MailingCountry + ' ';
            }
            
            if(contacts.get(caseRecord.ContactId).OtherPhone != null) {
                caseRecord.SuppliedPhone = contacts.get(caseRecord.ContactId).OtherPhone;
            }            
            if(contacts.get(caseRecord.ContactId).Phone != null) {
                caseRecord.SuppliedPhone = contacts.get(caseRecord.ContactId).Phone;
            }
        }
    }
    
    private void populateContactAndPoiInfo(Case caseRecord) {
        String contactInfo = getContactInfo(caseRecord);
        String poiInfo = getPoiInfo(caseRecord);
        if(String.isBlank(caseRecord.Description)) {
            caseRecord.Description = '';
        }
        if(!String.isBlank(contactInfo)) {
            caseRecord.Description = caseRecord.Description + '\n\n' + contactInfo;
        }
        if(!String.isBlank(poiInfo)) {
            caseRecord.Description = caseRecord.Description + '\n\n' + poiInfo;
        }
    }
    
    private String getPoiInfo(Case caseRecord) {
        String poiInfo;
        if(!String.isBlank(caseRecord.License_Photo_Card_Number__c) 
                || !String.isBlank(caseRecord.RMS_Vehicle_registration__c) 
                || !String.isBlank(caseRecord.E_Toll_Account_Number__c)) {
            poiInfo = 'POI Information:\n';
        }
        if(!String.isBlank(caseRecord.License_Photo_Card_Number__c)) {
            poiInfo = poiInfo + 'Licence/Photo card number: ' + caseRecord.License_Photo_Card_Number__c + '\n';
        }
        if(!String.isBlank(caseRecord.RMS_Vehicle_registration__c)) {
            poiInfo = poiInfo + 'Vehicle registration: ' + caseRecord.RMS_Vehicle_registration__c + '\n';
        }
        if(!String.isBlank(caseRecord.E_Toll_Account_Number__c)) {
            poiInfo = poiInfo + 'E-Toll account number: ' + caseRecord.E_Toll_Account_Number__c + '\n';
        }
        return poiInfo;
    }
    
    private String getContactInfo(Case caseRecord) {
        String contactInfo;
        if(!String.isBlank(caseRecord.SuppliedName) 
                || !String.isBlank(caseRecord.SuppliedEmail) 
                || !String.isBlank(caseRecord.SuppliedPhone)
                || !String.isBlank(caseRecord.Supplied_Address__c)) {
            contactInfo = 'Contact Information:\n';
        }
        if(!String.isBlank(caseRecord.SuppliedName)) {
            contactInfo = contactInfo + 'Name: ' + caseRecord.SuppliedName + '\n';
        }
        if(!String.isBlank(caseRecord.SuppliedEmail)) {
            contactInfo = contactInfo + 'Email: ' + caseRecord.SuppliedEmail + '\n';
        }
        if(!String.isBlank(caseRecord.SuppliedPhone)) {
            contactInfo = contactInfo + 'Phone: ' + caseRecord.SuppliedPhone + '\n';
        }
        if(contacts.get(caseRecord.ContactId) != null && contacts.get(caseRecord.ContactId).MobilePhone != null) {
            contactInfo = contactInfo + 'Mobile: ' + contacts.get(caseRecord.ContactId).MobilePhone + '\n';
        }
        if(!String.isBlank(caseRecord.Supplied_Address__c)) {
            contactInfo = contactInfo + 'Address: ' + caseRecord.Supplied_Address__c + '\n';
        }
        
        return contactInfo;
    }
    
    private static void retrieveQueueId() {
        List<Group> groups = [  SELECT Id, Name 
                                FROM Group 
                                WHERE Name = :GlobalConstants.SNSW_HOLDING_QUEUE
                                    AND Type = 'Queue'];
        if(!groups.isEmpty()) {
            sharedCaseOwner = groups[0].Id;
        }
    }

    private void determineLastAssignedQueue(TriggerParameters tp) {
        map <Id,Id> caseIdVsOwnerQueueId = new map <Id,Id>();
        map <Id,Group> queues = CaseTriggerDispatcher.queues;        
        for (Case newCase : (list<Case>) tp.newList){
            //If owner is queue then capture that Queue Name
            if(((String) newCase.OwnerId).startsWith(GlobalConstants.GROUP_ID_PREFIX))  {
                caseIdVsOwnerQueueId.put(newCase.Id, newCase.OwnerId);
            }
        }
        
        for(Case newCase : (list<Case>) tp.newList){
            if(caseIdVsOwnerQueueId.containsKey(newCase.Id) && queues.containsKey(caseIdVsOwnerQueueId.get(newCase.Id))) {
                newCase.Last_Queue_Assigned__c = queues.get(caseIdVsOwnerQueueId.get(newCase.Id)).DeveloperName;
                newCase.Datetime_last_assigned_queue__c = System.now();
                
            //SFCOE-88 Stamp email address of Last Assigned Queue - Start
            //Added email
            	String lastQueueEmail = queues.get(caseIdVsOwnerQueueId.get(newCase.Id)).Email;
                if(!String.isEmpty(lastQueueEmail))
                	newCase.Last_Queue_Assigned_Email__c = lastQueueEmail;
                
            //SFCOE-88 Stamp email address of Last Assigned Queue - End                
                
            }
        }
        System.debug('-------@CaseBeforeInsert----Last Assigned Queue Stamped----');
    }
}