import { getLabelsMap } from "prolet/wizardUtils";

/**
 * Validators of the carRental wizard.
 *
 * Field validator: (value, message) => the error text, or undefined when the value is valid.
 *   prolet__Rules__c: "validators": { "myField": ["ValidateMyField"] }
 * Page validator:  (page, model, props, errors) => true when the page is valid, false otherwise.
 *   prolet__Rules__c: "pageValidators": [{ "validator": "ValidateMyPage", "message": "…" }]
 *
 * WIZARD-MAKER: "npm run make validator" adds new validators at the end of this file
 * and registers them in the registry and the Rules.
 *
 * The messages in prolet__Rules__c are label names. t() gives the label's text in the user's language.
 */

/** The text of a message: the label with that name (registered by the registry), or the message itself. */
function t(message, fallback) {
  if (!message) {
    return fallback;
  }
  return getLabelsMap()[message] || message;
}

/**
 * ValidateLicenceFormat: checks the field "licenceNumber" on the "Driver" page.
 * prolet__Rules__c: "validators": { "licenceNumber": [{ "validator": "ValidateLicenceFormat", "message": "…" }] }
 * @returns the error text, or undefined when the value is valid
 */
export function validateLicenceFormat(value, message) {
  if (!value) {
    return undefined; // empty values are handled by "required"
  }
  // WIZARD-MAKER: TODO replace "true" with your check. Example, an e-mail address:
  //   const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  const ok = /^[A-Z]{2}\d{6}$/i.test(value);
  return ok ? undefined : t(message, "Two letters and six digits");
}

/**
 * ValidateLicenceAge: checks the whole "Driver" page (several fields, or answers of other pages).
 * prolet__Rules__c: "pageValidators": [{ "validator": "ValidateLicenceAge", "message": "…" }]
 * @returns true when the page is valid, false otherwise
 */
export function validateLicenceAge(page, model, props, errors) {
  // WIZARD-MAKER: TODO replace "true" with your check. Examples:
  // const answers = model[page] || {};
  //   const ok = !answers.endDate || answers.endDate >= answers.startDate;  end date not before start date
  //   const ok = model.OtherPageName?.someField === "yes";                  an answer of another page
  const ok = true;
  if (!ok) {
    // errors.<fieldName> shows the text under that field, errors.$global at the top of the page
    errors.$global = t(
      props?.message,
      "Your licence must be at least 2 years old"
    );
  }
  return ok;
}
