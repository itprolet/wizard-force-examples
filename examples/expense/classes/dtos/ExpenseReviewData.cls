/**
 * @description Data shown to the manager in the expenseReviewPanel LWC.
 */
public class ExpenseReviewData {
    @AuraEnabled public Id reportId;
    @AuraEnabled public Id wizardId;
    @AuraEnabled public String status;
    @AuraEnabled public String wizardState;
    @AuraEnabled public String iban;
    @AuraEnabled public String comment;
    @AuraEnabled public Decimal totalAmount;
    @AuraEnabled public List<Line> lines = new List<Line>();
    /** The user's own report: shown, but they cannot decide on it (ExpenseReportService) */
    @AuraEnabled public Boolean ownReport = false;

    public class Line {
        /** Id of the item in the wizard model (ExpenseItems.expenses[].id) */
        @AuraEnabled public String lineKey;
        @AuraEnabled public String type;
        @AuraEnabled public Date expenseDate;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String receiptNumber;
    }
}
