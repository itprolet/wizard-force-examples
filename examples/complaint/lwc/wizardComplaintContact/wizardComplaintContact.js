import { api, wire } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import COMPLAINT_OBJECT from "@salesforce/schema/Complaint__c";
import PREFERRED_CONTACT_FIELD from "@salesforce/schema/Complaint__c.Preferred_Contact__c";
import PREFERRED_TIME_FIELD from "@salesforce/schema/Complaint__c.Preferred_Time__c";

export default class WizardComplaintContact extends WizardPageBase {
  @api prop1;

  @api prop2;

  // --- page data ---
  data = {
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
}
