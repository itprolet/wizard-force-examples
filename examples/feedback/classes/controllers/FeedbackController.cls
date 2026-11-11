/** with sharing: a user submits only a wizard the org's sharing lets them see (as WizardController) */
public with sharing class FeedbackController {
    public static final IFeedbackService feedbackService = new FeedbackService();

    @AuraEnabled
    public static Id submitFeedback(Id wizardId, Boolean agreedToGdpr) {
        try {
            return feedbackService.submitFeedback(wizardId, agreedToGdpr);
        } catch (FeedbackException e) {
            // our own messages (e.g. the consent) are shown to the user as they are
            throw forTheUser(e.getMessage());
        } catch (prolet.WizardException e) {
            // the wizard's: submitted already, or not finished
            throw forTheUser(e.getMessage());
        } catch (Exception e) {
            throw forTheUser('Error submitting feedback: ' + e.getMessage());
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
