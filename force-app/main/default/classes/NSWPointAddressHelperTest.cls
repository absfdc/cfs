@IsTest
public with sharing class NSWPointAddressHelperTest{

    public static testMethod void testForAddressSearch(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.PREDICTIVE1;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String searchKey = '477 Pitt Street';
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        List<Predictive1ServiceResponse> response = NSWPointAddressHelper.searchAddress(searchKey);
        System.Test.stopTest();
        System.assert(response.size() > 0, 'Address search using predictive1 service failed');
        System.assert(response[0].address != null, 'Address details not available in response');
        System.assert(response[0].id != null, 'Address id not available in response');
        System.assert(response[0].rank > -1, 'Address rank details not available in response');
    }
    
    public static testMethod void testForAddressVerification(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.ADDRESS_VALIDATION;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String searchKey = '477 Pitt Street';
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        AddressValidationServiceResponse response = NSWPointAddressHelper.validateAddress(searchKey);
        System.Test.stopTest();
        System.assert(response != null, 'Failed to test address validation service');
        System.assert(response.isValid(), 'Failed to test valid response for address validation service');
        System.assert(String.isNotBlank(response.data.addressDetails.streetNumber1), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.streetName), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.streetType), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.localityName), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.stateTerritory), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.postcode), 
            'Failure response received for predictive2 service response');          
        System.assert(String.isNotBlank(response.data.addressDetails.formattedAddressString), 
            'Failure response received for predictive2 service response');      
        System.assert(String.isNotBlank(response.data.properties.matchResult), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.properties.matchCertainty), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressIdentifier), 
            'Failure response received for predictive2 service response');
    }
    
    public static testMethod void testForAddressComponent(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.PREDICTIVE2;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String addressId = '201911125f8e3a59-83ef-438e-894f-e6438c4cf1c7';
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        Predictive2ServiceResponse response = NSWPointAddressHelper.getAddressComponent(addressId, '[]');
        System.Test.stopTest();
        System.assert(response != null, 'Null response received for predictive2 service');
        System.assert(response.data != null && response.data.addressDetails != null, 'Empty response received for predictive2 service');
        System.assert(response.data.addressId != null, 'Address id details not availabe in predictive2 service response');
        System.assert(response.data.addressRecordType != null, 'Address record type details not availabe in predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.complexUnitType), 
            'Failure response received for predictive2 service response');          
        System.assert(String.isBlank(response.data.addressDetails.complexUnitType), 
            'Failure response received for predictive2 service response');
        System.assert(response.data.addressDetails.complexUnitIdentifier == null, 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.complexLevelType), 
            'Failure response received for predictive2 service response');
        System.assert(response.data.addressDetails.complexLevelNumber == null, 
            'Failure response received for predictive2 service response');
        System.assert(response.data.addressDetails.complexStreetNumber1 == null, 
            'Failure response received for predictive2 service response');
        System.assert(response.data.addressDetails.complexStreetNumber2 == null, 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.complexStreetName), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.complexStreetType), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.complexStreetSuffix), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.streetNumber1), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.streetName), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.streetType), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.localityName), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.stateTerritory), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.postcode), 
            'Failure response received for predictive2 service response');          
        System.assert(String.isNotBlank(response.data.addressDetails.formattedAddress), 
            'Failure response received for predictive2 service response');
        System.assert(String.isNotBlank(response.data.addressDetails.streetTypeDescription), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.lotIdentifier), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.aliasPrincipal), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.gnafLocalityPid), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.gnafStreetLocalityPid), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.localityNeighbours), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.cadastralIdentifier), 
            'Failure response received for predictive2 service response');
        System.assert(String.isBlank(response.data.addressDetails.deliveryPointIdentifier), 
            'Failure response received for predictive2 service response');
    }
    
    public static testMethod void testForAddressSearchFailure(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.PREDICTIVE1;
        NSWPointServiceMockResponse.errorResponse = true;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String searchKey = '477 Pitt Street';
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        List<Predictive1ServiceResponse> response = NSWPointAddressHelper.searchAddress(searchKey);
        System.Test.stopTest();
        System.assert(response.isEmpty(), 'Negative testing for address search using predictive1 service failed');
    }
    
    public static testMethod void testForAddressVerificationFailure(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.ADDRESS_VALIDATION;
        NSWPointServiceMockResponse.errorResponse = true;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String searchKey = '477 Pitt Street';
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        AddressValidationServiceResponse response = NSWPointAddressHelper.validateAddress(searchKey);
        System.Test.stopTest();
        System.assert(response != null, 'Failed to test address validation service');
        System.assert(!response.isValid(), 'Failed to test invalid response for address validation service');
    }
    
    public static testMethod void testForAddressComponentFailure(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.PREDICTIVE2;
        NSWPointServiceMockResponse.errorResponse = true;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String addressId = '201911125f8e3a59-83ef-438e-894f-e6438c4cf1c7';
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        Predictive2ServiceResponse response = NSWPointAddressHelper.getAddressComponent(addressId, '[]');
        System.Test.stopTest();
        System.assert(response != null, 'Null response received for predictive2 service');
        System.assert(response.data == null, 'Invalid response received for predictive2 service');
    }
    
    public static testMethod void testForPostAddressSearch(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.PREDICTIVE1;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String searchKey = '477 Pitt Street';
        System.Test.startTest();
        Predictive1ServiceRequest.testPost = true;
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        List<Predictive1ServiceResponse> response = NSWPointAddressHelper.searchAddress(searchKey);
        System.Test.stopTest();
        System.assert(response != null && response.isEmpty(), 'Test failed on POST call for predictive1 service');
    }
    
    public static testMethod void testForPostAddressVerification(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.ADDRESS_VALIDATION;
        NSWPointServiceMockResponse.errorResponse = true;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String searchKey = '477 Pitt Street';
        System.Test.startTest();
        AddressValidationServiceRequest.testPost = true;
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        AddressValidationServiceResponse response = NSWPointAddressHelper.validateAddress(searchKey);
        System.Test.stopTest();     
        System.assert(response != null && !response.isValid(), 'Test failed on POST call for address validation service');
    }
    
    public static testMethod void testForGetOnAddressComponent(){
        NSWPointServiceMockResponse.service = NSWPointServiceMockResponse.Service_Name.PREDICTIVE2;
        NSWPointServiceMockResponse.errorResponse = true;
        NSWPointServiceCalloutMock mockCallout = new NSWPointServiceCalloutMock();
        String addressId = '201911125f8e3a59-83ef-438e-894f-e6438c4cf1c7';
        System.Test.startTest();
        Predictive2ServiceRequest.testGet = true;
        System.Test.setMock(HttpCalloutMock.class, mockCallout);
        Predictive2ServiceResponse response = NSWPointAddressHelper.getAddressComponent(addressId, '[]');               
        System.Test.stopTest();
        System.assert(response != null && response.data == null, 'Test failed on GET call for predictive2 service.');
    }   
}