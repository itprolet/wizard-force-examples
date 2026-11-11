/**
 * The submit of the Feedback wizard: it creates the Feedback__c of a finished wizard and locks
 * the wizard. A finished wizard is written here as the wizard would leave it: its answers, and its
 * path up to the summary (only what the framework offers to every package: the fields of Wizard__c).
 */
@isTest
private class FeedbackServiceTest {

    private static final String WIZARD_TYPE = 'Feedback';

    private static Map<String, Object> answers() {
        return new Map<String, Object>{
            'FeedbackRating' => new Map<String, Object>{ 'rating' => '4', 'wouldRecommend' => true },
            'FeedbackComment' => new Map<String, Object>{
                'comment' => 'Quick and friendly',
                'email' => 'ann@example.com'
            }
        };
    }

    private static final List<prolet.WizardPageData> PATH = new List<prolet.WizardPageData>{
        new prolet.WizardPageData('Rating', 'FeedbackRating'),
        new prolet.WizardPageData('Comment', 'FeedbackComment'),
        new prolet.WizardPageData('Summary', 'WizardFeedbackSummary')
    };

    /**
     * The path as the framework stores it, written from maps: Apex outside the framework's package
     * cannot serialize the package's classes (WizardPageData), so JSON.serialize(path) fails there.
     */
    private static String pathJson(List<prolet.WizardPageData> path) {
        List<Map<String, Object>> pages = new List<Map<String, Object>>();
        for (prolet.WizardPageData page : path) {
            pages.add(new Map<String, Object>{ 'title' => page.title, 'page' => page.page, 'initParams' => page.initParams,
                'paramsJson' => page.paramsJson });
        }
        return JSON.serialize(pages);
    }

    private static prolet__Wizard__c wizard(String modelJson, List<prolet.WizardPageData> path) {
        // ACTIVE written, not left to the picklist default: a wizard without a state is locked
        prolet__Wizard__c wizard = new prolet__Wizard__c(
            prolet__Wizard_Type__c = WIZARD_TYPE,
            prolet__State__c = prolet.WizardStates.ACTIVE,
            prolet__Model__c = modelJson,
            prolet__Path__c = pathJson(path)
        );
        insert wizard;
        return wizard;
    }

    private static String stateOf(Id wizardId) {
        return [SELECT prolet__State__c FROM prolet__Wizard__c WHERE Id = :wizardId].prolet__State__c;
    }

    @isTest
    static void submitCreatesTheFeedbackAndLocksTheWizard() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);

        Test.startTest();
        Id feedbackId = FeedbackController.submitFeedback(wizard.Id, true);
        Test.stopTest();

        Feedback__c feedback = [
            SELECT Wizard__c, Rating__c, Would_Recommend__c, Comment__c, Email__c, Agreed_to_GDPR__c
            FROM Feedback__c
            WHERE Id = :feedbackId
        ];
        Assert.areEqual(wizard.Id, feedback.Wizard__c, 'The feedback is linked to its wizard');
        Assert.areEqual(4, feedback.Rating__c);
        Assert.isTrue(feedback.Would_Recommend__c);
        Assert.areEqual('Quick and friendly', feedback.Comment__c);
        Assert.areEqual('ann@example.com', feedback.Email__c);
        Assert.isTrue(feedback.Agreed_to_GDPR__c);
        Assert.areEqual(prolet.WizardStates.LOCKED, stateOf(wizard.Id), 'The wizard can only be looked at');
    }

    @isTest
    static void aSecondSubmitIsRefused() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);
        FeedbackController.submitFeedback(wizard.Id, true);
        try {
            FeedbackController.submitFeedback(wizard.Id, true);
            Assert.fail('A second submit should fail');
        } catch (AuraHandledException e) {
            // the wizard's own message, as it is (not "Error submitting feedback: ")
            Assert.isTrue(e.getMessage().startsWith(System.Label.get('prolet', 'Wizard_err_locked')), e.getMessage());
            Assert.areEqual(1, [SELECT COUNT() FROM Feedback__c], 'Nothing more was created');
        }
    }

    @isTest
    static void theConsentIsRequired() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);
        try {
            FeedbackController.submitFeedback(wizard.Id, false);
            Assert.fail('The submit should fail without the consent');
        } catch (AuraHandledException e) {
            Assert.areEqual('GDPR consent is required to submit feedback.', e.getMessage());
            Assert.areEqual(0, [SELECT COUNT() FROM Feedback__c], 'Nothing was created');
            Assert.areEqual(prolet.WizardStates.ACTIVE, stateOf(wizard.Id), 'The user can still change it');
        }
    }

    @isTest
    static void aWizardThatDidNotReachTheSummaryIsRefused() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), new List<prolet.WizardPageData>{ PATH[0] });
        try {
            FeedbackController.submitFeedback(wizard.Id, true);
            Assert.fail('The submit should fail before the last page');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('FeedbackRating'), e.getMessage());
            Assert.areEqual(0, [SELECT COUNT() FROM Feedback__c], 'Nothing was created');
        }
    }

    @isTest
    static void anUnexpectedProblemReachesTheUserAsAMessage() {
        // answers that cannot be read: no message of the service or the wizard, so the
        // controller's last catch turns it into a message for the user
        prolet__Wizard__c wizard = wizard('not JSON', PATH);
        try {
            FeedbackController.submitFeedback(wizard.Id, true);
            Assert.fail('The submit should fail when the answers cannot be read');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().startsWith('Error submitting feedback: '), e.getMessage());
            Assert.areEqual(0, [SELECT COUNT() FROM Feedback__c], 'Nothing was created');
        }
    }
}
