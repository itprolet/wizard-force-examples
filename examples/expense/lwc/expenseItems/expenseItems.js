import ExpensePageBase from "c/expensePageBase";

const TYPES = ["transport", "hotel", "meals", "taxi", "other"];
const EDIT_FIELDS = ["type", "date", "amount", "receiptNumber"];
const EMPTY_EDIT = {
  id: null,
  type: null,
  date: null,
  amount: null,
  receiptNumber: null
};
/** Review data keys: `expenses[id=e1].amount` (change a field) or `expenses[id=e2]` (delete the item) */
const REVIEW_KEY = /^expenses\[id=(.+?)\](?:\.(\w+))?$/;

/**
 * Page 3 - Expenses.
 *
 * Page model:
 *   expenses: [{ id, type, date, amount, receiptNumber }]  - the list (ids and amounts are STRINGS,
 *                                                            review mode compares them with ===)
 *   edit:     { id, type, date, amount, receiptNumber }    - the form above the table
 *
 * Rules: required ["expenses"] (empty list blocks Next), page validator ValidateExpenseLimit (JS + Apex),
 * pageFieldMapping { expenses: { amount: "edit.amount", ... } }.
 *
 * Review mode: the manager can ask to change the amount of an item or to delete an item.
 *   - Only those rows get enabled edit / delete icons (read from `reviewData`).
 *   - When a requested item is loaded into `edit`, pageFieldMapping tells the framework that
 *     `expenses[id=x].amount` is edited through `edit.amount`, so it unlocks that form field
 *     and marks it "Change required" until the value differs from the old one.
 */
export default class ExpenseItems extends ExpensePageBase {
  defaults() {
    return { expenses: [], edit: { ...EMPTY_EDIT } };
  }

  /** Errors of the add/edit form that are checked locally (not by the rules). */
  localErrors = {};

  // ---- options / labels ----
  get typeOptions() {
    return TYPES.map((value) => ({ label: this.typeLabel(value), value }));
  }
  typeLabel(value) {
    return this._l[`Expense_opt_${value}`] || value;
  }
  get isEditing() {
    return !!this.data.edit?.id;
  }
  get formTitle() {
    return this.isEditing
      ? this._l.Expense_msg_editing
      : this._l.Expense_act_add;
  }
  get saveLabel() {
    return this.isEditing ? this._l.Expense_act_save : this._l.Expense_act_add;
  }
  get isEmpty() {
    return !this.data.expenses?.length;
  }

  // ---- rule results for the nested `edit` object ----
  get editReadOnly() {
    return this._readOnly.edit || {};
  }
  get editErrors() {
    return { ...(this._errors.edit || {}), ...this.localErrors };
  }

  // ---- what may the user do (ACTIVE: everything, REVIEW: only requested items, else: nothing) ----
  get reviewRequests() {
    const result = { change: new Set(), remove: new Set() };
    Object.keys(this.reviewData?.[this.page] || {}).forEach((key) => {
      const match = key.match(REVIEW_KEY);
      if (match) {
        (match[2] ? result.change : result.remove).add(match[1]);
      }
    });
    return result;
  }
  canEdit(row) {
    if (this.isReview) {
      return this.reviewRequests.change.has(row.id);
    }
    return this.isEditable;
  }
  canDelete(row) {
    if (this.isReview) {
      return this.reviewRequests.remove.has(row.id);
    }
    return this.isEditable;
  }
  /** In REVIEW new items cannot be added (the server would ignore them), only requested ones edited. */
  get showForm() {
    if (!this.isEditable) {
      return false;
    }
    return this.isReview ? this.isEditing : true;
  }

  // ---- table ----
  get rows() {
    return (this.data.expenses || []).map((item) => ({
      ...item,
      typeLabel: this.typeLabel(item.type)
    }));
  }

  get columns() {
    return [
      { label: this._l.Expense_lbl_type, fieldName: "typeLabel" },
      { label: this._l.Expense_lbl_date, fieldName: "date", type: "date" },
      {
        label: this._l.Expense_lbl_amount,
        fieldName: "amount",
        type: "number",
        align: "right"
      },
      { label: this._l.Expense_lbl_receiptNumber, fieldName: "receiptNumber" },
      {
        label: "",
        fieldName: "editAction",
        type: "icon",
        align: "right",
        width: "48px",
        typeData: {
          icon: "edit",
          dataField: "id",
          disabled: (row) => !this.canEdit(row),
          callback: (event) => this.editRow(event)
        }
      },
      {
        label: "",
        fieldName: "deleteAction",
        type: "icon",
        align: "right",
        width: "48px",
        typeData: {
          icon: "x",
          dataField: "id",
          disabled: (row) => !this.canDelete(row),
          callback: (event) => this.deleteRow(event)
        }
      }
    ];
  }

  get totalLabel() {
    const total = (this.data.expenses || []).reduce(
      (sum, item) => sum + toNumber(item.amount),
      0
    );
    return `${total.toFixed(2)} EUR`;
  }

  // ---- actions ----
  findRow(event) {
    const id = event.currentTarget?.dataset?.id;
    return (this.data.expenses || []).find((item) => item.id === id);
  }

  editRow(event) {
    const row = this.findRow(event);
    if (!row || !this.canEdit(row)) {
      return;
    }
    this.localErrors = {};
    this.data = { ...this.data, edit: { ...EMPTY_EDIT, ...row } };
    this.dispatchPageChange("edit");
  }

  deleteRow(event) {
    const row = this.findRow(event);
    if (!row || !this.canDelete(row)) {
      return;
    }
    const expenses = this.data.expenses.filter((item) => item.id !== row.id);
    const edit =
      this.data.edit?.id === row.id ? { ...EMPTY_EDIT } : this.data.edit;
    this.data = { ...this.data, expenses, edit };
    this.dispatchPageChange("expenses");
  }

  cancelEdit() {
    this.localErrors = {};
    this.data = { ...this.data, edit: { ...EMPTY_EDIT } };
    this.dispatchPageChange("edit");
  }

  saveEdit() {
    const edit = this.data.edit || {};
    const errors = {};
    EDIT_FIELDS.forEach((field) => {
      if (!edit[field]) {
        errors[field] = this._l.Expense_err_fillExpense;
      }
    });
    if (!errors.amount && !(toNumber(edit.amount) > 0)) {
      errors.amount = this._l.Expense_err_fillExpense;
    }
    if (Object.keys(errors).length) {
      this.localErrors = errors;
      return;
    }
    const item = {
      id: edit.id || newId(),
      type: edit.type,
      date: edit.date,
      amount: String(edit.amount),
      receiptNumber: edit.receiptNumber
    };
    const exists = this.data.expenses.some((e) => e.id === item.id);
    const expenses = exists
      ? this.data.expenses.map((e) => (e.id === item.id ? item : e))
      : [...this.data.expenses, item];
    this.localErrors = {};
    this.data = { ...this.data, expenses, edit: { ...EMPTY_EDIT } };
    this.dispatchPageChange("expenses");
  }
}

function toNumber(value) {
  const number = parseFloat(String(value ?? "").replace(",", "."));
  return Number.isNaN(number) ? 0 : number;
}

/** Item ids must be strings without special characters - they are used in `expenses[id=...]` review keys. */
function newId() {
  return `e${Date.now().toString(36)}${Math.floor(Math.random() * 1000)}`;
}
