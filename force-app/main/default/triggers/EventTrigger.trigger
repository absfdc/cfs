trigger EventTrigger on Event (before delete) {
	    TriggerFactory.createTriggerDispatcher(Event.sObjectType);
}