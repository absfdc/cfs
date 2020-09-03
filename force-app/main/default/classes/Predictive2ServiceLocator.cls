/**
 * @Author: Sauce Consulting
 * @Description: Implementation of service locator class for predictive2 address search
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive2ServiceLocator implements NSWPointServiceLocator {
    
    private final String ENDPOINT;

    public Predictive2ServiceLocator(){
      ENDPOINT = NSWPointServiceCredsRetriever.getEndpoint(Label.Predictive2_Service_Name);
    }
    
    /**
     * provide the endpoint for the service
     */
    public String endpoint(){
      return this.ENDPOINT;
    }    
}