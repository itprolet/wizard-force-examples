/**
 * @description Service for the Expense Report example (Expense_Report__c / Expense_Line__c).
 *
 * Reuses the global WizardSelector for reading Wizard__c. State, context and review data are written
 * directly on Wizard__c because the framework does not expose a global API for them
 * (WizardService / WizardController are not callable from outside the package).
 *
 * Wizard model (Wizard__c.Model__c) used by this service:
 *   ExpenseTripInfo        → destinationType, destination, dateFrom, dateTo, purpose, accountId, accountName
 *   ExpenseTravelDocuments → passportNumber, passportExpiry, visaRequired, visaNumber   (international only)
 *   ExpenseEuHealthCard    → ehicNumber, ehicExpiry                                     (EU only)
 *   ExpenseItems           → expenses[] { id, type, date, amount, receiptNumber }, edit { ... }
 *   ExpenseReimbursement   → iban, bankName, accountHolder
 */
public inherited sharing class ExpenseReportService implements IExpenseReportService {

    public static final String PAGE_TRIP = 'ExpenseTripInfo';
    public static final String PAGE_DOCUMENTS = 'ExpenseTravelDocuments';
    public static final String PAGE_HEALTH = 'ExpenseEuHealthCard';
    public static final String PAGE_ITEMS = 'ExpenseItems';
    public static final String PAGE_REIMBURSEMENT = 'ExpenseReimbursement';

    public static final String STATE_ACTIVE = 'ACTIVE';
    public static final String STATE_SIGNED = 'SIGNED';
    public static final String STATE_REVIEW = 'REVIEW';
    public static final String STATE_APPROVED = 'APPROVED';

    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_CHANGES_REQUESTED = 'Changes Requested';
    public static final String STATUS_APPROVED = 'Approved';

    /** Wizard_Contstant__mdt records holding the per-diem rate for each destination type */
    private static final Map<String, String> PER_DIEM_CONSTANTS = new Map<String, String>{
            'domestic' => 'Expense_PerDiem_Domestic',
            'eu' => 'Expense_PerDiem_EU',
            'international' => 'Expense_PerDiem_International' 
    };
    /** Fallback rates when the constants are not deployed */
    private static final Map<String, Decimal> DEFAULT_PER_DIEM = new Map<String, Decimal>{
            'domestic' => 40, 'eu' => 90, 'international' => 120
    };

    private static final WizardSelector wizardSelector = new WizardSelector();

    // ------------------------------------------------------------------ submit

    public Id submitReport(Id wizardId, Boolean agreedToDeclaration) {
        if (agreedToDeclaration != true) {
            throw new ExpenseReportException('The declaration must be confirmed before submitting.');
        }
        Wizard__c wizard = loadWizard(wizardId);
        if (wizard.State__c != STATE_ACTIVE && wizard.State__c != STATE_REVIEW) {
            throw new ExpenseReportException('The report cannot be submitted in state ' + wizard.State__c + '.');
        }
        Map<String, Object> model = parseJson(wizard.Model__c);
        if (wizard.State__c == STATE_REVIEW) {
            List<String> pending = findPendingReviewChanges(model, parseJson(wizard.Review_Data__c));
            if (!pending.isEmpty()) {
                throw new ExpenseReportException('Complete the requested changes first: ' + String.join(pending, ', '));
            }
        }
        List<Map<String, Object>> expenses = getExpenses(model);
        if (expenses.isEmpty()) {
            throw new ExpenseReportException('At least one expense is required.');
        }
        Map<String, Object> context = parseJson(wizard.Context__c);

        // Re-submission after a review updates the same report
        Expense_Report__c report = findReportByWizard(wizardId);
        if (report == null) {
            report = new Expense_Report__c(Wizard__c = wizardId);
        }
        mapReport(report, model, expenses, context);
        report.Status__c = STATUS_SUBMITTED;
        upsert report;

        delete [SELECT Id FROM Expense_Line__c WHERE Expense_Report__c = :report.Id];
        List<Expense_Line__c> lines = new List<Expense_Line__c>();
        for (Map<String, Object> item : expenses) {
            lines.add(buildLine(report.Id, item));
        }
        insert lines;

        // Lock the wizard: SIGNED makes every field read-only in the UI
        context.remove('reviewComment');
        wizard.State__c = STATE_SIGNED;
        wizard.Review_Data__c = null;
        wizard.Context__c = JSON.serialize(context);
        update wizard;

        return report.Id;
    }

    // ------------------------------------------------------------------ $ctx

    public Map<String, Object> calculatePerDiem(Id wizardId) {
        Wizard__c wizard = loadWizard(wizardId);
        Map<String, Object> context = parseJson(wizard.Context__c);
        if (wizard.State__c != STATE_ACTIVE && wizard.State__c != STATE_REVIEW) {
            return context;
        }
        Map<String, Object> trip = toMap(parseJson(wizard.Model__c).get(PAGE_TRIP));
        Date dateFrom = toDate(strVal(trip, 'dateFrom'));
        Date dateTo = toDate(strVal(trip, 'dateTo'));
        Integer days = dateFrom != null && dateTo != null && dateTo >= dateFrom ? dateFrom.daysBetween(dateTo) + 1 : 0;
        Decimal rate = perDiemRate(strVal(trip, 'destinationType'));

        context.put('perDiemDays', days);
        context.put('perDiemRate', rate);
        context.put('perDiemTotal', rate * days);
        wizard.Context__c = JSON.serialize(context);
        update wizard;
        return context;
    }

    // ------------------------------------------------------------------ review

    public ExpenseReviewData getReview(Id reportId) {
        Expense_Report__c report = loadReport(reportId);
        ExpenseReviewData result = new ExpenseReviewData();
        result.reportId = report.Id;
        result.wizardId = report.Wizard__c;
        result.status = report.Status__c;
        result.iban = report.IBAN__c;
        result.comment = report.Manager_Comment__c;
        result.totalAmount = report.Total_Amount__c;
        if (report.Wizard__c != null) {
            result.wizardState = loadWizard(report.Wizard__c).State__c;
        }
        for (Expense_Line__c line : report.Expense_Lines__r) {
            ExpenseReviewData.Line l = new ExpenseReviewData.Line();
            l.lineKey = line.Line_Key__c;
            l.type = line.Type__c;
            l.expenseDate = line.Expense_Date__c;
            l.amount = line.Amount__c;
            l.receiptNumber = line.Receipt_Number__c;
            result.lines.add(l);
        }
        return result;
    }

    public void requestChanges(Id reportId, List<String> amountLineKeys, List<String> deleteLineKeys,
            Boolean ibanChange, String comment) {
        Expense_Report__c report = loadReport(reportId);
        Wizard__c wizard = loadWizard(report.Wizard__c);
        if (wizard.State__c != STATE_SIGNED) {
            throw new ExpenseReportException('Changes can be requested only for a submitted report.');
        }
        Map<String, Object> model = parseJson(wizard.Model__c);
        List<Map<String, Object>> expenses = getExpenses(model);
        Set<String> toDelete = deleteLineKeys == null ? new Set<String>() : new Set<String>(deleteLineKeys);

        // Review data format: key = field path, value = OLD value that must change ('' = item must be deleted).
        // Keys use the array filter syntax `expenses[id=<model id>]` supported by review mode.
        Map<String, Object> itemsReview = new Map<String, Object>();
        for (String key : amountLineKeys == null ? new List<String>() : amountLineKeys) {
            if (toDelete.contains(key)) {
                continue;
            }
            Map<String, Object> item = findExpense(expenses, key);
            itemsReview.put('expenses[id=' + key + '].amount', strVal(item, 'amount'));
        }
        for (String key : toDelete) {
            findExpense(expenses, key);
            itemsReview.put('expenses[id=' + key + ']', '');
        }

        Map<String, Object> reviewData = new Map<String, Object>();
        if (!itemsReview.isEmpty()) {
            reviewData.put(PAGE_ITEMS, itemsReview);
        }
        if (ibanChange == true) {
            Map<String, Object> reimbursement = toMap(model.get(PAGE_REIMBURSEMENT));
            reviewData.put(PAGE_REIMBURSEMENT, new Map<String, Object>{ 'iban' => strVal(reimbursement, 'iban') });
        }
        if (reviewData.isEmpty()) {
            throw new ExpenseReportException('Select at least one change to request.');
        }

        Map<String, Object> context = parseJson(wizard.Context__c);
        context.put('reviewComment', comment);
        wizard.State__c = STATE_REVIEW;
        wizard.Review_Data__c = JSON.serialize(reviewData);
        wizard.Context__c = JSON.serialize(context);
        update wizard;

        report.Status__c = STATUS_CHANGES_REQUESTED;
        report.Manager_Comment__c = comment;
        update report;
    }

    public void approveReport(Id reportId) {
        Expense_Report__c report = loadReport(reportId);
        Wizard__c wizard = loadWizard(report.Wizard__c);
        if (wizard.State__c != STATE_SIGNED) {
            throw new ExpenseReportException('Only a submitted report can be approved.');
        }
        wizard.State__c = STATE_APPROVED;
        update wizard;
        report.Status__c = STATUS_APPROVED;
        update report;
    }

    /**
     * @description Server-side check that every change requested in review mode was made.
     * The UI enforces the same rules while navigating, but the summary page can be reached directly.
     * @return human-readable list of pending changes (empty if all done)
     */
    @TestVisible
    private static List<String> findPendingReviewChanges(Map<String, Object> model, Map<String, Object> reviewData) {
        List<String> pending = new List<String>();
        Pattern arrayKey = Pattern.compile('^expenses\\[id=(.+?)\\](?:\\.(\\w+))?$');
        for (String page : reviewData.keySet()) {
            Map<String, Object> pageModel = toMap(model.get(page));
            Map<String, Object> pageReview = toMap(reviewData.get(page));
            for (String key : pageReview.keySet()) {
                String oldValue = String.valueOf(pageReview.get(key));
                Matcher m = arrayKey.matcher(key);
                if (m.matches()) {
                    Map<String, Object> item = findExpenseOrNull(getExpenses(model), m.group(1));
                    Boolean deleteRequested = m.group(2) == null;
                    if (item != null && (deleteRequested || sameValue(oldValue, strVal(item, m.group(2))))) {
                        pending.add(key);
                    }
                } else if (sameValue(oldValue, strVal(pageModel, key))) {
                    pending.add(page + '.' + key);
                }
            }
        }
        return pending;
    }

    /** Case-sensitive comparison (Apex `==` on strings ignores case) */
    private static Boolean sameValue(String a, String b) {
        return a == null ? b == null : a.equals(b);
    }

    // ------------------------------------------------------------------ mapping

    private static void mapReport(Expense_Report__c report, Map<String, Object> model,
            List<Map<String, Object>> expenses, Map<String, Object> context) {
        Map<String, Object> trip = toMap(model.get(PAGE_TRIP));
        Map<String, Object> reimbursement = toMap(model.get(PAGE_REIMBURSEMENT));
        String destinationType = strVal(trip, 'destinationType');

        report.Destination_Type__c = destinationType;
        report.Destination__c = strVal(trip, 'destination');
        report.Date_From__c = toDate(strVal(trip, 'dateFrom'));
        report.Date_To__c = toDate(strVal(trip, 'dateTo'));
        report.Purpose__c = strVal(trip, 'purpose');
        report.Account__c = toId(strVal(trip, 'accountId'));

        // Pages that are not in the current plan may still hold old data in the model
        // (e.g. the user switched from "international" to "eu"), so map them by destination type.
        Map<String, Object> documents = destinationType == 'international'
                ? toMap(model.get(PAGE_DOCUMENTS)) : new Map<String, Object>();
        Map<String, Object> health = destinationType == 'eu'
                ? toMap(model.get(PAGE_HEALTH)) : new Map<String, Object>();
        report.Passport_Number__c = strVal(documents, 'passportNumber');
        report.Visa_Number__c = boolVal(documents, 'visaRequired') ? strVal(documents, 'visaNumber') : null;
        report.EHIC_Number__c = strVal(health, 'ehicNumber');

        String iban = strVal(reimbursement, 'iban');
        report.IBAN__c = iban == null ? null : iban.deleteWhitespace().toUpperCase();
        report.Bank_Name__c = strVal(reimbursement, 'bankName');
        report.Account_Holder__c = strVal(reimbursement, 'accountHolder');

        Decimal total = 0;
        for (Map<String, Object> item : expenses) {
            total += toDecimal(item.get('amount'));
        }
        report.Total_Amount__c = total;
        report.Per_Diem__c = toDecimal(context.get('perDiemTotal'));
    }

    private static Expense_Line__c buildLine(Id reportId, Map<String, Object> item) {
        return new Expense_Line__c(
                Expense_Report__c = reportId,
                Line_Key__c = strVal(item, 'id'),
                Type__c = strVal(item, 'type'),
                Expense_Date__c = toDate(strVal(item, 'date')),
                Amount__c = toDecimal(item.get('amount')),
                Receipt_Number__c = strVal(item, 'receiptNumber')
        );
    }

    private static Decimal perDiemRate(String destinationType) {
        Decimal fallback = DEFAULT_PER_DIEM.containsKey(destinationType) ? DEFAULT_PER_DIEM.get(destinationType) : 0;
        String constantName = PER_DIEM_CONSTANTS.get(destinationType);
        if (constantName == null) {
            return fallback;
        }
        Wizard_Contstant__mdt constant = Wizard_Contstant__mdt.getInstance(constantName);
        Decimal value = constant == null ? null : toDecimal(constant.Value__c);
        return value != null && value > 0 ? value : fallback;
    }

    // ------------------------------------------------------------------ data access

    private static Wizard__c loadWizard(Id wizardId) {
        List<Wizard__c> wizards = wizardId == null ? new List<Wizard__c>() : wizardSelector.selectByIds(wizardId);
        if (wizards.isEmpty()) {
            throw new ExpenseReportException('Wizard not found, id= ' + wizardId);
        }
        return wizards[0];
    }

    private static Expense_Report__c loadReport(Id reportId) {
        List<Expense_Report__c> reports = [
                SELECT Id, Wizard__c, Status__c, IBAN__c, Manager_Comment__c, Total_Amount__c,
                (SELECT Line_Key__c, Type__c, Expense_Date__c, Amount__c, Receipt_Number__c
                 FROM Expense_Lines__r ORDER BY Expense_Date__c, Name)
                FROM Expense_Report__c
                WHERE Id = :reportId
        ];
        if (reports.isEmpty()) {
            throw new ExpenseReportException('Expense report not found, id= ' + reportId);
        }
        return reports[0];
    }

    private static Expense_Report__c findReportByWizard(Id wizardId) {
        List<Expense_Report__c> reports = [SELECT Id FROM Expense_Report__c WHERE Wizard__c = :wizardId LIMIT 1];
        return reports.isEmpty() ? null : reports[0];
    }

    // ------------------------------------------------------------------ JSON helpers

    private static List<Map<String, Object>> getExpenses(Map<String, Object> model) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        Object raw = toMap(model.get(PAGE_ITEMS)).get('expenses');
        if (raw instanceof List<Object>) {
            for (Object item : (List<Object>) raw) {
                if (item instanceof Map<String, Object>) {
                    result.add((Map<String, Object>) item);
                }
            }
        }
        return result;
    }

    private static Map<String, Object> findExpense(List<Map<String, Object>> expenses, String key) {
        Map<String, Object> item = findExpenseOrNull(expenses, key);
        if (item == null) {
            throw new ExpenseReportException('Expense not found: ' + key);
        }
        return item;
    }

    private static Map<String, Object> findExpenseOrNull(List<Map<String, Object>> expenses, String key) {
        for (Map<String, Object> item : expenses) {
            if (key != null && key == strVal(item, 'id')) {
                return item;
            }
        }
        return null;
    }

    // Parameter must not be called `json`: Apex names are case-insensitive, so it would hide the JSON class
    private static Map<String, Object> parseJson(String jsonText) {
        if (String.isBlank(jsonText)) {
            return new Map<String, Object>();
        }
        return toMap(JSON.deserializeUntyped(jsonText));
    }

    private static Map<String, Object> toMap(Object obj) {
        if (obj instanceof Map<String, Object>) {
            return (Map<String, Object>) obj;
        }
        return new Map<String, Object>();
    }

    private static String strVal(Map<String, Object> m, String key) {
        Object value = m == null ? null : m.get(key);
        return value == null || String.valueOf(value) == '' ? null : String.valueOf(value);
    }

    private static Boolean boolVal(Map<String, Object> m, String key) {
        Object value = m == null ? null : m.get(key);
        return value instanceof Boolean ? (Boolean) value : value != null && Boolean.valueOf(String.valueOf(value));
    }

    private static Decimal toDecimal(Object value) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return 0;
        }
        try {
            return Decimal.valueOf(String.valueOf(value).replace(',', '.'));
        } catch (Exception e) {
            return 0;
        }
    }

    private static Date toDate(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Date.valueOf(value);
        } catch (Exception e) {
            return null;
        }
    }

    private static Id toId(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Id.valueOf(value);
        } catch (Exception e) {
            return null;
        }
    }
}
