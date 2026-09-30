import { LightningElement, api, track } from "lwc";

const SESSION_KEYS = [
  "sessionM1",
  "sessionM2",
  "sessionM3",
  "sessionA1",
  "sessionA2",
  "sessionA3"
];

export default class ShowcaseSchedule extends LightningElement {
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
        SESSION_KEYS.forEach((key) => {
          if (pageModel[key] !== undefined) parsed[key] = pageModel[key];
        });
        this.data = parsed;
      }
    }
  }

  // --- framework props ---
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

  @api required;
  @api visible;
  @api patterns;
  @api hints;

  // --- page data: one boolean per session slot ---
  @track data = {
    sessionM1: false,
    sessionM2: false,
    sessionM3: false,
    sessionA1: false,
    sessionA2: false,
    sessionA3: false
  };

  // --- tab state ---
  activeTab = "morning";

  handleTabChange(event) {
    this.activeTab = event.detail.value;
  }

  // --- computed ---
  get selectedCount() {
    return SESSION_KEYS.filter((k) => this.data[k] === true).length;
  }

  // --- change handler ---
  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.checked ?? false;
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
