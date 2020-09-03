/**
 * @Author         : Sauce Consulting
 * @Description    : This is responsible to test AddressPageController class
 * History         :
 * Date            Author                      Comments
   --------------------------------------------------------------------
   20-11-2019       Sauce Consulting            Initial Release
 */
 @isTest
public with sharing class AddressPageControllerTest {
    @isTest

    private static void test_getAddressNames(){
        Contact con= new Contact();
        con.lastName = 'Test last Name';
		database.insert(con);
			
		Test.StartTest(); 
		    ApexPages.currentPage().getParameters().put('id',String.valueOf(con.Id));
			
			ApexPages.StandardController sc = new ApexPages.StandardController(con);
			AddressPageController sssController = new AddressPageController(sc);
			sssController.getAddressNames();
			
		Test.StopTest();
    }

}