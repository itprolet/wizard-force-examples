/**
 * Created by asen on 5.09.25.
 */

import { LightningElement, api, track } from "lwc";

export default class WizardPage2 extends LightningElement {
  @api wizardId;
  @api title;
  @api page;
  @api l;

  get _l() {
    return this.l || {};
  }

  @api wizardType;
  @api currentId;

  get name() {
    return this.title || "Page 2";
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

  emptyDataObjects = {
    subobject: {}
  };
  @api patterns;
  get _patterns() {
    if (this.patterns) {
      return {
        ...this.emptyDataObjects,
        ...this.patterns
      };
    }

    return this.emptyDataObjects;
  }
  @api required;
  get _required() {
    if (this.required) {
      return {
        ...this.emptyDataObjects,
        ...this.required
      };
    }

    return this.emptyDataObjects;
  }
  @api readOnly;
  get _readOnly() {
    if (this.readOnly) {
      return {
        ...this.emptyDataObjects,
        ...this.readOnly
      };
    }

    return this.emptyDataObjects;
  }
  @api errors;
  get _errors() {
    if (this.errors) {
      return {
        ...this.emptyDataObjects,
        ...this.errors
      };
    }

    return this.emptyDataObjects;
  }

  @track
  data = {
    flag2: false,
    subobject: {
      flag21: false
    }
  };

  /**
   * Handle property change
   */
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value || event.detail.checked || null;
    console.log("changeHandler-2", name, value);

    this.data = this.setDataValue(
      JSON.parse(JSON.stringify(this.data)),
      name,
      value
    );
    console.log("changeHandler-2", JSON.stringify(this.data));
    this.dispatchPageChange(name);
  }

  /**
   * Set property value to model using dot notation
   * @param {string} propertyPath - path in dot notation
   * @param {object} model - model
   * @returns {any} property value
   */
  setDataValue(model, propertyPath, value) {
    const parts = propertyPath.split(".");
    if (parts.length > 1) {
      model[parts[0]] = this.setDataValue(
        model[parts[0]] || {},
        parts.toSpliced(0, 1).join("."),
        value
      );
    } else {
      model[propertyPath] = value;
    }
    return model;
  }

  /**
   * Check result of validation after calling dispatchPageChange() and react to change if needed
   */
  @api
  processChange(key) {
    const value = this.getPropertyValue(key, this.data);
    const error = this.getPropertyValue(key, this.errors);
    console.log("processChange-2", key, value, error);
  }

  /**
   * Get property value from model using dot notation
   * @param {string} propertyPath - path in dot notation
   * @param {object} model - model
   * @returns {any} property value
   */
  getPropertyValue(propertyPath, model) {
    const parts = propertyPath.split(".");
    let current = model;

    for (const part of parts) {
      if (typeof current === "object" && current !== null) {
        current = current[part];
      } else {
        return false;
      }
    }

    return current;
  }

  /**
   * Handle page navigation
   * @param {string} dir: 'next' or 'back'
   */
  @api handlePage(dir) {
    // console.log('wizardPage1:pageHandler:', dir, this.wizardId, this.title);
    const pageModel = {
      ...this.data
    };
    console.log("wizardPage2:pageHandler:", JSON.stringify(pageModel));
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
