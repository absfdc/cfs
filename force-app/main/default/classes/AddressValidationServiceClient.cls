/**
 * @Author: Sauce Consulting
 * @Description: Address validation service client class to send request to address validation endpoint.
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   7-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class AddressValidationServiceClient extends NSWPointServiceClient{
    
    /**
     * Create an instance of the address validation service client
     */
    public AddressValidationServiceClient(NSWPointServiceLocator serviceLocator) {     
        super(serviceLocator);        
    }  

    /**
     * Though address validation service supports post method, it is preferred to use GET and hence throw exception
     */
    protected override HttpRequest buildPost(NSWPointServiceRequest request, String endpoint){
		  throw new NSWPointServiceException('Salesforce to AddressValidation service doesn\'t support POST method');      
	  }
}