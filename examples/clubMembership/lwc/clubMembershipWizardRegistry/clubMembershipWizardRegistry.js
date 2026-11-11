import { LightningElement } from "lwc";
import { registerLabels } from "prolet/wizardUtils";
import { L } from "./labels";
// WIZARD-MAKER:imports (new pages and validators are added below this line)
import ClubMembershipApplicant from "c/clubMembershipApplicant";
import ClubMembershipMembership from "c/clubMembershipMembership";
import ClubMembershipCompany from "c/clubMembershipCompany";
import ClubMembershipPayment from "c/clubMembershipPayment";
import ClubMembershipSummary from "c/clubMembershipSummary";
import {
  validateClubEmail,
  validateCompanyPage
} from "c/clubMembershipValidators";
// Example: import { validateMyField, validateMyPage } from "c/clubMembershipValidators";

// The wizard's texts are Custom Labels (labels.js), so they can be translated. Validator messages in
// prolet__Rules__c are label names; the framework translates them through the global label map (not through
// label-registry), so the labels are registered globally as well.
registerLabels(L);

/**
 * Registry of the "Club Membership" wizard (Wizard_Setup.ClubMembership).
 * The only component placed on the page: it renders <c-wizard> and passes the registries to it.
 */
export default class ClubMembershipWizardRegistry extends LightningElement {
  // Pages. Keys = page names used in Plan__c, prolet__Rules__c and the saved answers (model.<PageName>)
  _pageRegistry = {
    // WIZARD-MAKER:pages
    ClubMembershipApplicant,
    ClubMembershipMembership,
    ClubMembershipCompany,
    ClubMembershipPayment,
    ClubMembershipSummary
  };

  // Field validators: (value, message) => error text, or undefined when valid.
  // Used in prolet__Rules__c as: "validators": { "myField": ["ValidateMyField"] }
  _validatorRegistry = {
    // WIZARD-MAKER:validators
    ValidateClubEmail: validateClubEmail
    // ValidateMyField: validateMyField
  };

  // Page validators: (page, model, props, errors) => true when valid, false otherwise.
  // Used in prolet__Rules__c as: "pageValidators": [{ "validator": "ValidateMyPage", "message": "…" }]
  _pageValidatorRegistry = {
    // WIZARD-MAKER:pageValidators
    ValidateCompanyPage: validateCompanyPage
    // ValidateMyPage: validateMyPage
  };

  // Labels: every page gets them as "l" (in the pages: this._l.ClubMembership_lbl_myField)
  _labelRegistry = L;
}
