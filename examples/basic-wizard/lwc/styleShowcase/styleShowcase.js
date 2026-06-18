import { LightningElement } from "lwc";

export default class StyleShowcase extends LightningElement {
  tabValue = "tab1";

  comboItems = [
    { value: "opt1", label: "Опция едно" },
    { value: "opt2", label: "Опция две" },
    { value: "opt3", label: "Опция три" }
  ];

  mockPages = [
    { page: "page1", active: false, title: "Лични данни" },
    { page: "page2", active: false, title: "Контакти" },
    { page: "page3", active: true, title: "Преглед" },
    { page: "page4", active: false, title: "Потвърждение" }
  ];

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

  get sharpStyle() {
    return [
      "--wizard-shape-input: 6px",
      "--border-input-radius: 6px",
      "--wizard-shape-button: 8px",
      "--border-button-radius: 8px",
      "--wizard-shape-step: 30%",
      "--border-step-radius: 30%",
      "--wizard-shape-box: 4px",
      "--border-box-radius: 4px"
    ].join("; ");
  }

  handleTabChange(event) {
    this.tabValue = event.detail.value;
  }

  showToastError() {
    this.refs.toast.show("Грешка при запазване!", "error");
  }
  showToastSuccess() {
    this.refs.toast.show("Записано успешно!", "success");
  }
  showToastWarning() {
    this.refs.toast.show("Предупреждение!", "warning");
  }

  showToastErrorSharp() {
    this.refs.toastSharp.show("Грешка при запазване!", "error");
  }
  showToastSuccessSharp() {
    this.refs.toastSharp.show("Записано успешно!", "success");
  }
  showToastWarningSharp() {
    this.refs.toastSharp.show("Предупреждение!", "warning");
  }
}
