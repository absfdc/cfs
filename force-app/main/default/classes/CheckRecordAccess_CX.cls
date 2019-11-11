/*------------------------------------------------------------
Author:      Arxxus
Description: Class used to avoid annoying "Insufficient Privileges" standard error
             message and show a custom message for records of any object type.
             Assumes that ownwerhip is already changed and just validates that whether
             current user still has access to record or not and accordingly displays message 
             or refreshes record page

History
02 Feb 2017  Arxxus    created
------------------------------------------------------------*/

public with sharing class CheckRecordAccess_CX {

 //This flag will indicate that whether user has read access to record or not.
 public Boolean hasReadAccess {get; private set;}
 
 //The label of the object who's id is passed
 public String objectLabel {get; private set;}
 
 //The user/queue name to whom the record has been assigned
 public String assignedTo {get; private set;}
 
 //Record prefix id
 public String recordPrefix {get; private set;}
 
 //The label of the tab
 public String tabLabel {get; private set;}
 
 //Constructor - this only really matters if the autoRun function doesn't work right
 public CheckRecordAccess_CX() {
 
   hasReadAccess = true;
   objectLabel = '';
   assignedTo = 'appropriate queue';
   tabLabel = '';
 }
 
 //Code to invoke on page load.
 public PageReference autoRun() {
  
  Id theId = ApexPages.currentPage().getParameters().get('id');
  
  if(NULL != ApexPages.currentPage().getParameters().get('assignedTo') 
     && ApexPages.currentPage().getParameters().get('assignedTo') != '')
   assignedTo = ApexPages.currentPage().getParameters().get('assignedTo');
  
  tabLabel = ApexPages.currentPage().getParameters().get('tabLabel');
  hasReadAccess = true;
  
  if(theId == null) {
   
   //Display the Visualforce page's content if no Id is passed over
   hasReadAccess = false;
   return NULL;
  }
  
  objectLabel = theId.getSObjectType().getDescribe().getName();
  recordPrefix = String.valueOf(theId).substring(0,3);
   
  UserRecordAccess recordAccesss = [Select RecordId, HasReadAccess 
                                     From UserRecordAccess 
                                     Where UserId = :UserInfo.getUserId() 
                                     And RecordId = :theId];
  
  if(!recordAccesss.HasReadAccess)
   hasReadAccess = false;    
  
  return NULL;
 }
}