import { api } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
const SESSION_KEYS = [
  "sessionM1",
  "sessionM2",
  "sessionM3",
  "sessionA1",
  "sessionA2",
  "sessionA3"
];

export default class ShowcaseSchedule extends WizardPageBase {
  @api prop1;

  @api prop2;

  // --- page data: one boolean per session slot ---
  data = {
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
}
