@isTest
private class CIDRToIpConverter_Test {

    private static testMethod void testForInvalidIp() {
		System.Test.startTest();
		try {
			CIDRToIpConverter ipConverter = new CIDRToIpConverter('');
			System.assert(false);
		} catch(Exception e) {
			System.assert(true);
		}
		try {
			CIDRToIpConverter ipConverter = new CIDRToIpConverter('192');
			System.assert(false);
		} catch(Exception e) {
			System.assert(true);
		}
		try {
			CIDRToIpConverter ipConverter = new CIDRToIpConverter('192/21');
			System.assert(false);
		} catch(Exception e) {
			System.assert(true);
		}
		try {
			CIDRToIpConverter ipConverter = new CIDRToIpConverter('192.125.62.25/33');
			System.assert(false);
		} catch(Exception e) {
			System.assert(true);
		}
		try {
			CIDRToIpConverter ipConverter = new CIDRToIpConverter('192.125.62.25/7');
			System.assert(false);
		} catch(Exception e) {
			System.assert(true);
		}
		try {
			CIDRToIpConverter ipConverter = new CIDRToIpConverter('192.256.62.25/7');
			System.assert(false);
		} catch(Exception e) {
			System.assert(true);
		}
		System.Test.stopTest();
    }
    
    private static testMethod void testForValidIpAddr() {
    	System.Test.startTest();
    	CIDRToIpConverter ipConverter = new CIDRToIpConverter('192.125.62.25/24');
    	Set<String> ipAddresses = ipConverter.getIpAddresses();
    	System.Test.stopTest();
    	System.assert(ipAddresses.size() == 256);
    }    
}