public interface IExpenseReportService {
    /**
     * @description Creates (or, after a review, updates) Expense_Report__c with its Expense_Line__c records
     * from the wizard model and locks the wizard (WizardApi.lock): a second submit is refused.
     * @param wizardId ID of the Wizard__c record
     * @param agreedToDeclaration User confirmed the declaration on the summary page
     * @return ID of the Expense_Report__c record
     */
    Id submitReport(Id wizardId, Boolean agreedToDeclaration);

    /**
     * @description Calculates the per-diem allowance from the trip page (destination type x days) and stores it
     * in Wizard__c.Context__c, so the pages can read it as `$ctx`.
     * @param wizardId ID of the Wizard__c record
     * @return the updated context
     */
    Map<String, Object> calculatePerDiem(Id wizardId);

    /**
     * @description Data for the manager review panel.
     * @param reportId ID of the Expense_Report__c record
     * @return report, lines and wizard state (ACTIVE or LOCKED)
     */
    ExpenseReviewData getReview(Id reportId);

    /**
     * @description Sends a submitted report back to the employee: the wizard is ACTIVE again
     * (WizardApi.unlock), and what must change is put in its context ($ctx.requestedChanges), so the
     * pages let the employee change only that, and a resubmit is refused until it was changed.
     * @param reportId ID of the Expense_Report__c record
     * @param amountLineKeys model ids of the expenses whose amount must change
     * @param deleteLineKeys model ids of the expenses that must be removed
     * @param ibanChange true if the IBAN must change
     * @param comment comment for the employee (shown on the summary page via `$ctx.reviewComment`)
     */
    void requestChanges(Id reportId, List<String> amountLineKeys, List<String> deleteLineKeys, Boolean ibanChange,
            String comment);

    /**
     * @description Final approval: the report is Approved, the wizard stays locked ($ctx.reportStatus
     * tells the employee).
     * @param reportId ID of the Expense_Report__c record
     */
    void approveReport(Id reportId);
}
