import { LightningElement, api } from "lwc";
import ExpenseTripInfo from "c/expenseTripInfo";
import ExpenseTravelDocuments from "c/expenseTravelDocuments";
import ExpenseEuHealthCard from "c/expenseEuHealthCard";
import ExpenseItems from "c/expenseItems";
import ExpenseReimbursement from "c/expenseReimbursement";
import ExpenseSummary from "c/expenseSummary";
import {
  validateIban,
  validateTripDates,
  validatePassportValidity,
  validateExpenseLimit
} from "c/expenseValidators";
import { registerLabels } from "c/wizardUtils";
import { L } from "./labels";

// Page-validator messages in Rules__c are label names. The framework translates them through the
// global label map (not through label-registry), so register the labels globally as well.
registerLabels(L);

/**
 * Registry of the Expense Report wizard (Wizard_Setup.ExpenseReport).
 * This is the only component placed on the page (Lightning App Builder or Experience Builder).
 * It renders <c-wizard> and passes all registries to it.
 *
 * In Lightning App Builder set "Wizard Type" to ExpenseReport (the DeveloperName of the
 * Wizard_Setup__mdt record) - it is pre-filled with that value.
 *
 * Keys must match the names used in Wizard_Setup.ExpenseReport:
 *   Plan__c values            → _pageRegistry
 *   Rules__c validators       → _validatorRegistry
 *   Rules__c pageValidators   → _pageValidatorRegistry (ValidatePattern is pre-registered by the framework)
 */
export default class ExpenseReportRegistry extends LightningElement {
  /** Wizard type (Wizard_Setup__mdt DeveloperName) forwarded to <c-wizard>. Set in App Builder. */
  @api wizardTypeConfig = "ExpenseReport";

  _pageRegistry = {
    ExpenseTripInfo,
    ExpenseTravelDocuments,
    ExpenseEuHealthCard,
    ExpenseItems,
    ExpenseReimbursement,
    ExpenseSummary
  };

  _validatorRegistry = {
    ValidateIban: validateIban
  };

  _pageValidatorRegistry = {
    ValidateTripDates: validateTripDates,
    ValidatePassportValidity: validatePassportValidity,
    ValidateExpenseLimit: validateExpenseLimit
  };

  _labelRegistry = L;
}
