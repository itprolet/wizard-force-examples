/**
 * @description One-off upgrade: writes the wizard's side of the report link ($ctx.expenseReportId)
 * for reports submitted before the review checked it (ExpenseReportService.requireExpenseLink). The
 * review refuses a report whose wizard does not name it, and a locked wizard cannot be submitted
 * again, so without this such reports could not be reviewed.
 *
 * A pair (report, wizard) gets the link only when everything stored agrees that the submit made it:
 *   1. the wizard is of the expense process (ExpenseReportService.WIZARD_TYPE);
 *   2. it is the only report that points to the wizard (a second one is a copy or a forgery: which
 *      is the real one is not for the backfill to guess);
 *   3. the wizard's context has the status the submit and the review write ($ctx.reportStatus), and it
 *      is the report's Status__c;
 *   4. the wizard's state fits that status (Submitted / Approved: locked, Changes Requested: active);
 *   5. the context names no report yet (one that names another report is left as it is).
 * Every other pair is skipped and listed (skipped), for an admin to look at; nothing else changes.
 *
 * Run it as an admin from Anonymous Apex, first without writing:
 *     Database.executeBatch(new ExpenseReportLinkBackfill(false));   // dry run: the debug log lists it
 *     Database.executeBatch(new ExpenseReportLinkBackfill(true));    // writes the links
 * Running it again is safe: a wizard that names its report already is counted as done.
 *
 * without sharing: it must see every report and wizard, whoever runs it. It is not @AuraEnabled and
 * no permission set gives it; only someone who may run Anonymous Apex can start it.
 */
public without sharing class ExpenseReportLinkBackfill implements Database.Batchable<SObject>, Database.Stateful {

    private final Boolean apply;

    /** Wizards that got the link (or would, on a dry run) */
    public Integer linked = 0;
    /** Wizards that named their report already */
    public Integer alreadyLinked = 0;
    /** Report Id => why it was skipped */
    public Map<Id, String> skipped = new Map<Id, String>();

    public ExpenseReportLinkBackfill(Boolean apply) {
        this.apply = apply == true;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT Id, Wizard__c, Status__c FROM Expense_Report__c WHERE Wizard__c != NULL ORDER BY Id
        ]);
    }

    public void execute(Database.BatchableContext context, List<Expense_Report__c> reports) {
        run(reports);
    }

    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO, summary());
    }

    /** What it did (or would do): for the debug log, and for a test */
    public String summary() {
        List<String> lines = new List<String>{
                'ExpenseReportLinkBackfill ' + (apply ? '' : '(dry run) ') + 'linked=' + linked
                        + ' alreadyLinked=' + alreadyLinked + ' skipped=' + skipped.size()
        };
        for (Id reportId : skipped.keySet()) {
            lines.add('  skipped ' + reportId + ': ' + skipped.get(reportId));
        }
        return String.join(lines, '\n');
    }

    /** The checks and the writes for one chunk of reports */
    @TestVisible
    private void run(List<Expense_Report__c> reports) {
        Set<Id> wizardIds = new Set<Id>();
        for (Expense_Report__c report : reports) {
            wizardIds.add(report.Wizard__c);
        }
        // how many reports point to each wizard, across all reports (not only this chunk)
        Map<Id, Integer> reportsPerWizard = new Map<Id, Integer>();
        for (AggregateResult row : [
                SELECT Wizard__c wizardId, COUNT(Id) total FROM Expense_Report__c
                WHERE Wizard__c IN :wizardIds GROUP BY Wizard__c
        ]) {
            reportsPerWizard.put((Id) row.get('wizardId'), (Integer) row.get('total'));
        }
        // the whole context is written back: when it writes, the wizards are locked before they are
        // read, so a change of their context in another transaction (a review, a refresh) waits and
        // is not overwritten; a dry run writes nothing and locks nothing
        Map<Id, prolet__Wizard__c> wizards = new Map<Id, prolet__Wizard__c>(apply
                ? [SELECT Id, prolet__Wizard_Type__c, prolet__State__c, prolet__Context__c FROM prolet__Wizard__c WHERE Id IN :wizardIds FOR UPDATE]
                : [SELECT Id, prolet__Wizard_Type__c, prolet__State__c, prolet__Context__c FROM prolet__Wizard__c WHERE Id IN :wizardIds]);

        List<prolet__Wizard__c> updates = new List<prolet__Wizard__c>();
        for (Expense_Report__c report : reports) {
            prolet__Wizard__c wizard = wizards.get(report.Wizard__c);
            Map<String, Object> context = wizard == null ? null : parseContext(wizard.prolet__Context__c);
            String problem = problemOf(report, wizard, context, reportsPerWizard.get(report.Wizard__c));
            if (problem == ALREADY_LINKED) {
                alreadyLinked++;
            } else if (problem != null) {
                skipped.put(report.Id, problem);
            } else {
                linked++;
                context.put(ExpenseReportService.CTX_REPORT, report.Id);
                updates.add(new prolet__Wizard__c(Id = wizard.Id, prolet__Context__c = JSON.serialize(context)));
            }
        }
        if (apply && !updates.isEmpty()) {
            // only the context: the wizard trigger lets the process's Apex write it also when locked
            update updates;
        }
    }

    private static final String ALREADY_LINKED = 'already linked';

    /** null when the pair may get the link; ALREADY_LINKED; otherwise why it is skipped */
    private static String problemOf(Expense_Report__c report, prolet__Wizard__c wizard, Map<String, Object> context,
            Integer reportsOfWizard) {
        if (wizard == null) {
            return 'its wizard is not there';
        }
        if (wizard.prolet__Wizard_Type__c != ExpenseReportService.WIZARD_TYPE) {
            return 'its wizard is not an expense report (' + wizard.prolet__Wizard_Type__c + ')';
        }
        if (context == null) {
            return 'the context of its wizard cannot be read';
        }
        Object named = context.get(ExpenseReportService.CTX_REPORT);
        if (named != null) {
            return String.valueOf(named) == String.valueOf(report.Id)
                    ? ALREADY_LINKED
                    : 'its wizard names another report (' + named + ')';
        }
        if (reportsOfWizard != 1) {
            return reportsOfWizard + ' reports point to its wizard';
        }
        Object status = context.get(ExpenseReportService.CTX_STATUS);
        if (status == null) {
            return 'its wizard was never submitted ($ctx.' + ExpenseReportService.CTX_STATUS + ' is empty)';
        }
        if (String.valueOf(status) != report.Status__c) {
            return 'the status differs: report ' + report.Status__c + ', wizard ' + status;
        }
        Boolean locked = prolet.WizardStates.isLocked(wizard.prolet__State__c);
        Boolean shouldBeLocked = report.Status__c != ExpenseReportService.STATUS_CHANGES_REQUESTED;
        if (locked != shouldBeLocked) {
            return 'the wizard is ' + wizard.prolet__State__c + ' but the report is ' + report.Status__c;
        }
        return null;
    }

    /** The context as a map; an empty one when there is none; null when it is not a JSON object */
    private static Map<String, Object> parseContext(String text) {
        if (String.isBlank(text)) {
            return new Map<String, Object>();
        }
        try {
            Object parsed = JSON.deserializeUntyped(text);
            return parsed instanceof Map<String, Object> ? (Map<String, Object>) parsed : null;
        } catch (JSONException e) {
            return null;
        }
    }
}
