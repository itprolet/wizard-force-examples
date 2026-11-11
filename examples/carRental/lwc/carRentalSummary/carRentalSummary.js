import { LightningElement, api, track } from "lwc";
import submit from "@salesforce/apex/CarRentalController.submit";
import {
  clearStoredWizardId,
  errorMessage,
  isLockedState,
  lockWizardUi
} from "prolet/wizardUtils";

/**
 * Summary page of the carRental wizard: shows the answers of all pages, read only.
 * Page name (registry key, Plan): CarRentalSummary
 *
 * WIZARD-MAKER: this file is generated from the pages. "npm run make summary" regenerates it
 * (e.g. after adding a page or a field) and replaces changes made by hand.
 */
/** The steps the Edit links go back to: the page, and its key in prolet__Plan__c. */
const STEP_KEYS = {
  CarRentalDriver: "CarRental_pag_driver",
  CarRentalCar: "CarRental_pag_car",
  CarRentalExtras: "CarRental_pag_extras",
  CarRentalInvoice: "CarRental_pag_invoice"
};

export default class CarRentalSummary extends LightningElement {
  // ===== PART 1: what the wizard gives the page. WIZARD-MAKER: don't change =====
  @api wizardId;
  @api title;
  @api page;
  @api l;
  /** The wizard's texts (Custom Labels), in the user's language: this._l.<label name> */
  get _l() {
    return this.l || {};
  }
  @api wizardType;
  @api currentId;
  @api state;

  _model;
  @api get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
    const pageModel = val ? val[this.page] : null;
    if (pageModel) {
      Object.keys(pageModel).forEach((key) => {
        if (Object.prototype.hasOwnProperty.call(this.data, key)) {
          this.data[key] = pageModel[key];
        }
      });
    }
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
  @api visible;
  @api hints;
  @api patterns;
  @api messages;
  // WIZARD-MAKER optional: uncomment when the HTML uses read-only / hint / pattern / message / hidden
  // get _readOnly() { return this.readOnly || {}; }
  // get _visible() { return this.visible || {}; }
  // get _hints() { return this.hints || {}; }
  // get _patterns() { return this.patterns || {}; }
  // get _messages() { return this.messages || {}; }

  // ===== PART 2: the answers of the pages. WIZARD-MAKER: generated =====
  @track data = {
    confirmed: false
  };
  isSubmitting = false;
  submittedId = null;
  submitError = null;

  /** Submitted now, or before: a locked wizard (any state but ACTIVE) is not submitted again */
  get isSubmitted() {
    return this.submittedId !== null || isLockedState(this.state);
  }

  /** Submit while its request runs: disabled, with a turning ring (see the summary's CSS) */
  get submitClass() {
    return `slds-button eh-button summary-button active${this.isSubmitting ? " busy" : ""}`;
  }

  get submitBusy() {
    return this.isSubmitting ? "true" : "false";
  }

  /** Edit is only offered while the answers can change: not once the wizard is locked */
  get canEdit() {
    return !this.isSubmitted;
  }

  /** Answers of the "Driver" page */
  get driver() {
    return this.model?.CarRentalDriver || {};
  }

  /** Answers of the "Car" page */
  get car() {
    return this.model?.CarRentalCar || {};
  }

  /** Answers of the "Extras and Notes" page */
  get extras() {
    return this.model?.CarRentalExtras || {};
  }

  /** Answers of the "Invoice" page */
  get invoice() {
    return this.model?.CarRentalInvoice || {};
  }

  /** "Edit" next to a step's answers: back to that step; the wizard keeps all the answers. */
  editStep(event) {
    const page = event.currentTarget.dataset.page;
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: {
          direction: { title: STEP_KEYS[page], page },
          pageModel: { ...this.data }
        }
      })
    );
  }

  /** "I drive more than 5 years": true / false → Yes / No */
  get driverExperiencedLabel() {
    return this.driver.experienced
      ? this._l.CarRental_msg_yes
      : this._l.CarRental_msg_no;
  }

  /** "Pickup City": the saved value → the text shown to the user */
  get carPickupCityLabel() {
    const labels = {
      sofia: this._l.CarRental_opt_car_pickupCity_sofia,
      plovdiv: this._l.CarRental_opt_car_pickupCity_plovdiv,
      varna: this._l.CarRental_opt_car_pickupCity_varna
    };
    return labels[this.car.pickupCity] ?? this.car.pickupCity;
  }

  /** "Car Class": the saved value → the text shown to the user */
  get carCarClassLabel() {
    const labels = {
      economy: this._l.CarRental_opt_car_carClass_economy,
      suv: this._l.CarRental_opt_car_carClass_suv,
      luxury: this._l.CarRental_opt_car_carClass_luxury
    };
    return labels[this.car.carClass] ?? this.car.carClass;
  }

  /** "Full Insurance": true / false → Yes / No */
  get carFullInsuranceLabel() {
    return this.car.fullInsurance
      ? this._l.CarRental_msg_yes
      : this._l.CarRental_msg_no;
  }

  /** "GPS navigation": true / false → Yes / No */
  get extrasGpsLabel() {
    return this.extras.gps
      ? this._l.CarRental_msg_yes
      : this._l.CarRental_msg_no;
  }

  /** Show "Luxury Notes" only when the page showed it. Rules: if (carClass='luxury') */
  get showCarLuxuryNotes() {
    return this.car.carClass === "luxury";
  }

  /** Show "Full Insurance" only when the page showed it. Rules: if (carClass='luxury') */
  get showCarFullInsurance() {
    return this.car.carClass === "luxury";
  }

  /** Show the "Extras and Notes" section only when the page was part of the wizard. Plan: if (CarRentalCar.days > 7) */
  get showExtras() {
    return Number(this.car.days) > 7;
  }

  /** Show the "Invoice" section only when the page was part of the wizard. Plan: if (CarRentalCar.carClass='luxury') */
  get showInvoice() {
    return this.car.carClass === "luxury";
  }

  // WIZARD-MAKER examples: uncomment and adapt what you need.
  //
  // Combine two answers into one line:
  // get fullName() {
  //   return [this.somePage.firstName, this.somePage.lastName].filter(Boolean).join(" ");
  // }
  //
  // Show a date in the user's format:
  // get startDateText() {
  //   const value = this.somePage.startDate;
  //   return value ? new Date(value).toLocaleDateString() : "";
  // }
  //
  // Show a section only when a checkbox on another page is checked:
  // get showGuest() {
  //   return this.somePage.bringGuest === true;
  // }

  // ===== PART 3: talking to the wizard. WIZARD-MAKER: don't change =====
  /** Saves the answers as a record (CarRentalController.submit in Apex). */
  async handleSubmit() {
    this.submitError = null;
    if (!this.data.confirmed) {
      this.submitError = this._l.CarRental_err_confirm;
      return;
    }
    this.isSubmitting = true;
    try {
      // the wizard waits too: no move, no refresh of its own while the submit runs. Inside the
      // try: if it fails, the user gets the message and the button back, not a page that hangs
      lockWizardUi(this, true);
      this.submittedId = await submit({
        wizardId: this.wizardId,
        confirmed: this.data.confirmed
      });
      // tells the wizard (and a page that embeds it) that the wizard is done
      this.dispatchEvent(
        new CustomEvent("action", {
          detail: { action: "complete", recordId: this.submittedId }
        })
      );
    } catch (error) {
      this.submitError = errorMessage(error) || this._l.CarRental_err_submit;
    } finally {
      this.isSubmitting = false;
      lockWizardUi(this, false);
      // the wizard reads its state again: locked after the submit, or by a submit in another tab
      // when this one was refused. No answers with it (pageModel null): the tick is the submit's
      // own, not an answer a move saves, so the page keeps no draft and nothing is warned about
      this.dispatchEvent(
        new CustomEvent("pagechange", {
          detail: { direction: "refresh", pageModel: null }
        })
      );
    }
  }

  handleBack() {
    this.dispatchPageChange("prev");
  }

  /** Removes this wizard's Id from the browser memory, so the next visit starts a new wizard. */
  forgetWizard() {
    clearStoredWizardId(this.wizardType);
  }

  /** Starts again with an empty wizard (the page is loaded without the old wizard Id). */
  startNew() {
    this.forgetWizard();
    window.location.assign(window.location.pathname);
  }

  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data[name] = value;
    this.dispatchPageChange(name);
  }

  @api processChange() {}

  @api handlePage(dir) {
    this.dispatchPageChange(dir);
  }

  dispatchPageChange(action) {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: action, pageModel: { ...this.data } }
      })
    );
  }
}
