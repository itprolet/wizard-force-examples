import { LightningElement, api } from "lwc";
import FeedbackRating from "c/feedbackRating";
import FeedbackComment from "c/feedbackComment";
import WizardFeedbackSummary from "c/wizardFeedbackSummary";
import { validateFeedbackEmail } from "c/validatorFeedbackEmail";
import { cssColor } from "prolet/wizardUtils";

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
  // colors are free text: one that is not a plain CSS color (a typo, an empty field) gives the
  // example's own default, not the framework's
  @api primaryColor = PRIMARY_COLOR;
  @api secondaryColor = SECONDARY_COLOR;
  @api shape = SHAPE;

  get wizardPrimaryColor() {
    return cssColor(this.primaryColor) ?? PRIMARY_COLOR;
  }

  get wizardSecondaryColor() {
    return cssColor(this.secondaryColor) ?? SECONDARY_COLOR;
  }
}
