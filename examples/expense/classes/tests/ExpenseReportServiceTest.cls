@IsTest
private class ExpenseReportServiceTest {

    private static final ExpenseReportService service = new ExpenseReportService();

    @IsTest
    static void submitCreatesReportAndLinesAndLocksWizard() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');

        Test.startTest();
        Id reportId = service.submitReport(wizard.Id, true);
        Test.stopTest();

        Expense_Report__c report = [
                SELECT Wizard__c, Destination_Type__c, Destination__c, Date_From__c, Passport_Number__c,
                        Visa_Number__c, EHIC_Number__c, IBAN__c, Total_Amount__c, Status__c,
                        (SELECT Line_Key__c, Amount__c, Type__c FROM Expense_Lines__r ORDER BY Line_Key__c)
                FROM Expense_Report__c WHERE Id = :reportId
        ];
        Assert.areEqual(wizard.Id, report.Wizard__c);
        Assert.areEqual('international', report.Destination_Type__c);
        Assert.areEqual(Date.newInstance(2026, 10, 5), report.Date_From__c);
        Assert.areEqual('382000000', report.Passport_Number__c);
        Assert.areEqual('V-123', report.Visa_Number__c);
        Assert.isNull(report.EHIC_Number__c, 'EU page data must be ignored for international trips');
        Assert.areEqual(ExpenseReportTestData.VALID_IBAN, report.IBAN__c, 'IBAN is normalized');
        Assert.areEqual(585, report.Total_Amount__c.intValue());
        Assert.areEqual('Submitted', report.Status__c);
        Assert.areEqual(2, report.Expense_Lines__r.size());
        Assert.areEqual('e1', report.Expense_Lines__r[0].Line_Key__c);
        Assert.areEqual(540, report.Expense_Lines__r[0].Amount__c.intValue());

        Assert.areEqual('SIGNED', ExpenseReportTestData.reload(wizard.Id).State__c);
    }

    @IsTest
    static void submitRequiresDeclaration() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        try {
            service.submitReport(wizard.Id, false);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('declaration'), e.getMessage());
        }
    }

    @IsTest
    static void submitRequiresExpenses() {
        Map<String, Object> model = ExpenseReportTestData.validModel();
        ((Map<String, Object>) model.get('ExpenseItems')).put('expenses', new List<Object>());
        Wizard__c wizard = ExpenseReportTestData.insertWizard(model, 'ACTIVE');
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('At least one expense'), e.getMessage());
        }
    }

    @IsTest
    static void submitTwiceFails() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        service.submitReport(wizard.Id, true);
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('SIGNED'), e.getMessage());
        }
    }

    @IsTest
    static void submitUnknownWizardFails() {
        try {
            service.submitReport(null, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('Wizard not found'), e.getMessage());
        }
    }

    @IsTest
    static void calculatePerDiemStoresContext() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');

        Map<String, Object> context = service.calculatePerDiem(wizard.Id);

        Assert.areEqual(3, context.get('perDiemDays'), '5th to 7th October = 3 days');
        Decimal rate = (Decimal) context.get('perDiemRate');
        Assert.isTrue(rate > 0);
        Assert.areEqual(rate * 3, (Decimal) context.get('perDiemTotal'));
        Map<String, Object> stored = (Map<String, Object>) JSON.deserializeUntyped(
                ExpenseReportTestData.reload(wizard.Id).Context__c);
        Assert.areEqual(3, stored.get('perDiemDays'));
    }

    @IsTest
    static void calculatePerDiemDoesNothingWhenSigned() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'SIGNED');
        Map<String, Object> context = service.calculatePerDiem(wizard.Id);
        Assert.isFalse(context.containsKey('perDiemTotal'));
    }

    @IsTest
    static void requestChangesPutsWizardInReview() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);

        service.requestChanges(reportId, new List<String>{ 'e1' }, new List<String>{ 'e2' }, true, 'Hotel too expensive');

        Wizard__c reloaded = ExpenseReportTestData.reload(wizard.Id);
        Assert.areEqual('REVIEW', reloaded.State__c);
        Map<String, Object> reviewData = (Map<String, Object>) JSON.deserializeUntyped(reloaded.Review_Data__c);
        Map<String, Object> items = (Map<String, Object>) reviewData.get('ExpenseItems');
        Assert.areEqual('540', items.get('expenses[id=e1].amount'));
        Assert.areEqual('', items.get('expenses[id=e2]'));
        Map<String, Object> reimbursement = (Map<String, Object>) reviewData.get('ExpenseReimbursement');
        Assert.areEqual('bg80 bnbg 9661 1020 3456 78', reimbursement.get('iban'), 'old value as stored in the model');
        Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(reloaded.Context__c);
        Assert.areEqual('Hotel too expensive', context.get('reviewComment'));
        Assert.areEqual('Changes Requested', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    @IsTest
    static void requestChangesNeedsAtLeastOneChange() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        try {
            service.requestChanges(reportId, null, null, false, null);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('at least one change'), e.getMessage());
        }
    }

    @IsTest
    static void requestChangesUnknownLineFails() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        try {
            service.requestChanges(reportId, new List<String>{ 'nope' }, null, false, null);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('Expense not found'), e.getMessage());
        }
    }

    @IsTest
    static void resubmitWithPendingChangesFails() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        service.requestChanges(reportId, new List<String>{ 'e1' }, new List<String>{ 'e2' }, true, null);
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('expenses[id=e1].amount'), e.getMessage());
            Assert.isTrue(e.getMessage().contains('expenses[id=e2]'), e.getMessage());
            Assert.isTrue(e.getMessage().contains('ExpenseReimbursement.iban'), e.getMessage());
        }
    }

    @IsTest
    static void resubmitAfterChangesUpdatesSameReport() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        service.requestChanges(reportId, new List<String>{ 'e1' }, new List<String>{ 'e2' }, true, 'Fix it');

        // The employee changes the hotel amount, removes the taxi and enters another IBAN
        Map<String, Object> model = ExpenseReportTestData.validModel();
        ((Map<String, Object>) model.get('ExpenseItems')).put('expenses', new List<Object>{
                ExpenseReportTestData.expense('e1', 'hotel', '2026-10-05', '400')
        });
        ((Map<String, Object>) model.get('ExpenseReimbursement')).put('iban', 'DE89370400440532013000');
        ExpenseReportTestData.updateModel(wizard.Id, model);

        Id secondId = service.submitReport(wizard.Id, true);

        Assert.areEqual(reportId, secondId, 'the same report must be updated');
        Expense_Report__c report = [
                SELECT Total_Amount__c, IBAN__c, Status__c, (SELECT Id FROM Expense_Lines__r)
                FROM Expense_Report__c WHERE Id = :reportId
        ];
        Assert.areEqual(400, report.Total_Amount__c.intValue());
        Assert.areEqual('DE89370400440532013000', report.IBAN__c);
        Assert.areEqual('Submitted', report.Status__c);
        Assert.areEqual(1, report.Expense_Lines__r.size());
        Wizard__c reloaded = ExpenseReportTestData.reload(wizard.Id);
        Assert.areEqual('SIGNED', reloaded.State__c);
        Assert.isNull(reloaded.Review_Data__c);
    }

    @IsTest
    static void approveReport() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);

        service.approveReport(reportId);

        Assert.areEqual('APPROVED', ExpenseReportTestData.reload(wizard.Id).State__c);
        Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
        try {
            service.approveReport(reportId);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('Only a submitted report'), e.getMessage());
        }
    }

    @IsTest
    static void getReviewReturnsLines() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);

        ExpenseReviewData data = service.getReview(reportId);

        Assert.areEqual('SIGNED', data.wizardState);
        Assert.areEqual('Submitted', data.status);
        Assert.areEqual(2, data.lines.size());
        Assert.areEqual(585, data.totalAmount.intValue());
    }

    @IsTest
    static void getReviewUnknownReportFails() {
        Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        try {
            // a valid Id of another object type → no report found
            service.getReview(wizard.Id);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('Expense report not found'), e.getMessage());
        }
    }
}
