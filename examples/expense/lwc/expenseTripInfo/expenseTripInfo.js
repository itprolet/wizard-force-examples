import ExpensePageBase from "c/expensePageBase";

const DESTINATION_TYPES = ["domestic", "eu", "international"];

/**
 * Page 1 - Trip.
 * - destinationType drives the plan: "international" shows ExpenseTravelDocuments,
 *   "eu" shows ExpenseEuHealthCard (if / else if in Plan__c).
 * - The customer account is chosen with c-input-suggester in mode 1 (dynamic SOQL, no metadata).
 * - Rules: required fields, a hint for `purpose`, JS page validator ValidateTripDates.
 */
export default class ExpenseTripInfo extends ExpensePageBase {
  defaults() {
    return {
      destinationType: null,
      destination: null,
      dateFrom: null,
      dateTo: null,
      purpose: null,
      accountId: null,
      accountName: null
    };
  }

  get destinationTypeOptions() {
    return DESTINATION_TYPES.map((value) => ({
      label: this._l[`Expense_opt_${value}`] || value,
      value
    }));
  }

  accountSelected(event) {
    const { selectedId, selectedName } = event.detail;
    this.data = {
      ...this.data,
      accountId: selectedId || null,
      accountName: selectedName || null
    };
    this.dispatchPageChange("accountId");
  }
}
