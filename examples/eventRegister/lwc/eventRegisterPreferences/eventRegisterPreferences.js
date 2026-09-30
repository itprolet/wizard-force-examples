import { LightningElement, api, track } from 'lwc';

export default class EventRegisterPreferences extends LightningElement {
             // ===== PART 1: what the wizard gives the page (same on every page) =====
  @api wizardId;
  @api title;
  @api page;
  @api l;
  @api wizardType;
  @api currentId;
  @api patterns;
  @api readOnly;
  @api visible;
  @api hints;

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

  // ===== PART 2: this page's own things (the only part that changes) =====
  @track data = {
    tshirtSize: null,
    dietary: null,
    dietaryDetails: null,
    bringGuest: false,
    guestName: null
  };

  get tshirtSizeOptions() {
    return [
      { label: "S", value: "10" },
      { label: "M", value: "20" },
      { label: "L", value: "30" },
      { label: "XL", value: "40" }
    ];
  }

  get dietaryOptions() {
    return [
      { label: "None", value: "none" },
      { label: "Vegetarian", value: "vegetarian" },
      { label: "Vegan", value: "vegan" },
      { label: "Other", value: "other" }
    ];
  }

  get isBringGuest() {
    return this.data.bringGuest === true;
  }

  get isOther() {
    return this.data.dietary === "other";
  }

  // ===== PART 3: talking to the wizard (same on every page) =====
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