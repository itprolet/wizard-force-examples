import { LightningElement } from "lwc";
import WizardComplaintCategory from "c/wizardComplaintCategory";
import WizardComplaintDetails from "c/wizardComplaintDetails";
import WizardComplaintAttachment from "c/wizardComplaintAttachment";
import WizardComplaintContact from "c/wizardComplaintContact";
import WizardComplaintSummary from "c/wizardComplaintSummary";
import { L } from "./labels";

export default class ComplaintWizardRegistry extends LightningElement {
  _pageRegistry = {
      WizardComplaintCategory,
      WizardComplaintDetails,
      WizardComplaintAttachment,
      WizardComplaintContact,
      WizardComplaintSummary
  };

  _labelRegistry = L;
}
