/**
 * @description The upgrade of reports submitted before the review checked the link report <-> wizard
 * (ExpenseReportLinkBackfill): a real pair gets the link and can be reviewed again; a pair that the
 * stored data does not prove is left as it is, and its review stays refused.
 */
@IsTest
private class ExpenseReportLinkBackfillTest {

    private static final List<String> EXPENSE_SETS = new List<String>{ 'Wizard_Framework_User', 'Expense_Report_User' };
    private static final String NOT_LINKED = 'This expense report is not linked to its own expense wizard.';

    /** A report submitted by the employee before the link was written: its wizard does not name it */
    private static Id oldSubmittedWizard(User employee) {
        Id wizardId;
        System.runAs(employee) {
            wizardId = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE').Id;
            ExpenseReportController.submitReport(wizardId, true);
        }
        ExpenseReportTestData.removeReportLink(wizardId);
        return wizardId;
    }

    private static Id reportOf(Id wizardId) {
        return [SELECT Id FROM Expense_Report__c WHERE Wizard__c = :wizardId ORDER BY CreatedDate LIMIT 1].Id;
    }

    private static Object linkOf(Id wizardId) {
        String context = [SELECT prolet__Context__c FROM prolet__Wizard__c WHERE Id = :wizardId].prolet__Context__c;
        return context == null ? null : ((Map<String, Object>) JSON.deserializeUntyped(context)).get(ExpenseReportService.CTX_REPORT);
    }

    private static void assertReviewRefused(User manager, Id reportId) {
        System.runAs(manager) {
            try {
                ExpenseReviewController.getReview(reportId);
                System.Assert.fail('the review of a report whose wizard does not name it');
            } catch (AuraHandledException e) {
                System.Assert.areEqual(NOT_LINKED, e.getMessage());
            }
        }
    }

    @IsTest
    static void aReportSubmittedBeforeTheUpgradeIsReviewedAfterTheBackfill() {
        User employee = ExpenseReportTestData.userWith('emma', EXPENSE_SETS);
        User manager = ExpenseReportTestData.userWith('mark', EXPENSE_SETS);
        Id wizardId = oldSubmittedWizard(employee);
        Id reportId = reportOf(wizardId);

        // the ordinary review refuses a missing link: it does not fix it by itself
        assertReviewRefused(manager, reportId);
        System.Assert.isNull(linkOf(wizardId));

        // a dry run writes nothing
        ExpenseReportLinkBackfill dryRun = new ExpenseReportLinkBackfill(false);
        dryRun.run([SELECT Id, Wizard__c, Status__c FROM Expense_Report__c]);
        System.Assert.areEqual(1, dryRun.linked, dryRun.summary());
        System.Assert.isNull(linkOf(wizardId), 'a dry run wrote the link');

        // the batch, as an admin runs it
        Test.startTest();
        Database.executeBatch(new ExpenseReportLinkBackfill(true));
        Test.stopTest();
        System.Assert.areEqual(String.valueOf(reportId), String.valueOf(linkOf(wizardId)));
        System.Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizardId).prolet__State__c, 'still locked');

        // and the whole review works again
        System.runAs(manager) {
            System.Assert.areEqual(2, ExpenseReviewController.getReview(reportId).lines.size());
            ExpenseReviewController.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'Check hotel');
        }
        System.runAs(employee) {
            Map<String, Object> model = ExpenseReportTestData.validModel();
            for (Object item : (List<Object>) ((Map<String, Object>) model.get('ExpenseItems')).get('expenses')) {
                Map<String, Object> expense = (Map<String, Object>) item;
                if (expense.get('id') == 'e1') {
                    expense.put('amount', '123');
                }
            }
            ExpenseReportTestData.updateModel(wizardId, model);
            ExpenseReportController.submitReport(wizardId, true);
        }
        System.runAs(manager) {
            ExpenseReviewController.approveReport(reportId);
        }
        System.Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    @IsTest
    static void reportsInEveryStatusOfTheReviewAreLinked() {
        User employee = ExpenseReportTestData.userWith('emma', EXPENSE_SETS);
        // waiting for changes (the wizard is active again), and approved (locked)
        Id changesWizard;
        Id approvedWizard;
        System.runAs(employee) {
            changesWizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE').Id;
            ExpenseReportController.submitReport(changesWizard, true);
            approvedWizard = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE').Id;
            ExpenseReportController.submitReport(approvedWizard, true);
        }
        ExpenseReviewController.requestChanges(reportOf(changesWizard), new List<String>{ 'e1' }, null, false, 'x');
        ExpenseReviewController.approveReport(reportOf(approvedWizard));
        ExpenseReportTestData.removeReportLink(changesWizard);
        ExpenseReportTestData.removeReportLink(approvedWizard);

        ExpenseReportLinkBackfill backfill = new ExpenseReportLinkBackfill(true);
        backfill.run([SELECT Id, Wizard__c, Status__c FROM Expense_Report__c]);
        System.Assert.areEqual(2, backfill.linked, backfill.summary());
        System.Assert.areEqual(String.valueOf(reportOf(changesWizard)), String.valueOf(linkOf(changesWizard)));
        System.Assert.areEqual(String.valueOf(reportOf(approvedWizard)), String.valueOf(linkOf(approvedWizard)));

        // again: nothing more to do
        ExpenseReportLinkBackfill again = new ExpenseReportLinkBackfill(true);
        again.run([SELECT Id, Wizard__c, Status__c FROM Expense_Report__c]);
        System.Assert.areEqual(0, again.linked);
        System.Assert.areEqual(2, again.alreadyLinked);
    }

    @IsTest
    static void aPairTheDataDoesNotProveIsLeftAsItIs() {
        User employee = ExpenseReportTestData.userWith('emma', EXPENSE_SETS);
        User manager = ExpenseReportTestData.userWith('mark', EXPENSE_SETS);

        // 1. a second report that points to the employee's real wizard (a copy, or a forgery from
        //    before the field was read only): which one is real is not for the backfill to guess
        Id duplicated = oldSubmittedWizard(employee);
        Expense_Report__c copy = new Expense_Report__c(Wizard__c = duplicated, Status__c = 'Submitted');
        insert copy;
        // 2. a report on a wizard of another process
        prolet__Wizard__c carRental = new prolet__Wizard__c(prolet__Wizard_Type__c = 'CarRental', prolet__State__c = prolet.WizardStates.LOCKED,
                prolet__Context__c = JSON.serialize(new Map<String, Object>{ ExpenseReportService.CTX_STATUS => 'Submitted' }));
        insert carRental;
        Expense_Report__c onCarRental = new Expense_Report__c(Wizard__c = carRental.Id, Status__c = 'Submitted');
        insert onCarRental;
        // 3. a report on an expense wizard that was never submitted
        prolet__Wizard__c neverSubmitted = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE');
        Expense_Report__c onNeverSubmitted = new Expense_Report__c(Wizard__c = neverSubmitted.Id, Status__c = 'Submitted');
        insert onNeverSubmitted;
        // 4. the report says Approved, the wizard says Submitted
        Id otherStatus = oldSubmittedWizard(employee);
        Id otherStatusReport = reportOf(otherStatus);
        update new Expense_Report__c(Id = otherStatusReport, Status__c = 'Approved');
        // 5. the wizard names another report already
        Id namesAnother = oldSubmittedWizard(employee);
        Id namesAnotherReport = reportOf(namesAnother);
        Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(
                [SELECT prolet__Context__c FROM prolet__Wizard__c WHERE Id = :namesAnother].prolet__Context__c);
        context.put(ExpenseReportService.CTX_REPORT, copy.Id);
        update new prolet__Wizard__c(Id = namesAnother, prolet__Context__c = JSON.serialize(context));

        ExpenseReportLinkBackfill backfill = new ExpenseReportLinkBackfill(true);
        backfill.run([SELECT Id, Wizard__c, Status__c FROM Expense_Report__c]);

        System.Assert.areEqual(0, backfill.linked, backfill.summary());
        Map<Id, String> why = backfill.skipped;
        System.Assert.isTrue(why.get(reportOf(duplicated)).contains('2 reports'), backfill.summary());
        System.Assert.isTrue(why.get(copy.Id).contains('2 reports'), backfill.summary());
        System.Assert.isTrue(why.get(onCarRental.Id).contains('not an expense report'), backfill.summary());
        System.Assert.isTrue(why.get(onNeverSubmitted.Id).contains('never submitted'), backfill.summary());
        System.Assert.isTrue(why.get(otherStatusReport).contains('status differs'), backfill.summary());
        System.Assert.isTrue(why.get(namesAnotherReport).contains('names another report'), backfill.summary());

        // nothing was linked, and their review stays refused
        System.Assert.isNull(linkOf(duplicated));
        System.Assert.isNull(linkOf(carRental.Id));
        System.Assert.isNull(linkOf(neverSubmitted.Id));
        System.Assert.isNull(linkOf(otherStatus));
        System.Assert.areEqual(String.valueOf(copy.Id), String.valueOf(linkOf(namesAnother)), 'left as it was');
        assertReviewRefused(manager, reportOf(duplicated));
        assertReviewRefused(manager, copy.Id);
        assertReviewRefused(manager, otherStatusReport);
    }

    @IsTest
    static void aWizardInTheWrongStateIsLeftAsItIs() {
        User employee = ExpenseReportTestData.userWith('emma', EXPENSE_SETS);
        // submitted (the report and the context say so), but the wizard is active again
        Id wizardId = oldSubmittedWizard(employee);
        update new prolet__Wizard__c(Id = wizardId, prolet__State__c = prolet.WizardStates.ACTIVE);

        ExpenseReportLinkBackfill backfill = new ExpenseReportLinkBackfill(true);
        backfill.run([SELECT Id, Wizard__c, Status__c FROM Expense_Report__c]);
        System.Assert.areEqual(0, backfill.linked, backfill.summary());
        System.Assert.isTrue(backfill.skipped.get(reportOf(wizardId)).contains('ACTIVE'), backfill.summary());
        System.Assert.isNull(linkOf(wizardId));
    }
}
