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

/**
 * The color, or the default when it is not a CSS color. On App pages the colors are free text,
 * and <c-wizard> writes them into an inline style: "8dc8ff" or "sky" would leave the buttons
 * without a color, and a ";" would add declarations of its own.
 */
function cssColor(value, fallback) {
  if (!value) {
    return fallback;
  }
  // CSS.supports is in every browser; the check is skipped only where it is missing (Jest)
  // eslint-disable-next-line no-undef
  const css = typeof CSS === "undefined" ? null : CSS;
  return !css?.supports || css.supports("color", value) ? value : fallback;
}

export default class FeedbackWizardRegistry extends LightningElement {
  _pageRegistry = {
    FeedbackRating,
    FeedbackComment,
    WizardFeedbackSummary
  };

  _validatorRegistry = { validateFeedbackEmail };

  // the look of the wizard; App Builder and Experience Builder can change them
  @api primaryColor = PRIMARY_COLOR;
  @api secondaryColor = SECONDARY_COLOR;
  @api shape = SHAPE;

  get wizardPrimaryColor() {
    return cssColor(this.primaryColor, PRIMARY_COLOR);
  }

  get wizardSecondaryColor() {
    return cssColor(this.secondaryColor, SECONDARY_COLOR);
  }
}
