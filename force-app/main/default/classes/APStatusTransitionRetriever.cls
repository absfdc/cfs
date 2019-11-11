/**
*  Oct release: removed method for 'Send for printing' 
*/
public without sharing class APStatusTransitionRetriever {

    public static AbstractAPStatusTransition getTransitionRetriever(String action, Id actionPlanId) {
        AbstractAPStatusTransition instance;
        
        if(GlobalConstants.ACTION_PLAN_STATUS_ASSIGNED.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForAssign(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_STATUS_INPROGRESS.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForInProgress(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_CLOSED_STATUS.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForCompleted(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_INCORRECT_ASSIGNMENT.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForRejectedAssignment(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_TAKE_OWNERSHIP.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForTakeOwnership(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_NEW_APPROVED.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForReview(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_STATUS_AWAITING_SIG.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForAwaitingSig(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_AMENDMENT.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForAmendment(actionPlanId);
        } else if(GlobalConstants.ACTION_PLAN_REWORK.equalsIgnoreCase(action)) {
            instance = new APStatusTransitionForRework(actionPlanId);
        }
        
        if(instance == null) {
            throw new InvalidDataException('Failed to instantiate class. Current action[' + action + '] is not supported.');
        }
        
        return instance;
    }
     
    public class InvalidDataException extends Exception {}
}