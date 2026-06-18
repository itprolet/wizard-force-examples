@IsTest
private class ComplaintControllerTest {

    @IsTest
    static void testSubmitComplaintDelegatesToService() {
        Wizard__c wizard = new Wizard__c(
            Wizard_Type__c = 'TEST',
            Model__c = JSON.serialize(new Map<String, Object>{
                'WizardComplaintCategory' => new Map<String, Object>{
                    'category' => 'other'
                },
                'WizardComplaintDetails' => new Map<String, Object>{
                    'description' => 'General issue',
                    'incidentDate' => '2026-05-01'
                },
                'WizardComplaintContact' => new Map<String, Object>{
                    'email' => 'test@example.com'
                }
            })
        );
        insert wizard;

        Test.startTest();
        Id complaintId = ComplaintController.submitComplaint(wizard.Id, true);
        Test.stopTest();

        Assert.isNotNull(complaintId);
        Assert.areEqual(1, [SELECT COUNT() FROM Complaint__c WHERE Id = :complaintId]);
    }

    @IsTest
    static void testSubmitComplaintServiceFailureWrapsAuraHandledException() {
        try {
            ComplaintController.submitComplaint(Id.valueOf('000000000000000AAA'), true);
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e, 'Controller should surface failures as AuraHandledException');
        }
    }
}
