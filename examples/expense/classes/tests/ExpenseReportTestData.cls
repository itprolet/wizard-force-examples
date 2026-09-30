/**
 * @description Test data for the Expense Report example: a complete wizard model and Wizard__c records.
 */
@IsTest
public class ExpenseReportTestData {

    /**
     * Wizard__c.Wizard_Type__c is a restricted picklist (global value set Wizard_Type). The framework source
     * only ships the value TEST, so tests use it - like the other examples - to not depend on org setup.
     */
    public static final String WIZARD_TYPE = 'TEST';
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

    public static Wizard__c insertWizard(Map<String, Object> model, String state) {
        Wizard__c wizard = new Wizard__c(
                Wizard_Type__c = WIZARD_TYPE,
                Model__c = model == null ? null : JSON.serialize(model),
                State__c = state
        );
        insert wizard;
        return wizard;
    }

    public static Wizard__c reload(Id wizardId) {
        return [SELECT Id, State__c, Model__c, Context__c, Review_Data__c FROM Wizard__c WHERE Id = :wizardId];
    }

    /** Replaces the model of an existing wizard (simulates the user editing pages). */
    public static void updateModel(Id wizardId, Map<String, Object> model) {
        update new Wizard__c(Id = wizardId, Model__c = JSON.serialize(model));
    }
}
