public with sharing class WebsiteComponentController {
    public Boolean isIE8 {get; set;}
    public Integer textBoxHeight {get; set;}
    public static final Double CHARACTER_FONT_SIZE_ON_WEBFORM = 20.0;

    public List<String> websiteOptions {
        get{
            Map<String, WebsitesForWebForm__c> options = WebsitesForWebForm__c.getAll();
            List<String> optionValues = new List<String>();
            List<Integer> sortOrder = new List<Integer>();
            Map<Integer, WebsitesForWebForm__c> mapOfWebs = new Map<Integer, WebsitesForWebForm__c>();
            for(WebsitesForWebForm__c website : options.values()) {
                sortOrder.add((Integer)website.Sort_Order__c);
                mapOfWebs.put((Integer)website.Sort_Order__c, website);
            }
            sortOrder.sort();
            for(Integer index : sortOrder) {
                optionValues.add(mapOfWebs.get(index).Website_Name__c);
                if(mapOfWebs.get(index).Website_Name__c.length() > textBoxHeight) {
                    textBoxHeight = mapOfWebs.get(index).Website_Name__c.length();
                }
            }
            textBoxHeight = (Integer)((Math.ceil(textBoxHeight/CHARACTER_FONT_SIZE_ON_WEBFORM) + 1) * CHARACTER_FONT_SIZE_ON_WEBFORM);
            return optionValues;
        }
        set{}}  
    
    /*Dec 2016 - SP : SFCOE - 872 : remove thumbnails : new method added for displaying values as a dropdown on website*/
    public List<SelectOption> websiteOptionsDropDown{
        get{
            Map<String, WebsitesForWebForm__c> options = WebsitesForWebForm__c.getAll();
            List<SelectOption> websiteOptionsList = new List<SelectOption>();
            websiteOptionsList.add(new SelectOption('','Please select'));
            List<Integer> listOfValues = new List<Integer>();
            Map<Integer, String> orderVsValue = new Map<Integer, String>();
            for(WebsitesForWebForm__c option : options.values()) {            
                listOfValues.add(Integer.valueOf(option.Sort_Order__c));
                orderVsValue.put(Integer.valueOf(option.Sort_Order__c), option.Website_Name__c);
            }
            listOfValues.sort();
            for(Integer values : listOfValues) {
                String websiteName = orderVsValue.get(values);
                if(websiteName.indexOf('(') != -1 && websiteName.indexOf('State Transit') == -1)
					websiteName = websiteName.substring(0, websiteName.indexOf('('));
                
                websiteOptionsList.add(new SelectOption(orderVsValue.get(values), websiteName));
            }
            websiteOptionsList.add(new SelectOption('Other', 'Other'));
            return websiteOptionsList;
            
        }
        set{}}
    
    public List<SelectOption> relatedTo{
        get{
            Map<String, WebFeedbackRelatedTo__c> options = WebFeedbackRelatedTo__c.getAll();
            List<SelectOption> relatedToOptions = new List<SelectOption>();
            relatedToOptions.add(new SelectOption('','Please select'));
            List<Integer> listOfValues = new List<Integer>();
            Map<Integer, String> orderVsValue = new Map<Integer, String>();
            for(WebFeedbackRelatedTo__c option : options.values()) {
                listOfValues.add(Integer.valueOf(option.Sort_Order__c));
                orderVsValue.put(Integer.valueOf(option.Sort_Order__c), option.Related_To__c);
            }
            listOfValues.sort();
            for(Integer values : listOfValues) {
                
                String relatedToValuesName = orderVsValue.get(values);
                if(relatedToValuesName.indexOf('(') != -1)
					relatedToValuesName = relatedToValuesName.substring(0, relatedToValuesName.indexOf('(')-1);
                
                relatedToOptions.add(new SelectOption(orderVsValue.get(values), relatedToValuesName));
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
    
    public WebsiteComponentController() {
        textBoxHeight = 0;
        String userAgent = ApexPages.currentPage().getHeaders().get('User-Agent');
        if(!String.isBlank(userAgent) && userAgent.contains('MSIE 8')) {
            isIE8 = true;
        } else {
            isIE8 = false;
        }
    }
    
}