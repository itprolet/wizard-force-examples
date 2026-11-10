import ExpensePageBase from "c/expensePageBase";
import submitReport from "@salesforce/apex/ExpenseReportController.submitReport";
import calculatePerDiem from "@salesforce/apex/ExpenseReportController.calculatePerDiem";
import { clearStoredWizardId, errorMessage } from "prolet/wizardUtils";

/**
 * Page 5 - Summary.
 *
 * - Rules: navigationByChild = true, so the wizard hides its Back / Next buttons and this page
 *   renders its own Back / Submit.
 * - On open, Apex calculates the per-diem allowance into Wizard__c.prolet__Context__c, then the page sends
 *   `pagechange` with direction `refresh` - the wizard reloads the context and the page reads it as `$ctx`.
 * - Submit: Apex creates the Expense_Report__c, saves the ticked declaration in the answers of this
 *   page and locks the wizard (WizardApi.lock); another `refresh` makes the wizard pick up the new
 *   state, so every page becomes read-only (the declaration stays ticked: the form and the answers
 *   agree).
 * - Both Apex calls return what they did to the version of the wizard; the page sends it with its
 *   `refresh`, so the wizard knows the change was its own and its next move is not refused.
 * - The manager's decision is in $ctx (see ExpenseReportService): changes requested shows the
 *   comment ($ctx.reviewComment) and the button becomes "Submit corrections"; approved and submitted
 *   are shown on the locked wizard ($ctx.reportStatus).
 */
export default class ExpenseSummary extends ExpensePageBase {
  defaults() {
    return { agreeDeclaration: false };
  }

  isSubmitting = false;
  submitError;
  declarationError;

  connectedCallback() {
    if (this.wizardId && this.isEditable) {
      calculatePerDiem({ wizardId: this.wizardId })
        .then((change) => this.dispatchPageChange("refresh", change))
        .catch((error) => this.toast(messageOf(error), "error"));
    }
  }

  // ---- data from the other pages ----
  get trip() {
    return this._model?.ExpenseTripInfo || {};
  }
  get documents() {
    return this._model?.ExpenseTravelDocuments || {};
  }
  get health() {
    return this._model?.ExpenseEuHealthCard || {};
  }
  get reimbursement() {
    return this._model?.ExpenseReimbursement || {};
  }
  get expenses() {
    return this._model?.ExpenseItems?.expenses || [];
  }

  get isInternational() {
    return this.trip.destinationType === "international";
  }
  get isEu() {
    return this.trip.destinationType === "eu";
  }
  get destinationTypeLabel() {
    return (
      this._l[`Expense_opt_${this.trip.destinationType}`] ||
      this.trip.destinationType
    );
  }
  get tripDates() {
    return `${this.trip.dateFrom || ""} - ${this.trip.dateTo || ""}`;
  }

  get expenseColumns() {
    return [
      { label: this._l.Expense_lbl_type, fieldName: "typeLabel" },
      { label: this._l.Expense_lbl_date, fieldName: "date", type: "date" },
      {
        label: this._l.Expense_lbl_amount,
        fieldName: "amount",
        type: "number",
        align: "right"
      },
      { label: this._l.Expense_lbl_receiptNumber, fieldName: "receiptNumber" }
    ];
  }
  get expenseRows() {
    return this.expenses.map((item) => ({
      ...item,
      typeLabel: this._l[`Expense_opt_${item.type}`] || item.type
    }));
  }
  get totalLabel() {
    const total = this.expenses.reduce(
      (sum, item) => sum + (parseFloat(item.amount) || 0),
      0
    );
    return `${total.toFixed(2)} EUR`;
  }

  // ---- $ctx ----
  get hasPerDiem() {
    return (
      this.ctx.perDiemTotal !== undefined && this.ctx.perDiemTotal !== null
    );
  }
  get perDiemLabel() {
    const info = (this._l.Expense_msg_perDiemInfo || "{0} x {1}")
      .replace("{0}", this.ctx.perDiemDays)
      .replace("{1}", this.ctx.perDiemRate);
    return `${Number(this.ctx.perDiemTotal).toFixed(2)} EUR (${info})`;
  }
  get reviewComment() {
    return this.ctx.reviewComment;
  }

  // ---- state ----
  get isApproved() {
    return !this.isEditable && this.ctx.reportStatus === "Approved";
  }
  get isSubmitted() {
    return !this.isEditable && !this.isApproved;
  }
  get submitLabel() {
    return this.changesRequested
      ? this._l.Expense_act_resubmit
      : this._l.Expense_act_submit;
  }

  // ---- actions ----
  handleDeclaration(event) {
    this.declarationError = null;
    this.changeHandler(event);
  }

  handleBack() {
    this.dispatchPageChange("prev");
  }

  async handleSubmit() {
    if (!this.data.agreeDeclaration) {
      this.declarationError = this._l.Expense_err_declaration;
      return;
    }
    this.isSubmitting = true;
    this.submitError = null;
    this.lockUi(true);
    try {
      const change = await submitReport({
        wizardId: this.wizardId,
        agreedToDeclaration: true
      });
      // Reload state (LOCKED) and context from Wizard__c. No answers with it (pageModel null): the
      // tick is the submit's own, a locked wizard would warn that it was not saved
      this.dispatchPageChange("refresh", change, null);
    } catch (error) {
      this.submitError = messageOf(error);
      // refused: maybe submitted in another tab, so the wizard reads its state again
      this.dispatchPageChange("refresh", undefined, null);
    } finally {
      this.isSubmitting = false;
      this.lockUi(false);
    }
  }

  /**
   * c-wizard keeps the current Wizard__c id per wizard type in sessionStorage and reopens it.
   * To start a new report, forget that id and reload the page without URL parameters.
   */
  startNewReport() {
    clearStoredWizardId(this.wizardType);
    window.location.assign(window.location.pathname);
  }
}

/** The server's message (see errorMessage of c/wizardUtils), or a word when it says nothing */
function messageOf(error) {
  return errorMessage(error) || "Unexpected error";
}
