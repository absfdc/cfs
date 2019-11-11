/*------------------------------------------------------------
Author:         Arxxus
Description:    Class responsible for reassigning the MO Approval request 
                from Signatory to Signatory pp and vice a versa 
                depending on whether Signatory pp is specified.
                Class triggered from CaseAfterUpdateHandlerForMO trigger handler. 
Test Class:     CaseAfterUpdateHandlerForMO_Test
------------------------------------------------------------*/
public without sharing class ReassignSignatoryApproval {

    public static void reassignRequest(Map < Id, Case > caseRecordsToReassign) {

        List <ApplicationLogMessage> messages = new List <ApplicationLogMessage> ();
        List <Approval.ProcessWorkitemRequest> approvalWorkItemRequests = new List <Approval.ProcessWorkitemRequest> ();
        List <Approval.ProcessSubmitRequest> approvalRequests = new List <Approval.ProcessSubmitRequest> ();

        if (caseRecordsToReassign.size() > 0) {

            List <ProcessInstanceWorkItem> workItemList = [Select ProcessInstance.Status, ProcessInstance.TargetObjectId, ProcessInstanceId, OriginalActorId, Id, ActorId
                                                            From ProcessInstanceWorkitem
                                                            WHERE ProcessInstance.TargetObjectId IN: caseRecordsToReassign.KeySet()];

            for (ProcessInstanceWorkItem tempWorkItem: workItemList) {

                //recalling record form approval process as signatory needs to be reassgined
                if (caseRecordsToReassign.containsKey(tempWorkItem.ProcessInstance.TargetObjectId) && tempWorkItem.ActorId != caseRecordsToReassign.get(tempWorkItem.ProcessInstance.TargetObjectId).Signatory_Person_OBO__c) {

                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
                    pwr.SetComments('Recalled by ' + UserInfo.getName());
                    pwr.setWorkItemId(tempWorkItem.id);
                    pwr.setAction('Removed');
                    approvalWorkItemRequests.add(pwr);

                }
            }

            List <Approval.ProcessResult> prList = Approval.process(approvalWorkItemRequests, FALSE);

            approvalWorkItemRequests.clear();

            for (Approval.ProcessResult tempPR: prList) {

                if (tempPR.isSuccess()) {

                    Case tempCase = caseRecordsToReassign.get(tempPR.getEntityId());

                    //preparing case again for approval process so that it gets routed to correct obo/pp signatory
                    Approval.ProcessSubmitRequest tempReq = new Approval.ProcessSubmitRequest();
                    tempReq.setComments('Submitting response for approval as part of signatory change');
                    tempReq.setObjectId(tempCase.Id);

                    if ((tempCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE 
                         && tempCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE 
                         && tempCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) 
                        && tempCase.MO_User__c != NULL) {

                        tempReq.setSubmitterId(tempCase.MO_User__c);
                    }

                    approvalRequests.add(tempReq);
                }
            }

            if (approvalRequests.size() > 0) {

                //submitting case again for approval process
                Approval.ProcessResult[] processResults = Approval.process(approvalRequests, false);

                Set <Id> approvalWorkItemIds = new Set <Id> ();
                for (Approval.ProcessResult tempProcessResult: processResults) {

                    if (tempProcessResult.isSuccess()) {

                        approvalWorkItemIds.addAll(tempProcessResult.getNewWorkitemIds());
                    }
                }

                //fetching approval workitems of cases that were submitted for approval
                List <ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ActorId, ProcessInstance.TargetObjectId
                                                            FROM ProcessInstanceWorkitem
                                                            WHERE Id IN: approvalWorkItemIds];

                for (ProcessInstanceWorkitem workItem: workItems) {

                    Case tempCase = caseRecordsToReassign.get(workItem.ProcessInstance.TargetObjectId);

                    if ((tempCase.Signatory__c != GlobalConstants.MAGS_MANAGER_SIGNATORY_ROLE 
                            && tempCase.Signatory__c != GlobalConstants.EXECUTIVE_DIRECTOR_SIGNATORY_ROLE 
                            && tempCase.Signatory__c != GlobalConstants.PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE) 
                        && tempCase.MO_User__c != NULL) {

                        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                        req.setWorkitemId(workItem.Id);
                        req.setAction('Approve');
                        req.setComments('Approved and sent to updated signatory for further approval.');
                        approvalWorkItemRequests.add(req);
                    }

                }

                //performing DLO/PA auto-approval on resubmitted cases
                processResults = Approval.process(approvalWorkItemRequests, false);
                for (Approval.ProcessResult tempProcessResult: processResults) {

                    if (!tempProcessResult.isSuccess()) {

                        ApplicationLogMessage message = new ApplicationLogMessage();
                        message.source = 'ReassignSignatoryApproval';
                        message.sourceFunction = 'recallApproval';
                        message.logMessage = 'DLO/PA auto-approval failed for ' + tempProcessResult.getEntityId() + ': ' + tempProcessResult.getErrors()[0];
                        message.debugLevel = GlobalConstants.ERROR;
                        ApplicationLogUtility.logMessage(messages);

                        messages.clear();
                    }
                }

                // Unlock the cases         
                Approval.UnlockResult[] lrList = Approval.unlock(new List <Id> (caseRecordsToReassign.keySet()), false);

            }

        }
    }
}