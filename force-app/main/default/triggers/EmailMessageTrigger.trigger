trigger EmailMessageTrigger on EmailMessage (before insert, before delete) {

    // This is the only line of code that is required.
    TriggerFactory.createTriggerDispatcher(EmailMessage.sObjectType);

}