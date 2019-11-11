/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    Controller class for displaying any error during case creation from webform.
Inputs:         
Test Class:     WebToCaseErrorPage_Test
History:
------------------------------------------------------------*/
public with sharing class WebToCaseErrorPage_CC {
    
    public String source {get; set;}
    
    public WebToCaseErrorPage_CC() {
        try{
            String referer = ApexPages.currentPage().getHeaders().get('Referer');            
            String refererUrl = '';
            if(!String.isBlank(referer)) {
                refererUrl = EncodingUtil.urlDecode(referer, 'UTF-8');
            }            
            if(!String.isBlank(refererUrl)) {
                List<String> refererUrlComponents = refererUrl.split('\\?');
                System.debug(refererUrlComponents);
                if(refererUrlComponents.size() == 2) {
                    String queryString = refererUrlComponents[1];
                    List<String> parameters = queryString.split('&');
                    Map<String, String> keyValuePair = new Map<String, String>();
                    for(String parameter : parameters) {
                        List<String> keyValue = parameter.split('=');                        
                        if(keyValue.size() == 2) {
                            keyValuePair.put( keyValue[0],keyValue[1]);
                        }
                    }
                    source = keyValuePair.get('source');
                    if(!String.isBlank(source) && (source == 'rms intranet' || source == 'maritime')) {
                        source = 'rms';
                    }
                }
            } 
            if(!String.isBlank(ApexPages.currentPage().getParameters().get('source')) && source == null) {
                source = ApexPages.currentPage().getParameters().get('source');
                if(!String.isBlank(source) && (source == 'rms intranet' || source == 'maritime')) {
                    source = 'rms';
                }
            } 
            System.debug('Source in constructor ' + source);           
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e);
        }
    }
    
    public String getErrorMessage() {
        String errorMessage = '';
        Map<String, WebToCaseErrorMessages__c> errorMessages = WebToCaseErrorMessages__c.getAll();
        if(!errorMessages.isEmpty()) {
            System.debug('Source: ' + source);
            if(errorMessages.containsKey(source)) {
                errorMessage = errorMessages.get(source).Message__c;
            } else if(errorMessages.containsKey(GlobalConstants.WEBTOCASE_SOURCE_TNSW_TRAINS)) {
                errorMessage = errorMessages.get(GlobalConstants.WEBTOCASE_SOURCE_TNSW_TRAINS).Message__c;
            }
        }
        return errorMessage;
    }
    
    public void setErrorMessage(String errorMessage) {}
}