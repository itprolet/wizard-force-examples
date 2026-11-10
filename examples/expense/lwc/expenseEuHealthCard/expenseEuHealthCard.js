import ExpensePageBase from "c/expensePageBase";

/**
 * Page 2b - European Health Insurance Card (only for destinationType = eu).
 * This page appears through the `else if` branch of prolet__Plan__c.
 */
export default class ExpenseEuHealthCard extends ExpensePageBase {
  defaults() {
    return {
      ehicNumber: null,
      ehicExpiry: null
    };
  }
}
