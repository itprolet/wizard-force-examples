@IsTest
private class ValidateIbanTest {

    @IsTest
    static void validIbansPass() {
        ValidateIban validator = new ValidateIban();
        Assert.isNull(validator.validate('BG80BNBG96611020345678', null));
        Assert.isNull(validator.validate('DE89370400440532013000', null));
        Assert.isNull(validator.validate('gb82 west 1234 5698 7654 32', null), 'spaces and lower case are accepted');
    }

    @IsTest
    static void emptyValueIsNotValidatedHere() {
        ValidateIban validator = new ValidateIban();
        Assert.isNull(validator.validate(null, 'msg'));
        Assert.isNull(validator.validate('  ', 'msg'));
    }

    @IsTest
    static void wrongChecksumFails() {
        Assert.areEqual('Custom', new ValidateIban().validate('BG81BNBG96611020345678', 'Custom'));
    }

    @IsTest
    static void wrongFormatFailsWithDefaultMessage() {
        Assert.areEqual('Invalid IBAN', new ValidateIban().validate('12345', null));
        Assert.areEqual('Invalid IBAN', new ValidateIban().validate('BG80-BNBG', ''));
    }

    @IsTest
    static void worksThroughTheFrameworkInterface() {
        // This is how the framework creates it: Type.forName(<name from Rules__c>)
        IValidator validator = (IValidator) Type.forName('ValidateIban').newInstance();
        Assert.isNull(validator.validate('BG80BNBG96611020345678', null));
    }
}
