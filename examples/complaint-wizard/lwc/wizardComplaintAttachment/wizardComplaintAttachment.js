import { LightningElement, api, track } from "lwc";

export default class WizardComplaintAttachment extends LightningElement {
  @api wizardId;
  @api title;
  @api page;
  @api l;
  @api wizardType;
  @api currentId;
  @api prop1;
  @api prop2;

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
        let d = JSON.parse(JSON.stringify(this.data));
        Object.keys(pageModel).forEach((key) => {
          if (Object.prototype.hasOwnProperty.call(this.data, key)) {
            d[key] = pageModel[key];
          }
        });
        this.data = d;
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
    invoiceNumber: null,
    disputedAmount: null
  };

  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data = this.setDataValue(
      JSON.parse(JSON.stringify(this.data)),
      name,
      value
    );
    console.log("changeHandler-3", JSON.stringify(this.data));
    this.dispatchPageChange(name);
  }

  setDataValue(data, name, value) {
    const parts = name.split(".");
    if (parts.length > 1) {
      data[parts[0]] = this.setDataValue(
        data[parts[0]] || {},
        parts.toSpliced(0, 1).join("."),
        value
      );
    } else {
      data[name] = value;
    }
    return data;
  }

  @api processChange(name) {
    console.log("processChange-3", name);
  }

  @api handlePage(dir) {
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
}
