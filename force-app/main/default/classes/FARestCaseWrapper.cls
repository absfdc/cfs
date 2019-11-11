public with sharing class FARestCaseWrapper {

    public class TreeCase{
        public Attr attributes;
        public String RecordTypeId;
        public String Origin;
        public String Status;
        public String Subject;
        public String Type;
        public String Location;
        public String Page;
        public String SuppliedName;
        public String SuppliedEmail;
        public String SuppliedPhone;
        public boolean Sent_VIA_Rest;
        public String Description;
        public String Priority;
        public String OwnerId;
        public String What;

        public TreeCase(Case C ){
			this.attributes = new Attr(C.id);
            this.RecordTypeId = C.RecordTypeId;
            this.Origin = C.Origin;
            this.Status = C.status;
            this.OwnerId = C.ownerId;
            if(!String.isEmpty(C.Description))
            if(C.Description.length() >255)
            this.Subject = parseDescriptionForSubject(C.Description).substring(0,255);
            else
            this.Subject = parseDescriptionForSubject(C.Description);
            else
            this.Subject = parseDescriptionForSubject(C.Description);
            this.Type = C.Type;
            this.Location = C.Location_of_Incident__c;
            this.Page = C.DFSIPageSource__c;
            this.SuppliedName = C.SuppliedName;
            this.SuppliedEmail = C.SuppliedEmail;
            this.SuppliedPhone = C.SuppliedPhone;
            this.Sent_VIA_Rest = C.DFSISent_VIA_Rest__c;
            //this.Description = C.Description;
            this.Priority = C.Priority;
            this.What = parseDescriptionForSubject(C.Description);
            
        }
    }
    
    
    //SFCOE-2556 - reserve words in Case Description getting convered into Variable names - 24-07-2018 - Start
    //Required to avoid What getting converted to What__c, Page getting converted into Page__c, and Location to Location__c (reserve words)
    public static String parseDescriptionForSubject(String caseDescription){
        System.debug('Case Description Before Processing: ' + caseDescription);
        //Sample Input: 'XYZ What a Joke! what a joke! Page page Location location Test'
		//Sample Output: 'XYZ what a Joke! what a joke! page page location location Test'
        
        if(caseDescription.contains('What')) caseDescription = caseDescription.replace('What', 'what');
        if(caseDescription.contains('Page')) caseDescription = caseDescription.replace('Page', 'page');
        if(caseDescription.contains('Location')) caseDescription = caseDescription.replace('Location', 'location');
        
        System.debug('Case Description After Processing to lowercase for reserve words: ' + caseDescription);
        
        return caseDescription;
    }
    
    //SFCOE-2556 - reserve words in Case Description getting convered into Variable names - 24-07-2018 - End    

    
    public class Attr{
        public String referenceId;
        public String type;
        public Attr(string caseid){
            this.referenceId = caseid;
            this.type = 'Case';
        }
    }

    public static String generateTreeJson (list<Case> cases) {
        list<TreeCase> records = new list <TreeCase>();

        for (Case C :cases ){
            records.add(new TreeCase(C));
        }   
        
        string JSON = '{\"records\":'+Json.serialize(records)+'}';
        system.debug('JSON before replacing field names:'+JSON); 
        JSON = JSON.replace('Sent_VIA_Rest','Sent_VIA_Rest__c');
        JSON = JSON.replace('Page','Page__c');
        JSON = JSON.replace('Location','Location__c');
        JSON = JSON.replace('What','What__c');
        system.debug('JSON after replacing field names:'+JSON);
        return JSON;
        
        
    }
}