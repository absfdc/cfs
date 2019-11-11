trigger BUStagingTrigger on BU_Staging__c (before insert, after insert) {
	// This is the only line of code that is required.
    TriggerFactory.createTriggerDispatcher(BU_Staging__c.sObjectType);
}