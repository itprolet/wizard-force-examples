import { LightningElement, api, track } from "lwc";

export default class VacationSummary extends LightningElement {
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
  @track data = {};
  get details() {
    return this.model?.VacationDetails || {};
  }

  get sickNote() {
    return this.model?.VacationSickNote || {};
  }

  get isSick() {
    return this.details.type === "sick";
  }

  get typeLabel() {
    const labels = {
      paid: "Paid leave",
      unpaid: "Unpaid leave",
      sick: "Sick leave"
    };
    return labels[this.details.type];
  }

  // ===== PART 3: talking to the wizard (same on every page) =====
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
