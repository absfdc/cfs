/**
 * @Author: Sauce Consulting
 * @Description: Virtual response class for NSW Point service
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class NSWPointServiceResponse {
    /** response body */
    protected String responseText;
    
    /** response status */
    public Integer responseStatusCode { get; set;}
    
    /**
     * returns the response text
     */
    public String getResponseText() {
        return responseText;
    }
    
    /**
     * sets the response text
     */
    public void setResponseText(String responseText) {
        this.responseText = responseText;
    }
        
    public NSWPointServiceResponse(String responseText, Integer statusCode) {
        this.responseText = responseText;
        this.responseStatusCode = statusCode;        
    }  
}