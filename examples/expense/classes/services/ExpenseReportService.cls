/**
 * @description Service for the Expense Report example (Expense_Report__c / Expense_Line__c).
 *
 * Reuses the global WizardSelector for reading Wizard__c. The wizard is locked and unlocked through
 * WizardApi (the framework's global front): it is ACTIVE while the employee fills it in, LOCKED once
 * the report is submitted, and ACTIVE again when the manager asks for changes. The review is this
 * example's own process: what the manager asks for is in the context of the wizard ($ctx):
 *   reportStatus     → Submitted | Changes Requested | Approved (the summary page shows it)
 *   reviewComment    → the manager's comment
 *   requestedChanges → { page: { field path: its value when the change was asked for } }, e.g.
 *                      { "ExpenseItems": { "expenses[id=e1].amount": "540", "expenses[id=e2]": "" },
 *                        "ExpenseReimbursement": { "iban": "BG80..." } } ('' = the item must go)
 * The pages let the employee change only those (expenseItems), and a resubmit is refused until
 * every one of them was made (findPendingReviewChanges).
 *
 * Wizard model (Wizard__c.Model__c) used by this service:
 *   ExpenseTripInfo        → destinationType, destination, dateFrom, dateTo, purpose, accountId, accountName
 *   ExpenseTravelDocuments → passportNumber, passportExpiry, visaRequired, visaNumber   (international only)
 *   ExpenseEuHealthCard    → ehicNumber, ehicExpiry                                     (EU only)
 *   ExpenseItems           → expenses[] { id, type, date, amount, receiptNumber }, edit { ... }
 *   ExpenseReimbursement   → iban, bankName, accountHolder
 */
public inherited sharing class ExpenseReportService implements IExpenseReportService {

    /** The wizard type of this process (Wizard_Setup.ExpenseReport): a report is made only for it */
    public static final String WIZARD_TYPE = 'ExpenseReport';

    public static final String PAGE_TRIP = 'ExpenseTripInfo';
    public static final String PAGE_DOCUMENTS = 'ExpenseTravelDocuments';
    public static final String PAGE_HEALTH = 'ExpenseEuHealthCard';
    public static final String PAGE_ITEMS = 'ExpenseItems';
    public static final String PAGE_REIMBURSEMENT = 'ExpenseReimbursement';
    public static final String PAGE_SUMMARY = 'ExpenseSummary';

    /** What the review of the manager keeps in the context of the wizard ($ctx) */
    public static final String CTX_STATUS = 'reportStatus';
    public static final String CTX_COMMENT = 'reviewComment';
    public static final String CTX_REQUESTED = 'requestedChanges';
    /** The report the submit made for the wizard: the wizard's side of the link (requireExpenseLink) */
    public static final String CTX_REPORT = 'expenseReportId';

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

    private static final prolet.IWizardSelector selector = prolet.WizardSelector.newInstance();

    // ------------------------------------------------------------------ submit

    public Id submitReport(Id wizardId, Boolean agreedToDeclaration) {
        if (agreedToDeclaration != true) {
            throw new ExpenseReportException('The declaration must be confirmed before submitting.');
        }
        prolet__Wizard__c wizard = loadWizardForUpdate(wizardId);
        if (wizard.prolet__Wizard_Type__c != WIZARD_TYPE) {
            throw new ExpenseReportException('This wizard is not an expense report.');
        }
        if (prolet.WizardStates.isLocked(wizard.prolet__State__c)) {
            throw new ExpenseReportException('The report is submitted already: it can be changed only when the manager asks for changes.');
        }
        Map<String, Object> model = parseJson(wizard.prolet__Model__c);
        Map<String, Object> context = parseJson(wizard.prolet__Context__c);
        List<String> pending = findPendingReviewChanges(model, toMap(context.get(CTX_REQUESTED)));
        if (!pending.isEmpty()) {
            throw new ExpenseReportException('Complete the requested changes first: ' + String.join(pending, ', '));
        }
        List<Map<String, Object>> expenses = getExpenses(model);
        if (expenses.isEmpty()) {
            throw new ExpenseReportException('At least one expense is required.');
        }
        // every item once: its id is the key of its line (and of the changes the manager asks for)
        List<String> repeated = findRepeatedIds(expenses);
        if (!repeated.isEmpty()) {
            throw new ExpenseReportException('An expense is in the list more than once: ' + String.join(repeated, ', '));
        }

        // Re-submission after a review updates the same report
        Expense_Report__c report = findReportByWizard(wizardId);
        Map<String, Object> requested = toMap(context.get(CTX_REQUESTED));
        if (report != null && !requested.isEmpty()) {
            // only what the manager asked for may change in the list (the other pages are read-only
            // by their rules then, and the server keeps their stored values)
            List<String> unrequested = findUnrequestedLineChanges(expenses, toMap(requested.get(PAGE_ITEMS)), report.Id);
            if (!unrequested.isEmpty()) {
                throw new ExpenseReportException('Only the requested changes can be made: ' + String.join(unrequested, ', '));
            }
        }
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

        // The declaration is part of the answers: the signed summary shows it ticked, and the page's
        // form, which has it ticked, is the same as the answers the wizard reads after the submit
        Map<String, Object> summary = toMap(model.get(PAGE_SUMMARY));
        summary.put('agreeDeclaration', true);
        model.put(PAGE_SUMMARY, summary);
        wizard.prolet__Model__c = JSON.serialize(model);

        // What the wizard holds is written while it is ACTIVE: a locked wizard refuses every write
        context.remove(CTX_COMMENT);
        context.remove(CTX_REQUESTED);
        context.put(CTX_STATUS, STATUS_SUBMITTED);
        context.put(CTX_REPORT, report.Id);
        wizard.prolet__Context__c = JSON.serialize(context);
        update wizard;
        // Lock the wizard: every field is read-only, and a second submit is refused
        prolet.WizardApi.lock(wizardId);

        return report.Id;
    }

    // ------------------------------------------------------------------ $ctx

    public Map<String, Object> calculatePerDiem(Id wizardId) {
        prolet__Wizard__c wizard = loadWizard(wizardId);
        Map<String, Object> context = parseJson(wizard.prolet__Context__c);
        if (prolet.WizardStates.isLocked(wizard.prolet__State__c)) {
            return context;
        }
        Map<String, Object> trip = toMap(parseJson(wizard.prolet__Model__c).get(PAGE_TRIP));
        Date dateFrom = toDate(strVal(trip, 'dateFrom'));
        Date dateTo = toDate(strVal(trip, 'dateTo'));
        Integer days = dateFrom != null && dateTo != null && dateTo >= dateFrom ? dateFrom.daysBetween(dateTo) + 1 : 0;
        Decimal rate = perDiemRate(strVal(trip, 'destinationType'));

        context.put('perDiemDays', days);
        context.put('perDiemRate', rate);
        context.put('perDiemTotal', rate * days);
        wizard.prolet__Context__c = JSON.serialize(context);
        update wizard;
        return context;
    }

    // ------------------------------------------------------------------ review

    /*
     * The manager is often not the owner of the employee's wizard, nor above them in the role
     * hierarchy, and Wizard__c is Private. Access to the REPORT decides: who may read it sees the
     * review, who may edit it decides. After that check, the wizard of that report (and only it:
     * its Id comes from the report, not from the client) is read and written without sharing.
     *
     * The link report -> wizard is the server's: only submitReport sets it (users may not edit
     * Expense_Report__c.Wizard__c or Status__c, Expense_Report_User), and it cannot change after
     * (validation rule Wizard_Link_Is_Fixed). Before anything is read or written without sharing,
     * requireExpenseLink checks it again, from both sides: the wizard is of this process, and its
     * context names this report (the submit writes it there, in the wizard of the user who submits).
     * A report made or relinked another way (an admin, a data load) points to a wizard that does not
     * name it back, so it opens nothing. Who created the records does not matter: a wizard made for
     * the employee by an admin or an integration is theirs to submit.
     *
     * Nobody decides on their own report (requireNotOwnReport): the employee who submitted sees it
     * in the panel (ownReport), but requesting changes and approving are for someone else.
     */

    public ExpenseReviewData getReview(Id reportId) {
        requireReportAccess(reportId, false);
        return new ReviewOfTheReport().getReview(this, reportId);
    }

    public void requestChanges(Id reportId, List<String> amountLineKeys, List<String> deleteLineKeys,
            Boolean ibanChange, String comment) {
        requireReportAccess(reportId, true);
        new ReviewOfTheReport().requestChanges(this, reportId, amountLineKeys, deleteLineKeys, ibanChange, comment);
    }

    public void approveReport(Id reportId) {
        requireReportAccess(reportId, true);
        new ReviewOfTheReport().approveReport(this, reportId);
    }

    /**
     * The user may read (edit = false) or edit (edit = true) the report: the object permission and
     * the record's sharing. A report they may not read is answered as one that is not there.
     */
    @TestVisible
    private static void requireReportAccess(Id reportId, Boolean edit) {
        List<UserRecordAccess> access = reportId == null ? new List<UserRecordAccess>() : [
                SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId() AND RecordId = :reportId
        ];
        Schema.DescribeSObjectResult reports = Expense_Report__c.SObjectType.getDescribe();
        if (access.isEmpty() || !access[0].HasReadAccess || !reports.isAccessible()) {
            throw new ExpenseReportException('Expense report not found, id= ' + reportId);
        }
        if (edit && (!access[0].HasEditAccess || !reports.isUpdateable())) {
            throw new ExpenseReportException('You may not review this expense report.');
        }
    }

    /**
     * The review's reads and writes of the report's wizard, without sharing (see above). The
     * service is inherited sharing, so what it calls from here runs without sharing too.
     */
    private without sharing class ReviewOfTheReport {
        ExpenseReviewData getReview(ExpenseReportService service, Id reportId) {
            requireExpenseLink(reportId);
            ExpenseReviewData review = service.reviewOf(reportId);
            // the panel shows one's own report, without the decisions
            review.ownReport = isOwnReport(reportId);
            return review;
        }
        void requestChanges(ExpenseReportService service, Id reportId, List<String> amountLineKeys,
                List<String> deleteLineKeys, Boolean ibanChange, String comment) {
            requireExpenseLink(reportId);
            requireNotOwnReport(reportId);
            service.changesRequested(reportId, amountLineKeys, deleteLineKeys, ibanChange, comment);
        }
        void approveReport(ExpenseReportService service, Id reportId) {
            requireExpenseLink(reportId);
            requireNotOwnReport(reportId);
            service.approved(reportId);
        }
    }

    @TestVisible
    private static final String OWN_REPORT = 'You cannot review your own expense report.';

    /**
     * The user's own report: they own the report or its wizard (the employee who submits owns
     * both). Read without sharing (called from ReviewOfTheReport): the wizard is usually not the
     * reviewer's to see.
     */
    @TestVisible
    private static Boolean isOwnReport(Id reportId) {
        List<Expense_Report__c> reports = [SELECT OwnerId, Wizard__c FROM Expense_Report__c WHERE Id = :reportId];
        if (reports.isEmpty()) {
            return false;
        }
        Id me = UserInfo.getUserId();
        if (reports[0].OwnerId == me) {
            return true;
        }
        if (reports[0].Wizard__c == null) {
            return false;
        }
        List<prolet__Wizard__c> wizards = [SELECT OwnerId FROM prolet__Wizard__c WHERE Id = :reports[0].Wizard__c];
        return !wizards.isEmpty() && wizards[0].OwnerId == me;
    }

    /** Nobody decides on their own report: requesting changes and approving are for someone else */
    private static void requireNotOwnReport(Id reportId) {
        if (isOwnReport(reportId)) {
            throw new ExpenseReportException(OWN_REPORT);
        }
    }

    /**
     * The report's wizard is the one its submit made: of this process, and its context names this
     * report. Read without sharing (called from ReviewOfTheReport), only the type and the context;
     * nothing else is read before it passes. It fails closed: when the report names a wizard, the
     * check passes only for a row it read and that matches. A missing row (deleted, or hidden from a
     * caller that runs with sharing) is refused, so the check cannot be skipped by accident.
     */
    @TestVisible
    private static void requireExpenseLink(Id reportId) {
        List<Expense_Report__c> reports = [SELECT Wizard__c FROM Expense_Report__c WHERE Id = :reportId];
        if (reports.isEmpty()) {
            throw new ExpenseReportException('Expense report not found, id= ' + reportId);
        }
        if (reports[0].Wizard__c == null) {
            return; // no wizard to open: the review shows the report alone, a decision says "Wizard not found"
        }
        List<prolet__Wizard__c> wizards = [SELECT prolet__Wizard_Type__c, prolet__Context__c FROM prolet__Wizard__c WHERE Id = :reports[0].Wizard__c];
        Object named = wizards.isEmpty() ? null : parseJson(wizards[0].prolet__Context__c).get(CTX_REPORT);
        if (wizards.isEmpty() || wizards[0].prolet__Wizard_Type__c != WIZARD_TYPE || named == null
                || String.valueOf(named) != String.valueOf(reportId)) {
            throw new ExpenseReportException(NOT_LINKED);
        }
    }

    @TestVisible
    private static final String NOT_LINKED = 'This expense report is not linked to its own expense wizard.';

    private ExpenseReviewData reviewOf(Id reportId) {
        Expense_Report__c report = loadReport(reportId);
        ExpenseReviewData result = new ExpenseReviewData();
        result.reportId = report.Id;
        result.wizardId = report.Wizard__c;
        result.status = report.Status__c;
        result.iban = report.IBAN__c;
        result.comment = report.Manager_Comment__c;
        result.totalAmount = report.Total_Amount__c;
        if (report.Wizard__c != null) {
            result.wizardState = loadWizard(report.Wizard__c).prolet__State__c;
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

    private void changesRequested(Id reportId, List<String> amountLineKeys, List<String> deleteLineKeys,
            Boolean ibanChange, String comment) {
        Expense_Report__c report = loadReport(reportId);
        prolet__Wizard__c wizard = loadWizardForUpdate(report.Wizard__c);
        if (!isSubmitted(wizard, report)) {
            throw new ExpenseReportException('Changes can be requested only for a submitted report.');
        }
        Map<String, Object> model = parseJson(wizard.prolet__Model__c);
        List<Map<String, Object>> expenses = getExpenses(model);
        Set<String> toDelete = deleteLineKeys == null ? new Set<String>() : new Set<String>(deleteLineKeys);

        // The requested changes: key = field path, value = OLD value that must change ('' = item must be
        // deleted). The keys name an item of the list by its id: `expenses[id=<model id>]`.
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

        Map<String, Object> requested = new Map<String, Object>();
        if (!itemsReview.isEmpty()) {
            requested.put(PAGE_ITEMS, itemsReview);
        }
        if (ibanChange == true) {
            Map<String, Object> reimbursement = toMap(model.get(PAGE_REIMBURSEMENT));
            requested.put(PAGE_REIMBURSEMENT, new Map<String, Object>{ 'iban' => strVal(reimbursement, 'iban') });
        }
        if (requested.isEmpty()) {
            throw new ExpenseReportException('Select at least one change to request.');
        }

        // The employee can change the report again: first ACTIVE, then the context can be written
        prolet.WizardApi.unlock(wizard.Id);
        prolet.WizardApi.updateContext(wizard.Id, new Map<String, Object>{
                CTX_STATUS => STATUS_CHANGES_REQUESTED,
                CTX_COMMENT => comment,
                CTX_REQUESTED => requested
        });

        report.Status__c = STATUS_CHANGES_REQUESTED;
        report.Manager_Comment__c = comment;
        update report;
    }

    private void approved(Id reportId) {
        Expense_Report__c report = loadReport(reportId);
        prolet__Wizard__c wizard = loadWizardForUpdate(report.Wizard__c);
        if (!isSubmitted(wizard, report)) {
            throw new ExpenseReportException('Only a submitted report can be approved.');
        }
        // The employee sees the approval in the wizard, which stays locked
        prolet.WizardApi.updateContext(wizard.Id, new Map<String, Object>{ CTX_STATUS => STATUS_APPROVED });
        report.Status__c = STATUS_APPROVED;
        update report;
    }

    /** Submitted and waiting for the manager: locked, and no decision was made yet */
    private static Boolean isSubmitted(prolet__Wizard__c wizard, Expense_Report__c report) {
        return prolet.WizardStates.isLocked(wizard.prolet__State__c) && report.Status__c == STATUS_SUBMITTED;
    }

    /**
     * @description Server-side check that every change the manager asked for was made.
     * The pages let the employee change only those, but the summary page can be reached directly.
     * @param requested $ctx.requestedChanges (empty: nothing was asked for)
     * @return human-readable list of pending changes (empty if all done)
     */
    @TestVisible
    private static List<String> findPendingReviewChanges(Map<String, Object> model, Map<String, Object> requested) {
        List<String> pending = new List<String>();
        Pattern arrayKey = Pattern.compile('^expenses\\[id=(.+?)\\](?:\\.(\\w+))?$');
        for (String page : requested.keySet()) {
            Map<String, Object> pageModel = toMap(model.get(page));
            Map<String, Object> pageReview = toMap(requested.get(page));
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

    /**
     * @description The changes of the list that the manager did not ask for, against the lines that
     * were submitted: another field of a line (or its amount when only its removal was asked for),
     * a new line, a line that was taken out without being asked.
     * @param requestedItems the requested changes of the items page (`expenses[id=e1].amount`, `expenses[id=e2]`)
     * @return the paths of those changes (empty if none)
     */
    @TestVisible
    private static List<String> findUnrequestedLineChanges(List<Map<String, Object>> expenses,
            Map<String, Object> requestedItems, Id reportId) {
        Map<String, Expense_Line__c> submitted = new Map<String, Expense_Line__c>();
        for (Expense_Line__c line : [
                SELECT Line_Key__c, Type__c, Expense_Date__c, Amount__c, Receipt_Number__c
                FROM Expense_Line__c WHERE Expense_Report__c = :reportId]) {
            submitted.put(line.Line_Key__c, line);
        }
        List<String> unrequested = new List<String>();
        Set<String> seen = new Set<String>();
        for (Map<String, Object> item : expenses) {
            String key = strVal(item, 'id');
            String path = 'expenses[id=' + key + ']';
            seen.add(key);
            Expense_Line__c line = submitted.get(key);
            if (line == null) {
                unrequested.add(path + ' (new)');
                continue;
            }
            if (!sameValue(line.Type__c, strVal(item, 'type'))) {
                unrequested.add(path + '.type');
            }
            if (line.Expense_Date__c != toDate(strVal(item, 'date'))) {
                unrequested.add(path + '.date');
            }
            if (!sameValue(line.Receipt_Number__c, strVal(item, 'receiptNumber'))) {
                unrequested.add(path + '.receiptNumber');
            }
            if (!requestedItems.containsKey(path + '.amount') && line.Amount__c != toDecimal(item.get('amount'))) {
                unrequested.add(path + '.amount');
            }
        }
        for (String key : submitted.keySet()) {
            if (!seen.contains(key) && !requestedItems.containsKey('expenses[id=' + key + ']')) {
                unrequested.add('expenses[id=' + key + '] (removed)');
            }
        }
        return unrequested;
    }

    /** The ids that more than one item of the list has (an item without an id counts as "") */
    @TestVisible
    private static List<String> findRepeatedIds(List<Map<String, Object>> expenses) {
        Set<String> seen = new Set<String>();
        Set<String> repeated = new Set<String>();
        for (Map<String, Object> item : expenses) {
            String key = strVal(item, 'id') == null ? '' : strVal(item, 'id');
            if (!seen.add(key)) {
                repeated.add(key);
            }
        }
        return new List<String>(repeated);
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
        prolet__Wizard_Contstant__mdt constant = prolet__Wizard_Contstant__mdt.getInstance(constantName);
        Decimal value = constant == null ? null : toDecimal(constant.prolet__Value__c);
        return value != null && value > 0 ? value : fallback;
    }

    // ------------------------------------------------------------------ data access

    private static prolet__Wizard__c loadWizard(Id wizardId) {
        List<prolet__Wizard__c> wizards = wizardId == null ? new List<prolet__Wizard__c>() : selector.selectByIds(wizardId);
        if (wizards.isEmpty()) {
            throw new ExpenseReportException('Wizard not found, id= ' + wizardId);
        }
        return wizards[0];
    }

    /**
     * The wizard locked until the end of the transaction, for a step that changes the process (a
     * submit, a decision of the manager): a second one at the same time waits here and then sees
     * the state the first one left, so a report is not submitted or decided twice.
     */
    private static prolet__Wizard__c loadWizardForUpdate(Id wizardId) {
        List<prolet__Wizard__c> wizards = wizardId == null ? new List<prolet__Wizard__c>() : selector.selectByIdForUpdate(wizardId);
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
