trigger ActionPlanTrigger on Action_Plan__c (before insert, before update, before delete, after insert,after update, after delete, after undelete) {
   TriggerFactory.createTriggerDispatcher(Action_Plan__c.sObjectType);
}