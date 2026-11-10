import { api, track, wire } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
import {
  clearStoredWizardId,
  errorMessage,
  isLockedState
} from "prolet/wizardUtils";
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

export default class WizardComplaintSummary extends WizardPageBase {
  @api prop1;

  @api prop2;

  /** The GDPR tick: the submit's own, not an answer of the page (it is never sent as one) */
  complaintAgreeGdpr = false;

  /** The page's own error (the tick is missing): not one of the wizard's rules */
  localErrors = {};

  /** The GDPR tick changed: kept here, it goes with the submit */
  handleAgree(event) {
    this.complaintAgreeGdpr =
      (event.detail?.checked ?? event.target?.checked) === true;
  }

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
    return this.model?.WizardComplaintCategory || {};
  }

  get detailsData() {
    return this.model?.WizardComplaintDetails || {};
  }

  get attachmentData() {
    return this.model?.WizardComplaintAttachment || {};
  }

  get contactData() {
    return this.model?.WizardComplaintContact || {};
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
    return this.complaintAgreeGdpr === true;
  }

  // --- Navigation (navigationByChild) ---
  handleBack() {
    this.goBack();
  }

  @track isSubmitting = false;

  /** A locked wizard was submitted already: Submit is not offered again, and Back is the wizard's */
  get showOwnButtons() {
    return !isLockedState(this.state);
  }

  /**
   * A locked wizard was submitted already and is only looked at: a new one is started on a clean
   * page (the remembered Id and the Id in the URL are gone)
   */
  startNew() {
    clearStoredWizardId(this.wizardType);
    window.location.assign(window.location.pathname);
  }

  @track submitError = null;

  async handleSubmit() {
    if (!this.isAgreeGdprChecked) {
      this.localErrors = {
        complaintAgreeGdpr: this._l.Wizard_err_required_field
      };
      return;
    }
    this.localErrors = {}; // Clear any existing errors

    this.isSubmitting = true;
    // the wizard waits too: no move, no refresh of its own while the submit runs
    this.uiLock(true);
    this.submitError = null;
    try {
      const complaintId = await submitComplaint({
        wizardId: this.wizardId,
        agreedToGdpr: this.complaintAgreeGdpr
      });
      console.log("Complaint submitted successfully, ID:", complaintId);
    } catch (error) {
      console.error("Error submitting complaint:", error);
      // the server's message, wherever the platform put it (body.message, pageErrors, fieldErrors)
      this.submitError = errorMessage(error);
    } finally {
      this.isSubmitting = false;
      this.uiLock(false);
      // the wizard reads its state again: locked after the submit, or by a submit in another tab
      // when this one was refused. No answers with it (pageModel null): the tick is the submit's
      // own, not an answer a move saves, so the page keeps no draft and nothing is warned about
      this.refresh({ pageModel: null });
    }
  }
}
