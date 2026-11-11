import { getLabelsMap } from "prolet/wizardUtils";

/**
 * Validators of the clubMembership wizard.
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
 * ValidateClubEmail: checks the field "email" on the "Applicant" page.
 * prolet__Rules__c: "validators": { "email": [{ "validator": "ValidateClubEmail", "message": "…" }] }
 * @returns the error text, or undefined when the value is valid
 */
export function validateClubEmail(value, message) {
  if (!value) {
    return undefined; // empty values are handled by "required"
  }
  // WIZARD-MAKER: TODO replace "true" with your check. Example, an e-mail address:
  const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  return ok ? undefined : t(message, "Please use your own email");
}

/**
 * ValidateCompanyPage: checks the whole "Company" page (several fields, or answers of other pages).
 * prolet__Rules__c: "pageValidators": [{ "validator": "ValidateCompanyPage", "message": "…" }]
 * @returns true when the page is valid, false otherwise
 */
export function validateCompanyPage(page, model, props, errors) {
  // WIZARD-MAKER: TODO replace "true" with your check. Examples:
  //   const answers = model[page] || {};                                    the answers of this page
  //   const ok = !answers.endDate || answers.endDate >= answers.startDate;  end date not before start date
  //   const ok = model.OtherPageName?.someField === "yes";                  an answer of another page
  const ok = true;
  if (!ok) {
    // errors.<fieldName> shows the text under that field, errors.$global at the top of the page
    errors.$global = t(props?.message, "Please check the company");
  }
  return ok;
}
