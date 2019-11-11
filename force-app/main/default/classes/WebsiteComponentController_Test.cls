@isTest
private class WebsiteComponentController_Test {
    
    private static testMethod void testForAvailableWebsites() {
        List<WebsitesForWebForm__c> websites = new List<WebsitesForWebForm__c>();
        websites.add(new WebsitesForWebForm__c(Name='newcastlebuses.info',Website_Name__c='newcastlebuses.info', Sort_Order__c = 1));
        websites.add(new WebsitesForWebForm__c(Name='nswtrainlink.info',Website_Name__c='nswtrainlink.info', Sort_Order__c = 2));
        insert websites;
        
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getHeaders().put('User-Agent', 'MSIE 8');
        WebsiteComponentController acc = new WebsiteComponentController();
        List<String> websiteList = acc.websiteOptions ;
        List<SelectOption> websiteOptions = acc.websiteOptionsDropDown;
        System.Test.stopTest();
        System.assert(websiteList.size() == 2);
        System.assertNotEquals(websiteOptions,null);
    }
    
    private static testMethod void testForRelatedToField() {
        List<WebFeedbackRelatedTo__c> relatedTo = new List<WebFeedbackRelatedTo__c>();
        relatedTo.add(new WebFeedbackRelatedTo__c(name = '1', Related_To__c = 'Service disruption info', Sort_Order__c = 1));
        relatedTo.add(new WebFeedbackRelatedTo__c(name = '2', Related_To__c = 'Ticketing information', Sort_Order__c = 2));
        insert relatedTo;
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseForm);
        ApexPages.currentPage().getHeaders().put('User-Agent', 'MSIE 11');
        WebsiteComponentController acc = new WebsiteComponentController();
        List<SelectOption> relatedToList = acc.relatedTo;
        System.Test.stopTest();
        System.assert(relatedToList.size() == 3);
    }
    
    private static testMethod void testForOptions() {
        System.Test.startTest();
        WebsiteComponentController acc = new WebsiteComponentController();
        List<SelectOption> options = acc.yesNoOption;
        System.Test.stopTest();
        System.assert(options.size() == 2);
    }
}