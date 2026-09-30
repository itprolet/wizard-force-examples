/**
 * @description Apex controller for the Showcase Wizard.
 * Called by ShowcaseSummary when the user submits their registration.
 *
 * In a real implementation you would create or update a domain record here
 * (e.g. EventRegistration__c) and link it to the Wizard__c record.
 * For demonstration purposes this method only logs the submission.
 */
public with sharing class ShowcaseController {

    @AuraEnabled
    public static void submitShowcase(Id wizardId) {
        if (wizardId == null) {
            throw new AuraHandledException('wizardId is required');
        }
        // Replace with real domain logic, e.g.:
        //   EventRegistration__c reg = new EventRegistration__c(Wizard__c = wizardId, ...);
        //   insert reg;
        System.debug(LoggingLevel.INFO, 'Showcase wizard submitted: ' + wizardId);
    }
}
