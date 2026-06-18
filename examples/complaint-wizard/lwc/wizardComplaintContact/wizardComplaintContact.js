import { LightningElement, api, track, wire } from "lwc";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import COMPLAINT_OBJECT from "@salesforce/schema/Complaint__c";
import PREFERRED_CONTACT_FIELD from "@salesforce/schema/Complaint__c.Preferred_Contact__c";
import PREFERRED_TIME_FIELD from "@salesforce/schema/Complaint__c.Preferred_Time__c";

export default class WizardComplaintContact extends LightningElement {
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
  _messages;
  @api get messages() {
    return this._messages || {};
  }
  set messages(val) {
    this._messages = val;
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
    firstName: null,
    lastName: null,
    email: null,
    phone: null,
    preferredContact: null,
    preferredTime: null // initialized as null so the rules engine can process it
  };

  // --- @wire: dynamic picklist values ---

  recordTypeId;

  _preferredContactOptions = [];
  _preferredTimeOptions = [];

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
      const preferredContactField =
        data.picklistFieldValues[PREFERRED_CONTACT_FIELD.fieldApiName];
      const preferredTimeField =
        data.picklistFieldValues[PREFERRED_TIME_FIELD.fieldApiName];

      if (!preferredContactField || !preferredTimeField) return;

      this._preferredContactOptions = preferredContactField.values.map(
        (entry) => ({
          label: entry.label,
          value: entry.value
        })
      );
      this._preferredTimeOptions = preferredTimeField.values.map((entry) => ({
        label: entry.label,
        value: entry.value
      }));
      console.log("Preferred Contact options:", this._preferredContactOptions);
      console.log("Preferred Time options:", this._preferredTimeOptions);
    } else if (error) {
      console.error("Error loading picklist values:", error);
    }
  }

  // --- options getters ---
  get preferredContactOptions() {
    return this._preferredContactOptions;
  }
  get preferredTimeOptions() {
    return this._preferredTimeOptions;
  }

  // Hidden by Rules engine when preferredContact != 'phone'
  get isPreferredTimeVisible() {
    return this._visible.preferredTime !== false;
  }

  // --- change handler ---
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    let parsedData = JSON.parse(JSON.stringify(this.data));
    parsedData = this.setDataValue(parsedData, name, value);
    this.data = parsedData;
    console.log("changeHandler-4", JSON.stringify(this.data));
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
    console.log("processChange-4", name);
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
