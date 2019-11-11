@isTest
private class AppsComponentController_Test {
    
    private static testMethod void testForAvailableApps() {
        List<AppsForWebform__c> apps = new List<AppsForWebform__c>();
        apps.add(new AppsForWebform__c(Name='Arrivo', Sort_Order__c = 1));
        apps.add(new AppsForWebform__c(Name='Travel+', Sort_Order__c = 2));
        insert apps;        
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getHeaders().put('User-Agent', 'MSIE 11');
        AppsComponentController acc = new AppsComponentController();
        List<String> optionList = acc.appOptions;
        System.Test.stopTest();
        System.assert(optionList.size() == 2);
    }
    
    private static testMethod void testForRelatedToField() {
        List<AppFeedbackRelatedTo__c> relatedTo = new List<AppFeedbackRelatedTo__c>();
        relatedTo.add(new AppFeedbackRelatedTo__c(name = 'Functionality', Sort_Order__c = 1));
        relatedTo.add(new AppFeedbackRelatedTo__c(name = 'Messaging', Sort_Order__c = 2));
        insert relatedTo;        
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getHeaders().put('User-Agent', 'MSIE 8');
        AppsComponentController acc = new AppsComponentController();
        List<SelectOption> relatedToList = acc.relatedTo;
        System.Test.stopTest();
        System.assert(relatedToList.size() == 3);
    }
    
    private static testMethod void testForOptions() {
        System.Test.startTest();
        AppsComponentController acc = new AppsComponentController();
        List<SelectOption> options = acc.yesNoOption;
        System.Test.stopTest();
        System.assert(options.size() == 2);
    }
}