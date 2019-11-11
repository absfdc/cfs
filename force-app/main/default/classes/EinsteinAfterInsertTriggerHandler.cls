/*------------------------------------------------------------
Author:        Ian Fitzgerald, TransportNSW
Description:   After Insert handler class for Einstein AI calls to handle Cases

Test Class:    EinsteinAfterInsertTrigger_Test
History
20 Feb 2018    Ian Fitzgerald     created
------------------------------------------------------------*/
public without sharing class EinsteinAfterInsertTriggerHandler extends TriggerHandlerBase{
    
    private static Einstein_API_Settings__c einsteinSettings;
    @testvisible private static boolean predictionExecuted = false;
    
    static{
        if (einsteinSettings==null){
            List<Einstein_API_Settings__c> settings = [SELECT Einstein_Base_URL__c, Einstein_Access_Token__c, Max_Records_per_Process__c, Issue_Model_Id__c, 
                                       Location_Model_Id__c, Minimum_Probability_Level__c, Case_Origin_to_Stamp__c, Einstein_Enabled__c
                                                       FROM Einstein_API_Settings__c];
            
            if(settings!=null && settings.size()>0){
            	einsteinSettings = settings[0];
            } 
            else{
            	einsteinSettings = new Einstein_API_Settings__c();
            	einsteinSettings.Einstein_Enabled__c=false;
            }                   
                                
        }
    }
    
    public override void mainEntry(TriggerParameters tp) {
        System.debug('-@EinsteinAfterInsert-Main Entry----');
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('EinsteinAfterInsert reentrant code...');
    }
    
    private void process(TriggerParameters tp) {
    	if (einsteinSettings.Einstein_Enabled__c==true && predictionExecuted==false){
    		predictionExecuted=true;
            filterEinsteinCases(tp);
    	}    
    }
    
    //Filter the Cases that are to have their Taxonomy predicted by Einstein
    //Initially these are Cases that are:
    //                  non-Min Corro Cases
    //                  not Child Cases
    //                  Description is not null                  
    private void filterEinsteinCases(TriggerParameters tp){
        Map<Id,String> caseDescriptionMap = new Map<Id,String>();
        Map<Id,String> caseOriginMap = new Map<Id,String>();
        for (Case aCase:(List<Case>)tp.newList ){
            if (aCase.IsMinCorroCase__c==false && aCase.parentId==null && aCase.Description!=null){
                caseDescriptionMap.put(aCase.Id, aCase.Description);
                if (aCase.Origin_Details__c!=null){
                    caseOriginMap.put(aCase.Id, aCase.Origin_Details__c);
                }
            }
        }
        
        if (caseDescriptionMap.size()>0 && caseDescriptionMap.size()<=einsteinSettings.Max_Records_per_Process__c
             && !System.isFuture() && !System.isBatch())
        {
            predictTaxonomy(caseDescriptionMap, caseOriginMap);
        }
    }
    
    @future(callout=true)
    static public void predictTaxonomy(Map<Id,String> caseDescriptionMap, Map<Id,String> caseOriginMap){
    	try{
    	    Map<String,Map<String,Decimal>> locationPredictionMap = new Map<String,Map<String,Decimal>>();
    	    Map<String,Map<String,Decimal>> issuePredictionMap = new Map<String,Map<String,Decimal>>();
    	
    	    locationPredictionMap = EinsteinAfterInsertTriggerHandler.getEinsteinLocationTaxonomyPredictions (caseDescriptionMap);
    	    System.debug('predictTaxonomy locationPredictionMap : '+locationPredictionMap);
    	    issuePredictionMap = EinsteinAfterInsertTriggerHandler.getEinsteinIssueTaxonomyPredictions (caseDescriptionMap);
    	    System.debug('predictTaxonomy issuePredictionMap : '+issuePredictionMap);
    	    EinsteinAfterInsertTriggerHandler.populateCaseFields(caseDescriptionMap, locationPredictionMap, issuePredictionMap, caseOriginMap);
    	}
    	catch(Exception e){
    		System.debug(e);
    		
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'EinsteinAfterInsertTriggerHandler';
            message.sourceFunction = 'predictTaxonomy';

            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. 
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
    	}
    }
    
    //Get the predicted Location taxonomy from Einstein
    //We only retrieve one prediction - the one with the highest probability
    static public Map<String,Map<String,Decimal>> getEinsteinLocationTaxonomyPredictions(Map<Id,String> caseDescriptionMap){
     	Map<String,Map<String,Decimal>> locationPredictionMap = new Map<String,Map<String,Decimal>>();
     	
     	EinsteinPredictionEngine einsteinPrediction = new EinsteinPredictionEngine(einsteinSettings.Einstein_Access_Token__c, einsteinSettings.Einstein_Base_URL__c);
     	
     	for (String caseDescription : caseDescriptionMap.values()){
     	    Map<String, Decimal> einsteinLocationPredictionMap = einsteinPrediction.getPredictionLabelAndProbability(caseDescription,
     	                          einsteinSettings.Location_Model_Id__c, '/language/intent', 1);
     	    locationPredictionMap.put(caseDescription, einsteinLocationPredictionMap);
     	}       
     	              
     	return locationPredictionMap;
    }
    
    //Get the predicted Issue taxonomy from Einstein
    //We only retrieve one prediction - the one with the highest probability
    static public Map<String,Map<String,Decimal>> getEinsteinIssueTaxonomyPredictions(Map<Id,String> caseDescriptionMap){
     	Map<String,Map<String,Decimal>> issuePredictionMap = new Map<String,Map<String,Decimal>>();
     	
     	EinsteinPredictionEngine einsteinPrediction = new EinsteinPredictionEngine(einsteinSettings.Einstein_Access_Token__c, einsteinSettings.Einstein_Base_URL__c);
     	
     	for (String caseDescription : caseDescriptionMap.values()){
     	    Map<String, Decimal> einsteinIssuePredictionMap = einsteinPrediction.getPredictionLabelAndProbability(caseDescription,
     	                          einsteinSettings.Issue_Model_Id__c, '/language/intent', 1);
     	    issuePredictionMap.put(caseDescription, einsteinIssuePredictionMap);
     	}     
     	
     	return issuePredictionMap;
    }
    
    //Update the Cases based on the predictions returned by Einstein
    static public void populateCaseFields( Map<Id,String> caseDescriptionMap,  
                                           Map<String,Map<String,Decimal>> locationPredictionMap, 
    	                                   Map<String,Map<String,Decimal>> issuePredictionMap, 
    	                                   Map<Id,String> caseOriginMap )
    {
         List<Id> taxonomyIds = new List<Id>();
         
         for (Map<String,Decimal> predLocMap : locationPredictionMap.values()){
         	// This map will only have one entry as we are only retrieving one result from Einstein
         	// We add the label (Taxonomy Id) of the single Map entry to our list of Taxonomy to be retrieved
         	 System.debug ('Einstein Trigger populateCaseFields predLocMap : '+predLocMap);
         	 String firstElement = (new list<string>(predLocMap.keySet()) )[0];
         	 taxonomyIds.add(Id.valueOf(firstElement));
         }   
         for (Map<String,Decimal> predIssMap : issuePredictionMap.values()){
         	// This map will only have one entry as we are only retrieving one result from Einstein
         	// We add the label (Taxonomy Id) of the single Map entry to our list of Taxonomy to be retrieved
         	System.debug ('Einstein Trigger populateCaseFields predIssMap : '+predIssMap);
         	 String firstElement = (new List<String>(predIssMap.keySet()) )[0];
         	 taxonomyIds.add(Id.valueOf(firstElement));
         }        	
         
         //Retrieve the Taxonomy
         Map<Id, Taxonomy_Metadata__c> taxonomyMap = new Map<Id, Taxonomy_Metadata__c>([SELECT Id, Name, Parent_Id__r.Name, Parent_Id__r.Parent_Id__r.Name, 
                                                                                        Parent_Id__r.Parent_Id__r.Parent_Id__r.Name, Agency__c, KPI__c, Driver__c, 
                                                                                        Status_Staff_Facing__c,  Issue_Accountability__c
                                                                                        FROM Taxonomy_Metadata__c 
                                                                                        WHERE Id in :taxonomyIds AND Status_Staff_Facing__c='Active']);
                                                      
         if (taxonomyMap!=null && taxonomyMap.size()>0){
             List<Case> casesToUpdate = new List<Case>();	
             
             List<String> originsToStamp = einsteinSettings.Case_Origin_to_Stamp__c.split(',');
             
         	 for (Id caseId : caseDescriptionMap.keySet()){
         	 	Boolean stampOrigin = false;
         	 	String strDesc = caseDescriptionMap.get(caseId);
         	 	//Get Location Taxonomy Id and Probability
         	 	Map<String,Decimal> predLocMap = locationPredictionMap.get(strDesc);
         	 	String locationIdStr = (new List<String>(predLocMap.keySet()) )[0];
         	 	Decimal locationProbability = predLocMap.get(locationIdStr)*100;
         	 	Id locationId = Id.valueOf(locationIdStr);
         	 	Taxonomy_Metadata__c locationTaxonomy = taxonomyMap.get(locationId);
         	 	//Get Location Taxonomy Id and Probability
         	 	Map<String,Decimal> predIssMap = issuePredictionMap.get(strDesc);
         	 	String issueIdStr = (new list<string>(predIssMap.keySet()) )[0];
         	 	Decimal issueProbability = predIssMap.get(issueIdStr)*100;
         	 	Id issueId = Id.valueOf(issueIdStr);
         	 	Taxonomy_Metadata__c issueTaxonomy = taxonomyMap.get(issueId);
         	 	
         	 	//Populate the back-end fields with the predicted values and probabilities
         	 	Case updCase = new Case (Id=caseId,
         	 	                         Einstein_Location_Taxonomy_Id__c=locationId,
         	 	                         Einstein_Issue_Taxonomy_Id__c=issueId,
         	 	                         Einstein_Location_Taxonomy_Probability__c=locationProbability,
         	 	                         Einstein_Issue_Taxonomy_Probability__c=issueProbability,
         	 	                         Einstein_Location_Taxonomy__c = locationTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name+'->'+
         	 	                                                         locationTaxonomy.Parent_Id__r.Parent_Id__r.Name+'->'+
         	 	                                                         locationTaxonomy.Parent_Id__r.Name+'->'+
         	 	                                                         locationTaxonomy.Name,
         	 	                         Einstein_Issue_Taxonomy__c = issueTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name+'->'+
         	 	                                                      issueTaxonomy.Parent_Id__r.Parent_Id__r.Name+'->'+
         	 	                                                      issueTaxonomy.Parent_Id__r.Name+'->'+
         	 	                                                      issueTaxonomy.Name );
         	 	
         	 	//If the Probability of both the Issue and Location Taxonomy predictions are greater than the "Minimum Probability" setting
         	 	//and Location Taxonom Mode = Issue Taxonomy mode
         	 	//and the Origin Details value on the Case is listed in the "Origins to Stam" setting
         	 	//then stamp the front end fields with the predicted values
         	 	if ( locationProbability>=einsteinSettings.Minimum_Probability_Level__c 
         	 	     && issueProbability>=einsteinSettings.Minimum_Probability_Level__c
         	 	     && issueTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name==locationTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name)
         	 	{
         	 	    String caseOriginDetails = caseOriginMap.get(caseId);
         	 	    if (caseOriginDetails!=null){
         	 	        for (String org : originsToStamp){
         	 		        if (caseOriginDetails.startsWith(org)){
         	 			        stampOrigin=true;
         	 			        break;
         	 		        }
         	 	        }
         	 	    }
         	 	    if (stampOrigin==true){
         	 	        updCase.Taxonomy_Symptom_Id__c=issueId;
         	 	        updCase.Taxonomy_Location_Id__c=locationId;
         	 	        updCase.modes__c=issueTaxonomy.Parent_Id__r.Parent_Id__r.Parent_Id__r.Name;
         	 	        updCase.Taxonomy_Location_Type__c=locationTaxonomy.Parent_Id__r.Parent_Id__r.Name;
                        updCase.Taxonomy_Area__c=locationTaxonomy.Parent_Id__r.Name;
                        updCase.Taxonomy_Moment__c=issueTaxonomy.Parent_Id__r.Parent_Id__r.Name;
                        updCase.Taxonomy_Transaction__c=issueTaxonomy.Parent_Id__r.Name;
                        updCase.KPI__c=issueTaxonomy.KPI__c;
                        updCase.Key_Driver__c=issueTaxonomy.Driver__c;
                        updCase.Taxonomy_Location__c=locationTaxonomy.Name;
                        updCase.Taxonomy_Symptom__c=issueTaxonomy.Name;
                        updCase.Taxonomy_Accountability__c=issueTaxonomy.Issue_Accountability__c!=NULL ? issueTaxonomy.Issue_Accountability__c : locationTaxonomy.Issue_Accountability__c;
                        updCase.Agency__c=issueTaxonomy.Agency__c!=NULL ? issueTaxonomy.Agency__c : locationTaxonomy.Agency__c;
         	 	    }
         	 	}
         	 	casesToUpdate.add(updCase);
         	 }
         	 update casesToUpdate;
         }                                                                            	
    }
}