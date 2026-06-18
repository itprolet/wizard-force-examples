import { LightningElement, api, track } from "lwc";

export default class FeedbackRating extends LightningElement {
  // ---- framework-injected properties (contract, do not rename) ----
  @api wizardId;
  @api title;
  @api page; // page identifier (e.g. 'FeedbackRating')
  @api l; // translated labels map
  @api wizardType;
  @api currentId;

  get _l() {
    return this.l || {};
  }

  _model;
  @api get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
    if (val) {
      const pageModel = val[this.page];
      if (pageModel) {
        Object.keys(pageModel).forEach((key) => {
          if (Object.prototype.hasOwnProperty.call(this.data, key)) {
            this.data[key] = pageModel[key];
          }
        });
      }
    }
  }

  _patterns;
  @api get patterns() {
    return this._patterns || {};
  }
  set patterns(v) {
    this._patterns = v;
  }
  _required;
  @api get required() {
    return this._required || {};
  }
  set required(v) {
    this._required = v;
  }
  _errors;
  @api get errors() {
    return this._errors || {};
  }
  set errors(v) {
    this._errors = v;
  }
  @api readOnly;
  get _readOnly() {
    return this.readOnly || {};
  }
  @api visible;
  get _visible() {
    return this.visible || {};
  }
  @api hints;
  get _hints() {
    return this.hints || {};
  }

  // ---- your page data model ----
  @track data = {
    rating: null,
    wouldRecommend: false
  };

  // ---- event handlers ----
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data[name] = value;
    this.dispatchPageChange(name);
  }

  @api
  processChange(name) {
    // optional post-validation hook — inspect this.errors[name] if you need
    // to react to validation outcome (flash UI, focus fields, etc.).
    console.log("Feedback rating processChange name:", name);
  }

  @api
  handlePage(dir) {
    this.dispatchPageChange(dir); // 'next' or 'back'
  }

  dispatchPageChange(action) {
    const pageModel = { ...this.data };
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: action, pageModel }
      })
    );
  }

  // custom page properties configured by wizard plan
  @api prop1;
}
