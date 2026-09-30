/**
 * @description Server-side page validator: the total amount of all expenses on the page must not exceed a limit.
 *
 * Referenced by name from Wizard_Setup.ExpenseReport Rules__c:
 *   "pageValidators": [
 *     { "validator": "ValidateExpenseLimit", "limit": "$con.Expense_Trip_Limit", "message": "Expense_err_limit" }
 *   ]
 * `$con.Expense_Trip_Limit` is replaced by the framework with Wizard_Contstant__mdt.Expense_Trip_Limit.Value__c.
 * Every property except `validator` and `message` is available in `entry.properties`.
 *
 * The same check runs on the client via the JS function registered as `ValidateExpenseLimit`
 * in the registry's page-validator-registry.
 *
 * Declared `global` so the managed package can instantiate it when the example lives in a subscriber org.
 */
global with sharing class ValidateExpenseLimit implements IPageValidator {

    private static final String DEFAULT_MESSAGE = 'The total amount exceeds the allowed limit';

    /**
     * @param page page id (the model has a key with this name holding the page data)
     * @param model complete wizard model
     * @param entry rule entry: properties.limit, message
     * @param errors field -> error message; `$global` is shown as a page-level error
     * @return true if valid
     */
    global Boolean validate(String page, Map<String, Object> model, WizardPageRules.ValidatorEntry entry,
            Map<String, Object> errors) {
        if (String.isBlank(page) || model == null || entry == null || entry.properties == null || errors == null) {
            return true;
        }
        Decimal limitValue = toDecimal(entry.properties.get('limit'));
        if (limitValue == null) {
            return true;
        }
        Decimal total = 0;
        Object pageModel = model.get(page);
        Object expenses = pageModel instanceof Map<String, Object> ? ((Map<String, Object>) pageModel).get('expenses') : null;
        if (expenses instanceof List<Object>) {
            for (Object item : (List<Object>) expenses) {
                if (item instanceof Map<String, Object>) {
                    Decimal amount = toDecimal(((Map<String, Object>) item).get('amount'));
                    total += amount == null ? 0 : amount;
                }
            }
        }
        if (total > limitValue) {
            errors.put('$global', String.isNotBlank(entry.message) ? entry.message : DEFAULT_MESSAGE);
            return false;
        }
        return true;
    }

    private static Decimal toDecimal(Object value) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(value).replace(',', '.'));
        } catch (Exception e) {
            return null;
        }
    }
}
