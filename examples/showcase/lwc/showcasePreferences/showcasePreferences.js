import { LightningElement, api, track } from "lwc";

const DIETARY_OPTIONS = [
  { label: "No restriction", value: "none" },
  { label: "Vegetarian", value: "vegetarian" },
  { label: "Vegan", value: "vegan" },
  { label: "Gluten-free", value: "gluten-free" }
];

const SHIRT_SIZES = ["XS", "S", "M", "L", "XL", "XXL"].map((s) => ({
  label: s,
  value: s
}));

const ACCOMMODATION_OPTIONS = [
  { label: "No accommodation needed", value: "none" },
  { label: "Single room", value: "single" },
  { label: "Double room (shared)", value: "double" }
];

export default class ShowcasePreferences extends LightningElement {
  @api wizardId;
  @api title;
  @api page;
  @api l;
  @api wizardType;
  @api currentId;
  @api prop1;
  @api prop2;

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
        const parsed = JSON.parse(JSON.stringify(this.data));
        Object.keys(pageModel).forEach((key) => {
          if (Object.prototype.hasOwnProperty.call(this.data, key)) {
            parsed[key] = pageModel[key];
          }
        });
        this.data = parsed;
      }
    }
  }

  // --- framework props ---
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
  @api patterns;
  @api hints;

  // --- page data ---
  @track data = {
    dietaryOption: null,
    shirtSize: null,
    accommodation: "none",
    shuttle: false
  };

  // --- options ---
  get dietaryOptions() {
    return DIETARY_OPTIONS;
  }
  get shirtSizeOptions() {
    return SHIRT_SIZES;
  }
  get accommodationOptions() {
    return ACCOMMODATION_OPTIONS;
  }

  // --- conditional ---
  get isAccommodationBooked() {
    return this.data.accommodation && this.data.accommodation !== "none";
  }

  // --- change handler ---
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data = { ...this.data, [name]: value };
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
