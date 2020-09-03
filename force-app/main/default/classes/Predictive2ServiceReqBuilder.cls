/**
 * @Author: Sauce Consulting
 * @Description: Implementation class for predictive2 service request builder
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive2ServiceReqBuilder implements NSWPointServiceRequestBuilder {
    
    /**
     * Implementation of buildRequest for predictive2 service
     */
    public NSWPointServiceRequest buildRequest(Object reqParams) {
	    Predictive2ServiceRequest request = new Predictive2ServiceRequest();
        if(reqParams instanceof AddressDetails) {
			AddressDetails addrDetails = (AddressDetails) reqParams;
			if(String.isBlank(addrDetails.addressId)){
				throw new NSWPointServiceException('Address Id is mandatory for predictive2 service.');
            }
            String outputFields = '[]';
            if(!String.isBlank(addrDetails.outputFields)){
                outputFields = addrDetails.outputFields;
            }
			String addressId = addrDetails.addressId;
            System.debug(LoggingLevel.INFO, 'AddressId: ' + addressId);
            System.debug(LoggingLevel.INFO, 'OutFields: ' + outputFields);
            request.requestBody = '{"id":"' + addressId + '", "outFields":' + outputFields + '}';
			request.headers = new Map<String, String>();
            request.headers.put('x-api-key',NSWPointServiceCredsRetriever.getKey(Label.Predictive2_Service_Name));
            request.headers.put('Access-Control-Request-Headers','x-requested-with');
        }else{
			throw new NSWPointServiceException('Invalid parameter to build predictive2 service request');
        }
	    return request;
    }
}