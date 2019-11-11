/*------------------------------------------------------------
Author:        Ian Fitzgerald, TransportNSW
Description:   Generic code to call Einstein API to make predictions

Test Class:    EinsteinPredictionEngine_Test
History
21 Feb 2018    Ian Fitzgerald     created
------------------------------------------------------------*/
public class EinsteinPredictionEngine{
    
    private String einsteinAccessToken;
    private String einsteinEndPoint;
    
    //Initialise the Access Token and base endpoint to be used to call Einstein
    public EinsteinPredictionEngine(String strEinsteinAccessToken, String strEinsteinEndPoint){
        this.einsteinAccessToken = strEinsteinAccessToken;
        this.einsteinEndPoint = strEinsteinEndPoint;
    }
    
    /*********************************************************************************
    Inputs:
       einsteinInput:  The input for which a prediction is to be made eg. a Case description field
       einsteinModelId:  The Id of the Einstein model to be used to make the prediction
       einsteinType:  The type of prediction eg. '/language/intent', '/language/sentiment'
       einsteinNumResults:  The number of predictions to return
    
    Returns:
       A map of predicted Labels for the input mapped to the probability returned by Einstein.
       The number of items in the Map will b determined by the einsteinNumResults passed in.
    *********************************************************************************/
    public Map<String, Decimal> getPredictionLabelAndProbability(String einsteinInput, String einsteinModelId, 
                                                                 String einsteinType, Integer einsteinNumResults){
    	Map<String, Decimal> predictedLabelsAndProbability = new Map<String, Decimal>();
    	
    	HttpRequest predictionReq = new HttpRequest();
        predictionReq.setMethod('POST');
        predictionReq.setTimeout(120000);
        predictionReq.setHeader('Cache-Control', 'no-cache');
        predictionReq.setHeader('Content-Type', 'application/json');
        predictionReq.setHeader('Authorization','Bearer ' + this.einsteinAccessToken);
        predictionReq.setEndpoint(this.einsteinEndPoint+einsteinType);
        
        String strBody = getJSONBody(einsteinInput, einsteinModelId, einsteinNumResults);
        System.debug('EinsteinPredictionEngine Request Body : '+strBody);
        
        predictionReq.setBody(strBody);
        
        System.debug('EinsteinPredictionEngine predictionReq : '+predictionReq);
        
        Http http = new Http();
        HTTPResponse predictionResponse;
        if(Test.isRunningTest()){
            predictionResponse = new HTTPResponse();
            if (einsteinInput == 'FAIL'){
                predictionResponse.setStatusCode(400);
                predictionResponse.setBody ('Test Failure message');
            } else {
                predictionResponse.setStatusCode(200);
                Taxonomy_Metadata__c tm = [Select Id from Taxonomy_Metadata__c where Name='Test' limit 1];
                predictionResponse.setBody ('{ "probabilities": [ { "label": "'+ tm.Id + '",  "probability": 0.99 }]}');
            }
        }     
        else{
        	predictionResponse = http.send(predictionReq);
        }
        System.debug('EinsteinPredictionEngine predictionResponse : '+predictionResponse);
        
        if ( predictionResponse.getStatusCode() == 200 ) {
            predictedLabelsAndProbability = parsePredictionResults(predictionResponse.getBody());
        }
        else{
        	System.debug('EinsteinPredictionEngine failed : '+predictionResponse);
    		
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'EinsteinPredictionEngine';
            message.sourceFunction = 'getPredictionLabelAndProbability';
            message.logMessage = 'Endpoint : '+this.einsteinEndPoint+einsteinType;
            message.payLoad = 'Status Code: ' + predictionResponse.getStatusCode() + '   Response Body : '+predictionResponse.getBody();
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);      
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
        }
    	
    	return predictedLabelsAndProbability;
    }
    
    private Map<String, Decimal> parsePredictionResults (String predictionResponse){
    	Map<String, Decimal> predictionMap = new Map<String, Decimal>();
    	JSONParser parser = JSON.createParser(predictionResponse);
        JSONToken currentToken = parser.nextToken();
        while (currentToken!=null){
            if(parser.getText()!=null && parser.getText().equalsIgnoreCase('probabilities')){
                currentToken = parser.nextToken(); 
                while (currentToken!=JSONToken.END_ARRAY){
                	String currentLabel = null;
                	Decimal currentProbability = 0;
                	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'label')) {
                       parser.nextValue();
                       currentLabel = parser.getText();
                       parser.nextValue();
                       currentProbability = parser.getDecimalValue();
                       predictionMap.put(currentLabel, currentProbability);
                	}
                	currentToken = parser.nextToken(); 
                }
            }
            currentToken = parser.nextToken();
        }
        return predictionMap;
    }
    
    private String getJSONBody(String einsteinInput, String einsteinModelId, Integer einsteinNumResults){
    //	einsteinInput.replaceAll('[\n\r]', ' ')
    	String escapedInput = einsteinInput.escapeJava();
    	return '{"modelId":"' + einsteinModelId + '", "document":"' + escapedInput + '", "numResults" : "'+einsteinNumResults + '"}';
    }

}