/**
 * @Author: Sauce Consulting
 * @Description: Predictive2 service response class
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive2ServiceResponse {
  	public String errorMessage {get; set;}
	@AuraEnabled
	public ResponseData data {get; set;}
    
	public class AddressDetails {
		@AuraEnabled
		public Integer complexUnitIdentifier {get; set;}
		@AuraEnabled
		public String complexUnitType {get; set;}
		@AuraEnabled
		public String complexLevelType {get; set;}
		@AuraEnabled
		public Integer complexLevelNumber {get; set;}
		@AuraEnabled
		public Integer complexStreetNumber1 {get; set;}
		@AuraEnabled
		public Integer complexStreetNumber2 {get; set;}
		@AuraEnabled
		public String complexStreetName {get; set;}
		@AuraEnabled
		public String complexStreetType {get; set;}
		@AuraEnabled
		public String complexStreetSuffix {get; set;}
		@AuraEnabled
		public String streetNumber1 {get;set;} 
		@AuraEnabled
		public String streetName {get;set;} 
		@AuraEnabled
		public String streetType {get;set;} 
		@AuraEnabled
		public String localityName {get;set;} 
		@AuraEnabled
		public String stateTerritory {get;set;} 
		@AuraEnabled
		public String postcode {get;set;} 
		@AuraEnabled
		public String formattedAddress {get;set;} 
		@AuraEnabled
		public String streetTypeDescription {get;set;} 
		public String lotIdentifier {get;set;} 
		public String aliasPrincipal {get;set;} 
		public String gnafLocalityPid {get;set;} 
		public String gnafStreetLocalityPid {get;set;} 
		public String localityNeighbours {get;set;} 
		public String cadastralIdentifier {get;set;} 
		public String deliveryPointIdentifier {get;set;}
	}
	
	public class ResponseData {
		@AuraEnabled
		public AddressDetails addressDetails {get;set;} 
		public String addressId {get;set;} 
		public String addressRecordType {get;set;}		
	} 
}