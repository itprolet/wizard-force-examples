import { LightningElement, api, track } from "lwc";
import submitFeedback from "@salesforce/apex/FeedbackController.submitFeedback";
import { L } from "c/wizardUtils";

export default class WizardFeedbackSummary extends LightningElement {
  /** Expose imported labels to the template */
  labels = L;
  @api wizardId;
  @api title;
  @api page;
  @api l;
  @api wizardType;
  @api currentId;

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

  get _l() {
    return this.l || {};
  }

  _model;
  @api get model() {
    return this._model;
  }
  set model(val) {
    this._model = val;
  }

  _errors;
  @api get errors() {
    return this._errors || {};
  }
  set errors(val) {
    this._errors = val;
  }

  @api readOnly;
  @api visible;
  @api patterns;
  @api required;
  @api hints;

  @track data = {
    feedbackAgreeGdpr: false
  };

  get ratingData() {
    return this._model?.FeedbackRating || {};
  }

  get commentData() {
    return this._model?.FeedbackComment || {};
  }

  get recommendLabel() {
    return this.ratingData.wouldRecommend ? "Yes" : "No";
  }

  get isAgreeGdprChecked() {
    return this.data.feedbackAgreeGdpr === true;
  }

  handleBack() {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: "prev", pageModel: {} }
      })
    );
  }

  changeHandler(event) {
    const name = event.detail?.name || event.currentTarget.dataset.name;
    const value = event.detail.value ?? event.detail.checked ?? null;
    this.data = {
      ...this.data,
      [name]: value
    };
  }

  @track isSubmitting = false;
  @track submitError = null;

  async handleSubmit() {
    if (!this.isAgreeGdprChecked) {
      this._errors = {
        feedbackAgreeGdpr: this.labels.Wizard_err_required_field
      };
      return;
    }
    this._errors = {};

    this.isSubmitting = true;
    this.submitError = null;
    try {
      await submitFeedback({
        wizardId: this.wizardId,
        agreedToGdpr: this.data.feedbackAgreeGdpr
      });
    } catch (error) {
      this.submitError = error.message;
    } finally {
      this.isSubmitting = false;
    }
  }

  @api handlePage(dir) {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { direction: dir, pageModel: {} }
      })
    );
  }

  @api processChange() {
    // summary page: no-op
  }
}
