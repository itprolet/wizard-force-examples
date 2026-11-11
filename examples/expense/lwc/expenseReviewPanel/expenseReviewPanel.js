import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import getReview from "@salesforce/apex/ExpenseReviewController.getReview";
import requestChanges from "@salesforce/apex/ExpenseReviewController.requestChanges";
import approveReport from "@salesforce/apex/ExpenseReviewController.approveReport";
import { errorMessage } from "prolet/wizardUtils";

/**
 * Manager side of the Expense Report example (record page of Expense_Report__c).
 *
 * "Request changes" makes the wizard ACTIVE again and puts what must change into its context
 * ($ctx.requestedChanges), e.g.
 *   { "ExpenseItems": { "expenses[id=e1].amount": "540", "expenses[id=e2]": "" },
 *     "ExpenseReimbursement": { "iban": "BG80..." } }
 * When the employee opens the wizard again, only these can be changed, and must be changed before
 * the report is submitted again. Decisions are made on a submitted report only (its status).
 */
export default class ExpenseReviewPanel extends LightningElement {
  @api recordId;

  review;
  error;
  busy = false;
  comment = "";
  ibanChange = false;
  amountKeys = new Set();
  deleteKeys = new Set();

  connectedCallback() {
    this.load();
  }

  async load() {
    try {
      this.review = await getReview({ reportId: this.recordId });
      this.error = undefined;
    } catch (error) {
      this.error = messageOf(error);
    }
    this.amountKeys = new Set();
    this.deleteKeys = new Set();
    this.ibanChange = false;
    this.comment = "";
  }

  get canReview() {
    return (
      this.review?.status === "Submitted" &&
      this.review?.wizardState !== "ACTIVE" &&
      !this.review?.ownReport
    );
  }

  get stateMessage() {
    if (this.review?.ownReport && this.review?.status === "Submitted") {
      // the server refuses it too: someone else reviews it
      return "This is your own report: someone else reviews it.";
    }
    switch (this.review?.status) {
      case "Changes Requested":
        return "Changes were requested. Waiting for the employee to submit corrections.";
      case "Approved":
        return "The report is approved.";
      default:
        return "The report is not submitted yet.";
    }
  }

  get ibanLabel() {
    return `IBAN must change (${this.review?.iban || "-"})`;
  }

  toggleLine(event) {
    const { key, kind } = event.target.dataset;
    const target = kind === "amount" ? this.amountKeys : this.deleteKeys;
    if (event.target.checked) {
      target.add(key);
    } else {
      target.delete(key);
    }
  }

  toggleIban(event) {
    this.ibanChange = event.target.checked;
  }

  commentChanged(event) {
    this.comment = event.target.value;
  }

  async handleRequestChanges() {
    await this.run(
      () =>
        requestChanges({
          reportId: this.recordId,
          amountLineKeys: [...this.amountKeys],
          deleteLineKeys: [...this.deleteKeys],
          ibanChange: this.ibanChange,
          comment: this.comment
        }),
      "Changes requested. The employee can now correct the report in the wizard."
    );
  }

  async handleApprove() {
    await this.run(
      () => approveReport({ reportId: this.recordId }),
      "Report approved."
    );
  }

  async run(action, successMessage) {
    this.busy = true;
    try {
      await action();
      this.dispatchEvent(
        new ShowToastEvent({ title: successMessage, variant: "success" })
      );
      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      await this.load();
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: messageOf(error),
          variant: "error"
        })
      );
    } finally {
      this.busy = false;
    }
  }
}

/** The server's message (see errorMessage of c/wizardUtils), or a word when it says nothing */
function messageOf(error) {
  return errorMessage(error) || "Unexpected error";
}
