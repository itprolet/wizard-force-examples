import { LightningElement } from "lwc";
import EmbeddedContactForm from "c/embeddedContactForm";
import { validateEmbeddedEmail } from "c/validatorEmbeddedEmail";

/**
 * Reference registry for the embedded wizard pattern.
 *
 * Registers the single page LWC and listens for the wizard's bubbled `wizardcomplete`
 * event. The framework persists field changes through saveOnChange on its own; the
 * embedder only needs to react to "the user is done".
 *
 * handleComplete is intentionally left as a neutral hook — the single-page layout is a
 * generic pattern, not a contact form, so there is no built-in confirmation UI. Wire up
 * whatever finalization the use case needs here (confirmation, subscriber Apex,
 * navigation, ...). event.detail carries { wizardId, wizardType, model, ... }.
 */
export default class EmbeddedFormRegistry extends LightningElement {
  _pageRegistry = {
    EmbeddedContactForm
  };

  // Custom field validators referenced by name from Wizard_Setup.EmbeddedContact Rules__c.
  _validatorRegistry = { validateEmbeddedEmail };

  // eslint-disable-next-line no-unused-vars
  handleComplete(event) {
    // No-op for now — add finalization per use case.
  }
}
