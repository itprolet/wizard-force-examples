---
title: Validation
---

# Validation

Checks are written once, in the rules (`prolet__Rules__c`), and run in the browser while the user fills a page and again on the server on every move. This page lists the rules, the order they run in, and how to plug in validators of your own.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## The Rules of a Page

`Rules__c` is a JSON object keyed by page name:

```json
{
  "ContactPage": {
    "required": ["name", "email"],
    "patterns": { "zip": "\\d{4}" },
    "validators": { "email": ["validateEmail"] },
    "if (kind = 'company')": {
      "required": ["vat"],
      "pageValidators": [
        {
          "validator": "ValidatePattern",
          "fields": ["companyName"],
          "pattern": "$con.regex_cyrillic",
          "message": "My_err_cyrillic"
        }
      ]
    }
  }
}
```

| Rule                | What it does                                                                                                          |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `required`          | Fields that must have a value. For a checkbox, `false` is an answer (yes/no).                                         |
| `ticked`            | Checkboxes that must be ticked to go on ("I agree"). A path to a field, not a pattern.                                |
| `hidden`            | Fields not shown. A hidden field is never required.                                                                   |
| `readOnly`          | Fields the user cannot change; the server keeps their stored values too.                                              |
| `patterns`          | A regular expression per field, for the whole value. `(?i)` at the start ignores case. An empty field is not checked. |
| `validators`        | Per field, a list of validator names (or `{ "validator", "message", ... }`).                                          |
| `pageValidators`    | Validators of the whole page: `{ "validator": "Name", "message": "...", ...settings }`.                               |
| `pageErrors`        | Errors for the whole page (a text or a list), usually under a condition.                                              |
| `hints`, `messages` | A text per field: a `?` next to the label, a line under the field.                                                    |
| `navigationByChild` | `true`: the page has its own buttons and sends the moves itself.                                                      |
| `hideProgress`      | `true`: no steps on the left for this page.                                                                           |

Field lists accept dotted paths (`address.city`), `*` for every field, and `-name` to leave one out (`["*", "-comment"]`). `address` written exactly covers all of its fields.

A message (`message`, `pageErrors`, `hints`, `messages`) may be a label name: it is translated from the wizard's labels and the org's custom labels.

## Conditions

A key `"if (expression)"`, `"else if (expression)"` or `"else"` holds rules that apply only then. Expressions read:

- the page's own answers by name (`kind`), another page's by page name (`ContactPage.kind`);
- `$ctx.name` (the wizard's context) and `$con.Name` (a constant);
- texts in single quotes (`'it''s'`), numbers, `true`, `false`, `null`.

Operators: `=`, `!=` / `<>`, `<`, `<=`, `>`, `>=`, `~` (contains), `<<` (starts with), `>>` (ends with). Functions: `AND(a, b, ...)`, `OR(a, b, ...)`, `NOT(a)`, `isEmpty(a)`.

- `=` and `!=` compare value and type: texts exactly, case included (`'Active'` is not `'active'`); a text is never equal to a number (`'20'` is not `20`).
- `<`, `>` and the others order two numbers or two texts; a text against a number is `false`. Save a number as a number.
- A condition that cannot be read is `false`, and is written to the log once.

The browser and the server read conditions the same way.

## The Order of the Checks

For each page, in the browser and on the server:

1. `required`
2. `ticked`
3. `validators` (field validators)
4. `pageValidators`
5. `pageErrors`
6. `patterns`

An empty required field shows `Wizard_err_required_field` once the user has pressed **Next**, and from then on while they fill the page. A value that does not match its pattern shows `Wizard_err_invalid_value`.

On **Next** the server checks every page of the path; a page that does not pass stops the move.

## Validators of Your Own

A validator has the same name on both sides: a JavaScript function in the browser, an Apex class on the server. A side that has no validator of that name skips it and logs it once. `"scope": "client"` in the rule runs it only in the browser, `"scope": "server"` only on the server.

**In the browser**, register the functions in your registry:

```js
// a field validator: undefined when valid, otherwise the message
export function validateFeedbackEmail(value, message) {
  if (!value) return undefined;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
    ? undefined
    : message || "Invalid email";
}

// a page validator: true when valid; errors gets field -> message, or $global
export function validateExpenseLimit(page, model, props, errors) {
  const total = (model?.[page]?.expenses || []).reduce(
    (sum, item) => sum + Number(item?.amount || 0),
    0,
  );
  if (total > Number(props?.limit)) {
    errors.$global =
      props?.message || "The total amount exceeds the allowed limit";
    return false;
  }
  return true;
}
```

```html
<prolet-wizard
  page-registry="{pageRegistry}"
  validator-registry="{validatorRegistry}"
  page-validator-registry="{pageValidatorRegistry}"
  wizard-type-config="Expense"
></prolet-wizard>
```

**On the server**, a `global` class implementing `prolet.IValidator` or `prolet.IPageValidator` (see [Apex Extension Points](apex-extension-points.md)). If your org has a namespace of its own, name the class with it in the rules (`myns.ValidateIban`).

## Built In: `ValidatePattern`

A page validator for several fields at once:

```json
{
  "validator": "ValidatePattern",
  "fields": ["firstName", "lastName"],
  "pattern": "$con.regex_cyrillic",
  "message": "My_err_cyrillic"
}
```

It needs no registration, in the browser or on the server.

## Patterns on Both Sides

A pattern is read by Java on the server and by JavaScript in the browser. Use only what both understand: no possessive quantifiers (`*+`, `++`), no `\p{...}`, and no flags but a leading `(?i)`.

## Examples

- [feedback](../examples/feedback): a field validator (`validatorFeedbackEmail`)
- [embedded](../examples/embedded): a validator in the single-page mode
- [clubMembership](../examples/clubMembership): `ticked`, `hidden`, page validators
- [expense](../examples/expense): constants, `IValidator` and `IPageValidator` on the server
