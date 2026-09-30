import ExpensePageBase from "c/expensePageBase";

/**
 * Page 4 - Reimbursement.
 * - iban: field validator ValidateIban - runs in JS (validator-registry) and in Apex (class ValidateIban).
 * - accountHolder: framework page validator ValidatePattern with the regex from the constant
 *   `$con.Expense_Regex_Name` (Wizard_Contstant__mdt).
 * - Review mode: reviewFieldRelationship [["iban", "bankName", "accountHolder"]] - when the manager asks
 *   to change the IBAN, the bank name and the account holder are unlocked as well (optional change).
 *   The framework puts "Change required" / "Change made" into errors / messages.
 */
export default class ExpenseReimbursement extends ExpensePageBase {
  defaults() {
    return {
      iban: null,
      bankName: null,
      accountHolder: null
    };
  }

  /** "Change made" message in review mode, otherwise the hint from the rules. */
  get ibanMessage() {
    return this._messages.iban || this._hints.iban;
  }
}
