import { LightningElement, api, track, wire } from "lwc";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import COMPLAINT_OBJECT from "@salesforce/schema/Complaint__c";
import AFFECTED_SERVICE_FIELD from "@salesforce/schema/Complaint__c.Affected_Service__c";

export default class WizardComplaintDetails extends LightningElement {
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

  @track data = {
    description: null,
    incidentDate: null,
    referenceNumber: null,
    affectedService: null // initialized as null so the rules engine can process it
  };

  // --- @wire: dynamic picklist values ---

  recordTypeId;

  _affectedServiceOptions = [];

  // Retrieve defaultRecordTypeId
  @wire(getObjectInfo, { objectApiName: COMPLAINT_OBJECT })
  objectInfo({ data, error }) {
    if (data) {
      this.recordTypeId = data.defaultRecordTypeId;
      console.log("Complaint Record Type ID:", this.recordTypeId);
    } else if (error) {
      console.error("Error loading Complaint object info:", error);
    }
  }

  // Load picklist values once recordTypeId is available
  @wire(getPicklistValuesByRecordType, {
    objectApiName: COMPLAINT_OBJECT,
    recordTypeId: "$recordTypeId"
  })
  wiredPicklistValues({ data, error }) {
    if (data) {
      const affectedServiceField =
        data.picklistFieldValues[AFFECTED_SERVICE_FIELD.fieldApiName];

      if (!affectedServiceField) return;

      this._affectedServiceOptions = affectedServiceField.values.map(
        (entry) => ({
          label: entry.label,
          value: entry.value
        })
      );
      console.log("Affected Service options:", this._affectedServiceOptions);
    } else if (error) {
      console.error("Error loading picklist values:", error);
    }
  }

  // --- options getter ---
  get affectedServiceOptions() {
    return this._affectedServiceOptions;
  }

  // Cross-page hidden by Rules engine when WizardComplaintCategory.category != 'technical
  get isAffectedServiceVisible() {
    return this._visible.affectedService !== false;
  }

  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data = this.setDataValue(
      JSON.parse(JSON.stringify(this.data)),
      name,
      value
    );
    console.log("changeHandler-2", JSON.stringify(this.data));
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
    console.log("processChange-2", name);
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
