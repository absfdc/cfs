/**
 * @Author: Sauce Consulting
 * @Description: Predictive1 service response class
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class AddressValidationServiceResponse{
  	public String errorMessage {get; set;}
	public ResponseData data {get; set;}
    
	public class AddressDetails {
    	public String streetNumber1 {get;set;} 
		public String streetName {get;set;} 
		public String streetType {get;set;} 
		public String localityName {get;set;} 
		public String stateTerritory {get;set;} 
		public String postcode {get;set;} 
		public String formattedAddressString {get;set;} 
	}
	
	public class ResponseData {
		public AddressDetails addressDetails {get;set;} 
		public DataProperties properties {get; set;}
		public String addressIdentifier {get;set;}
	}

	public class DataProperties{
		public String matchResult {get; set;}
		public String matchCertainty {get; set;}
		public String matchQualityPercentage {get; set;}
	}

	public Boolean isValid(){
		Boolean result = false;
		if(data != null && data.addressDetails != null && data.properties != null 
				&& Decimal.valueOf(data.properties.matchQualityPercentage) >= Integer.valueOf(Label.Address_Validation_Probability_Match)){
			result = true;
		}
		return result;
	}
}