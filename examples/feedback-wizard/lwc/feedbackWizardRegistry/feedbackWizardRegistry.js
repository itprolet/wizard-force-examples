import { LightningElement, api } from "lwc";
import FeedbackRating from "c/feedbackRating";
import FeedbackComment from "c/feedbackComment";
import WizardFeedbackSummary from "c/wizardFeedbackSummary";
import { validateFeedbackEmail } from "c/validatorFeedbackEmail";

export default class FeedbackWizardRegistry extends LightningElement {
  _pageRegistry = {
    FeedbackRating,
    FeedbackComment,
    WizardFeedbackSummary
  };

  _validatorRegistry = { validateFeedbackEmail };

  @api primaryColor;
  @api secondaryColor;
  @api shape;
}
