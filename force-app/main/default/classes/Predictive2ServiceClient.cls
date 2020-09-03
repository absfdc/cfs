/**
 * @Author: Sauce Consulting
 * @Description: Predictive2 service client class to send request to predictive2 endpoint.
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   7-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class Predictive2ServiceClient extends NSWPointServiceClient{
    
    /**
     * Create an instance of the predictive2 service client
     */
    public Predictive2ServiceClient(NSWPointServiceLocator serviceLocator) {     
        super(serviceLocator);        
    }

    /**
     * Predictive2 service doesn't support GET method and hence throw exception
     */
    protected override HttpRequest buildGet(NSWPointServiceRequest request, String endpoint){
      throw new NSWPointServiceException('Predictive2 service doesn\'t support GET method');
    }	
}