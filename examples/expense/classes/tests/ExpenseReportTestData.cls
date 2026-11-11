/**
 * @description Test data for the Expense Report example: a complete wizard model and Wizard__c records.
 */
@IsTest
public class ExpenseReportTestData {

    /** The type of the expense process: the service makes a report only for a wizard of it */
    public static final String WIZARD_TYPE = ExpenseReportService.WIZARD_TYPE;
    public static final String VALID_IBAN = 'BG80BNBG96611020345678';

    /** Model of an international trip with two expenses (e1 = 540 hotel, e2 = 45 taxi). */
    public static Map<String, Object> validModel() {
        return new Map<String, Object>{
                'ExpenseTripInfo' => new Map<String, Object>{
                        'destinationType' => 'international',
                        'destination' => 'New York, USA',
                        'dateFrom' => '2026-10-05',
                        'dateTo' => '2026-10-07',
                        'purpose' => 'Customer workshop',
                        'accountId' => null,
                        'accountName' => null
                },
                'ExpenseTravelDocuments' => new Map<String, Object>{
                        'passportNumber' => '382000000',
                        'passportExpiry' => '2030-01-01',
                        'visaRequired' => true,
                        'visaNumber' => 'V-123'
                },
                'ExpenseEuHealthCard' => new Map<String, Object>{
                        'ehicNumber' => 'should-be-ignored'
                },
                'ExpenseItems' => new Map<String, Object>{
                        'expenses' => new List<Object>{
                                expense('e1', 'hotel', '2026-10-05', '540'),
                                expense('e2', 'taxi', '2026-10-06', '45')
                        },
                        'edit' => new Map<String, Object>()
                },
                'ExpenseReimbursement' => new Map<String, Object>{
                        'iban' => 'bg80 bnbg 9661 1020 3456 78',
                        'bankName' => 'BNB',
                        'accountHolder' => 'Ivan Ivanov'
                }
        };
    }

    public static Map<String, Object> expense(String id, String type, String expenseDate, String amount) {
        return new Map<String, Object>{
                'id' => id, 'type' => type, 'date' => expenseDate, 'amount' => amount, 'receiptNumber' => 'R-' + id
        };
    }

    public static prolet__Wizard__c insertWizard(Map<String, Object> model, String state) {
        prolet__Wizard__c wizard = new prolet__Wizard__c(
                prolet__Wizard_Type__c = WIZARD_TYPE,
                prolet__Model__c = model == null ? null : JSON.serialize(model),
                prolet__State__c = state
        );
        insert wizard;
        return wizard;
    }

    public static prolet__Wizard__c reload(Id wizardId) {
        return [SELECT Id, prolet__State__c, prolet__Model__c, prolet__Context__c, prolet__PathVersion__c FROM prolet__Wizard__c WHERE Id = :wizardId];
    }

    /** Standard User with the given permission sets (no role, so no hierarchy) */
    public static User userWith(String name, List<String> permissionSets) {
        User user;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile standard = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            user = new User(
                    ProfileId = standard.Id, LastName = name, Alias = name.left(8),
                    Email = name + '@expense.test', Username = name + Crypto.getRandomInteger() + '@expense.test',
                    TimeZoneSidKey = 'Europe/Sofia', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US');
            insert user;
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet permissionSet : [SELECT Id FROM PermissionSet WHERE Name IN :permissionSets]) {
                assignments.add(new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = user.Id));
            }
            System.Assert.areEqual(permissionSets.size(), assignments.size(), 'permission sets ' + permissionSets);
            insert assignments;
        }
        return user;
    }

    /**
     * Takes the wizard's side of the report link out of its context ($ctx.expenseReportId): a report
     * as it was submitted before the review checked the link.
     */
    public static void removeReportLink(Id wizardId) {
        prolet__Wizard__c wizard = [SELECT prolet__Context__c FROM prolet__Wizard__c WHERE Id = :wizardId];
        Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(wizard.prolet__Context__c);
        context.remove(ExpenseReportService.CTX_REPORT);
        update new prolet__Wizard__c(Id = wizardId, prolet__Context__c = JSON.serialize(context));
    }

    private static User employee;

    /**
     * Gives a submitted wizard and its report to an employee (a user of the expense example): the
     * test user then reviews someone else's report, as a manager does. Nobody decides on their own.
     */
    public static void giveToEmployee(Id wizardId) {
        if (employee == null) {
            employee = userWith('employee', new List<String>{ 'Wizard_Framework_User', 'Expense_Report_User' });
        }
        update new prolet__Wizard__c(Id = wizardId, OwnerId = employee.Id);
        List<Expense_Report__c> reports = [SELECT Id FROM Expense_Report__c WHERE Wizard__c = :wizardId];
        for (Expense_Report__c report : reports) {
            report.OwnerId = employee.Id;
        }
        update reports;
    }

    /** Replaces the model of an existing wizard (simulates the user editing pages). */
    public static void updateModel(Id wizardId, Map<String, Object> model) {
        update new prolet__Wizard__c(Id = wizardId, prolet__Model__c = JSON.serialize(model));
    }
}
