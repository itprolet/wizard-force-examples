@IsTest
private class ValidateExpenseLimitTest {

    private static final String PAGE = 'ExpenseItems';

    private static Map<String, Object> model(List<String> amounts) {
        List<Object> expenses = new List<Object>();
        Integer i = 0;
        for (String amount : amounts) {
            expenses.add(ExpenseReportTestData.expense('e' + (i++), 'other', '2026-10-05', amount));
        }
        return new Map<String, Object>{ PAGE => new Map<String, Object>{ 'expenses' => expenses } };
    }

    private static WizardPageRules.ValidatorEntry entry(Object limitValue, String message) {
        return new WizardPageRules.ValidatorEntry(new Map<String, Object>{
                'validator' => 'ValidateExpenseLimit', 'limit' => limitValue, 'message' => message
        });
    }

    @IsTest
    static void underLimitPasses() {
        Map<String, Object> errors = new Map<String, Object>();
        Assert.isTrue(new ValidateExpenseLimit().validate(PAGE, model(new List<String>{ '100', '200,50' }),
                entry('5000', null), errors));
        Assert.isTrue(errors.isEmpty());
    }

    @IsTest
    static void overLimitFailsWithGlobalError() {
        Map<String, Object> errors = new Map<String, Object>();
        Boolean valid = new ValidateExpenseLimit().validate(PAGE, model(new List<String>{ '3000', '2500' }),
                entry(5000, 'Too much'), errors);
        Assert.isFalse(valid);
        Assert.areEqual('Too much', errors.get('$global'));
    }

    @IsTest
    static void defaultMessage() {
        Map<String, Object> errors = new Map<String, Object>();
        new ValidateExpenseLimit().validate(PAGE, model(new List<String>{ '10' }), entry('5', null), errors);
        Assert.areEqual('The total amount exceeds the allowed limit', errors.get('$global'));
    }

    @IsTest
    static void missingConfigurationPasses() {
        Map<String, Object> errors = new Map<String, Object>();
        ValidateExpenseLimit validator = new ValidateExpenseLimit();
        Assert.isTrue(validator.validate(PAGE, model(new List<String>{ '10' }), entry(null, null), errors));
        Assert.isTrue(validator.validate(PAGE, model(new List<String>{ '10' }), entry('abc', null), errors));
        Assert.isTrue(validator.validate(null, model(new List<String>{ '10' }), entry('5', null), errors));
        Assert.isTrue(validator.validate(PAGE, new Map<String, Object>(), entry('5', null), errors));
        Assert.isTrue(errors.isEmpty());
    }

    @IsTest
    static void worksThroughTheFrameworkInterface() {
        IPageValidator validator = (IPageValidator) Type.forName('ValidateExpenseLimit').newInstance();
        Map<String, Object> errors = new Map<String, Object>();
        Assert.isFalse(validator.validate(PAGE, model(new List<String>{ '10' }), entry('5', null), errors));
    }
}
