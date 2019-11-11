/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the contact trigger

Test Class:    ContactTriggerDispatcher_Test
History
16 Mar 2015      Dipankar Barman     created
13/01/2017       Arxxus              updated - optimised record type query
------------------------------------------------------------*/
public class ContactAfterInsertTriggerHandler extends TriggerHandlerBase {

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
    Description:   Handler function creates an Account after inserting a new contact
                    if Account by same name did not exist
    Inputs:        Trigger context parameters

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            
            if(HOUSEHOLD == NULL)
             HOUSEHOLD = [SELECT ID FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = :GlobalConstants.B2C_ACCNT_RECTYPE_NAME];
            
            if(CUSTOMER == NULL)
             CUSTOMER = [SELECT ID FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = :GlobalConstants.CUSTOMER_CONTACT_RECTYPE_NAME];

            Map<Id, Account> aMap = new Map<Id, Account>();
            //if b2c contact and not associated with account create household account and associate
            List<Contact> householdsWithoutAccount= new List<Contact> ();
            for(contact cust:(List<Contact>)tp.newList){

                if (cust.recordTypeId==CUSTOMER.Id && cust.AccountId==null) {
                    householdsWithoutAccount.add(cust);
                }
            }

            for (Contact con : householdsWithoutAccount){

                Account acc = new Account();
                acc.name =con.FirstName==null?con.LastName:con.FirstName+' '+con.LastName;
                acc.name =acc.name+ GlobalConstants.B2C_ACCNT_SUFFIX;
                
                acc.RecordTypeId = HOUSEHOLD.Id;
                //connect the Account to the Contact
                if (con.Id != null) {
                    acc.Primary_Contact_Id__c = con.Id;
                    acc.OwnerId = con.OwnerId;
                }

                aMap.put(con.Id, acc);

            }

            if (!aMap.isEmpty()) {
                insert aMap.values();

                List<Contact> cList = new List<Contact>();

                for (Id cId : aMap.keySet()) {
                    Contact con = new Contact();
                    con.Id = cId;
                    con.AccountId = aMap.get(cId).Id;
                    cList.add(con);
                }

                update cList;
            }
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ContactAfterInsertTriggerHandler';
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