export function validateFeedbackEmail(value, message) {
    if (!value) return undefined;
    const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
    return ok ? undefined : (message || 'Invalid email');
}