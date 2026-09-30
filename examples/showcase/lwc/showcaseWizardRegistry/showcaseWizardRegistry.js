import { LightningElement } from "lwc";
import ShowcaseEventType from "c/showcaseEventType";
import ShowcaseSchedule from "c/showcaseSchedule";
import ShowcasePreferences from "c/showcasePreferences";
import ShowcaseContact from "c/showcaseContact";
import ShowcaseSummary from "c/showcaseSummary";
import { validateShowcaseEmail } from "c/validatorShowcaseEmail";
import { validateSessionMin } from "c/validatorShowcaseSession";
import { L } from "./labels";

export default class ShowcaseWizardRegistry extends LightningElement {
  _pageRegistry = {
    ShowcaseEventType,
    ShowcaseSchedule,
    ShowcasePreferences,
    ShowcaseContact,
    ShowcaseSummary
  };

  // validateShowcaseEmail  → field validator  (used in Rules: validators.email)
  // validateSessionMin     → page validator   (used in Rules: pageValidators)
  _validatorRegistry = { validateShowcaseEmail };
  _pageValidatorRegistry = { validateSessionMin };

  // Labels are passed to each page component via the `l` prop.
  // Only Contact and Summary use them; other pages use hardcoded strings
  // to illustrate both approaches side by side.
  _labelRegistry = L;
}
