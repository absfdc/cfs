@isTest
private class WebformContactController_Test {

    private static testMethod void testForStates() {
        List<AusStates__c> ausStates = new List<AusStates__c>();
        ausStates.add(new AusStates__c(Name='NSW', Sort_order__c = 1));
        ausStates.add(new AusStates__c(Name='VIC', Sort_order__c = 2));
        ausStates.add(new AusStates__c(Name='QLD', Sort_order__c = 3));
        insert ausStates;
        System.Test.startTest();
        WebformContactController controller = new WebformContactController();
        List<SelectOption> states = controller.getStates();
        controller.setStates(states);
        System.Test.stopTest();
        System.assert(states.size() == 4);
    }
    
    private static testMethod void testForPreviouslyRaisedOptions() {
        System.Test.startTest();
        WebformContactController controller = new WebformContactController();
        List<SelectOption> options = controller.getPreviouslyRaisedIssueOptions();
        controller.setPreviouslyRaisedIssueOptions(options);
        System.Test.stopTest();
        System.assert(!options.isEmpty());
    }
}