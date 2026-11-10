import { LightningElement } from "lwc";
// WIZARD-MAKER:imports (new pages and validators are added below this line)
import ServiceVisitCustomer from "c/serviceVisitCustomer";
import ServiceVisitVisit from "c/serviceVisitVisit";
import ServiceVisitRepairDetails from "c/serviceVisitRepairDetails";
import ServiceVisitSummary from "c/serviceVisitSummary";
// Example: import { validateMyField, validateMyPage } from "c/serviceVisitValidators";

/**
 * Registry of the "Service Visit" wizard (Wizard_Setup.ServiceVisit).
 * The only component placed on the page: it renders <c-wizard> and passes the registries to it.
 */
export default class ServiceVisitWizardRegistry extends LightningElement {
  // Pages. Keys = page names used in prolet__Plan__c, prolet__Rules__c and the saved answers (model.<PageName>)
  _pageRegistry = {
    // WIZARD-MAKER:pages
    ServiceVisitCustomer,
    ServiceVisitVisit,
    ServiceVisitRepairDetails,
    ServiceVisitSummary
  };

  // Field validators: (value, message) => error text, or undefined when valid.
  // Used in prolet__Rules__c as: "validators": { "myField": ["ValidateMyField"] }
  _validatorRegistry = {
    // WIZARD-MAKER:validators
    // ValidateMyField: validateMyField
  };

  // Page validators: (page, model, props, errors) => true when valid, false otherwise.
  // Used in prolet__Rules__c as: "pageValidators": [{ "validator": "ValidateMyPage", "message": "…" }]
  _pageValidatorRegistry = {
    // WIZARD-MAKER:pageValidators
    // ValidateMyPage: validateMyPage
  };
}
