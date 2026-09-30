import { getLabelsMap } from "c/wizardUtils";

/**
 * Validators of the Expense Report wizard. They are registered in expenseReportRegistry under the names
 * used in Wizard_Setup.ExpenseReport Rules__c:
 *
 *   validator-registry       { ValidateIban }                     field validators:  (value, message) => error | undefined
 *   page-validator-registry  { ValidateTripDates,                  page validators:   (page, model, props, errors) => valid
 *                              ValidatePassportValidity,
 *                              ValidateExpenseLimit }
 *
 * ValidateIban and ValidateExpenseLimit also exist as Apex classes with the same names, so the framework runs
 * the same check on the server (Type.forName) when the user navigates. The other two are client-only:
 * a name without an Apex class is simply skipped on the server.
 *
 * Messages in Rules__c are label names; they are translated through the labels registered by the registry.
 */

function t(message, fallback) {
  if (!message) {
    return fallback;
  }
  return getLabelsMap()[message] || message;
}

function toNumber(value) {
  const number = parseFloat(String(value ?? "").replace(",", "."));
  return Number.isNaN(number) ? 0 : number;
}

/** IBAN check: format + mod-97 checksum (same algorithm as Apex ValidateIban). */
export function validateIban(value, message) {
  if (!value) {
    return undefined;
  }
  const iban = String(value).replace(/\s+/g, "").toUpperCase();
  if (!/^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$/.test(iban)) {
    return t(message, "Invalid IBAN");
  }
  const rearranged = iban.slice(4) + iban.slice(0, 4);
  let remainder = 0;
  for (const char of rearranged) {
    const digits = /[A-Z]/.test(char) ? String(char.charCodeAt(0) - 55) : char;
    for (const digit of digits) {
      remainder = (remainder * 10 + Number(digit)) % 97;
    }
  }
  return remainder === 1 ? undefined : t(message, "Invalid IBAN");
}

/** Trip page: return date must not be before the departure date. */
export function validateTripDates(page, model, props, errors) {
  const pageModel = model?.[page] || {};
  if (
    pageModel.dateFrom &&
    pageModel.dateTo &&
    pageModel.dateTo < pageModel.dateFrom
  ) {
    errors.dateTo = t(props?.message, "Invalid dates");
    return false;
  }
  return true;
}

/** Travel documents page: cross-page check against ExpenseTripInfo.dateTo. */
export function validatePassportValidity(page, model, props, errors) {
  const expiry = model?.[page]?.passportExpiry;
  const tripEnd = model?.ExpenseTripInfo?.dateTo;
  if (expiry && tripEnd && expiry < tripEnd) {
    errors.passportExpiry = t(
      props?.message,
      "Passport expires before the end of the trip"
    );
    return false;
  }
  return true;
}

/** Expenses page: total amount must not exceed props.limit (a $con constant in Rules__c). */
export function validateExpenseLimit(page, model, props, errors) {
  const limit = parseFloat(props?.limit);
  if (Number.isNaN(limit)) {
    return true;
  }
  const expenses = model?.[page]?.expenses || [];
  const total = expenses.reduce((sum, item) => sum + toNumber(item?.amount), 0);
  if (total > limit) {
    errors.$global = t(
      props?.message,
      "The total amount exceeds the allowed limit"
    );
    return false;
  }
  return true;
}
