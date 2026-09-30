export function validateEmail(value, message) {
  if (!value) {
    return undefined;
  }
  const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  return ok ? undefined : message || "Please enter a valid email address";
}