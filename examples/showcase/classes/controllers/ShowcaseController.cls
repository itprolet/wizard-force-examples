/**
 * @description Apex controller for the Showcase Wizard.
 * Called by ShowcaseSummary when the user submits their registration.
 *
 * In a real implementation you would create or update a domain record here
 * (e.g. EventRegistration__c) and link it to the Wizard__c record.
 * For demonstration purposes this method only logs the submission, and locks the wizard: from
 * then on it can only be looked at, and a second click on Submit is refused.
 */
public with sharing class ShowcaseController {

    @AuraEnabled
    public static void submitShowcase(Id wizardId) {
        if (wizardId == null) {
            throw forTheUser('wizardId is required');
        }
        try {
            // ACTIVE, and the user went through every page: a second click is refused here
            prolet.WizardApi.assertCompleted(wizardId);
            // Replace with real domain logic, e.g.:
            //   EventRegistration__c reg = new EventRegistration__c(Wizard__c = wizardId, ...);
            //   insert reg;
            System.debug(LoggingLevel.INFO, 'Showcase wizard submitted: ' + wizardId);
            // from now on the wizard can only be looked at
            prolet.WizardApi.lock(wizardId);
        } catch (prolet.WizardException e) {
            // the wizard's: submitted already, or not finished
            throw forTheUser(e.getMessage());
        } catch (Exception e) {
            throw forTheUser('Could not submit the registration: ' + e.getMessage());
        }
    }

    /**
     * The error the user sees. setMessage too: without it getMessage() says only
     * "Script-thrown exception", and a test could not tell which catch was used.
     */
    private static AuraHandledException forTheUser(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}
