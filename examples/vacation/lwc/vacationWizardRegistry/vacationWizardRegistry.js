import { LightningElement } from "lwc";
import VacationDetails from "c/vacationDetails";
import VacationSickNote from "c/vacationSickNote";
import VacationSummary from "c/vacationSummary";

export default class VacationWizardRegistry extends LightningElement {
  _pageRegistry = {
    VacationDetails,
    VacationSickNote,
    VacationSummary
  };
}
