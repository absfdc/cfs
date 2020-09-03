/**
 * @Author: Sauce Consulting
 * @Description: Wrapper class for address details to be used for sending request to NSW Point service
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class AddressDetails{
	
	public String addressSearchStr;
	public String stateTerritory = Label.NSW_Point_StateTerritory_Config;
	public Integer maxNumberOfResults = Integer.valueOf(Label.NSW_Point_MaxNumberOfResults_Config);
	public String dataset = Label.NSW_Point_DataSet_Config;
	public String addressType = Label.NSW_Point_AddressType_Config;
	public String addressId;
	public String outputFields;
}