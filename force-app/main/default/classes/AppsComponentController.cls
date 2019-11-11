public with sharing class AppsComponentController {
    public Boolean isIE8 {get; set;}
    public static final String USER_AGENT_IE8 = 'MSIE 8';
    
    public AppsComponentController() {
        String userAgent = ApexPages.currentPage().getHeaders().get('User-Agent');
        if(!String.isBlank(userAgent) && userAgent.contains(USER_AGENT_IE8)) {
            isIE8 = true;
        } else {
            isIE8 = false;
        }
    }
    public List<String> appOptions {
        get{
            Map<String, AppsForWebform__c> options = AppsForWebform__c.getAll();
            List<String> optionValues = new List<String>();
            List<Integer> sortOrder = new List<Integer>();
            Map<Integer, AppsForWebform__c> mapOfApps = new Map<Integer, AppsForWebform__c>();
            for(AppsForWebform__c app : options.values()) {
                sortOrder.add((Integer)app.Sort_Order__c);
                mapOfApps.put((Integer)app.Sort_Order__c, app);
            }
            sortOrder.sort();
            for(Integer index : sortOrder) {
                optionValues.add(mapOfApps.get(index).Name);
            }
            return optionValues;
        }
        set{}}  
    
    public List<SelectOption> relatedTo{
        get{
            Map<String, AppFeedbackRelatedTo__c> options = AppFeedbackRelatedTo__c.getAll();
            List<SelectOption> relatedToOptions = new List<SelectOption>();
            relatedToOptions.add(new SelectOption('','Please select'));
            List<Integer> listOfValues = new List<Integer>();
            Map<Integer, String> orderVsValue = new Map<Integer, String>();
            for(AppFeedbackRelatedTo__c option : options.values()) {
                listOfValues.add(Integer.valueOf(option.Sort_Order__c));
                orderVsValue.put(Integer.valueOf(option.Sort_Order__c), option.Name);
            }
            listOfValues.sort();
            for(Integer values : listOfValues) {
                relatedToOptions.add(new SelectOption(orderVsValue.get(values), orderVsValue.get(values)));
            }
            return relatedToOptions;
            
        }
        set{}} 
        
    public List<SelectOption> yesNoOption { set{}
        get{
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('Yes','Yes'));
            options.add(new SelectOption('No','No'));
            return options;
        }
    }     
}