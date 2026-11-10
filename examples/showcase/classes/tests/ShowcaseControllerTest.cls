/**
 * The submit of the Showcase wizard: it only locks a finished wizard. A finished wizard is written
 * here as the wizard would leave it: its answers, and its path up to the summary (only what the
 * framework offers to every package: the fields of Wizard__c).
 */
@isTest
private class ShowcaseControllerTest {

    private static final String WIZARD_TYPE = 'ShowcaseWizard';

    /** An online event, so the preferences page is not on the path */
    private static Map<String, Object> answers() {
        return new Map<String, Object>{
            'ShowcaseEventType' => new Map<String, Object>{ 'eventType' => 'online' },
            'ShowcaseSchedule' => new Map<String, Object>{ 'sessions' => new List<Object>{ 'morning' } },
            'ShowcaseContact' => new Map<String, Object>{
                'firstName' => 'Ann',
                'lastName' => 'Smith',
                'email' => 'ann@example.com',
                'phone' => '+359888123456'
            }
        };
    }

    private static final List<prolet.WizardPageData> PATH = new List<prolet.WizardPageData>{
        new prolet.WizardPageData('EventType', 'ShowcaseEventType'),
        new prolet.WizardPageData('Schedule', 'ShowcaseSchedule'),
        new prolet.WizardPageData('Contact', 'ShowcaseContact'),
        new prolet.WizardPageData('Summary', 'ShowcaseSummary')
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
    static void submitLocksTheWizard() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);

        Test.startTest();
        ShowcaseController.submitShowcase(wizard.Id);
        Test.stopTest();

        Assert.areEqual(prolet.WizardStates.LOCKED, stateOf(wizard.Id), 'The wizard can only be looked at');
    }

    @isTest
    static void aSecondSubmitIsRefused() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);
        ShowcaseController.submitShowcase(wizard.Id);
        try {
            ShowcaseController.submitShowcase(wizard.Id);
            Assert.fail('A second submit should fail');
        } catch (AuraHandledException e) {
            // the wizard's own message, as it is
            Assert.isTrue(e.getMessage().startsWith(System.Label.get('prolet', 'Wizard_err_locked')), e.getMessage());
            Assert.areEqual(prolet.WizardStates.LOCKED, stateOf(wizard.Id));
        }
    }

    @isTest
    static void aWizardThatDidNotReachTheSummaryIsRefused() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), new List<prolet.WizardPageData>{ PATH[0], PATH[1] });
        try {
            ShowcaseController.submitShowcase(wizard.Id);
            Assert.fail('The submit should fail before the last page');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('ShowcaseSchedule'), e.getMessage());
            Assert.areEqual(prolet.WizardStates.ACTIVE, stateOf(wizard.Id), 'The user can still go on');
        }
    }

    @isTest
    static void aWizardIsRequired() {
        try {
            ShowcaseController.submitShowcase(null);
            Assert.fail('The submit should fail without a wizard');
        } catch (AuraHandledException e) {
            Assert.areEqual('wizardId is required', e.getMessage());
        }
    }

    @isTest
    static void anUnexpectedProblemReachesTheUserAsAMessage() {
        // answers that cannot be read: no message of the wizard, so the controller's last catch
        // turns it into a message for the user
        prolet__Wizard__c wizard = wizard('not JSON', PATH);
        try {
            ShowcaseController.submitShowcase(wizard.Id);
            Assert.fail('The submit should fail when the answers cannot be read');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().startsWith('Could not submit the registration: '), e.getMessage());
            Assert.areEqual(prolet.WizardStates.ACTIVE, stateOf(wizard.Id), 'Not locked');
        }
    }
}
