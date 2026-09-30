import { LightningElement, api, track } from "lwc";

/**
 * Base class for the Expense Report wizard pages.
 *
 * It implements the page contract of <c-wizard> ONCE, so every page only has to define:
 *   - defaults(): the page data model with default values;
 *   - its template and page-specific logic.
 *
 * Page contract (see README of the framework, section "API на страниците"):
 *   @api properties  - set by the wizard on every render (model, required, errors, readOnly, ...);
 *   handlePage(dir)  - called by the wizard on Next / Back / progress-bar jump. The page answers with a
 *                      `pagechange` event carrying its current data, and the wizard saves it and navigates;
 *   processChange()  - called after the wizard validated a field change (optional hook).
 *   `pagechange`     - event { direction, pageModel } sent by the page. direction is `next`, `prev`,
 *                      `refresh` (reload $ctx from the backend) or the name of the changed field.
 */
export default class ExpensePageBase extends LightningElement {
  // ---- framework-injected properties (contract, do not rename) ----
  @api wizardId;
  @api title;
  /** Page id from the plan, e.g. 'ExpenseItems'. The page data lives in model[page]. */
  @api page;
  @api wizardType;
  @api currentId;
  /** ACTIVE | SIGNED | REVIEW | APPROVED */
  @api state;
  /** Wizard__c.Review_Data__c - fields requested for change in REVIEW state */
  @api reviewData;
  @api hasPrev;
  @api hasNext;
  /** Labels: framework labels + label-registry of expenseReportRegistry */
  @api l;
  /** Rule results for the page fields, computed by the wizard from Rules__c */
  @api patterns;
  @api required;
  @api errors;
  @api readOnly;
  @api visible;
  @api hints;
  @api messages;

  get _l() {
    return this.l || {};
  }
  get _required() {
    return this.required || {};
  }
  get _errors() {
    return this.errors || {};
  }
  get _readOnly() {
    return this.readOnly || {};
  }
  get _visible() {
    return this.visible || {};
  }
  get _patterns() {
    return this.patterns || {};
  }
  get _messages() {
    return this.messages || {};
  }
  /** Hints in Rules__c are label names - translate them. */
  get _hints() {
    const result = {};
    Object.entries(this.hints || {}).forEach(([key, value]) => {
      result[key] = this._l[value] || value;
    });
    return result;
  }

  /** Context written by the backend (Wizard__c.Context__c). The wizard adds it to the current page model. */
  get ctx() {
    return this._model?.[this.page]?.$ctx || {};
  }
  get isEditable() {
    return !this.state || this.state === "ACTIVE" || this.state === "REVIEW";
  }
  get isReview() {
    return this.state === "REVIEW";
  }

  // ---- page data ----
  /** Override in the page: data model of the page with default values. */
  defaults() {
    return {};
  }

  @track data = this.defaults();

  _model;
  /** Complete wizard model. Copy the known keys of this page's namespace into `data`. */
  @api
  get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
    const pageModel = val?.[this.page];
    if (pageModel) {
      const merged = this.defaults();
      Object.keys(merged).forEach((key) => {
        if (pageModel[key] !== undefined && pageModel[key] !== null) {
          merged[key] = clone(pageModel[key]);
        }
      });
      this.data = merged;
    }
  }

  // ---- change handling ----
  /** Generic handler for c-input-* components. Supports nested names like `edit.amount`. */
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget?.dataset?.name;
    let value = event.detail?.value;
    if (value === undefined) {
      value = event.detail?.checked;
    }
    this.setValue(name, value === undefined ? null : value);
    this.dispatchPageChange(name);
  }

  setValue(path, value) {
    const data = clone(this.data);
    const parts = path.split(".");
    let target = data;
    parts.slice(0, -1).forEach((part) => {
      target[part] = { ...(target[part] || {}) };
      target = target[part];
    });
    target[parts[parts.length - 1]] = value;
    this.data = data;
  }

  dispatchPageChange(direction) {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction, pageModel: clone(this.data) }
      })
    );
  }

  @api
  handlePage(dir) {
    this.dispatchPageChange(dir);
  }

  // eslint-disable-next-line no-unused-vars
  @api processChange(name, veto) {
    // optional hook - errors are already delivered through the `errors` property
  }

  // ---- wizard services ----
  /** Show a toast through the wizard (c-elem-toasts). variant: success | error | warning | info */
  toast(message, variant = "info") {
    this.dispatchEvent(
      new CustomEvent("toast", { detail: { message, variant } })
    );
  }

  /** Lock / unlock the wizard UI (shows the preloader) while a server call is running. */
  lockUi(locked) {
    this.dispatchEvent(
      new CustomEvent("action", {
        detail: { action: "uiLock", status: locked ? "in_progress" : "done" }
      })
    );
  }
}

function clone(value) {
  return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}
