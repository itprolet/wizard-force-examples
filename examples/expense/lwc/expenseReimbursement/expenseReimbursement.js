import ExpensePageBase from "c/expensePageBase";

/**
 * Page 4 - Reimbursement.
 * - iban: field validator ValidateIban - runs in JS (validator-registry) and in Apex (class ValidateIban).
 * - accountHolder: framework page validator ValidatePattern with the regex from the constant
 *   `$con.Expense_Regex_Name` (Wizard_Contstant__mdt).
 * - When the manager asks to change the IBAN ($ctx.requestedChanges), the resubmit is refused on the
 *   server until it is another one; the bank name and the account holder can be changed with it.
 */
export default class ExpenseReimbursement extends ExpensePageBase {
  defaults() {
    return {
      iban: null,
      bankName: null,
      accountHolder: null
    };
  }

  /** The message of the rules for the IBAN, otherwise its hint. */
  get ibanMessage() {
    return this._messages.iban || this._hints.iban;
  }
}
