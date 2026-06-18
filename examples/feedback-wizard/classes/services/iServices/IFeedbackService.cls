public interface IFeedbackService {
    /**
     * @description Finalizes feedback wizard and persists Feedback__c.
     * @param wizardId ID of the Wizard__c record
     * @param agreedToGdpr User consented to GDPR on the summary step
     * @return ID of the new Feedback__c record
     */
    Id submitFeedback(Id wizardId, Boolean agreedToGdpr);
}
