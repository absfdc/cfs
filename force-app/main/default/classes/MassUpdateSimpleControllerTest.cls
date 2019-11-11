/**
 * This class contains unit tests for validating the behavior of MassUpdateController
 * and triggers.
 */
@isTest
private class MassUpdateSimpleControllerTest {

	@testSetup static void setTestData() {
		Case c = new Case();
		insert c;

		Contact con = new Contact();
		con.firstname = 'Vishal';
		con.lastName = 'Taware';
		insert con; 
	}

	static testMethod void constructorTest(){
		Case c = [select Id from case LIMIT 1];
		ApexPages.currentPage().getParameters().put('id', c.Id);
		MassUpdateSimpleController muc = new MassUpdateSimpleController(null);
	}

	static testMethod void navigationAndGetterTest(){
		Case c = [select Id from case LIMIT 1];
		ApexPages.currentPage().getParameters().put('id', c.Id);
		MassUpdateSimpleController muc = new MassUpdateSimpleController(null);
		muc.getStep();
		muc.getsType();
		muc.getRecordSize();
		muc.getNow(true);
		//muc.filterId;
		//muc.objsToUpdate;
		//muc.valueToUpdate;
		//muc.fieldName;
		//muc.fieldType;
		muc.cancel();
		muc.step1();
		muc.step2();
		muc.step3();
		muc.step4();
		muc.step5();

		muc.convertUserInputToFieldData();
		muc.getFieldInfoToDisplay();
		muc.getFieldTypeOptions();
		muc.getPicklistValues();
	}

	static testMethod void testConvertInputField(){
		Case c = [select Id from case LIMIT 1];
		ApexPages.currentPage().getParameters().put('id', c.Id);
		MassUpdateSimpleController muc = new MassUpdateSimpleController(null);

		Contact con = [select Id from contact limit 1];
		muc.getFieldTypeOptions();
		//Refernce
		muc.fieldName = 'Assigned_SME__c'; 
		muc.valueToUpdate = con.Id;
		
		muc.convertUserInputToFieldData();

		//Double
		muc.fieldName = 'categorisation_count__c'; 
		muc.valueToUpdate = '10';
		muc.convertUserInputToFieldData();
		muc.getFieldInfoToDisplay();

		//Boolean
		muc.fieldName = 'Active__c'; 
		muc.valueToUpdate = 'true';
		muc.convertUserInputToFieldData();
		muc.getFieldInfoToDisplay();

		//Date
		muc.fieldName = 'Reopen_Till_Date__c'; 
		muc.valueToUpdate =Date.newInstance(2015, 7, 22) +'';
		muc.convertUserInputToFieldData();
		muc.getFieldInfoToDisplay();

		//Date time 
		muc.fieldName = 'ClosedDate'; 
		muc.valueToUpdate = Datetime.newInstance(2015, 7, 22) +'';
		muc.convertUserInputToFieldData();
		muc.getFieldInfoToDisplay();

		//Picklist
		muc.fieldName = 'Origin'; 
		muc.valueToUpdate = 'Web';
		muc.convertUserInputToFieldData();
		muc.getFieldInfoToDisplay();

	}

//    static testMethod void singleUpdateTest() {
//        Opportunity o = new Opportunity();
//        List<Opportunity> oppList = [SELECT name FROM Opportunity LIMIT 20];
        
//        System.debug('oppList......'+oppList);

//        ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
//        setCtr.setSelected(new Opportunity[]{o});
//        MassUpdateSimpleController controller = new MassUpdateSimpleController(setCtr);
//        System.assertEquals(1, controller.getRecordSize());
        
//        System.assert(controller.getFieldTypeOptions().size()>1);
        
//        system.assertEquals(1, controller.objsToUpdate.size());
        
//        String value = '123test';
//        controller.fieldName='name';
//        controller.valueToUpdate=value; 
//        //controller.convertedFieldData = controller.convertUserInputToFieldData(); 
//        controller.step4();
//        controller.step5();
        
//        System.assert(o.name==value);
        
//        value ='123';
//        controller.step3();
//        controller.fieldName='amount';
//        controller.valueToUpdate=value; 
//        controller.step4();
//        controller.step5();
        
//        System.assert(o.amount==decimal.valueOf(value));
        
///*      value ='true';
//        controller.fieldName='IsPrivate';
//        controller.step3();
//        controller.valueToUpdate=value;     
//        controller.step4();
//        controller.step5();
        
//        System.assert(o.IsPrivate); */
//        // make sure no exception from display tips
//        System.assertEquals(controller.getFieldInfoToDisplay()!=null,true);
                
//        value ='2009-4-7';
//        controller.fieldName='CloseDate';
//        controller.valueToUpdate=value;     
//        controller.step4();
//        controller.step5();
//        System.assert(o.CloseDate==Date.valueOf(value));
        
//        value ='Closed';
//        controller.fieldName='StageName';
//        controller.valueToUpdate=value;     
//        controller.step4();
//        controller.step5();
//        System.assert(o.StageName=='Closed');
//    }
    
//    static testMethod void massUpdateAsStandardUserTest() {
        
//        Profile p = [select id from profile where name='Standard User'];
//        User u = new User(alias = 'standt', email='standarduser@testorg.com',
//          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
//          localesidkey='en_US', profileid = p.Id,
//          timezonesidkey='America/Los_Angeles', username='standarduser@test.com');
        
//        System.runAs(u) {
//          Opportunity o = new Opportunity();
//          List<Opportunity> oppList = [SELECT name FROM Opportunity LIMIT 20];
        
//          ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
//          setCtr.setSelected(new Opportunity[]{o});
//          MassUpdateSimpleController controller = new MassUpdateSimpleController(setCtr);
//          System.assertEquals(1, controller.getRecordSize());
        
//          System.assert(controller.getFieldTypeOptions().size()>1);
        
//          system.assertEquals(1, controller.objsToUpdate.size());
        
//          String value = '123test';
//          controller.fieldName='name';
//          controller.valueToUpdate=value;       
//          controller.save();
        
//          System.assert(o.name==value);
         
//        }
//    }  
    
//    static testMethod void linkTest() {
//        Opportunity o = new Opportunity();
//        List<Opportunity> oppList = [SELECT name FROM Opportunity LIMIT 20];
        
//        ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
//        setCtr.setSelected(new Opportunity[]{o});
//        MassUpdateSimpleController controller = new MassUpdateSimpleController(setCtr);
        
//        // verify following exceptions will not cause exception
//        System.assert(controller.step1()!=null);
//        System.assert(controller.step2()!=null);
//        System.assert(controller.step3()!=null);
//        System.assert(controller.step4()!=null);
//        System.assert(controller.step5()!=null);
//        //System.assert(controller.cancel()!=null);
        
//        System.assert(controller.getFieldTypeOptions()!=null);
//    }
    
//    static testMethod void fieldTest() {
        
//        List<Opportunity> oppList = new Opportunity[]{};
        
//        ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
//        MassUpdateSimpleController controller = new MassUpdateSimpleController(setCtr);
//        System.assert(controller.cancel()!=null);
//        System.assert(controller.getFieldTypeOptions()==null);
//    }
    
//    static testMethod void miscTest() {
        
//        List<Opportunity> oppList = new Opportunity[]{};
        
//        ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
//        MassUpdateSimpleController controller = new MassUpdateSimpleController(setCtr);
        
//        System.assert(controller.getNow(true)!=null);
//        System.assert(controller.getNow(false)!=null);
//        System.assert(controller.getRecordSize()==0);
//        System.assert(controller.getPicklistValues()==null);
//    }
}