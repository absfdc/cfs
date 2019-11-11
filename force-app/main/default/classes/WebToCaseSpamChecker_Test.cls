@isTest
private class WebToCaseSpamChecker_Test {
	
	private static String ipAddress;

    private static testMethod void testForInvalidIp() {
        System.Test.startTest();
        try {
        	WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker('');
        	System.assert(false);
        } catch(Exception e) {
        	System.assert(true);
        }
        try {
        	WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker('192.125');
        	System.assert(false);
        } catch(Exception e) {
        	System.assert(true);
        }
        try {
        	WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker('192.125.256.25');
        	System.assert(false);
        } catch(Exception e) {
        	System.assert(true);
        }
        System.Test.stopTest();
    }
    
    private static testMethod void testForWhiteListedIp() {
    	setUpTestData(false, true, 10);
    	System.Test.startTest();
    	WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker(ipAddress);
    	System.assert(!spamChecker.isSuspectedSpam());
    	System.Test.stopTest();
    }
    
	private static testMethod void testForNonWhitelistedIpRegularCase() {
		setUpTestData(false, false, 10);
		System.Test.startTest();
    	WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker(ipAddress);
    	System.assert(!spamChecker.isSuspectedSpam());
    	System.Test.stopTest();
	}
	
	private static testMethod void testForNonWhitelistedIpSpamCase() {
		setUpTestData(true, false, 10);
		System.Test.startTest();
    	WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker(ipAddress);
    	System.assert(spamChecker.isSuspectedSpam());
    	System.Test.stopTest();
	}
	
	private static testMethod void testForSpamCaseWithoutCustomSetting() {
		System.Test.startTest();
		WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker('192.125.62.125');
    	System.assert(!spamChecker.isSuspectedSpam());
		System.Test.stopTest();
	}
    
    private static void setUpTestData(Boolean isSpam, Boolean isWhitelisted, Integer caseCount) {
    	WebToCaseSpamSettings__c spamSetting = new WebToCaseSpamSettings__c();
    	//create spam setting for max 10 allowed cases within 10 mins.
    	spamSetting.Within_duration_in_min__c = 10;
    	spamSetting.Frequency__c = caseCount;
    	spamSetting.Name = 'WebToCase';
    	insert spamSetting;
    	if(isWhitelisted) {
    		ipAddress = '192.125.62.125';
    		caseCount++;
    	} else {
    		ipAddress = '192.125.26.146';
    	}
    	
    	if(!isSpam) {
    		caseCount--; 
    	}
    	createCases(caseCount); 
    	createWhiteListSetting();
    }
    private static void createCases(Integer caseCount) {
    	List<Case> cases = new List<Case>();
    	for(Integer i = 0; i < caseCount; i++) {
    		Case caseRecord = new Case();
    		caseRecord.Origin = 'Web';
    		caseRecord.Priority = 'Normal';
    		caseRecord.Type = 'Compliment';
    		caseRecord.Description = 'Test case for spam check';
    		caseRecord.Users_Ip_address__c = ipAddress;
    		cases.add(caseRecord);
    	}
    	insert cases;
    }
    
    private static void createWhiteListSetting() {
    	WebToCaseWhitelistedIps__c whitelistedip = new WebToCaseWhitelistedIps__c();
    	whitelistedip.CIDR_Ip_Address_range__c = '192.125.62.25/24';
    	whitelistedip.Name = 'Whitelisted ip for Web2Case';
    	
    	insert whitelistedip;
    }
}