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

// right for `color`, but in a custom property they mean "no value": the buttons would have no color
const CSS_WIDE_KEYWORDS = [
  "initial",
  "inherit",
  "unset",
  "revert",
  "revert-layer"
];

/** Every bracket is closed, and none is closed before it is opened */
function bracketsClosed(text) {
  let depth = 0;
  for (const char of text) {
    if (char === "(") {
      depth++;
    } else if (char === ")" && --depth < 0) {
      return false;
    }
  }
  return depth === 0;
}

/**
 * The color, or the default when it is not a plain CSS color. On App pages the colors are free
 * text, and the wizard writes them into an inline style: "8dc8ff" or "sky" would leave the buttons
 * without a color, and a ";", an open bracket or comment would change the rest of the style.
 * CSS.supports alone is not enough: it closes an open bracket or comment itself, and says yes to
 * the keywords and to var(), env() and attr(). Where CSS.supports is missing, the default is used.
 */
function cssColor(value, fallback) {
  const text = typeof value === "string" ? value.trim() : "";
  if (
    !text ||
    /[;{}!"'\\]|\/\*|\b(?:var|env|attr)\(/i.test(text) ||
    CSS_WIDE_KEYWORDS.includes(text.toLowerCase()) ||
    !bracketsClosed(text)
  ) {
    return fallback;
  }
  const supported =
    typeof CSS !== "undefined" &&
    typeof CSS.supports === "function" &&
    CSS.supports("color", text);
  return supported ? text : fallback;
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
