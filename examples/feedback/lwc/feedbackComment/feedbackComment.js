import { api } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
export default class FeedbackComment extends WizardPageBase {
  data = {
    comment: "",
    email: ""
  };

  @api prop1;
}
