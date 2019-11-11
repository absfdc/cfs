trigger DraftTrigger on TH1__Draft__c (after insert, after Update, before update) {
    TriggerFactory.createTriggerDispatcher(TH1__Draft__c.sObjectType);
}