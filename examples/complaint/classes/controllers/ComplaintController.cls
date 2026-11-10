/** with sharing: a user submits only a wizard the org's sharing lets them see (as WizardController) */
public with sharing class ComplaintController {
    public static final IComplaintService complaintService = new ComplaintService();

    @AuraEnabled
    public static Id submitComplaint(Id wizardId, Boolean agreedToGdpr) {
        try {
            return complaintService.submitComplaint(wizardId, agreedToGdpr);
        } catch (ComplaintException e) {
            // our own messages (e.g. the consent) are shown to the user as they are
            throw forTheUser(e.getMessage());
        } catch (prolet.WizardException e) {
            // the wizard's: submitted already, or not finished
            throw forTheUser(e.getMessage());
        } catch (Exception e) {
            throw forTheUser('Error submitting complaint: ' + e.getMessage());
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
