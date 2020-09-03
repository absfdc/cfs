/**
 * @Author: Sauce Consulting
 * @Description: Predictive1 service client class to send request to predictive1 endpoint.
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   7-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class Predictive1ServiceClient extends NSWPointServiceClient{
    
    /**
     * Create an instance of the predictive1 service client
     */
    public Predictive1ServiceClient(NSWPointServiceLocator serviceLocator) {     
        super(serviceLocator);        
    }

    /**
     * Predictive1 service doesn't support post method and hence throw exception
     */
    protected override HttpRequest buildPost(NSWPointServiceRequest request, String endpoint){
      throw new NSWPointServiceException('Predictive1 service doesn\'t support POST method');
    }	
}