/**
 * Field validator for the embedded single-page wizard example.
 *
 * Validators are the framework's mechanism for custom field error messages: a `patterns`
 * rule only vetoes navigation silently, whereas a validator returns a message string that
 * the wizard delivers back as errors[field] and the input renders below the field.
 *
 * Contract: return `undefined` when the value is valid, or the error message when invalid.
 * The optional `message` arg comes from the Rules__c entry, allowing the text to be
 * configured without code; falls back to a sensible default.
 */
export function validateEmbeddedEmail(value, message) {
  if (!value) {
    return undefined;
  }
  const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  return ok ? undefined : message || "Please enter a valid email address";
}
