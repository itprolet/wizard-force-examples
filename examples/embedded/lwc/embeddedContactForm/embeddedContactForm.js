import WizardPageBase from "prolet/wizardPageBase";

/**
 * Reference page LWC for the embedded / single-page wizard pattern, made on c/wizardPageBase.
 *
 * Renders with the framework's custom inputs (c-input-text, c-input-button) so the
 * styling matches the rest of the wizard. Custom inputs dispatch their change on
 * every keystroke as { detail: { name, value } }: the base's handleChange writes the answer
 * and tells the wizard, which checks it and sends `wizardchange` to the embedder.
 *
 * The same contract as any other wizard page (the base). What is its own in stateless mode:
 *   - its own submit button signals completion with the base's complete() (the `action`
 *     event { action: 'complete' }), which the wizard re-dispatches as `wizardcomplete`.
 *     Not required: the parent can also finalize off `wizardchange`.
 *
 * The framework still owns validation: `required` and the regex `patterns` / `validators`
 * declared in the rules the parent passes (embeddedFormRegistry) run on every dispatch, and
 * `errors[name]` is delivered back via the @api props so we can paint field-level messages.
 */
export default class EmbeddedContactForm extends WizardPageBase {
  data = {
    name: "",
    email: "",
    message: ""
  };

  get nameError() {
    return this.errors?.name;
  }
  get emailError() {
    return this.errors?.email;
  }
  get messageError() {
    return this.errors?.message;
  }
  get isSubmitDisabled() {
    return !(
      this.data.name &&
      this.data.email &&
      this.data.message &&
      !this.nameError &&
      !this.emailError &&
      !this.messageError
    );
  }

  submitHandler() {
    this.complete();
  }
}
