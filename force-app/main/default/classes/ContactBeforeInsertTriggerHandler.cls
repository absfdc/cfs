public with sharing class ContactBeforeInsertTriggerHandler extends TriggerHandlerBase{
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    /*------------------------------------------------------------
	Author:        Shrikant Hase
	Company:       Arxxus.com
	Description:   Handler function fills normlized contact numbers on inserting a contact
	Inputs:        Trigger context parameters

	History
	<Date>      <Authors Name>     <Brief Description of Change>
	------------------------------------------------------------*/
    private void process(TriggerParameters tp){
        try{
            System.debug('create NormalizePhoneFieldHandler instance');
            NormalizePhoneFieldHandler obj = new NormalizePhoneFieldHandler();
            for(Contact con : (List<Contact>)tp.newList){
                con = obj.normalizePhoneFields(con);
            }
            if(Test.isRunningTest()) throw new NormalizePhoneException();
        }catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ContactBeforeUpdateTriggerHandler ';
            message.sourceFunction='process';
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