import { LightningElement, api, track } from "lwc";

/**
 * Reference page LWC for the embedded / single-page wizard pattern.
 *
 * Renders with the framework's custom inputs (c-input-text, c-input-button) so the
 * styling matches the rest of the wizard. Custom inputs dispatch their change on
 * every keystroke as { detail: { name, value } }, which changeHandler reads directly.
 *
 * Uses the same @api contract as any other wizard page. What changes for embedded mode:
 *   - dispatchPageChange uses bubbles + composed so the wizard hears the event reliably
 *     across any registry wrapper or shadow boundary introduced by the embedder.
 *   - The page renders its own submit button. On click it signals completion through
 *     the `action` event channel ({ action: 'complete' }) which the wizard flushes
 *     any pending save against and re-dispatches as `wizardcomplete`.
 *
 * The framework still owns validation: `required` and the regex `patterns` declared in
 * Wizard_Setup.EmbeddedContact.md run on every dispatch, and `errors[name]` is delivered
 * back via the @api props so we can paint field-level messages.
 */
export default class EmbeddedContactForm extends LightningElement {
  @api wizardId;
  @api title;
  @api page;
  @api l;
  @api wizardType;
  @api currentId;

  _model;
  @api get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
    if (val) {
      const pageModel = val[this.page];
      if (pageModel) {
        Object.keys(pageModel).forEach((key) => {
          if (Object.prototype.hasOwnProperty.call(this.data, key)) {
            this.data[key] = pageModel[key];
          }
        });
      }
    }
  }

  @api patterns;
  @api required;
  @api errors;
  @api readOnly;
  @api visible;
  @api hints;

  @track data = {
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

  changeHandler(event) {
    // Custom inputs (c-input-text) emit { detail: { name, value } }.
    const { name, value } = event.detail;
    this.data[name] = value;
    this.dispatchPageChange(name);
  }

  @api
  processChange(name) {
    // Optional hook called after each field-level validation pass.
    // Use it to react to errors[name] — focus shifts, inline hints, etc.
  }

  @api
  handlePage() {
    // navigationByChild === true: the wizard never calls this for next/prev because
    // its own buttons are hidden. Kept for parity with the contract.
  }

  // bubbles + composed so the wizard hears the event even when the registry wraps
  // the page in extra elements or a shadow boundary sits between them.
  dispatchPageChange(action) {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: action, pageModel: { ...this.data } },
        bubbles: true,
        composed: true
      })
    );
  }

  submitHandler() {
    this.dispatchEvent(
      new CustomEvent("action", {
        detail: { action: "complete" },
        bubbles: true,
        composed: true
      })
    );
  }
}
