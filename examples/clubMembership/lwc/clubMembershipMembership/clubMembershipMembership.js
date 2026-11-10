import { LightningElement, api, track } from "lwc";

/**
 * Membership page of the clubMembership wizard.
 * Page name (registry key, Plan, Rules, saved answers): ClubMembershipMembership
 */
export default class ClubMembershipMembership extends LightningElement {
  // ===== PART 1: what the wizard gives the page. WIZARD-MAKER: don't change =====
  @api wizardId;
  @api title;
  @api page;
  @api l;
  /** The wizard's texts (Custom Labels), in the user's language: this._l.<label name> */
  get _l() {
    return this.l || {};
  }
  @api wizardType;
  @api currentId;
  @api state;

  _model;
  @api get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
    const pageModel = val ? val[this.page] : null;
    if (pageModel) {
      Object.keys(pageModel).forEach((key) => {
        if (Object.prototype.hasOwnProperty.call(this.data, key)) {
          this.data[key] = pageModel[key];
        }
      });
    }
  }

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

  @api readOnly;
  @api visible;
  @api hints;
  @api patterns;
  @api messages;
  // WIZARD-MAKER optional: uncomment when the HTML uses read-only / hint / pattern / message / hidden
  // get _readOnly() { return this.readOnly || {}; }
  // get _visible() { return this.visible || {}; }
  // get _hints() { return this.hints || {}; }
  // get _patterns() { return this.patterns || {}; }
  // get _messages() { return this.messages || {}; }

  // ===== PART 2: this page's own things. WIZARD-MAKER: edit here =====
  // One key per field (name="..." in the HTML). The values are saved in model.ClubMembershipMembership.
  @track data = {
    plan: null,
    startDate: null,
    familyMembers: null,
    familyNames: null,
    premiumWishes: null,
    hasCompany: false
  };

  get planOptions() {
    return [
      {
        label: this._l.ClubMembership_opt_membership_plan_basic,
        value: "basic"
      },
      {
        label: this._l.ClubMembership_opt_membership_plan_standard,
        value: "standard"
      },
      {
        label: this._l.ClubMembership_opt_membership_plan_premium,
        value: "premium"
      }
    ];
  }

  /** "Family Names" is shown only if (familyMembers > 0). Change the condition in prolet__Rules__c, not here. */
  get showFamilyNames() {
    return this.visible?.familyNames !== false;
  }

  /** "Premium Wishes" is shown only if (plan='premium'). Change the condition in prolet__Rules__c, not here. */
  get showPremiumWishes() {
    return this.visible?.premiumWishes !== false;
  }

  // WIZARD-MAKER examples: uncomment and adapt what you need.
  //
  // Show a field only when another field has a certain value ("npm run make page" → add fields
  // does this for you). The condition is written once, in prolet__Rules__c:
  // Rules: "if (myChoice='other')":      { "required": ["otherDetails"] },
  //        "if (not(myChoice='other'))": { "hidden":   ["otherDetails"] }
  // HTML:  <template lwc:if={showOtherDetails}> …the field… </template>
  // get showOtherDetails() {
  //   return this.visible?.otherDetails !== false;
  // }
  //
  // Read an answer from another page (use that page's name from the registry):
  // get answerFromOtherPage() {
  //   return this.model?.OtherPageName?.someField;
  // }
  //
  // Today as "YYYY-MM-DD", e.g. min={today} on a date field to block past dates:
  // get today() {
  //   return new Date().toISOString().slice(0, 10);
  // }

  // ===== PART 3: talking to the wizard. WIZARD-MAKER: don't change =====
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    let value = event.detail.value ?? event.detail.checked ?? null;
    // Number fields are saved as real numbers, so Rules like "if (quantity > 1)" work
    if (["familyMembers"].includes(name) && value !== null && value !== "") {
      value = Number(value);
    }
    this.data[name] = value;
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
