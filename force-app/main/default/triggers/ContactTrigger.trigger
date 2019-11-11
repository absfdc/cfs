trigger ContactTrigger on Contact (after insert, after delete, before update, before insert) {
	// This is the only line of code that is required.
	TriggerFactory.createTriggerDispatcher(Contact.sObjectType);
}