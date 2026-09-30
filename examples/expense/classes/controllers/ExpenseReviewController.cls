/**
 * @description Apex entry point for the manager review panel (expenseReviewPanel on the Expense_Report__c page).
 */
public with sharing class ExpenseReviewController {
    @TestVisible
    private static IExpenseReportService service = new ExpenseReportService();

    @AuraEnabled
    public static ExpenseReviewData getReview(Id reportId) {
        try {
            return service.getReview(reportId);
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    @AuraEnabled
    public static void requestChanges(Id reportId, List<String> amountLineKeys, List<String> deleteLineKeys,
            Boolean ibanChange, String comment) {
        try {
            service.requestChanges(reportId, amountLineKeys, deleteLineKeys, ibanChange, comment);
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    @AuraEnabled
    public static void approveReport(Id reportId) {
        try {
            service.approveReport(reportId);
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
