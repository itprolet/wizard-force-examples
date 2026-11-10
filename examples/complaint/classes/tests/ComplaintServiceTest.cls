/**
 * The submit of the Complaint wizard: it creates the Complaint__c of a finished wizard and locks
 * the wizard. A finished wizard is written here as the wizard would leave it: its answers, and its
 * path up to the summary (only what the framework offers to every package: the fields of Wizard__c).
 */
@isTest
private class ComplaintServiceTest {

    private static final String WIZARD_TYPE = 'ComplaintRegistration';

    /** A billing complaint, so the attachment page is on the path too */
    private static Map<String, Object> answers() {
        return new Map<String, Object>{
            'WizardComplaintCategory' => new Map<String, Object>{
                'category' => 'billing',
                'subCategory' => 'wrong_amount'
            },
            'WizardComplaintDetails' => new Map<String, Object>{
                'description' => 'Charged twice for October',
                'incidentDate' => '2026-10-01',
                'referenceNumber' => 'AB-12345'
            },
            'WizardComplaintAttachment' => new Map<String, Object>{
                'invoiceNumber' => 'INV-12345',
                'disputedAmount' => '120.50'
            },
            'WizardComplaintContact' => new Map<String, Object>{
                'firstName' => 'Ann',
                'lastName' => 'Smith',
                'email' => 'ann@example.com',
                'phone' => '0888123456',
                'preferredContact' => 'email'
            }
        };
    }

    private static final List<prolet.WizardPageData> PATH = new List<prolet.WizardPageData>{
        new prolet.WizardPageData('Wizard_pag_ComplaintCategory', 'WizardComplaintCategory'),
        new prolet.WizardPageData('Wizard_pag_ComplaintDetails', 'WizardComplaintDetails'),
        new prolet.WizardPageData('Wizard_pag_ComplaintAttachment', 'WizardComplaintAttachment'),
        new prolet.WizardPageData('Wizard_pag_ComplaintContact', 'WizardComplaintContact'),
        new prolet.WizardPageData('Wizard_pag_ComplaintSummary', 'WizardComplaintSummary')
    };

    /**
     * The path as the framework stores it, written from maps: Apex outside the framework's package
     * cannot serialize the package's classes (WizardPageData), so JSON.serialize(path) fails there.
     */
    private static String pathJson(List<prolet.WizardPageData> path) {
        List<Map<String, Object>> pages = new List<Map<String, Object>>();
        for (prolet.WizardPageData page : path) {
            pages.add(new Map<String, Object>{ 'title' => page.title, 'page' => page.page, 'initParams' => page.initParams });
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
    static void submitCreatesTheComplaintAndLocksTheWizard() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);

        Test.startTest();
        Id complaintId = ComplaintController.submitComplaint(wizard.Id, true);
        Test.stopTest();

        Complaint__c complaint = [
            SELECT Wizard__c, Category__c, Sub_Category__c, Description__c, Incident_Date__c, Reference_Number__c,
                Invoice_Number__c, Disputed_Amount__c, First_Name__c, Last_Name__c, Email__c, Phone__c,
                Preferred_Contact__c, Agreed_to_GDPR__c
            FROM Complaint__c
            WHERE Id = :complaintId
        ];
        Assert.areEqual(wizard.Id, complaint.Wizard__c, 'The complaint is linked to its wizard');
        Assert.areEqual('billing', complaint.Category__c);
        Assert.areEqual('wrong_amount', complaint.Sub_Category__c);
        Assert.areEqual(Date.newInstance(2026, 10, 1), complaint.Incident_Date__c);
        Assert.areEqual('INV-12345', complaint.Invoice_Number__c);
        Assert.areEqual(120.50, complaint.Disputed_Amount__c);
        Assert.areEqual('ann@example.com', complaint.Email__c);
        Assert.areEqual('email', complaint.Preferred_Contact__c);
        Assert.isTrue(complaint.Agreed_to_GDPR__c);
        Assert.areEqual(prolet.WizardStates.LOCKED, stateOf(wizard.Id), 'The wizard can only be looked at');
    }

    @isTest
    static void aSecondSubmitIsRefused() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);
        ComplaintController.submitComplaint(wizard.Id, true);
        try {
            ComplaintController.submitComplaint(wizard.Id, true);
            Assert.fail('A second submit should fail');
        } catch (AuraHandledException e) {
            // the wizard's own message, as it is (not "Error submitting complaint: ")
            Assert.isTrue(e.getMessage().startsWith(System.Label.get('prolet', 'Wizard_err_locked')), e.getMessage());
            Assert.areEqual(1, [SELECT COUNT() FROM Complaint__c], 'Nothing more was created');
        }
    }

    @isTest
    static void theConsentIsRequired() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), PATH);
        try {
            ComplaintController.submitComplaint(wizard.Id, false);
            Assert.fail('The submit should fail without the consent');
        } catch (AuraHandledException e) {
            Assert.areEqual('GDPR consent is required to submit a complaint.', e.getMessage());
            Assert.areEqual(0, [SELECT COUNT() FROM Complaint__c], 'Nothing was created');
            Assert.areEqual(prolet.WizardStates.ACTIVE, stateOf(wizard.Id), 'The user can still change it');
        }
    }

    @isTest
    static void aWizardThatDidNotReachTheSummaryIsRefused() {
        prolet__Wizard__c wizard = wizard(JSON.serialize(answers()), new List<prolet.WizardPageData>{ PATH[0], PATH[1] });
        try {
            ComplaintController.submitComplaint(wizard.Id, true);
            Assert.fail('The submit should fail before the last page');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('WizardComplaintDetails'), e.getMessage());
            Assert.areEqual(0, [SELECT COUNT() FROM Complaint__c], 'Nothing was created');
        }
    }

    @isTest
    static void anUnexpectedProblemReachesTheUserAsAMessage() {
        // answers that cannot be read: no message of the service or the wizard, so the
        // controller's last catch turns it into a message for the user
        prolet__Wizard__c wizard = wizard('not JSON', PATH);
        try {
            ComplaintController.submitComplaint(wizard.Id, true);
            Assert.fail('The submit should fail when the answers cannot be read');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().startsWith('Error submitting complaint: '), e.getMessage());
            Assert.areEqual(0, [SELECT COUNT() FROM Complaint__c], 'Nothing was created');
        }
    }
}
