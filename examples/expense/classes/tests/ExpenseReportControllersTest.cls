@IsTest
private class ExpenseReportControllersTest {

    @IsTest
    static void employeeAndManagerFlow() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');

        prolet.WizardVersionChange change = ExpenseReportController.calculatePerDiem(wizard.Id);
        Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(ExpenseReportTestData.reload(wizard.Id).prolet__Context__c);
        Assert.areEqual(3, context.get('perDiemDays'));
        // the page sends this with its "refresh": the context changed, so the version went up by one
        Assert.areEqual(change.fromVersion + 1, change.pathVersion);
        Assert.areEqual(change.pathVersion, ExpenseReportTestData.reload(wizard.Id).prolet__PathVersion__c);

        prolet.WizardVersionChange submit = ExpenseReportController.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
        Assert.areEqual(change.pathVersion, submit.fromVersion, 'the submit starts from the version after the calculation');
        // the answers and the context, then the lock (WizardApi.lock within the page's own change)
        Assert.areEqual(submit.fromVersion + 2, submit.pathVersion);
        Assert.areEqual(submit.pathVersion, ExpenseReportTestData.reload(wizard.Id).prolet__PathVersion__c, 'what the trigger stored');
        Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizard.Id).prolet__State__c);
        Id reportId = reportOf(wizard.Id);
        ExpenseReviewData data = ExpenseReviewController.getReview(reportId);
        Assert.areEqual(2, data.lines.size());

        ExpenseReviewController.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'Check hotel');
        Assert.areEqual(prolet.WizardStates.ACTIVE, ExpenseReportTestData.reload(wizard.Id).prolet__State__c);
    }

    @IsTest
    static void approveFromController() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        ExpenseReportController.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
        ExpenseReviewController.approveReport(reportOf(wizard.Id));
        Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizard.Id).prolet__State__c);
        Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Wizard__c = :wizard.Id].Status__c);
    }

    @IsTest
    static void errorsAreWrappedInAuraHandledException() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        try {
            ExpenseReportController.submitReport(wizard.Id, false);
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('declaration'), e.getMessage());
        }
    }

    @IsTest
    static void allEndpointsWrapErrors() {
        Integer failures = 0;
        try { ExpenseReportController.calculatePerDiem(null); } catch (AuraHandledException e) { failures++; }
        try { ExpenseReportController.submitReport(null, true); } catch (AuraHandledException e) { failures++; }
        try { ExpenseReviewController.getReview(null); } catch (AuraHandledException e) { failures++; }
        try { ExpenseReviewController.requestChanges(null, null, null, false, null); } catch (AuraHandledException e) { failures++; }
        try { ExpenseReviewController.approveReport(null); } catch (AuraHandledException e) { failures++; }
        Assert.areEqual(5, failures);
    }

    @IsTest
    static void aCalculationThatChangesNothingKeepsTheVersion() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        ExpenseReportController.calculatePerDiem(wizard.Id);
        prolet.WizardVersionChange again = ExpenseReportController.calculatePerDiem(wizard.Id);
        Assert.areEqual(again.fromVersion, again.pathVersion, 'the same per-diem again: no change');
    }

    private static Id reportOf(Id wizardId) {
        return [SELECT Id FROM Expense_Report__c WHERE Wizard__c = :wizardId].Id;
    }
}
