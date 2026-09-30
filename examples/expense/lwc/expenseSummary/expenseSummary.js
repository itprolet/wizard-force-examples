import ExpensePageBase from "c/expensePageBase";
import submitReport from "@salesforce/apex/ExpenseReportController.submitReport";
import calculatePerDiem from "@salesforce/apex/ExpenseReportController.calculatePerDiem";

/** sessionStorage key used by c-wizard to remember the current Wizard__c id per wizard type. */
const WIZARD_IDS_SESSION_KEY = "wizard_ids";

/**
 * Page 5 - Summary.
 *
 * - Rules: navigationByChild = true, so the wizard hides its Back / Next buttons and this page
 *   renders its own Back / Submit.
 * - On open, Apex calculates the per-diem allowance into Wizard__c.Context__c, then the page sends
 *   `pagechange` with direction `refresh` - the wizard reloads the context and the page reads it as `$ctx`.
 * - Submit: Apex creates the Expense_Report__c and sets State__c = SIGNED; another `refresh` makes the
 *   wizard pick up the new state, so every page becomes read-only.
 * - REVIEW: shows the manager comment ($ctx.reviewComment); the button becomes "Submit corrections".
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
        .then(() => this.dispatchPageChange("refresh"))
        .catch((error) => this.toast(errorMessage(error), "error"));
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
  get isSigned() {
    return this.state === "SIGNED";
  }
  get isApproved() {
    return this.state === "APPROVED";
  }
  get isFinished() {
    return this.isSigned || this.isApproved;
  }
  get submitLabel() {
    return this.isReview
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
      await submitReport({
        wizardId: this.wizardId,
        agreedToDeclaration: true
      });
      // Reload state (SIGNED) and context from Wizard__c
      this.dispatchPageChange("refresh");
    } catch (error) {
      this.submitError = errorMessage(error);
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
    try {
      const stored = JSON.parse(
        sessionStorage.getItem(WIZARD_IDS_SESSION_KEY) || "{}"
      );
      delete stored[this.wizardType];
      sessionStorage.setItem(WIZARD_IDS_SESSION_KEY, JSON.stringify(stored));
    } catch (error) {
      // sessionStorage not available - the page reload below still works for a new tab
    }
    window.location.assign(window.location.pathname);
  }
}

function errorMessage(error) {
  return error?.body?.message || error?.message || "Unexpected error";
}
