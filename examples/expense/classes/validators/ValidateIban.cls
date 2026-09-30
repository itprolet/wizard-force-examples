/**
 * @description Server-side field validator for IBANs (ISO 13616: format + mod-97 checksum).
 *
 * Referenced by name from Wizard_Setup.ExpenseReport Rules__c:
 *   "validators": { "iban": [ { "validator": "ValidateIban", "message": "Expense_err_iban" } ] }
 *
 * The framework runs validators on both sides with the same name:
 *   - client: the JS function registered as `ValidateIban` in the registry's validator-registry;
 *   - server: this class, created with Type.forName('ValidateIban') during navigation.
 *
 * Declared `global` so the managed package can instantiate it when the example lives in a subscriber org.
 */
global with sharing class ValidateIban implements IValidator {

    private static final String DEFAULT_MESSAGE = 'Invalid IBAN';

    /**
     * @param value field value (spaces and lower case are accepted)
     * @param message optional custom error message from the rules
     * @return null if valid (or empty - use `required` for mandatory fields), error message otherwise
     */
    global String validate(Object value, String message) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return null;
        }
        return isValid(String.valueOf(value)) ? null : (String.isNotBlank(message) ? message : DEFAULT_MESSAGE);
    }

    public static Boolean isValid(String rawIban) {
        String iban = rawIban.deleteWhitespace().toUpperCase();
        if (!Pattern.matches('[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}', iban)) {
            return false;
        }
        // Move the first 4 characters to the end, replace letters with numbers (A=10 ... Z=35)
        // and check that the resulting number mod 97 equals 1. Computed digit by digit to avoid overflow.
        String rearranged = iban.substring(4) + iban.substring(0, 4);
        Integer remainder = 0;
        for (Integer i = 0; i < rearranged.length(); i++) {
            Integer code = rearranged.charAt(i);
            String digits = code >= 65 ? String.valueOf(code - 55) : String.valueOf(code - 48);
            for (Integer j = 0; j < digits.length(); j++) {
                remainder = Math.mod(remainder * 10 + (digits.charAt(j) - 48), 97);
            }
        }
        return remainder == 1;
    }
}
