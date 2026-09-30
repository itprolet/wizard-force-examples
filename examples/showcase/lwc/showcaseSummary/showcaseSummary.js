import { LightningElement, api, track } from "lwc";
import submitShowcase from "@salesforce/apex/ShowcaseController.submitShowcase";

// All available sessions — used to build the datatable from the boolean flags in the model.
const ALL_SESSIONS = [
  {
    key: "sessionM1",
    time: "09:00",
    title: "Opening Keynote",
    trackName: "Morning"
  },
  {
    key: "sessionM2",
    time: "10:30",
    title: "Workshop A: LWC Fundamentals",
    trackName: "Morning"
  },
  {
    key: "sessionM3",
    time: "12:00",
    title: "Networking Lunch",
    trackName: "Morning"
  },
  {
    key: "sessionA1",
    time: "14:00",
    title: "Panel: The Future of Salesforce",
    trackName: "Afternoon"
  },
  {
    key: "sessionA2",
    time: "15:30",
    title: "Workshop B: Apex Best Practices",
    trackName: "Afternoon"
  },
  {
    key: "sessionA3",
    time: "17:00",
    title: "Closing Keynote & Awards",
    trackName: "Afternoon"
  }
];

const EVENT_TYPE_LABELS = {
  online: "Online (virtual)",
  "in-person": "In-Person",
  hybrid: "Hybrid"
};

export default class ShowcaseSummary extends LightningElement {
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

  // Summary reads the full model, not just its own page namespace
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

  @track data = { agreeGdpr: false };
  @track isSubmitting = false;
  @track isSubmitted = false;
  @track submitError = null;

  // --- cross-page data getters ---
  get eventTypeData() {
    return this._model?.ShowcaseEventType || {};
  }
  get scheduleData() {
    return this._model?.ShowcaseSchedule || {};
  }
  get preferencesData() {
    return this._model?.ShowcasePreferences || {};
  }
  get contactData() {
    return this._model?.ShowcaseContact || {};
  }

  // --- labels ---
  get eventTypeLabel() {
    return (
      EVENT_TYPE_LABELS[this.eventTypeData.eventType] ||
      this.eventTypeData.eventType ||
      "—"
    );
  }

  get shuttleLabel() {
    return this.preferencesData.shuttle ? "Requested" : "Not requested";
  }

  // --- conditional section rendering ---
  get hasPreferences() {
    return (
      !!this.preferencesData.dietaryOption || !!this.preferencesData.shirtSize
    );
  }

  // --- datatable ---
  get sessionColumns() {
    return [
      { fieldName: "time", label: "Time", align: "left" },
      { fieldName: "title", label: "Session", align: "left" },
      { fieldName: "trackName", label: "Track", align: "center" }
    ];
  }

  get sessionData() {
    const schedule = this.scheduleData;
    return ALL_SESSIONS.filter((s) => schedule[s.key] === true).map(
      ({ time, title, trackName }) => ({ time, title, trackName })
    );
  }

  // --- GDPR ---
  get isGdprChecked() {
    return this.data.agreeGdpr === true;
  }

  // --- submit button label ---
  get submitLabel() {
    return this.isSubmitting
      ? this._l.Showcase_act_submitting || "Submitting…"
      : this._l.Showcase_act_submit || "Submit Registration";
  }

  // --- navigationByChild handlers ---
  handleBack() {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: "prev", pageModel: {} }
      })
    );
  }

  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.checked ?? false;
    this.data = { ...this.data, [name]: value };
  }

  async handleSubmit() {
    if (!this.isGdprChecked) {
      this._errors = {
        agreeGdpr: "You must agree to the processing of your personal data."
      };
      return;
    }
    this._errors = {};
    this.isSubmitting = true;
    this.submitError = null;
    try {
      await submitShowcase({ wizardId: this.wizardId });
      this.isSubmitted = true;
    } catch (e) {
      this.submitError =
        e?.body?.message || "An unexpected error occurred. Please try again.";
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

  @api processChange() {}
}
