public with sharing class ContactBeforeUpdateTriggerHandler extends TriggerHandlerBase {
    
    private static RecordType HOUSEHOLD = NULL;
    private static RecordType CUSTOMER = NULL;
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   Handler function updates an Account name before updating a contact
    Inputs:        Trigger context parameters

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    06/02/2017  Arxxus             Optimised code for fetching Contact record types
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            
            if(HOUSEHOLD == NULL)
             HOUSEHOLD = [SELECT ID FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = :GlobalConstants.B2C_ACCNT_RECTYPE_NAME];
            
            if(CUSTOMER == NULL)
             CUSTOMER = [SELECT ID FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = :GlobalConstants.CUSTOMER_CONTACT_RECTYPE_NAME];
             
            Set<Id> relatedAccountsNew=new Set<Id>();

            for (ID eachContact:tp.newMap.keySet())
            {
                if (((Contact)tp.newMap.get(eachContact)).RecordTypeId==CUSTOMER.Id){
                    Id eachNewAccount= ((Contact)tp.newMap.get(eachContact)).AccountId;

                    if (eachNewAccount!=null) relatedAccountsNew.add(eachNewAccount);
                }

            }
            //if b2c contact if not associated with household account
            Map<Id, Account> householdsNew = new Map<Id, Account>([select Id, Name,RecordTypeId from Account where Id in:relatedAccountsNew]);

            Map<Id,Contact> householdIdvsContactNameChanged= new Map<Id,Contact>  ();
            for(Id custId:tp.newMap.keySet()){
                contact cust=(Contact)tp.newMap.get(custId);
                if ( cust.RecordTypeId==CUSTOMER.Id && cust.AccountId!=null
                        && householdsNew.get(cust.AccountId) !=null
                        && householdsNew.get(cust.AccountId).RecordTypeId==HOUSEHOLD.Id) {

                    Contact oldCust=(Contact)tp.oldMap.get(custId);
                    if (oldCust.AccountId==cust.AccountId
                            && householdsNew.get(cust.AccountId) !=null
                            && householdsNew.get(cust.AccountId).RecordTypeId==HOUSEHOLD.Id
                            && (oldCust.FirstName!=cust.FirstName
                                ||oldCust.LastName!=cust.LastName ) ){

                        householdIdvsContactNameChanged.put(cust.AccountId,cust);

                    }
                }
            }
            if(householdIdvsContactNameChanged.size()!=0){
                Map<Id,Account> accountsforNameUpdate= new Map<Id,Account>(
                [select Id, name from Account where RecordTypeId=:HOUSEHOLD.Id and Id in:householdIdvsContactNameChanged.keySet()]);
                for (Id householdId:householdIdvsContactNameChanged.keySet()){
                    Account forNameUpdate=accountsforNameUpdate.get(householdId);
                    if (forNameUpdate!=null){
                        Contact con=householdIdvsContactNameChanged.get(householdId);
                        forNameUpdate.name=con.FirstName==null?con.LastName:con.FirstName+' '+con.LastName;
                        forNameUpdate.name=forNameUpdate.name +  GlobalConstants.B2C_ACCNT_SUFFIX;

                    }
                }
                update accountsforNameUpdate.values();
            }
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ContactBeforeUpdateTriggerHandler ';
            message.sourceFunction='process';
            if (tp!=null && tp.newMap!=null) message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel='Error';
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }

    }
}