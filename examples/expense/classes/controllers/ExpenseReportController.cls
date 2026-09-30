/**
 * @description Apex entry point for the Expense Report wizard pages (employee side).
 */
public with sharing class ExpenseReportController {
    @TestVisible
    private static IExpenseReportService service = new ExpenseReportService();

    /** Called from the summary page (expenseSummary) when the user submits the report. */
    @AuraEnabled
    public static Id submitReport(Id wizardId, Boolean agreedToDeclaration) {
        try {
            return service.submitReport(wizardId, agreedToDeclaration);
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    /** Called from the summary page to (re)calculate the per-diem allowance stored in `$ctx`. */
    @AuraEnabled
    public static Map<String, Object> calculatePerDiem(Id wizardId) {
        try {
            return service.calculatePerDiem(wizardId);
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    private static AuraHandledException auraError(Exception e) {
        AuraHandledException ex = new AuraHandledException(e.getMessage());
        ex.setMessage(e.getMessage());
        return ex;
    }
}
