/**
 * Created by asen on 5.09.25.
 */

import { LightningElement, api, track } from "lwc";

export default class WizardPage1 extends LightningElement {
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
    // console.log('model', JSON.stringify(val));
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
  set patterns(val) {
    this._patterns = val;
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

  @track
  data = {
    flag1: false
  };

  get name() {
    return this.title || "Page 1";
  }

  /**
   * Handle property change
   */
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data = this.setDataValue(
      JSON.parse(JSON.stringify(this.data)),
      name,
      value
    );
    console.log("changeHandler-1", JSON.stringify(this.data));
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

  /**
   * Check result of validation after calling dispatchPageChange() and react to change if needed
   */
  @api
  processChange(key) {
    const value = this.data[key];
    const error = this.errors[key];
    console.log("processChange-1", key, value, error);
  }

  /**
   * Handle page navigation
   * @param {string} dir: 'next' or 'back'
   */
  @api handlePage(dir) {
    // console.log('wizardPage1:pageHandler:', dir, this.wizardId, this.title);
    this.dispatchPageChange(dir);
  }

  /**
   * Dispatch page change event
   * @param {string} action:
   * - 'next' or 'back' for page navigation
   * - property name for property change
   * - 'refresh' for refreshing the page with data from backend
   * - 'error' when error occurs
   */
  dispatchPageChange(action) {
    const pageModel = {
      ...this.data
    };
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: action, pageModel }
      })
    );
  }

  // custom page properties configured by wizard plan
  @api prop1;
  @api prop2;
}
