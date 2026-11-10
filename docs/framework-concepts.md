---
title: Framework Concepts
---

# Framework Concepts

This page explains the runtime model of the Wizard Framework for developers who build on the package without access to its source: how a wizard type, its pages, the registry, the checks, navigation and locking work together.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Runtime Building Blocks

- `prolet__Wizard__c`: one record per wizard a user fills in.
- `prolet__Wizard_Setup__mdt`: one record per wizard type, with its plan, rules and title.
- `<prolet-wizard>`: the container that shows the steps, the current page and the buttons.
- Your page LWCs, registered by name in a registry component.
- Your validators (JavaScript, Apex), named in the rules.
- Your submit, in Apex, that turns the answers into your own records.

## `prolet__Wizard__c`: One Wizard

Each wizard a user fills in is one record:

| Field            | What it holds                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------- |
| `Wizard_Type__c` | The type: the `DeveloperName` of a `Wizard_Setup__mdt` record. A type without one is refused.       |
| `Model__c`       | The answers, as JSON: one object per page (`{ "Trip": { "city": "Sofia" } }`).                      |
| `Context__c`     | The context of the process, as JSON (`$ctx` in the rules). Written by your Apex, never by the user. |
| `State__c`       | `ACTIVE` (the user fills it in) or `LOCKED` (read-only). Anything but `ACTIVE` counts as locked.    |
| `Path__c`        | The pages the user went through, in order.                                                          |
| `PathVersion__c` | The version of the wizard: one more on every real change of the fields above.                       |

A new wizard first shows its first page without a record: the record is created on the first **Next**. Details: [Data Model](data-model.md).

## The Wizard Type: Plan and Rules

A `Wizard_Setup__mdt` record has three fields:

- `Title__c`: the title of the wizard (a label name or a text).
- `Plan__c`: the steps, as JSON: each step has a title (its key) and a page name (its value). A step can be shown only under a condition (`"if (...)"`), and can pass parameters to its page.
- `Rules__c`: per page, what is required, hidden, read-only, which patterns and validators apply, and page-level errors; also under conditions.

Conditions read the answers (`city = 'Sofia'`, `Contact.kind = 'company'` for another page), the context (`$ctx.status`) and the constants the setup names (`$con.MAX_DAYS`, from `Wizard_Contstant__mdt`). The browser and the server read them the same way.

A page name in the plan must be a key of the page registry; otherwise the wizard cannot show that page.

## Pages and the Registry

The wizard resolves your code by name:

- page name → page LWC constructor (`pageRegistry`);
- validator name → JavaScript validator function (`validatorRegistry`); a name that is not there may be an Apex class (see [Validation](validation.md));
- label names → texts (`l`).

The usual way is a registry LWC that renders `<prolet-wizard>` with these maps. See [Registry API](registry-api.md).

## A Page

A page receives the answers of the whole wizard (`model`) and what the rules say about its fields (`required`, `readOnly`, `visible`, `errors`, `hints`, `messages`, `patterns`), plus the wizard's `state`. It shows its fields and sends its answers back when the wizard asks it to move (`handlePage`), with a `pagechange` event. Extending `prolet/wizardPageBase` gives all of this in one place.

The wizard does the moving and the checks; the page renders and reacts to its own fields.

## Navigation

- **Next** checks the page (in the browser, then on the server) and saves its answers; the server decides the next page from the plan.
- **Previous** goes back without checks.
- **A step of the progress bar** goes back to an earlier page of the path. Later pages are reached one at a time, with **Next**. (In a locked wizard every page of its path can be opened, forward too.)

`prolet.WizardNavigationMode` is the direction of a move: `FORWARD`, `BACKWARD` or `JUMP` (to a step). It is not a policy.

Each move sends the version of the wizard the tab has. If another tab, another browser or your own Apex changed the wizard in between, the server refuses the move, saves nothing, and the wizard shows the latest saved state with a warning (code `WIZARD_PATH_VERSION_CONFLICT`).

## The Order of the Checks

For a page, the checks run in this order, in the browser and again on the server:

1. `required`: a required field without a value (a hidden field is never required);
2. `ticked`: a checkbox that must be ticked ("I agree");
3. field validators (`validators`): your JavaScript functions in the browser, your `prolet.IValidator` classes on the server;
4. page validators (`pageValidators`): your page-level JavaScript, your `prolet.IPageValidator` classes on the server;
5. `pageErrors`: errors the rules raise for the whole page (under a condition);
6. `patterns`: a regular expression per field.

Any of them stops the move and shows its message. On **Next** the server checks every page of the path, not only the current one. See [Validation](validation.md).

## Locked Wizards

A wizard is `ACTIVE` while the user fills it in, and `LOCKED` once it is submitted. A locked wizard only shows: every field is read-only, nothing is saved, and the server refuses every write of the answers. Your submit locks it with `prolet.WizardApi.lock`, after `assertCompleted`. Your Apex can still write its context (a status the user sees), and can unlock it again. See [Locked Wizards](locked-wizards.md).

## What the Package Owns, What You Own

The package owns the wizard: its record, its moves, its checks, its locking. You own:

- your page LWCs and your registry;
- your validators;
- your submit and your own records;
- the security of your own Apex (`with sharing`, `USER_MODE`).

Rely only on what these pages document. Anything else in the package may change.

## Related Documentation

- [Getting Started](getting-started.md)
- [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md)
- [Validation](validation.md)
- [Data Model](data-model.md)
- [Locked Wizards](locked-wizards.md)
- [Apex Extension Points](apex-extension-points.md)
