@IsTest
public class NSWPointServiceMockResponse {
	public enum Service_Name {PREDICTIVE1, PREDICTIVE2, ADDRESS_VALIDATION}
	public static Boolean errorResponse = false;
	public static Service_Name service;
	private String responseStr;
	
	public static String getResponseStr(){
		String response;
		if(errorResponse){
			response = '{"errorMessage": "An internal error occured."}';
		} else if(service == Service_Name.PREDICTIVE1){
			response = '[' +
						'{"address": "312-350 PAYNES RD ROCKBANK VIC 3336","id": "20190619d6f400b3-6e0b-4902-9418-d8ac8278cc12", "rank": 0},' + 
						'{"address": "346 PACIFIC HWY HIGHFIELDS NSW 2289","id": "20190619cb7a47c0-2401-49da-8263-12178dee1683","rank": 1},' + 
						'{"address": "346 PACIFIC HWY LANE COVE NSW 2066","id": "2019061909c22d23-c0b4-40af-a950-9be10cefa5c3","rank": 2},' +
						'{"address": "346 PANORAMA AV BATHURST NSW 2795","id": "20190619bbacb468-218f-4a8d-948c-44d5e2cd988e","rank": 3},' +
						'{"address": "346 PARTELLIS CROSSING RD TOSTAREE VIC 3888","id": "201906198767d43c-db63-4d7d-8e83-0d886057f83f","rank": 4}' +
					  ']';
		} else if(service == Service_Name.PREDICTIVE2){
			response = '{"data": {"addressDetails": {"streetNumber1": "346", "streetName": "PANORAMA","streetType": "AV",' + 
						'"localityName": "BATHURST","stateTerritory": "NSW",' +
						'"postcode": "2795","formattedAddress": "346 PANORAMA AV, BATHURST NSW 2795","streetTypeDescription": "AVENUE"},' + 
						'"addressId": "GANSW704038094","addressRecordType": "PRIMARY"},"requestTimestamp": "1563849913308","requestDate": "2019-07-23 12:45:13"}';
		} else if(service == Service_Name.ADDRESS_VALIDATION){
			response = '{"data": {"addressDetails": {"streetNumber1": "346","streetName": "PANORAMA","streetType": "AV","localityName": ' + 
						 '"BATHURST","stateTerritory": "NSW","postcode": "2795","formattedAddressString": "346 PANORAMA AV, ' + 
						 'BATHURST NSW 2795"},"properties": {"matchResult": "100","matchQualityPercentage": "100","matchCode": ' + 
						 ' "SE:Y;UT:Y;UI:Y;LT:Y;CL:Y;LI:Y;NR:Y;SN:Y;ST:Y;SS:Y;LN:Y;PC:Y;SA:Y;","matchCertainty": "full"}},' + 
						 '"requestTimestamp":"1561003119186","requestDate": "2019-06-20 01:58:39"}';
		}
        return response;
	}
}