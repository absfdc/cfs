global class ReassignCasesHandler implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        System.debug(LoggingLevel.INFO, 'Email details ' + email);
        String subject = email.subject;
        String body = email.plainTextBody;
        System.debug('body: ' + body);
        
        String caseId = '';
        String caseownerId = '';
        
        if (body!=null && body.length()> 0){
            caseId = body.substring(0, body.indexOf('--'));
            System.debug('CaseId: ' + caseId);
            
            caseownerId = body.substring(body.indexOf('--')+2, body.length());
            System.debug('CaseownerId: ' + caseownerId);
            
        }
        
        if (caseId!=null && caseId.length()> 0 && caseownerId!=null && caseownerId.length()> 0){		
            System.debug('<===case===>' + body);
            List < ProcessInstanceWorkItem > workItemList = [Select p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.OriginalActorId, p.Id, p.ActorId
                                                             From ProcessInstanceWorkitem p where p.ProcessInstance.TargetObjectId =: caseId]; 
            
            if(workItemList.size() > 0)
            	workItemList.get(0).ActorId = caseownerId;
            update workItemList;
        }
        else {
            result.success = false;    
            return result;
        }
        
        result.success = true;    
        return result; 
    }      
    
}