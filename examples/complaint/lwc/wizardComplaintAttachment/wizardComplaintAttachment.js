import { api } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
export default class WizardComplaintAttachment extends WizardPageBase {
  @api prop1;

  @api prop2;

  data = {
    invoiceNumber: null,
    disputedAmount: null
  };
}
