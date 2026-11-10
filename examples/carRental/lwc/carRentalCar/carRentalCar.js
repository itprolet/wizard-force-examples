import { LightningElement, api, track } from "lwc";

/**
 * Car page of the carRental wizard.
 * Page name (registry key, Plan, Rules, saved answers): CarRentalCar
 */
export default class CarRentalCar extends LightningElement {
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

  // ===== PART 2: this page's own things. WIZARD-MAKER: edit here =====
  // One key per field (name="..." in the HTML). The values are saved in model.CarRentalCar.
  @track data = {
    pickupCity: null,
    carClass: null,
    pickupDate: null,
    days: null,
    fullInsurance: false,
    luxuryNotes: null,
    bookedThrough: null,
    bookedThroughName: null,
    carModel: null,
    carModelName: null
  };

  get pickupCityOptions() {
    return [
      { label: this._l.CarRental_opt_car_pickupCity_sofia, value: "sofia" },
      { label: this._l.CarRental_opt_car_pickupCity_plovdiv, value: "plovdiv" },
      { label: this._l.CarRental_opt_car_pickupCity_varna, value: "varna" }
    ];
  }

  get carClassOptions() {
    return [
      { label: this._l.CarRental_opt_car_carClass_economy, value: "economy" },
      { label: this._l.CarRental_opt_car_carClass_suv, value: "suv" },
      { label: this._l.CarRental_opt_car_carClass_luxury, value: "luxury" }
    ];
  }

  /** "Full Insurance" is shown only if (carClass='luxury'). Change the condition in prolet__Rules__c, not here. */
  get showFullInsurance() {
    return this.visible?.fullInsurance !== false;
  }

  /** "Luxury Notes" is shown only if (carClass='luxury'). Change the condition in prolet__Rules__c, not here. */
  get showLuxuryNotes() {
    return this.visible?.luxuryNotes !== false;
  }

  /** "Booked Through": saves the record Id and its name (the name shows the choice again after Back) */
  bookedThroughSelected(event) {
    const { selectedId, selectedName } = event.detail;
    this.data.bookedThrough = selectedId || null;
    this.data.bookedThroughName = selectedName || null;
    this.dispatchPageChange("bookedThrough");
  }

  /** "Car Model": saves the record Id and its name (the name shows the choice again after Back) */
  carModelSelected(event) {
    const { selectedId, selectedName } = event.detail;
    this.data.carModel = selectedId || null;
    this.data.carModelName = selectedName || null;
    this.dispatchPageChange("carModel");
  }

  // WIZARD-MAKER examples: uncomment and adapt what you need.
  //
  // Show a field only when another field has a certain value ("npm run make page" → add fields
  // does this for you). The condition is written once, in prolet__Rules__c:
  // Rules: "if (myChoice='other')":      { "required": ["otherDetails"] },
  //        "if (not(myChoice='other'))": { "hidden":   ["otherDetails"] }
  // HTML:  <template lwc:if={showOtherDetails}> …the field… </template>
  // get showOtherDetails() {
  //   return this.visible?.otherDetails !== false;
  // }
  //
  // Read an answer from another page (use that page's name from the registry):
  // get answerFromOtherPage() {
  //   return this.model?.OtherPageName?.someField;
  // }
  //
  // Today as "YYYY-MM-DD", e.g. min={today} on a date field to block past dates:
  // get today() {
  //   return new Date().toISOString().slice(0, 10);
  // }

  // ===== PART 3: talking to the wizard. WIZARD-MAKER: don't change =====
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    let value = event.detail.value ?? event.detail.checked ?? null;
    // Number fields are saved as real numbers, so Rules like "if (quantity > 1)" work
    if (["days"].includes(name) && value !== null && value !== "") {
      value = Number(value);
    }
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
