@IsTest
private class ExpenseReportControllersTest {

    @IsTest
    static void employeeAndManagerFlow() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');

        Map<String, Object> context = ExpenseReportController.calculatePerDiem(wizard.Id);
        Assert.areEqual(3, context.get('perDiemDays'));

        Id reportId = ExpenseReportController.submitReport(wizard.Id, true);
        ExpenseReviewData data = ExpenseReviewController.getReview(reportId);
        Assert.areEqual(2, data.lines.size());

        ExpenseReviewController.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'Check hotel');
        Assert.areEqual('REVIEW', ExpenseReportTestData.reload(wizard.Id).State__c);
    }

    @IsTest
    static void approveFromController() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = ExpenseReportController.submitReport(wizard.Id, true);
        ExpenseReviewController.approveReport(reportId);
        Assert.areEqual('APPROVED', ExpenseReportTestData.reload(wizard.Id).State__c);
    }

    @IsTest
    static void errorsAreWrappedInAuraHandledException() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
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
}
