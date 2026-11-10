@IsTest
private class ExpenseReportServiceTest {

    private static final ExpenseReportService service = new ExpenseReportService();

    @IsTest
    static void submitCreatesReportAndLinesAndLocksWizard() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');

        Test.startTest();
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
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

        prolet__Wizard__c reloaded = ExpenseReportTestData.reload(wizard.Id);
        Assert.areEqual(prolet.WizardStates.LOCKED, reloaded.prolet__State__c);
        // the declaration is in the answers: the submitted summary shows it ticked
        Map<String, Object> model = (Map<String, Object>) JSON.deserializeUntyped(reloaded.prolet__Model__c);
        Assert.areEqual(true, ((Map<String, Object>) model.get(ExpenseReportService.PAGE_SUMMARY)).get('agreeDeclaration'));
        Assert.areEqual('Submitted', context(wizard.Id).get(ExpenseReportService.CTX_STATUS));
    }

    @IsTest
    static void submitRequiresDeclaration() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
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
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(model, 'ACTIVE');
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('At least one expense'), e.getMessage());
        }
    }

    @IsTest
    static void submitTwiceFails() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        service.submitReport(wizard.Id, true);
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('submitted already'), e.getMessage());
            Assert.areEqual(1, [SELECT COUNT() FROM Expense_Report__c]);
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
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');

        Map<String, Object> context = service.calculatePerDiem(wizard.Id);

        Assert.areEqual(3, context.get('perDiemDays'), '5th to 7th October = 3 days');
        Decimal rate = (Decimal) context.get('perDiemRate');
        Assert.isTrue(rate > 0);
        Assert.areEqual(rate * 3, (Decimal) context.get('perDiemTotal'));
        Map<String, Object> stored = (Map<String, Object>) JSON.deserializeUntyped(
                ExpenseReportTestData.reload(wizard.Id).prolet__Context__c);
        Assert.areEqual(3, stored.get('perDiemDays'));
    }

    @IsTest
    static void calculatePerDiemDoesNothingWhenLocked() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), prolet.WizardStates.LOCKED);
        Map<String, Object> context = service.calculatePerDiem(wizard.Id);
        Assert.isFalse(context.containsKey('perDiemTotal'));
    }

    @IsTest
    static void requestChangesMakesTheWizardActiveWithTheRequestInItsContext() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);

        service.requestChanges(reportId, new List<String>{ 'e1' }, new List<String>{ 'e2' }, true, 'Hotel too expensive');

        Assert.areEqual(prolet.WizardStates.ACTIVE, ExpenseReportTestData.reload(wizard.Id).prolet__State__c);
        Map<String, Object> context = context(wizard.Id);
        Map<String, Object> requested = (Map<String, Object>) context.get(ExpenseReportService.CTX_REQUESTED);
        Map<String, Object> items = (Map<String, Object>) requested.get('ExpenseItems');
        Assert.areEqual('540', items.get('expenses[id=e1].amount'));
        Assert.areEqual('', items.get('expenses[id=e2]'));
        Map<String, Object> reimbursement = (Map<String, Object>) requested.get('ExpenseReimbursement');
        Assert.areEqual('bg80 bnbg 9661 1020 3456 78', reimbursement.get('iban'), 'old value as stored in the model');
        Assert.areEqual('Hotel too expensive', context.get(ExpenseReportService.CTX_COMMENT));
        Assert.areEqual('Changes Requested', context.get(ExpenseReportService.CTX_STATUS));
        Assert.areEqual('Changes Requested', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    @IsTest
    static void requestChangesNeedsAtLeastOneChange() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
        try {
            service.requestChanges(reportId, null, null, false, null);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('at least one change'), e.getMessage());
        }
    }

    @IsTest
    static void requestChangesUnknownLineFails() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
        try {
            service.requestChanges(reportId, new List<String>{ 'nope' }, null, false, null);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('Expense not found'), e.getMessage());
        }
    }

    @IsTest
    static void resubmitWithPendingChangesFails() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
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
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
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
        Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizard.Id).prolet__State__c);
        Map<String, Object> context = context(wizard.Id);
        Assert.isFalse(context.containsKey(ExpenseReportService.CTX_REQUESTED), 'the request is done');
        Assert.isFalse(context.containsKey(ExpenseReportService.CTX_COMMENT));
        Assert.areEqual('Submitted', context.get(ExpenseReportService.CTX_STATUS));
    }

    @IsTest
    static void onlyTheRequestedChangesCanBeMade() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
        service.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'Hotel too expensive');

        // the requested amount, and also the type and receipt of the same row, and a new row
        Map<String, Object> model = ExpenseReportTestData.validModel();
        Map<String, Object> changed = ExpenseReportTestData.expense('e1', 'meals', '2026-10-05', '400');
        changed.put('receiptNumber', 'R-other');
        ((Map<String, Object>) model.get('ExpenseItems')).put('expenses', new List<Object>{
                changed,
                ExpenseReportTestData.expense('e9', 'taxi', '2026-10-06', '10')
        });
        ExpenseReportTestData.updateModel(wizard.Id, model);
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().startsWith('Only the requested changes can be made: '), e.getMessage());
            for (String path : new List<String>{ 'expenses[id=e1].type', 'expenses[id=e1].receiptNumber',
                    'expenses[id=e9] (new)', 'expenses[id=e2] (removed)' }) {
                Assert.isTrue(e.getMessage().contains(path), path + ': ' + e.getMessage());
            }
            Assert.isFalse(e.getMessage().contains('expenses[id=e1].amount'), 'the amount was asked for: ' + e.getMessage());
        }
    }

    @IsTest
    static void anItemThatIsInTheListTwiceIsRefused() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
        service.requestChanges(reportId, new List<String>{ 'e1' }, new List<String>{ 'e2' }, false, null);

        // a request made by hand: e1 with the requested amount, twice; e2 taken out as asked
        Map<String, Object> model = ExpenseReportTestData.validModel();
        ((Map<String, Object>) model.get('ExpenseItems')).put('expenses', new List<Object>{
                ExpenseReportTestData.expense('e1', 'hotel', '2026-10-05', '400'),
                ExpenseReportTestData.expense('e1', 'hotel', '2026-10-05', '400')
        });
        ExpenseReportTestData.updateModel(wizard.Id, model);
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.areEqual('An expense is in the list more than once: e1', e.getMessage());
        }
        Expense_Report__c report = [SELECT Total_Amount__c, (SELECT Id FROM Expense_Lines__r) FROM Expense_Report__c WHERE Id = :reportId];
        Assert.areEqual(585, report.Total_Amount__c.intValue(), 'the submitted report stays as it was');
        Assert.areEqual(2, report.Expense_Lines__r.size());
    }

    @IsTest
    static void aFirstSubmitWithAnItemTwiceIsRefusedToo() {
        Map<String, Object> model = ExpenseReportTestData.validModel();
        ((Map<String, Object>) model.get('ExpenseItems')).put('expenses', new List<Object>{
                ExpenseReportTestData.expense('e1', 'hotel', '2026-10-05', '540'),
                ExpenseReportTestData.expense('e1', 'taxi', '2026-10-06', '45')
        });
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(model, 'ACTIVE');
        try {
            service.submitReport(wizard.Id, true);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.areEqual('An expense is in the list more than once: e1', e.getMessage());
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Expense_Report__c]);
        Assert.areEqual(prolet.WizardStates.ACTIVE, ExpenseReportTestData.reload(wizard.Id).prolet__State__c);
    }

    @IsTest
    static void theRulesMakeWhatWasNotRequestedReadOnly() {
        // a query: getInstance() cuts long text at 255 characters
        prolet__Wizard_Setup__mdt setup = [SELECT prolet__Rules__c FROM prolet__Wizard_Setup__mdt WHERE DeveloperName = 'ExpenseReport'];
        Map<String, Object> rules = (Map<String, Object>) JSON.deserializeUntyped(setup.prolet__Rules__c);
        Map<String, Object> requested = new Map<String, Object>{
                'reportStatus' => 'Changes Requested',
                'requestedChanges' => new Map<String, Object>{
                        'ExpenseItems' => new Map<String, Object>{ 'expenses[id=e1].amount' => '540' }
                }
        };
        Map<String, Object> model = new Map<String, Object>{ '$ctx' => requested };

        for (String page : new List<String>{ 'ExpenseTripInfo', 'ExpenseTravelDocuments', 'ExpenseEuHealthCard',
                'ExpenseReimbursement' }) {
            prolet.WizardPageRules pageRules = prolet.WizardApi.parsePageRules(new prolet.WizardPageData(page, page), rules, model);
            Assert.areEqual(new List<String>{ '*' }, pageRules.readOnly, page);
        }
        // the items page: its form is a draft, read-only on the page itself; the list is checked on submit
        // (findUnrequestedLineChanges), so a stored draft is never kept over the row being edited
        prolet.WizardPageRules items = prolet.WizardApi.parsePageRules(new prolet.WizardPageData('ExpenseItems', 'ExpenseItems'), rules, model);
        Assert.isTrue(items.readOnly.isEmpty(), String.valueOf(items.readOnly));

        // the IBAN was asked for: the reimbursement page can be changed
        ((Map<String, Object>) requested.get('requestedChanges')).put('ExpenseReimbursement',
                new Map<String, Object>{ 'iban' => 'BG80' });
        prolet.WizardPageRules reimbursement = prolet.WizardApi.parsePageRules(
                new prolet.WizardPageData('ExpenseReimbursement', 'ExpenseReimbursement'), rules, model);
        Assert.isTrue(reimbursement.readOnly.isEmpty(), String.valueOf(reimbursement.readOnly));

        // submitted or ACTIVE without a request: nothing read-only by these rules
        requested.put('reportStatus', 'Submitted');
        Assert.isTrue(prolet.WizardApi.parsePageRules(new prolet.WizardPageData('ExpenseTripInfo', 'ExpenseTripInfo'), rules, model)
                .readOnly.isEmpty());
    }

    @IsTest
    static void approveReport() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);

        service.approveReport(reportId);

        Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizard.Id).prolet__State__c, 'it stays locked');
        Assert.areEqual('Approved', context(wizard.Id).get(ExpenseReportService.CTX_STATUS), 'the employee sees it');
        Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
        Integer refused = 0;
        try {
            service.approveReport(reportId);
        } catch (ExpenseReportException e) {
            refused += e.getMessage().contains('Only a submitted report') ? 1 : 0;
        }
        try {
            service.requestChanges(reportId, new List<String>{ 'e1' }, null, false, null);
        } catch (ExpenseReportException e) {
            refused += e.getMessage().contains('only for a submitted report') ? 1 : 0;
        }
        Assert.areEqual(2, refused, 'an approved report is decided');
    }

    @IsTest
    static void aReportWithChangesRequestedIsNotApproved() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);
        service.requestChanges(reportId, new List<String>{ 'e1' }, null, false, null);
        try {
            service.approveReport(reportId);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('Only a submitted report'), e.getMessage());
        }
    }

    @IsTest
    static void getReviewReturnsLines() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Id reportId = service.submitReport(wizard.Id, true);
        ExpenseReportTestData.giveToEmployee(wizard.Id);

        ExpenseReviewData data = service.getReview(reportId);

        Assert.areEqual(prolet.WizardStates.LOCKED, data.wizardState);
        Assert.areEqual('Submitted', data.status);
        Assert.areEqual(2, data.lines.size());
        Assert.areEqual(585, data.totalAmount.intValue());
    }

    private static Map<String, Object> context(Id wizardId) {
        return (Map<String, Object>) JSON.deserializeUntyped(ExpenseReportTestData.reload(wizardId).prolet__Context__c);
    }

    @IsTest
    static void getReviewUnknownReportFails() {
        prolet__Wizard__c wizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        try {
            // a valid Id of another object type → no report found
            service.getReview(wizard.Id);
            Assert.fail('Expected ExpenseReportException');
        } catch (ExpenseReportException e) {
            Assert.isTrue(e.getMessage().contains('Expense report not found'), e.getMessage());
        }
    }
}
