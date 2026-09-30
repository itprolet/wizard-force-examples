/**
 * Field validator: validates that a value is a well-formed email address.
 * Registered in the wizard Rules under `validators.email`.
 *
 * @param {string} value  - field value to validate
 * @param {string} message - custom error message from the Rules config (optional)
 * @returns {string|undefined} error message, or undefined when valid
 */
export function validateShowcaseEmail(value, message) {
  if (!value) return undefined;
  const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  return ok ? undefined : message || "Please enter a valid email address.";
}
