/*********************************************************
Class to generate access token to call Einstein Rest API

**********************************************************/
public class JWTBearerFlow {

    public static String getAccessToken(String tokenEndpoint, JWT jwt) {
    
        String access_token = null;
        String body = 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwt.issue();
        system.debug('JWTBearerFlow body : '+body);
        HttpRequest req = new HttpRequest();                            
        req.setMethod('POST');
        system.debug('JWTBearerFlow tokenEndpoint : '+tokenEndpoint);
        req.setEndpoint(tokenEndpoint);
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        req.setBody(body);
        system.debug('JWTBearerFlow req : '+req);
        Http http = new Http();         
        HTTPResponse res;
        if(Test.isRunningTest()){
            res = new HTTPResponse();
            if (tokenEndpoint == 'FAIL'){
                res.setStatusCode(400);
                res.setBody ('Test Failure message');
            } else {
                res.setStatusCode(200);
                res.setBody ('{ "access_token" : "QWERTY12345" }');
            }
        }     
        else{
            res = http.send(req);
        }
        system.debug('JWTBearerFlow res : '+res);
        if ( res.getStatusCode() == 200 ) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }
        else{
            System.debug('JWTBearerFlow failed : '+res);
            
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'JWTBearerFlow';
            message.sourceFunction = 'getAccessToken';
            message.logMessage = 'Endpoint : '+tokenEndpoint;
            message.payLoad = 'Status Code: ' + res.getStatusCode() + '   Response Body : '+res.getBody();
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);      
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
        }
        return access_token;
        
    }

}