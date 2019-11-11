public without sharing class S2SConnectionHelper {

    private static Set<Id> sharedRecords = new Set<Id>();
    
    private static Id getConnectionId(String connectionName) {        
        List<PartnerNetworkConnection> partnerNetConList = [SELECT Id FROM PartnerNetworkConnection 
                                                            WHERE connectionStatus = :GlobalConstants.S2S_CONNECTION_ACCEPTED
                                                                AND connectionName = :String.escapeSingleQuotes(connectionName)];
        
        if ( !partnerNetConList.isEmpty()) {
            return partnerNetConList.get(0).Id;            
        } else {
            throw new InvalidConnectionException('Failed to share record. Connection name is invalid');
        }        
    }
    
    public static Boolean shareRecord(Map<Id, Id> objVsParent, String connectionName){
        Boolean flag = true;
        if(objVsParent == null || objVsParent.isEmpty()) {
            throw new InvalidConnectionException('Failed to share record. Records to be shared not available');
        }
        Map<Id, Id> recordsToShare = new Map<Id, Id>();
        for(Id recordId : objVsParent.keySet()) {
            if(!sharedRecords.contains(recordId)) {
                recordsToShare.put(recordId, recordsToShare.get(recordId));
            }
        }
        if(recordsToShare.isEmpty()) {
            return flag;
        }
        try{        
            Id networkId = S2SConnectionHelper.getConnectionId(connectionName); 
      
            List<PartnerNetworkRecordConnection> objectConnections = new List<PartnerNetworkRecordConnection>();
            
            for(Id recordToShare : recordsToShare.keySet()) {
                System.debug(LoggingLevel.INFO, 'Record to share ' + recordToShare + '  ParentId ' + objVsParent.get(recordToShare));
                PartnerNetworkRecordConnection newConnection =
                    new PartnerNetworkRecordConnection(
                        ConnectionId = networkId,
                        LocalRecordId = recordToShare,
                        SendClosedTasks = false,
                        SendOpenTasks = false,
                        SendEmails = false,
                        ParentRecordId = objVsParent.get(recordToShare)
                    );
                objectConnections.add(newConnection);                
            }
             
            if (!objectConnections.isEmpty()) { 
                insert objectConnections;
                sharedRecords.addAll(recordsToShare.keySet());
            }
        } catch(Exception e){
            flag = false;
            List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'S2SConnectionHelper';
            message.sourceFunction = 'shareRecord';
            message.referenceInfo=JSON.serialize(objVsParent.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
        }
        return flag;
    }
    
    public class InvalidConnectionException extends Exception {}
}