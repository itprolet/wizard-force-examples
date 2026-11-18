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

    /** Standard User with the framework's and the example's permission sets, as the docs assign them */
    private static User feedbackUser(String name) {
        User user;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile standard = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            user = new User(
                    ProfileId = standard.Id, LastName = name, Alias = name.left(8),
                    Email = name + '@feedback.test', Username = name + Crypto.getRandomInteger() + '@feedback.test',
                    TimeZoneSidKey = 'Europe/Sofia', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US');
            insert user;
            List<String> permissionSets = new List<String>{ 'Wizard_Framework_User', 'Feedback_Wizard_User' };
            // each set from its own package: the framework's, and the example's (an org may also
            // have a copy of the same name elsewhere)
            String framework = namespaceOf(prolet__Wizard__c.SObjectType);
            String example = namespaceOf(Feedback__c.SObjectType);
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet permissionSet : [
                    SELECT Id FROM PermissionSet
                    WHERE (Name = 'Wizard_Framework_User' AND NamespacePrefix = :framework)
                    OR (Name = 'Feedback_Wizard_User' AND NamespacePrefix = :example)
            ]) {
                assignments.add(new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = user.Id));
            }
            Assert.areEqual(permissionSets.size(), assignments.size(), 'permission sets ' + permissionSets);
            insert assignments;
        }
        return user;
    }

    /**
     * The namespace of the package the custom object is in (prolet__Wizard__c), null for the org's
     * own (Feedback__c). getLocalName() is no help: outside the package it keeps the namespace.
     */
    private static String namespaceOf(Schema.SObjectType type) {
        String name = type.getDescribe().getName();
        return name.countMatches('__') > 1 ? name.substringBefore('__') : null;
    }

    @isTest
    static void aUserWhoIsNotAnAdminSubmitsAndReadsOnlyTheirOwnFeedback() {
        User anna = feedbackUser('anna');
        User ben = feedbackUser('ben');
        Id feedbackId;
        System.runAs(anna) {
            // her own wizard (Wizard__c is Private), submitted through the controller
            prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);
            Test.startTest();
            feedbackId = FeedbackController.submitFeedback(wizard.Id, true);
            Test.stopTest();
            Assert.areEqual(1, [SELECT COUNT() FROM Feedback__c WHERE Id = :feedbackId], 'she reads her feedback');
        }
        System.runAs(ben) {
            // Feedback__c is Private: the same permission sets do not show him hers, e-mail included
            Assert.areEqual(0, [SELECT COUNT() FROM Feedback__c WHERE Id = :feedbackId], 'he does not read hers');
        }
        Assert.areEqual(anna.Id, [SELECT OwnerId FROM Feedback__c WHERE Id = :feedbackId].OwnerId);
    }
}
