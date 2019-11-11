global class InboundEmailsWithScannedDocumentsHandler implements Messaging.InboundEmailHandler {
	  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		  ProcessEmailsWithScannedDocuments emailProcessor = new ProcessEmailsWithScannedDocuments();
		  return emailProcessor.processEmails(email, envelope); 
	  }
 }