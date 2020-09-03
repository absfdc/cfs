/**
 * @Author: Sauce Consulting
 * @Description: Implementation class for address validation request builder
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class AddressValidationServiceReqBuilder implements NSWPointServiceRequestBuilder {
    
    /**
     * Implementation of buildRequest for address validation service
     */
    public NSWPointServiceRequest buildRequest(Object reqParams) {
	    AddressValidationServiceRequest request = new AddressValidationServiceRequest();
        if(reqParams instanceof AddressDetails) {
			AddressDetails addrDetails = (AddressDetails) reqParams;
			if(String.isBlank(addrDetails.addressSearchStr)){
				throw new NSWPointServiceException('Address to validate is mandatory parameter for address validation service.');
            }
			String address = 'address=' + getEncodedParameter(addrDetails.addressSearchStr);
            request.requestBody = address;
			request.headers = new Map<String, String>();
            request.headers.put('x-api-key',NSWPointServiceCredsRetriever.getKey(Label.Address_Validation_Service_Name));
            request.headers.put('Access-Control-Request-Headers','x-requested-with');
        }else{
			throw new NSWPointServiceException('Invalid parameter to build address validation service request');
        }
	    return request;
    }

    private String getEncodedParameter(String param){
        return EncodingUtil.urlEncode(param, 'UTF-8');
    }
}