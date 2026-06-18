import { LightningElement, api, track } from "lwc";

export default class FeedbackComment extends LightningElement {
  @api wizardId;
  @api title;
  @api page;
  @api l;
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

  @track data = {
    comment: "",
    email: ""
  };

  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data[name] = value;
    this.dispatchPageChange(name);
  }

  @api
  processChange(key) {
    console.log(key);
    // Errors are displayed via the error prop on c-input-text
  }

  @api
  handlePage(dir) {
    this.dispatchPageChange(dir);
  }

  dispatchPageChange(action) {
    const pageModel = { ...this.data };
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: action, pageModel }
      })
    );
  }

  @api prop1;
}
