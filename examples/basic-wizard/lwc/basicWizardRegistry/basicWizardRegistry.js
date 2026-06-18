import { LightningElement, api } from "lwc";
import WizardPage1 from "c/wizardPage1";
import WizardPage2 from "c/wizardPage2";
import WizardPage3 from "c/wizardPage3";
import { registerPage } from "c/wizardUtils";

/**
 * Registers the basic wizard example pages with the framework's runtime page
 * registry, then renders <c-wizard> with the configured type.
 *
 * In Experience Cloud the wizardType comes from the URL and this prop can be
 * left blank. On Lightning App / Home / Record pages, set this from App
 * Builder (or the FlexiPage XML) so the wizard knows which type to load.
 */
export default class BasicWizardRegistry extends LightningElement {
  /** Wizard type developer name (e.g. "TEST") forwarded to <c-wizard>. */
  @api wizardTypeConfig;

  connectedCallback() {
    registerPage("WizardPage1", WizardPage1);
    registerPage("WizardPage2", WizardPage2);
    registerPage("WizardPage3", WizardPage3);
  }
}
