import { api } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
export default class FeedbackRating extends WizardPageBase {
  // ---- your page data model ----
  data = {
    rating: null,
    wouldRecommend: false
  };

  // custom page properties configured by wizard plan
  @api prop1;
}
