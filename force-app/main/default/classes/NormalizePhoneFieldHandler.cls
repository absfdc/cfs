public with sharing class NormalizePhoneFieldHandler {
    /*------------------------------------------------------------
	Author:        Shrikant Hase
	Company:       Arxxus.com
	Description:   Handler function fills normlized contact numbers on inserting a contact
	Inputs:        Trigger context parameters

	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
    public Contact normalizePhoneFields(Contact con){
        con.Normalized_Mobile__c = normalizePhone((String)con.MobilePhone);
        con.Normalized_Home_Phone__c = normalizePhone((String)con.HomePhone);
        con.Normalized_Work_Phone__c = normalizePhone((String)con.Phone);
        con.Normalized_Other_Phone__c = normalizePhone((String)con.Other_Phone__c);
        return con;
    }
    
    public String normalizePhone(String phoneNumber) {
        if(String.isBlank(phoneNumber)) {
			return '';    
        } 
        System.debug('Entered Phone :'+phoneNumber);
        String regExp = '[|,|.|\\,||"||:|~|!|@|#|$|%|^|&|*|_|=|<|>|?|\\(|\\)|\\{|\\}|\\;|\\\'"]';
        String emptyString = '';
        phoneNumber = phoneNumber.replaceAll(regExp, emptyString);
        phoneNumber = phoneNumber.deleteWhitespace();
        if(phoneNumber.contains('-')){
            phoneNumber = phoneNumber.remove('-');
        }
        if(phoneNumber.startsWith('02')){
            String ISDCode = phoneNumber.substring(0, 2);
            phoneNumber = '0'+phoneNumber;
        }
        if(phoneNumber.startsWith('+')){
            String ISDCode = phoneNumber.substring(0, 3);
            phoneNumber = phoneNumber.remove(ISDCode);
        }
        if(!phoneNumber.startsWith('0'))
        	phoneNumber = '0'+phoneNumber;
        System.debug('updated phone number = '+phoneNumber);
        return phoneNumber;
    }
    
}