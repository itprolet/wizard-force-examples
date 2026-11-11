import { api, wire } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import COMPLAINT_OBJECT from "@salesforce/schema/Complaint__c";
import AFFECTED_SERVICE_FIELD from "@salesforce/schema/Complaint__c.Affected_Service__c";

export default class WizardComplaintDetails extends WizardPageBase {
  @api prop1;

  @api prop2;

  data = {
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
}
