import { LightningElement } from "lwc";
import { registerLabels } from "prolet/wizardUtils";
import { L } from "./labels";
// WIZARD-MAKER:imports (new pages and validators are added below this line)
import CarRentalDriver from "c/carRentalDriver";
import CarRentalCar from "c/carRentalCar";
import CarRentalExtras from "c/carRentalExtras";
import CarRentalInvoice from "c/carRentalInvoice";
import CarRentalSummary from "c/carRentalSummary";
import {
  validateLicenceFormat,
  validateLicenceAge
} from "c/carRentalValidators";
// Example: import { validateMyField, validateMyPage } from "c/carRentalValidators";

// The wizard's texts are Custom Labels (labels.js), so they can be translated. Validator messages in
// prolet__Rules__c are label names; the framework translates them through the global label map (not through
// label-registry), so the labels are registered globally as well.
registerLabels(L);

/**
 * Registry of the "Car Rental" wizard (Wizard_Setup.CarRental).
 * The only component placed on the page: it renders <c-wizard> and passes the registries to it.
 */
export default class CarRentalWizardRegistry extends LightningElement {
  // Pages. Keys = page names used in prolet__Plan__c, prolet__Rules__c and the saved answers (model.<PageName>)
  _pageRegistry = {
    // WIZARD-MAKER:pages
    CarRentalDriver,
    CarRentalCar,
    CarRentalExtras,
    CarRentalInvoice,
    CarRentalSummary
  };

  // Field validators: (value, message) => error text, or undefined when valid.
  // Used in prolet__Rules__c as: "validators": { "myField": ["ValidateMyField"] }
  _validatorRegistry = {
    // WIZARD-MAKER:validators
    ValidateLicenceFormat: validateLicenceFormat
    // ValidateMyField: validateMyField
  };

  // Page validators: (page, model, props, errors) => true when valid, false otherwise.
  // Used in prolet__Rules__c as: "pageValidators": [{ "validator": "ValidateMyPage", "message": "…" }]
  _pageValidatorRegistry = {
    // WIZARD-MAKER:pageValidators
    ValidateLicenceAge: validateLicenceAge
    // ValidateMyPage: validateMyPage
  };

  // Labels: every page gets them as "l" (in the pages: this._l.CarRental_lbl_myField)
  _labelRegistry = L;
}
