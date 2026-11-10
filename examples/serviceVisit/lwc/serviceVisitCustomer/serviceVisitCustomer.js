import { LightningElement, api, track } from "lwc";

/**
 * Customer page of the serviceVisit wizard.
 * Page name (registry key, Plan, Rules, saved answers): ServiceVisitCustomer
 */
export default class ServiceVisitCustomer extends LightningElement {
  // ===== PART 1: what the wizard gives the page. WIZARD-MAKER: don't change =====
  @api wizardId;
  @api title;
  @api page;
  @api l;
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
  // One key per field (name="..." in the HTML). The values are saved in model.ServiceVisitCustomer.
  @track data = {
    account: null,
    accountName: null,
    contact: null,
    contactName: null,
    contactEmail: null
  };

  /** "Account": saves the record Id and its name (the name shows the choice again after Back) */
  accountSelected(event) {
    const { selectedId, selectedName } = event.detail;
    this.data.account = selectedId || null;
    this.data.accountName = selectedName || null;
    this.dispatchPageChange("account");
  }

  /** "Contact": saves the record Id and its name (the name shows the choice again after Back) */
  contactSelected(event) {
    const { selectedId, selectedName } = event.detail;
    this.data.contact = selectedId || null;
    this.data.contactName = selectedName || null;
    this.dispatchPageChange("contact");
  }

  /** The "Contact" lookup only offers records that match this answer ("Account"). It is :arg0 in Smart_Lookup_Setting.ServiceVisit_Contact. */
  get contactArg0() {
    return this.data.account ?? undefined;
  }

  /** The "Contact" lookup waits until the answer it depends on is given. */
  get contactDisabled() {
    return this.contactArg0 === undefined;
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
    const value = event.detail.value ?? event.detail.checked ?? null;
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
