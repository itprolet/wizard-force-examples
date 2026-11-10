import { api, wire } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import COMPLAINT_OBJECT from "@salesforce/schema/Complaint__c";
import CATEGORY_FIELD from "@salesforce/schema/Complaint__c.Category__c";
import SUB_CATEGORY_FIELD from "@salesforce/schema/Complaint__c.Sub_Category__c";

export default class WizardComplaintCategory extends WizardPageBase {
  @api prop1;

  @api prop2;

  // --- page data ---
  data = {
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

  // --- change handler ---
  /** A new category clears the sub-category (it is sent with the same change) */
  handleChange(event) {
    if (event.detail?.name === "category" && !this.isLocked) {
      this.setValue("subCategory", null, false);
    }
    super.handleChange(event);
  }

  // --- visibility getters ---
  get isSubCategoryVisible() {
    return this._visible.subCategory !== false;
  }
}
