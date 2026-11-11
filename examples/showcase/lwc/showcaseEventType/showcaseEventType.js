import { api } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
const EVENT_TYPE_OPTIONS = [
  { label: "Online (virtual)", value: "online" },
  { label: "In-Person", value: "in-person" },
  { label: "Hybrid", value: "hybrid" }
];

export default class ShowcaseEventType extends WizardPageBase {
  @api prop1;

  @api prop2;

  // --- page data ---
  data = { eventType: null };

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
}
