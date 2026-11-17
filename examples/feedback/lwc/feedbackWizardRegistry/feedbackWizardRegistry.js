import { LightningElement, api } from "lwc";
import FeedbackRating from "c/feedbackRating";
import FeedbackComment from "c/feedbackComment";
import WizardFeedbackSummary from "c/wizardFeedbackSummary";
import { validateFeedbackEmail } from "c/validatorFeedbackEmail";

// The look of the example. The same defaults are written in both targetConfigs of
// feedbackWizardRegistry.js-meta.xml (a component dropped on a page takes those); change all three.
const PRIMARY_COLOR = "#8dc8ff";
const SECONDARY_COLOR = "#535857";
const SHAPE = "sharp";

export default class FeedbackWizardRegistry extends LightningElement {
  _pageRegistry = {
    FeedbackRating,
    FeedbackComment,
    WizardFeedbackSummary
  };

  _validatorRegistry = { validateFeedbackEmail };

  // the look of the wizard; App Builder and Experience Builder can change them. On App pages the
  // colors are free text: the wizard writes only a plain CSS color, else it keeps its default
  @api primaryColor = PRIMARY_COLOR;
  @api secondaryColor = SECONDARY_COLOR;
  @api shape = SHAPE;
}
