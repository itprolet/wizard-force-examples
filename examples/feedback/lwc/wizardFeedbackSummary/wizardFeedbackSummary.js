import { track } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
import submitFeedback from "@salesforce/apex/FeedbackController.submitFeedback";
import {
  L,
  clearStoredWizardId,
  errorMessage,
  isLockedState
} from "prolet/wizardUtils";

export default class WizardFeedbackSummary extends WizardPageBase {
  /** Expose imported labels to the template */
  labels = L;

  tableColumns = [
    { fieldName: "name", label: "Клиент", sortable: true },
    {
      fieldName: "amount",
      label: "Сума (лв.)",
      type: "number",
      align: "right",
      sortable: true
    },
    { fieldName: "date", label: "Дата", type: "date" },
    { fieldName: "active", label: "Активен", type: "boolean" },
    {
      fieldName: "status",
      label: "Статус",
      type: "chip",
      typeData: {
        chipItems: [
          { value: "нов", color: "var(--color-primary-default)" },
          { value: "активен", color: "var(--color-success)" },
          { value: "затворен", color: "var(--color-bgr-dark)" },
          { value: "грешка", color: "var(--color-error)" }
        ]
      }
    }
  ];

  tableData = [
    {
      name: "Иван Иванов",
      amount: 1250,
      date: "2024-03-15",
      active: true,
      status: "активен"
    },
    {
      name: "Мария Петрова",
      amount: 890,
      date: "2024-03-10",
      active: false,
      status: "затворен"
    },
    {
      name: "Георги Димитров",
      amount: 3400,
      date: "2024-04-01",
      active: true,
      status: "нов"
    },
    {
      name: "Петя Стоянова",
      amount: 120,
      date: "2024-02-28",
      active: true,
      status: "грешка"
    },
    {
      name: "Христо Николов",
      amount: 2100,
      date: "2024-03-22",
      active: false,
      status: "активен"
    }
  ];

  /** The GDPR tick: the submit's own, not an answer of the page (it is never sent as one) */
  feedbackAgreeGdpr = false;

  /** The page's own error (the tick is missing): not one of the wizard's rules */
  localErrors = {};

  /** The GDPR tick changed: kept here, it goes with the submit */
  handleAgree(event) {
    this.feedbackAgreeGdpr =
      (event.detail?.checked ?? event.target?.checked) === true;
  }

  get ratingData() {
    return this.model?.FeedbackRating || {};
  }

  get commentData() {
    return this.model?.FeedbackComment || {};
  }

  get recommendLabel() {
    return this.ratingData.wouldRecommend ? "Yes" : "No";
  }

  get isAgreeGdprChecked() {
    return this.feedbackAgreeGdpr === true;
  }

  handleBack() {
    this.goBack();
  }

  @track isSubmitting = false;

  /** A locked wizard was submitted already: Submit is not offered again, and Back is the wizard's */
  get showOwnButtons() {
    return !isLockedState(this.state);
  }

  /**
   * A locked wizard was submitted already and is only looked at: a new one is started on a clean
   * page (the remembered Id and the Id in the URL are gone)
   */
  startNew() {
    clearStoredWizardId(this.wizardType);
    window.location.assign(window.location.pathname);
  }

  @track submitError = null;

  async handleSubmit() {
    if (!this.isAgreeGdprChecked) {
      this.localErrors = {
        feedbackAgreeGdpr: this.labels.Wizard_err_required_field
      };
      return;
    }
    this.localErrors = {};

    this.isSubmitting = true;
    // the wizard waits too: no move, no refresh of its own while the submit runs
    this.uiLock(true);
    this.submitError = null;
    try {
      await submitFeedback({
        wizardId: this.wizardId,
        agreedToGdpr: this.feedbackAgreeGdpr
      });
    } catch (error) {
      // the server's message, wherever the platform put it (body.message, pageErrors, fieldErrors)
      this.submitError = errorMessage(error);
    } finally {
      this.isSubmitting = false;
      this.uiLock(false);
      // the wizard reads its state again: locked after the submit, or by a submit in another tab
      // when this one was refused. No answers with it (pageModel null): the tick is the submit's
      // own, not an answer a move saves, so the page keeps no draft and nothing is warned about
      this.refresh({ pageModel: null });
    }
  }
}
