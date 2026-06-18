@IsTest
private class ComplaintServiceTest {

    private static final String WIZARD_TYPE = 'TEST';

    @IsTest
    static void testSubmitComplaintHappyPathPersistsComplaintFromWizardModel() {
        Wizard__c wizard = insertWizardWithModel(validComplaintModel());

        Test.startTest();
        Id complaintId = new ComplaintService().submitComplaint(wizard.Id, true);
        Test.stopTest();

        Complaint__c complaint = [
            SELECT Category__c, Sub_Category__c, Description__c, Email__c,
                   Agreed_to_GDPR__c, Wizard__c
            FROM Complaint__c
            WHERE Id = :complaintId
        ];

        Assert.areEqual(wizard.Id, complaint.Wizard__c);
        Assert.areEqual('billing', complaint.Category__c);
        Assert.areEqual('double_charge', complaint.Sub_Category__c);
        Assert.areEqual('Late charge on account', complaint.Description__c);
        Assert.areEqual('user@example.com', complaint.Email__c);
        Assert.isTrue(complaint.Agreed_to_GDPR__c);
    }

    @IsTest
    static void testSubmitComplaintMissingWizardThrowsComplaintException() {
        try {
            new ComplaintService().submitComplaint(Id.valueOf('000000000000000AAA'), true);
            Assert.fail('Expected ComplaintException');
        } catch (ComplaintException e) {
            Assert.isTrue(e.getMessage().contains('Wizard model is empty'), e.getMessage());
        }
    }

    @IsTest
    static void testSubmitComplaintEmptyModelThrowsComplaintException() {
        Wizard__c wizard = new Wizard__c(Wizard_Type__c = WIZARD_TYPE);
        insert wizard;

        try {
            new ComplaintService().submitComplaint(wizard.Id, true);
            Assert.fail('Expected ComplaintException');
        } catch (ComplaintException e) {
            Assert.isTrue(e.getMessage().contains('Wizard model is empty'), e.getMessage());
        }
    }

    @IsTest
    static void testSubmitComplaintGdprNotAcceptedThrowsComplaintException() {
        Wizard__c wizard = insertWizardWithModel(validComplaintModel());

        try {
            new ComplaintService().submitComplaint(wizard.Id, false);
            Assert.fail('Expected ComplaintException');
        } catch (ComplaintException e) {
            Assert.areEqual('GDPR consent is required to submit a complaint.', e.getMessage());
        }
    }

    @IsTest
    static void testSubmitComplaintInvalidDateAndAmountIgnoresMalformedValues() {
        Map<String, Object> model = validComplaintModel();
        Map<String, Object> details = (Map<String, Object>) model.get('WizardComplaintDetails');
        details.put('incidentDate', 'not-a-date');
        Map<String, Object> attachment = (Map<String, Object>) model.get('WizardComplaintAttachment');
        attachment.put('disputedAmount', 'not-a-number');

        Wizard__c wizard = insertWizardWithModel(model);

        Test.startTest();
        Id complaintId = new ComplaintService().submitComplaint(wizard.Id, true);
        Test.stopTest();

        Complaint__c complaint = [
            SELECT Incident_Date__c, Disputed_Amount__c
            FROM Complaint__c
            WHERE Id = :complaintId
        ];
        Assert.isNull(complaint.Incident_Date__c);
        Assert.isNull(complaint.Disputed_Amount__c);
    }

    // --- helpers ---

    private static Wizard__c insertWizardWithModel(Map<String, Object> model) {
        Wizard__c wizard = new Wizard__c(
            Wizard_Type__c = WIZARD_TYPE,
            Model__c = JSON.serialize(model)
        );
        insert wizard;
        return wizard;
    }

    private static Map<String, Object> validComplaintModel() {
        return new Map<String, Object>{
            'WizardComplaintCategory' => new Map<String, Object>{
                'category' => 'billing',
                'subCategory' => 'double_charge'
            },
            'WizardComplaintDetails' => new Map<String, Object>{
                'description' => 'Late charge on account',
                'incidentDate' => '2026-05-01',
                'referenceNumber' => 'AB-12345',
                'affectedService' => 'internet'
            },
            'WizardComplaintAttachment' => new Map<String, Object>{
                'invoiceNumber' => 'INV-99',
                'disputedAmount' => '120.50'
            },
            'WizardComplaintContact' => new Map<String, Object>{
                'firstName' => 'Alex',
                'lastName' => 'Ivanov',
                'email' => 'user@example.com',
                'phone' => '+3598000000',
                'preferredContact' => 'email',
                'preferredTime' => 'morning'
            }
        };
    }
}
