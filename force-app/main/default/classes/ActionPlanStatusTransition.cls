/**
*  Oct release: removed method for 'Send for printing' 
*/
global with sharing class ActionPlanStatusTransition {
    private static final String FIELD_CUSTOM_VALIDATION_EXCEPTION = 'FIELD_CUSTOM_VALIDATION_EXCEPTION,';

    webservice static String assign(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED , actionPlanId);
    }
    
    webservice static String complete(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_CLOSED_STATUS , actionPlanId);
    }
    
    webservice static String inProgress(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS , actionPlanId);
    }

    webservice static String rejectedIncorrectAssignment(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT , actionPlanId);
    }
    
    webservice static String takeOwnership(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_TAKE_OWNERSHIP , actionPlanId);
    }
    
    webservice static String submitForReview(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_NEW_APPROVED , actionPlanId);
    }
    
    webservice static String amendment(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_AMENDMENT , actionPlanId);
    }
    
    webservice static String awaitingSignature(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG , actionPlanId);
    }
    
    webservice static String rework(Id actionPlanId) {
        return performTransition(GlobalConstants.ACTION_PLAN_REWORK , actionPlanId);
    }
    
    private static String performTransition(String status, Id actionPlanId) {
        String returnStr = '';
        try {
            AbstractAPStatusTransition instance = APStatusTransitionRetriever.getTransitionRetriever(status , actionPlanId);
            instance.performTransition();
        } catch(Exception e) {
            returnStr = e.getMessage();
            if(!String.isBlank(returnStr) && returnStr.contains(FIELD_CUSTOM_VALIDATION_EXCEPTION)) {
                Integer index = returnStr.indexOf(FIELD_CUSTOM_VALIDATION_EXCEPTION) + FIELD_CUSTOM_VALIDATION_EXCEPTION.length();
                Integer lastIndex = returnStr.lastIndexOf(':');
                if(lastIndex < 0) {
                    lastIndex = returnStr.length();
                }
                returnStr = returnStr.substring(index + 1, lastIndex);
            }
        }
        return returnStr;
    }
}