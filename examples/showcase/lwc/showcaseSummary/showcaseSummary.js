import { api, track } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
import {
  clearStoredWizardId,
  errorMessage,
  isLockedState
} from "prolet/wizardUtils";
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

export default class ShowcaseSummary extends WizardPageBase {
  @api prop1;

  @api prop2;

  /** The GDPR tick: the submit's own, not an answer of the page (it is never sent as one) */
  agreeGdpr = false;

  /** The page's own error (the tick is missing): not one of the wizard's rules */
  localErrors = {};

  /** The GDPR tick changed: kept here, it goes with the submit */
  handleAgree(event) {
    this.agreeGdpr = (event.detail?.checked ?? event.target?.checked) === true;
  }

  @track isSubmitting = false;

  /** Submitted in this visit */
  @track submitted = false;

  /** Submitted now, or before: a locked wizard (any state but ACTIVE) is not submitted again */
  get isSubmitted() {
    return this.submitted || isLockedState(this.state);
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

  // --- cross-page data getters ---
  get eventTypeData() {
    return this.model?.ShowcaseEventType || {};
  }

  get scheduleData() {
    return this.model?.ShowcaseSchedule || {};
  }

  get preferencesData() {
    return this.model?.ShowcasePreferences || {};
  }

  get contactData() {
    return this.model?.ShowcaseContact || {};
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
    return this.agreeGdpr === true;
  }

  // --- submit button label ---
  get submitLabel() {
    return this.isSubmitting
      ? this._l.Showcase_act_submitting || "Submitting…"
      : this._l.Showcase_act_submit || "Submit Registration";
  }

  // --- navigationByChild handlers ---
  handleBack() {
    this.goBack();
  }

  async handleSubmit() {
    if (!this.isGdprChecked) {
      this.localErrors = {
        agreeGdpr: "You must agree to the processing of your personal data."
      };
      return;
    }
    this.localErrors = {};
    this.isSubmitting = true;
    // the wizard waits too: no move, no refresh of its own while the submit runs
    this.uiLock(true);
    this.submitError = null;
    try {
      await submitShowcase({ wizardId: this.wizardId });
      this.submitted = true;
    } catch (e) {
      this.submitError =
        errorMessage(e) || "An unexpected error occurred. Please try again.";
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
