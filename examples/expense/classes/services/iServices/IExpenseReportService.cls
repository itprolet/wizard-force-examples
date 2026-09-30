public interface IExpenseReportService {
    /**
     * @description Creates (or, after a review, updates) Expense_Report__c with its Expense_Line__c records
     * from the wizard model and locks the wizard (State__c = SIGNED).
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
     * @return report, lines and wizard state
     */
    ExpenseReviewData getReview(Id reportId);

    /**
     * @description Sends a submitted report back to the employee (State__c = REVIEW) and fills
     * Wizard__c.Review_Data__c, so review mode unlocks only the requested fields.
     * @param reportId ID of the Expense_Report__c record
     * @param amountLineKeys model ids of the expenses whose amount must change
     * @param deleteLineKeys model ids of the expenses that must be removed
     * @param ibanChange true if the IBAN must change
     * @param comment comment for the employee (shown on the summary page via `$ctx.reviewComment`)
     */
    void requestChanges(Id reportId, List<String> amountLineKeys, List<String> deleteLineKeys, Boolean ibanChange,
            String comment);

    /**
     * @description Final approval (State__c = APPROVED).
     * @param reportId ID of the Expense_Report__c record
     */
    void approveReport(Id reportId);
}
