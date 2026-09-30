/**
 * Page validator: ensures at least one session slot is selected on the Schedule page.
 * Registered in the wizard Rules under `pageValidators`.
 *
 * The framework calls this with signature: (page, model, entry, errors)
 *   page   – the current page key (e.g. 'ShowcaseSchedule')
 *   model  – the complete wizard model map
 *   entry  – the ValidatorEntry object (contains `message` and other properties)
 *   errors – mutable errors map; set a key here to surface an error in the page
 *
 * @returns {boolean} true if validation passes
 */
export function validateSessionMin(page, model, entry, errors) {
  const pageModel = (model && model[page]) || {};
  const hasSession = Object.keys(pageModel).some(
    (key) => key.startsWith("session") && pageModel[key] === true
  );
  if (!hasSession) {
    errors.sessionMin =
      (entry && entry.message) || "Please select at least one session slot.";
    return false;
  }
  return true;
}
