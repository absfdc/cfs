trigger TaskTrigger on Task (after insert, before delete, before insert, before update) {
    // This is the only line of code that is required.
    TriggerFactory.createTriggerDispatcher(Task.sObjectType);
}