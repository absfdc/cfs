/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Salesforce.com
Description:    This class is responsible to check for any suspected spam based on ip address of user responsible for creating case.
Inputs:         "ipAddress" - ip address to be used for spam check
Test Class:     WebToCaseSpamChecker_Test
History:
------------------------------------------------------------*/
public without sharing class WebToCaseSpamChecker {
    private static final Integer MAX_INT_FOR_8_BITS = 255;
    private String ipAddress;
    public WebToCaseSpamChecker(String ipAddress) {
        if(String.isBlank(ipAddress)) {
            throw new InvalidParameterForSpamCheckException('Failed to instantiate WebToCaseSpamChecker. Ip Address missing');
        }
        
        List<String> ipComponent = ipAddress.split('\\.');
        if (ipComponent.size()!= 4) {
            throw new InvalidParameterForSpamCheckException('Invalid IP address: ' + ipAddress);
        }
        for (Integer n = 0; n < ipComponent.size(); n++) {
            Integer value = Integer.valueOf(ipComponent[n]);
            if (value != (value & MAX_INT_FOR_8_BITS)) {
                throw new InvalidParameterForSpamCheckException('Invalid IP address: ' + ipAddress);
            }
        }
        this.ipAddress = ipAddress;
    }
    
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Salesforce.com
    Description:    Function checks for spam case based on number of cases created from same ip address within pre-configured time frame
    Inputs:         
    Returns:        "true" - if it is suspected spam
                    "false" - if it is normal processing and within the limits of pre-configured spam checks
    History:
    ------------------------------------------------------------*/
    public Boolean isSuspectedSpam() {
        if(isWhiteListedIp()) {
            return false; //
        }
        WebToCaseSpamSettings__c spamSettings = WebToCaseSpamSettings__c.getValues('WebToCase');
        if(spamSettings == null) {
            return false;
        }
        
        DateTime since = System.now().addMinutes(-1 * Integer.valueOf(spamSettings.Within_duration_in_min__c));
        List<Case> cases = [SELECT Id 
                            FROM Case 
                            WHERE Users_Ip_address__c = :ipAddress 
                                AND CreatedDate > :since];
                                
        if(cases.size() < spamSettings.Frequency__c) {
            return false;
        } else {
            return true;
        }
    }
    
    private Boolean isWhiteListedIp() {
        Boolean isWhitelisted = false;
        try {
            Map<String, WebToCaseWhitelistedIps__c> whitelistedIpSetting = WebToCaseWhitelistedIps__c.getAll();
            Set<String> whitelistedIps = new Set<String>();
            for(String key : whitelistedIpSetting.keySet()) {
                CIDRToIpConverter ipConverter = new CIDRToIpConverter(whitelistedIpSetting.get(key).CIDR_Ip_Address_range__c);
                whitelistedIps.addAll(ipConverter.getIpAddresses());
                if(whitelistedIps.contains(ipAddress)) {
                    return true;
                }
                whitelistedIps.clear();
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            ExceptionLogger.logException('WebToCaseSpamChecker', 'isWhiteListedIp', e, null);
        }
        return isWhitelisted;
    }
    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Salesforce.com
    Description:    Custom exception class used to throw exception in case invalid i.e. blank ip address is used to instantiate WebToCaseSpamChecker class
    Inputs:         
    Test Class:     
    History:
    ------------------------------------------------------------*/
    public class InvalidParameterForSpamCheckException extends Exception {}
}