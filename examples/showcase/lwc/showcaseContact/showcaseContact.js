import { api } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
const HEAR_ABOUT_OPTIONS = [
  { label: "Social Media", value: "social" },
  { label: "Email Newsletter", value: "email" },
  { label: "Colleague / Friend", value: "colleague" },
  { label: "Referral", value: "referral" },
  { label: "Other", value: "other" }
];

export default class ShowcaseContact extends WizardPageBase {
  @api prop1;

  @api prop2;

  // --- page data ---
  data = {
    firstName: null,
    lastName: null,
    email: null,
    phone: null,
    company: null,
    hearAboutUs: null,
    referralName: null // initialized so the Rules engine can process it
  };

  // --- options ---
  get hearAboutOptions() {
    return HEAR_ABOUT_OPTIONS;
  }

  // --- change handler ---
  /** Switching away from "Referral" clears the referral name (it is sent with the same change) */
  handleChange(event) {
    const { name, value } = event.detail || {};
    if (name === "hearAboutUs" && value !== "referral" && !this.isLocked) {
      this.setValue("referralName", null, false);
    }
    super.handleChange(event);
  }

  // --- conditional field visibility ---
  // The Rules engine sets visible.referralName = false when hearAboutUs != 'referral'
  get isReferralNameVisible() {
    return this._visible.referralName !== false;
  }
}
