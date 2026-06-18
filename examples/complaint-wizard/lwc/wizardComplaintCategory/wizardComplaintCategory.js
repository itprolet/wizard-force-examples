import { LightningElement, api, track, wire } from "lwc";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import COMPLAINT_OBJECT from "@salesforce/schema/Complaint__c";
import CATEGORY_FIELD from "@salesforce/schema/Complaint__c.Category__c";
import SUB_CATEGORY_FIELD from "@salesforce/schema/Complaint__c.Sub_Category__c";

export default class WizardComplaintCategory extends LightningElement {
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
        let parsedData = JSON.parse(JSON.stringify(this.data));
        Object.keys(pageModel).forEach((key) => {
          if (Object.prototype.hasOwnProperty.call(this.data, key)) {
            parsedData[key] = pageModel[key];
          }
        });
        this.data = parsedData;
      }
    }
  }

  // --- framework props ---
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

  // --- page data ---
  @track data = {
    category: null,
    subCategory: null
  };

  // --- @wire: dynamic picklist values ---

  // Plain field (no @track) — populated once by the wire.
  recordTypeId;

  _categoryOptions = [];
  _allSubCategoryValues = [];
  _subCategoryControllerValues = {};

  // Step 1: retrieve defaultRecordTypeId for the Complaint__c object.
  @wire(getObjectInfo, { objectApiName: COMPLAINT_OBJECT })
  objectInfo({ data, error }) {
    if (data) {
      this.recordTypeId = data.defaultRecordTypeId;
      console.log("Complaint Record Type ID:", this.recordTypeId);
    } else if (error) {
      console.error("Error loading Complaint object info:", error);
    }
  }

  // Step 2: load picklist values for the resolved record type.
  // '$recordTypeId' with $ is a reactive parameter — this wire waits until
  // recordTypeId is set by the first wire, then executes automatically.
  @wire(getPicklistValuesByRecordType, {
    objectApiName: COMPLAINT_OBJECT,
    recordTypeId: "$recordTypeId"
  })
  wiredPicklistValues({ data, error }) {
    if (data) {
      const categoryField =
        data.picklistFieldValues[CATEGORY_FIELD.fieldApiName];
      // SubCategory — dependent picklist (controlled by Category)
      const subCategoryField =
        data.picklistFieldValues[SUB_CATEGORY_FIELD.fieldApiName];

      if (!categoryField || !subCategoryField) {
        return;
      }

      // Category — simple picklist: map label + value for each entry
      this._categoryOptions = categoryField.values.map((entry) => ({
        label: entry.label,
        value: entry.value
      }));

      // controllerValues: { "billing": 0, "technical": 1, ... }
      // Key is the controlling field value, value is its index.
      this._subCategoryControllerValues = subCategoryField.controllerValues;

      // Store all sub-category values with their validFor indices.
      // validFor: [0] means "valid only when Category is billing (index 0)"
      this._allSubCategoryValues = subCategoryField.values.map((entry) => ({
        label: entry.label,
        value: entry.value,
        validFor: entry.validFor || []
      }));

      console.log("Category options:", this._categoryOptions);
      console.log(
        "SubCategory controller values:",
        this._subCategoryControllerValues
      );
      console.log("All SubCategory values:", this._allSubCategoryValues);
    } else if (error) {
      console.error("Error loading picklist values:", error);
    }
  }

  // --- options getters ---
  get categoryOptions() {
    return this._categoryOptions;
  }

  get subCategoryOptions() {
    if (!this.data.category) {
      return [];
    }
    // Find the index of the selected category in controllerValues
    const idx = this._subCategoryControllerValues[this.data.category];
    if (idx === undefined) {
      return [];
    }
    // Return only values whose validFor includes the current category index
    return this._allSubCategoryValues
      .filter((entry) => entry.validFor.includes(idx))
      .map((entry) => ({ label: entry.label, value: entry.value }));
  }

  // --- visibility getters ---
  get isSubCategoryVisible() {
    return this._visible.subCategory !== false;
  }

  // --- change handler ---
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;

    let parsedData = JSON.parse(JSON.stringify(this.data));
    parsedData = this.setDataValue(parsedData, name, value);
    // Reset subCategory when category changes
    if (name === "category") {
      parsedData = this.setDataValue(parsedData, "subCategory", null);
    }
    this.data = parsedData;
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

  @api processChange(name) {
    console.log("processChange-1", name);
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
