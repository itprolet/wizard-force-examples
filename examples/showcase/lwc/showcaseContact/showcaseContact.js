import { LightningElement, api, track } from "lwc";

const HEAR_ABOUT_OPTIONS = [
  { label: "Social Media", value: "social" },
  { label: "Email Newsletter", value: "email" },
  { label: "Colleague / Friend", value: "colleague" },
  { label: "Referral", value: "referral" },
  { label: "Other", value: "other" }
];

export default class ShowcaseContact extends LightningElement {
  @api wizardId;
  @api title;
  @api page;
  @api wizardType;
  @api currentId;
  @api prop1;
  @api prop2;

  @api l;
  get _l() {
    return this.l || {};
  }

  // --- model ---
  _model;
  @api get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
    if (val) {
      const pageModel = val[this.page];
      if (pageModel) {
        const parsed = JSON.parse(JSON.stringify(this.data));
        Object.keys(pageModel).forEach((key) => {
          if (Object.prototype.hasOwnProperty.call(this.data, key)) {
            parsed[key] = pageModel[key];
          }
        });
        this.data = parsed;
      }
    }
  }

  // --- framework props ---
  _required;
  @api get required() {
    return this._required || {};
  }
  set required(val) {
    this._required = val;
  }

  _errors;
  @api get errors() {
    return this._errors || {};
  }
  set errors(val) {
    this._errors = val;
  }

  _patterns;
  @api get patterns() {
    return this._patterns || {};
  }
  set patterns(val) {
    this._patterns = val;
  }

  _hints;
  @api get hints() {
    return this._hints || {};
  }
  set hints(val) {
    this._hints = val;
  }

  @api readOnly;
  get _readOnly() {
    return this.readOnly || {};
  }

  @api visible;
  get _visible() {
    return this.visible || {};
  }

  // --- page data ---
  @track data = {
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

  // --- conditional field visibility ---
  // The Rules engine sets visible.referralName = false when hearAboutUs != 'referral'
  get isReferralNameVisible() {
    return this._visible.referralName !== false;
  }

  // --- change handler ---
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? null;
    const parsed = JSON.parse(JSON.stringify(this.data));
    parsed[name] = value;
    // Clear referral name when switching away from 'referral'
    if (name === "hearAboutUs" && value !== "referral") {
      parsed.referralName = null;
    }
    this.data = parsed;
    this.dispatchPageChange(name);
  }

  @api processChange() {}

  @api handlePage(dir) {
    this.dispatchPageChange(dir);
  }

  dispatchPageChange(action) {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: action, pageModel: { ...this.data } }
      })
    );
  }
}
