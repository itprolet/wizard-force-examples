import ExpensePageBase from "c/expensePageBase";

/**
 * Page 2a - Travel documents (only for destinationType = international).
 * - Rules: `if (visaRequired)` makes visaNumber required, `else` hides it.
 * - JS page validator ValidatePassportValidity compares passportExpiry with ExpenseTripInfo.dateTo
 *   (a value from ANOTHER page of the model).
 */
export default class ExpenseTravelDocuments extends ExpensePageBase {
  defaults() {
    return {
      passportNumber: null,
      passportExpiry: null,
      visaRequired: false,
      visaNumber: null
    };
  }

  /** The rules engine sets visible.visaNumber = false through the `hidden` rule. */
  get showVisaNumber() {
    return this._visible.visaNumber !== false;
  }

  changeHandler(event) {
    super.changeHandler(event);
    // Clear the hidden value, so the model does not keep an old visa number
    if (
      event.detail?.name === "visaRequired" &&
      !event.detail.checked &&
      this.data.visaNumber
    ) {
      this.setValue("visaNumber", null);
      this.dispatchPageChange("visaNumber");
    }
  }
}
