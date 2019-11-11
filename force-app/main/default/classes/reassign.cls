/*------------------------------------------------------------
Author:        Arxxus
Description:   This class is used to perform custom Re-Assign functionality.
Test Class:    
History
<Date>        <Authors Name>     <Brief Description of Change>
16-APR-2018   Ankur Jaiswal       
------------------------------------------------------------*/

public class reassign {
 
 String caseId;
 public Case newCase {get; set;}
 public reassign(ApexPages.StandardController controller) {
     Id id = ApexPages.currentPage().getParameters().get('id');
     this.newCase=(Case)controller.getRecord(); 
 }

 public reassign() {
      
 }

 public pagereference searchdata() {
    
      
  if (System.currentPagereference().getParameters().get('Id') != null || System.currentPagereference().getParameters().get('Id') != '') {
   caseId = System.currentPagereference().getParameters().get('Id');
  }

  System.debug('@@@@@@@@@@@' + newCase + ' <===case===>' + caseId);
  List < ProcessInstanceWorkItem > workItemList = [Select p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.OriginalActorId, p.Id, p.ActorId
                                                   From ProcessInstanceWorkitem p where p.ProcessInstance.TargetObjectId =: caseId]; 
      
      workItemList.get(0).ActorId = newCase.ownerId;
      update workItemList;
      
      newCase.MO_User__c = newCase.ownerId;
      newCase.ownerId = newCase.ownerId;
      Update newCase;
      
  if (System.currentPagereference().getParameters().get('Id') != null || System.currentPagereference().getParameters().get('Id') != '') {
      caseId = System.currentPagereference().getParameters().get('Id');
      PageReference pageRef = new PageReference('/' + caseId);
      return pageRef;
  }
      return null;
 }

 public PageReference Cancel() {
  
   if (System.currentPagereference().getParameters().get('Id') != null || System.currentPagereference().getParameters().get('Id') != '') {
       caseId = System.currentPagereference().getParameters().get('Id');
       PageReference pageRef = new PageReference('/' + caseId);
       return pageRef;
   }
       
       return null;
 }
}