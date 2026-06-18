import { LightningElement, api, track, wire } from "lwc";
import submitComplaint from "@salesforce/apex/ComplaintController.submitComplaint";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import COMPLAINT_OBJECT from "@salesforce/schema/Complaint__c";
import CATEGORY_FIELD from "@salesforce/schema/Complaint__c.Category__c";
import SUB_CATEGORY_FIELD from "@salesforce/schema/Complaint__c.Sub_Category__c";
import AFFECTED_SERVICE_FIELD from "@salesforce/schema/Complaint__c.Affected_Service__c";
import PREFERRED_CONTACT_FIELD from "@salesforce/schema/Complaint__c.Preferred_Contact__c";
import PREFERRED_TIME_FIELD from "@salesforce/schema/Complaint__c.Preferred_Time__c";

// Transforms wire picklist data into a { value: label } map for lookup in getters.
function toLabelsMap(picklistField) {
  if (!picklistField?.values) {
    return {};
  }
  return picklistField.values.reduce((labelsMap, entry) => {
    labelsMap[entry.value] = entry.label;
    return labelsMap;
  }, {});
}

export default class WizardComplaintSummary extends LightningElement {
  @api wizardId;
  @api title;
  @api page;
  @api l;
  @api wizardType;
  @api currentId;
  @api hasPrev;
  @api hasNext;
  @api prop1;
  @api prop2;

  get _l() {
    return this.l || {};
  }

  // Summary reads the ENTIRE model, not just its own namespace
  _model;
  @api get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
  }

  _errors;
  @api get errors() {
    return this._errors || {};
  }
  set errors(val) {
    this._errors = val;
  }

  @api readOnly;
  @api visible;
  @api patterns;
  @api required;
  @api hints;

  @track data = {
    complaintAgreeGdpr: false
  };

  // --- @wire: load picklist labels dynamically ---

  recordTypeId;

  // Build value→label maps for all picklist fields shown in the summary
  _categoryLabels = {};
  _subCategoryLabels = {};
  _affectedServiceLabels = {};
  _preferredContactLabels = {};
  _preferredTimeLabels = {};

  // Retrieve defaultRecordTypeId for the Complaint__c object
  @wire(getObjectInfo, { objectApiName: COMPLAINT_OBJECT })
  objectInfo({ data, error }) {
    if (data) {
      this.recordTypeId = data.defaultRecordTypeId;
    } else if (error) {
      console.error("Error loading Complaint object info:", error);
    }
  }

  @wire(getPicklistValuesByRecordType, {
    objectApiName: COMPLAINT_OBJECT,
    recordTypeId: "$recordTypeId"
  })
  wiredPicklistValues({ data, error }) {
    if (data) {
      this._categoryLabels = toLabelsMap(
        data.picklistFieldValues[CATEGORY_FIELD.fieldApiName]
      );
      this._subCategoryLabels = toLabelsMap(
        data.picklistFieldValues[SUB_CATEGORY_FIELD.fieldApiName]
      );
      this._affectedServiceLabels = toLabelsMap(
        data.picklistFieldValues[AFFECTED_SERVICE_FIELD.fieldApiName]
      );
      this._preferredContactLabels = toLabelsMap(
        data.picklistFieldValues[PREFERRED_CONTACT_FIELD.fieldApiName]
      );
      this._preferredTimeLabels = toLabelsMap(
        data.picklistFieldValues[PREFERRED_TIME_FIELD.fieldApiName]
      );
    } else if (error) {
      console.error("Error loading picklist values:", error);
    }
  }

  // --- Data getters (one per page section) ---
  // Used directly in HTML for plain text fields
  get categoryData() {
    return this._model?.WizardComplaintCategory || {};
  }
  get detailsData() {
    return this._model?.WizardComplaintDetails || {};
  }
  get attachmentData() {
    return this._model?.WizardComplaintAttachment || {};
  }
  get contactData() {
    return this._model?.WizardComplaintContact || {};
  }

  // --- Picklist label getters ---
  get categoryLabel() {
    return this._categoryLabels[this.categoryData.category];
  }
  get subCategoryLabel() {
    return this._subCategoryLabels[this.categoryData.subCategory];
  }
  get affectedServiceLabel() {
    return this._affectedServiceLabels[this.detailsData.affectedService];
  }
  get preferredContactLabel() {
    return this._preferredContactLabels[this.contactData.preferredContact];
  }
  get preferredTimeLabel() {
    return this._preferredTimeLabels[this.contactData.preferredTime];
  }

  // --- Conditional rendering helpers ---
  get hasBillingData() {
    return !!this.attachmentData.invoiceNumber;
  }
  get hasPreferredTime() {
    return this.contactData.preferredContact === "phone";
  }

  get isAgreeGdprChecked() {
    return this.data.complaintAgreeGdpr === true;
  }

  // --- Navigation (navigationByChild) ---
  handleBack() {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: "prev", pageModel: {} }
      })
    );
  }

  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data = this.setDataValue(
      JSON.parse(JSON.stringify(this.data)),
      name,
      value
    );
    console.log("changeHandler-last", JSON.stringify(this.data));
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

  @track isSubmitting = false;
  @track submitError = null;

  async handleSubmit() {
    if (!this.isAgreeGdprChecked) {
      this._errors = { complaintAgreeGdpr: this._l.Wizard_err_required_field };
      return;
    }
    this._errors = {}; // Clear any existing errors

    this.isSubmitting = true;
    this.submitError = null;
    try {
      const complaintId = await submitComplaint({
        wizardId: this.wizardId,
        agreedToGdpr: this.data.complaintAgreeGdpr
      });
      console.log("Complaint submitted successfully, ID:", complaintId);
    } catch (error) {
      console.error("Error submitting complaint:", error);
      this.submitError = error.message;
    } finally {
      this.isSubmitting = false;
    }
  }

  @api handlePage(dir) {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: dir, pageModel: {} }
      })
    );
  }

  @api processChange(name) {
    console.log("processChange-last", name);
  }
}
