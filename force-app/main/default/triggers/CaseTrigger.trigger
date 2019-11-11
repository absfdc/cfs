trigger CaseTrigger on Case (before insert, before update, before delete, after update, after delete, after undelete, after insert) {
    // This is the only line of code that is required.
    TriggerFactory.createTriggerDispatcher(Case.sObjectType);
}