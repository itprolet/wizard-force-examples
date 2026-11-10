import { LightningElement } from "lwc";
import EmbeddedContactForm from "c/embeddedContactForm";
import { validateEmbeddedEmail } from "c/validatorEmbeddedEmail";

/**
 * Reference registry for the stateless single-page wizard pattern.
 *
 * Unlike the backend-driven examples, this registry supplies the wizard's entire
 * configuration from the client — plan, rules and the initial model — so the wizard
 * runs fully stateless: it creates no Wizard__c record, persists nothing and calls no
 * Apex. The `stateless: true` rule flag is what switches the wizard into this mode.
 *
 * The parent owns the data: it seeds the initial model and receives every field change
 * via `wizardchange` ({ model, page, pageModel, valid, errors }). Wire up whatever the
 * use case needs in handleChange — local state, a custom Apex submit, an event to a
 * sibling component, etc. There is no built-in persistence or confirmation UI.
 */
export default class EmbeddedFormRegistry extends LightningElement {
  _pageRegistry = {
    EmbeddedContactForm
  };

  // Custom field validators referenced by name from the rules below — run client-side.
  _validatorRegistry = { validateEmbeddedEmail };

  // Plan: page title (key) → page/component id (value). Single page for this form.
  _plan = {
    "Contact us": "EmbeddedContactForm"
  };

  // Rules keyed by page id. `stateless` + `hideProgress` + `navigationByChild` make this a
  // self-contained single-page form. required + validators still run client-side.
  _rules = {
    EmbeddedContactForm: {
      stateless: true,
      hideProgress: true,
      navigationByChild: true,
      required: ["name", "email", "message"],
      validators: {
        email: [
          {
            validator: "validateEmbeddedEmail",
            message: "Please enter a valid email address"
          }
        ]
      }
    }
  };

  // Initial model, namespaced under the page id.
  _initialModel = {
    EmbeddedContactForm: {
      name: "",
      email: "",
      message: ""
    }
  };

  // eslint-disable-next-line no-unused-vars
  handleChange(event) {
    // event.detail = { model, page, pageModel, valid, errors }
    // No-op reference hook — react to the model here per use case.
  }

  // eslint-disable-next-line no-unused-vars
  handleComplete(event) {
    // Optional — only fires if the page exposes an explicit submit button.
  }
}
