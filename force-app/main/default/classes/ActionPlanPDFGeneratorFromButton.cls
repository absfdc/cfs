/*------------------------------------------------------------
Author:        Vishnu Belkone
Company:       Arxxus.com
Description:   This class is responsible for handling the Apex sharing
               for Action Plan object

Test Class:    ActionPlanPDFGeneratorFromButton_Test
History
07/05/2015     Vishnu Belkone       Created
------------------------------------------------------------*/
global with sharing  class ActionPlanPDFGeneratorFromButton {
	webservice static String genratePDF(Id actionPlanId) // you can pass parameters
    {
        ActionPlanPDFGenerator actionPlanPDF = new ActionPlanPDFGenerator();
        Boolean isSuccess = actionPlanPDF.callFromButton(actionPlanId);
        if(isSuccess) {
        	return 'File generated successfully!\nYou can find the generated pdf in Case Notes & Attachments.';
    	} 
    	return 'Error occured while generating PDF file. Please try again.';
    }
}