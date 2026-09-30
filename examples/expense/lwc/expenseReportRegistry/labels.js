import Expense_title from "@salesforce/label/c.Expense_title";
import Expense_pag_trip from "@salesforce/label/c.Expense_pag_trip";
import Expense_pag_documents from "@salesforce/label/c.Expense_pag_documents";
import Expense_pag_health from "@salesforce/label/c.Expense_pag_health";
import Expense_pag_items from "@salesforce/label/c.Expense_pag_items";
import Expense_pag_reimbursement from "@salesforce/label/c.Expense_pag_reimbursement";
import Expense_pag_summary from "@salesforce/label/c.Expense_pag_summary";
import Expense_lbl_destinationType from "@salesforce/label/c.Expense_lbl_destinationType";
import Expense_lbl_destination from "@salesforce/label/c.Expense_lbl_destination";
import Expense_lbl_dateFrom from "@salesforce/label/c.Expense_lbl_dateFrom";
import Expense_lbl_dateTo from "@salesforce/label/c.Expense_lbl_dateTo";
import Expense_lbl_purpose from "@salesforce/label/c.Expense_lbl_purpose";
import Expense_lbl_account from "@salesforce/label/c.Expense_lbl_account";
import Expense_lbl_passportNumber from "@salesforce/label/c.Expense_lbl_passportNumber";
import Expense_lbl_passportExpiry from "@salesforce/label/c.Expense_lbl_passportExpiry";
import Expense_lbl_visaRequired from "@salesforce/label/c.Expense_lbl_visaRequired";
import Expense_lbl_visaNumber from "@salesforce/label/c.Expense_lbl_visaNumber";
import Expense_lbl_ehicNumber from "@salesforce/label/c.Expense_lbl_ehicNumber";
import Expense_lbl_ehicExpiry from "@salesforce/label/c.Expense_lbl_ehicExpiry";
import Expense_lbl_type from "@salesforce/label/c.Expense_lbl_type";
import Expense_lbl_date from "@salesforce/label/c.Expense_lbl_date";
import Expense_lbl_amount from "@salesforce/label/c.Expense_lbl_amount";
import Expense_lbl_receiptNumber from "@salesforce/label/c.Expense_lbl_receiptNumber";
import Expense_lbl_iban from "@salesforce/label/c.Expense_lbl_iban";
import Expense_lbl_bankName from "@salesforce/label/c.Expense_lbl_bankName";
import Expense_lbl_accountHolder from "@salesforce/label/c.Expense_lbl_accountHolder";
import Expense_lbl_declaration from "@salesforce/label/c.Expense_lbl_declaration";
import Expense_lbl_total from "@salesforce/label/c.Expense_lbl_total";
import Expense_lbl_perDiem from "@salesforce/label/c.Expense_lbl_perDiem";
import Expense_opt_domestic from "@salesforce/label/c.Expense_opt_domestic";
import Expense_opt_eu from "@salesforce/label/c.Expense_opt_eu";
import Expense_opt_international from "@salesforce/label/c.Expense_opt_international";
import Expense_opt_transport from "@salesforce/label/c.Expense_opt_transport";
import Expense_opt_hotel from "@salesforce/label/c.Expense_opt_hotel";
import Expense_opt_meals from "@salesforce/label/c.Expense_opt_meals";
import Expense_opt_taxi from "@salesforce/label/c.Expense_opt_taxi";
import Expense_opt_other from "@salesforce/label/c.Expense_opt_other";
import Expense_act_add from "@salesforce/label/c.Expense_act_add";
import Expense_act_save from "@salesforce/label/c.Expense_act_save";
import Expense_act_cancel from "@salesforce/label/c.Expense_act_cancel";
import Expense_act_submit from "@salesforce/label/c.Expense_act_submit";
import Expense_act_resubmit from "@salesforce/label/c.Expense_act_resubmit";
import Expense_act_new from "@salesforce/label/c.Expense_act_new";
import Expense_act_back from "@salesforce/label/c.Expense_act_back";
import Expense_msg_noExpenses from "@salesforce/label/c.Expense_msg_noExpenses";
import Expense_msg_editing from "@salesforce/label/c.Expense_msg_editing";
import Expense_msg_submitted from "@salesforce/label/c.Expense_msg_submitted";
import Expense_msg_approved from "@salesforce/label/c.Expense_msg_approved";
import Expense_msg_review from "@salesforce/label/c.Expense_msg_review";
import Expense_msg_reviewComment from "@salesforce/label/c.Expense_msg_reviewComment";
import Expense_msg_perDiemInfo from "@salesforce/label/c.Expense_msg_perDiemInfo";
import Expense_hint_purpose from "@salesforce/label/c.Expense_hint_purpose";
import Expense_hint_iban from "@salesforce/label/c.Expense_hint_iban";
import Expense_err_iban from "@salesforce/label/c.Expense_err_iban";
import Expense_err_limit from "@salesforce/label/c.Expense_err_limit";
import Expense_err_dates from "@salesforce/label/c.Expense_err_dates";
import Expense_err_passport from "@salesforce/label/c.Expense_err_passport";
import Expense_err_name from "@salesforce/label/c.Expense_err_name";
import Expense_err_fillExpense from "@salesforce/label/c.Expense_err_fillExpense";
import Expense_err_declaration from "@salesforce/label/c.Expense_err_declaration";

const L = {
  Expense_title,
  Expense_pag_trip,
  Expense_pag_documents,
  Expense_pag_health,
  Expense_pag_items,
  Expense_pag_reimbursement,
  Expense_pag_summary,
  Expense_lbl_destinationType,
  Expense_lbl_destination,
  Expense_lbl_dateFrom,
  Expense_lbl_dateTo,
  Expense_lbl_purpose,
  Expense_lbl_account,
  Expense_lbl_passportNumber,
  Expense_lbl_passportExpiry,
  Expense_lbl_visaRequired,
  Expense_lbl_visaNumber,
  Expense_lbl_ehicNumber,
  Expense_lbl_ehicExpiry,
  Expense_lbl_type,
  Expense_lbl_date,
  Expense_lbl_amount,
  Expense_lbl_receiptNumber,
  Expense_lbl_iban,
  Expense_lbl_bankName,
  Expense_lbl_accountHolder,
  Expense_lbl_declaration,
  Expense_lbl_total,
  Expense_lbl_perDiem,
  Expense_opt_domestic,
  Expense_opt_eu,
  Expense_opt_international,
  Expense_opt_transport,
  Expense_opt_hotel,
  Expense_opt_meals,
  Expense_opt_taxi,
  Expense_opt_other,
  Expense_act_add,
  Expense_act_save,
  Expense_act_cancel,
  Expense_act_submit,
  Expense_act_resubmit,
  Expense_act_new,
  Expense_act_back,
  Expense_msg_noExpenses,
  Expense_msg_editing,
  Expense_msg_submitted,
  Expense_msg_approved,
  Expense_msg_review,
  Expense_msg_reviewComment,
  Expense_msg_perDiemInfo,
  Expense_hint_purpose,
  Expense_hint_iban,
  Expense_err_iban,
  Expense_err_limit,
  Expense_err_dates,
  Expense_err_passport,
  Expense_err_name,
  Expense_err_fillExpense,
  Expense_err_declaration
};

export { L };
