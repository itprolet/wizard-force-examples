/**
 * @description Service for operations with feedback (Feedback__c).
 * Reuses WizardSelector for querying Wizard__c.
 */
public inherited sharing class FeedbackService implements IFeedbackService {

    private static final WizardSelector wizardSelector = new WizardSelector();

    public Id submitFeedback(Id wizardId, Boolean agreedToGdpr) {
        List<Wizard__c> wizards = wizardSelector.selectByIds(wizardId);
        if (wizards.isEmpty()) {
            throw new FeedbackException('Wizard not found, id= ' + wizardId);
        }

        Wizard__c wizard = wizards[0];
        if (String.isBlank(wizard.Model__c)) {
            throw new FeedbackException('Wizard model is empty, id= ' + wizardId);
        }

        Map<String, Object> model = (Map<String, Object>) JSON.deserializeUntyped(wizard.Model__c);
        Feedback__c feedback = buildFeedback(wizardId, model, agreedToGdpr);

        if (agreedToGdpr != true) {
            throw new FeedbackException('GDPR consent is required to submit feedback.');
        }

        insert feedback;
        return feedback.Id;
    }

    /**
     * @description Maps wizard model (JSON) to Feedback__c fields.
     *   FeedbackRating → rating, wouldRecommend
     *   FeedbackComment → comment, email
     */
    private static Feedback__c buildFeedback(Id wizardId, Map<String, Object> model, Boolean agreedToGdpr) {
        Map<String, Object> ratingData = toMap(model.get('FeedbackRating'));
        Map<String, Object> commentData = toMap(model.get('FeedbackComment'));

        Feedback__c feedback = new Feedback__c();
        feedback.Wizard__c = wizardId;

        String ratingStr = strVal(ratingData, 'rating');
        if (String.isNotBlank(ratingStr)) {
            try {
                feedback.Rating__c = Decimal.valueOf(ratingStr);
            } catch (Exception e) {
                // invalid number — leave null
            }
        }

        feedback.Would_Recommend__c = boolVal(ratingData, 'wouldRecommend');
        feedback.Comment__c = strVal(commentData, 'comment');
        feedback.Email__c = strVal(commentData, 'email');
        feedback.Agreed_to_GDPR__c = agreedToGdpr;

        return feedback;
    }

    private static Map<String, Object> toMap(Object obj) {
        if (obj instanceof Map<String, Object>) {
            return (Map<String, Object>) obj;
        }
        return new Map<String, Object>();
    }

    private static String strVal(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key)) {
            return null;
        }
        Object val = m.get(key);
        return val != null ? String.valueOf(val) : null;
    }

    private static Boolean boolVal(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key)) {
            return false;
        }
        Object v = m.get(key);
        if (v instanceof Boolean) {
            return (Boolean) v;
        }
        if (v != null) {
            return Boolean.valueOf(String.valueOf(v));
        }
        return false;
    }
}
