/**
 * @Author: Sauce Consulting
 * @Description: Predictive1 service response class
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive1ServiceResponse{
    @AuraEnabled
    public String address {get; set;}
		@AuraEnabled
    public String id {get; set;}
		public Integer rank {get; set;}
		public String errorMessage {get; set;}
}