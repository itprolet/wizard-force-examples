---
title: Troubleshooting
---

# Troubleshooting

Common errors, what they mean, and what to do.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## "Wizard not found, id= ..."

The user cannot see the wizard: it was deleted, or the org's sharing does not give it to them. `prolet__Wizard__c` is **Private**: a user sees only their own wizards, unless the role hierarchy, a sharing rule, manual sharing or View All gives them others. People who must read every wizard need `prolet__Wizard_Framework_Back_Office`. With `wizard-type-config`, a link to someone else's wizard starts a new one instead.

## "This wizard was changed in another tab or window. ..."

The wizard changed after the tab read it: another tab, another browser, or your own Apex. The move was refused by the server (`WIZARD_PATH_VERSION_CONFLICT`, which the user does not see), nothing was saved, and the wizard shows the latest state with one of these warnings: what you entered "was not saved", "is still here but was not saved yet", or "The page now shows the latest saved state". If your own Apex changes the wizard during a page's action, return its `prolet.WizardVersionChange` and send it with the page's refresh (see [Data Model](data-model.md)).

## `Invalid Wizard_Setup__mdt.Plan__c: ...`

The plan has a mistake, listed in the message: a step without a page, a condition with a single value instead of an object (`"if (vip)": "Page"`), the same step twice in branches that can show together, or JSON that is not an object. Give a repeated page another step title, or a suffix (`Address_2`).

## "Unknown wizard type ..." (`Wizard_err_unknown_type`)

`prolet__Wizard_Type__c` must be the `DeveloperName` of a `prolet__Wizard_Setup__mdt` record, exactly (case included). Deploy the record with the wizard, or correct the type.

## "This wizard is locked: it can only be viewed, changes are not saved." (`Wizard_err_locked`)

Something tried to change the answers of a locked wizard (`prolet__State__c` is not `ACTIVE`): a second submit, a page of a submitted wizard. Show the wizard read-only; unlock it from Apex if it must change ([Locked Wizards](locked-wizards.md)).

## "The wizard is locked and cannot be changed now ..." (`Wizard_err_record_locked`)

Not the wizard's state: Salesforce itself locked the record, for example while it waits in an approval process. `prolet.WizardApi.unlock` does not help; the record is free again when the approval is decided (or recalled), or an admin unlocks it.

## "The wizard is being saved by another request. Please try again." (`Wizard_err_busy`)

Two saves of one wizard at the same moment (a double click, two tabs). Trying again works.

## "The wizard is not complete: please go through every page before you submit it." (`Wizard_err_not_completed`)

`prolet.WizardApi.assertCompleted` refused a submit: the path did not reach the last page of the plan, or a page before it does not pass its checks (named in the message).

## A lookup shows "The list could not be loaded"

The browser always gets this one message; the reason is in the debug log of the user. Common ones: the setting has neither a query nor a class, the class is not found (it is not `global`, or in an org with its own namespace, write `myns.MyLookup`), the user lacks the `RequiredPermission__c`, or the query selects a field the user may not read. A message in the list itself names what the page did not pass: "lookup-name is missing", "key-field is missing", "name-field is missing", or "key-field and name-field are missing".

## A page stays empty, or the wizard waits

- "Unknown wizard page: X" (`Wizard_err_unknown_page`): the plan names a page X that is not in `page-registry`. Check the spelling, it is case-sensitive.
- The page never answered `handlePage`: it must always send `pagechange` (with its direction, or `error`). Pages on `wizardPageBase` always do.

## A condition never applies

A condition that cannot be read counts as `false` and is written to the browser console and the debug log once. Check quotes (`'text'`), `=` (not `==`), and the type: `'20'` is a text, `20` a number, and they are never equal.

## A validator does not run on one side

A validator must exist under the same name in the browser (the registry) and on the server (a `global` Apex class); the missing side is logged once. Use `"scope": "client"` or `"scope": "server"` for a validator that belongs to one side only.

## "Type cannot be serialized"

Your Apex called `JSON.serialize` or `JSON.deserialize` on a class of the package. Build the JSON from maps instead (see [Namespace](namespace.md)).

## The page shows old components after a deploy

Lightning caches components: reload with Ctrl+Shift+R.
