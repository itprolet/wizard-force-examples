public without sharing class FeedbackController {
    public static final IFeedbackService feedbackService = new FeedbackService();

    @AuraEnabled
    public static Id submitFeedback(Id wizardId, Boolean agreedToGdpr) {
        try {
            return feedbackService.submitFeedback(wizardId, agreedToGdpr);
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting feedback: ' + e.getMessage());
        }
    }
}
