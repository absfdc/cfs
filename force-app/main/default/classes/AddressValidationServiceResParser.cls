/**
 * @Author: Sauce Consulting
 * @Description: Implementation class for address validation service response parser
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class AddressValidationServiceResParser implements NSWPointServiceResponseParser {
	private Boolean isError = true;
	private AddressValidationServiceResponse responseData;
	
	public void parse(NSWPointServiceResponse response){
		if(response != null){
			if(response.responseStatusCode == 200) {
				isError = false;
				System.debug(LoggingLevel.INFO, 'Success response received from address validation service.');
				responseData = (AddressValidationServiceResponse) JSON.deserialize(response.getResponseText(), AddressValidationServiceResponse.class);
			} else {
				System.debug(LoggingLevel.WARN, 'Request to address validation service failed with status code ' + response.responseStatusCode);
				responseData = (AddressValidationServiceResponse) JSON.deserialize(response.getResponseText(), AddressValidationServiceResponse.class);				
			}
		} else {
			throw new NSWPointServiceException('Response parser expects instance of NSWPointServiceResponse as input');
		}
	}
		
	public AddressValidationServiceResponse getResponseData(){
		return this.responseData;
	}

	public String getErrorMessage(){
		if(responseData != null){
			return responseData.errorMessage;
		}
		return null;
	}

	public Boolean isErrorResponse(){
		return this.isError;
	}
}