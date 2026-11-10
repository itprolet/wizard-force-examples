/**
 * @description Apex entry point for the Expense Report wizard pages (employee side).
 * A call that changes the wizard runs between WizardVersionChange.startChange (the wizard locked as
 * the framework locks it) and finish (the version the trigger gave it): the page sends the result
 * with its "refresh", so its tab is not out of date.
 */
public with sharing class ExpenseReportController {
    @TestVisible
    private static IExpenseReportService service = new ExpenseReportService();

    /** Called from the summary page (expenseSummary) when the user submits the report. */
    @AuraEnabled
    public static prolet.WizardVersionChange submitReport(Id wizardId, Boolean agreedToDeclaration) {
        prolet.WizardVersionChange change = null;
        try {
            change = prolet.WizardVersionChange.startChange(wizardId);
            service.submitReport(wizardId, agreedToDeclaration);
            return change.finish();
        } catch (Exception e) {
            throw auraError(e);
        } finally {
            // also when the service fails: the wizard is not noted for the rest of the transaction
            if (change != null) {
                change.finish();
            }
        }
    }

    /** Called from the summary page to (re)calculate the per-diem allowance stored in `$ctx`. */
    @AuraEnabled
    public static prolet.WizardVersionChange calculatePerDiem(Id wizardId) {
        prolet.WizardVersionChange change = null;
        try {
            change = prolet.WizardVersionChange.startChange(wizardId);
            service.calculatePerDiem(wizardId);
            return change.finish();
        } catch (Exception e) {
            throw auraError(e);
        } finally {
            // also when the service fails: the wizard is not noted for the rest of the transaction
            if (change != null) {
                change.finish();
            }
        }
    }

    private static AuraHandledException auraError(Exception e) {
        AuraHandledException ex = new AuraHandledException(e.getMessage());
        ex.setMessage(e.getMessage());
        return ex;
    }
}
