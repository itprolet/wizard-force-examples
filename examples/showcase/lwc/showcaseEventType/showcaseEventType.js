import { LightningElement, api, track } from "lwc";

const EVENT_TYPE_OPTIONS = [
  { label: "Online (virtual)", value: "online" },
  { label: "In-Person", value: "in-person" },
  { label: "Hybrid", value: "hybrid" }
];

export default class ShowcaseEventType extends LightningElement {
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
  @track data = { eventType: null };

  // --- options ---
  get eventTypeOptions() {
    return EVENT_TYPE_OPTIONS;
  }

  // --- conditional rendering ---
  get isHybrid() {
    return this.data.eventType === "hybrid";
  }
  get isTypeSelected() {
    return !!this.data.eventType;
  }

  // --- change handler ---
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? null;
    this.data = { ...this.data, [name]: value };
    this.dispatchPageChange(name);
  }

  @api processChange(name) {
    console.log(name);
  }

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
