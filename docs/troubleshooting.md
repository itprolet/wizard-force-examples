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

## "WIZARD_PATH_VERSION_CONFLICT ..."

The wizard changed after the tab read it: another tab, another browser, or your own Apex. Nothing was saved; the wizard shows the latest state with a warning. If your own Apex changes the wizard during a page's action, return its `prolet.WizardVersionChange` and send it with the page's refresh (see [Data Model](data-model.md)).

## "Invalid Wizard_Setup**mdt.Plan**c: ..."

The plan has a mistake, listed in the message: a step without a page, a condition with a single value instead of an object (`"if (vip)": "Page"`), the same step twice in branches that can show together, or JSON that is not an object. Give a repeated page another step title, or a suffix (`Address_2`).

## "Unknown wizard type ..." (`Wizard_err_unknown_type`)

`prolet__Wizard_Type__c` must be the `DeveloperName` of a `prolet__Wizard_Setup__mdt` record, exactly (case included). Deploy the record with the wizard, or correct the type.

## "The wizard is locked" (`Wizard_err_locked`)

Something tried to change the answers of a locked wizard: a second submit, a page of a submitted wizard. Show the wizard read-only; unlock it from Apex if it must change ([Locked Wizards](locked-wizards.md)).

## "The wizard is not complete" (`Wizard_err_not_completed`)

`prolet.WizardApi.assertCompleted` refused a submit: the path did not reach the last page of the plan, or a page before it does not pass its checks (named in the message).

## A lookup shows "The list could not be loaded"

The browser always gets this one message; the reason is in the debug log of the user. Common ones: the setting has neither a query nor a class, the class is not found (in an org with its own namespace, write `myns.MyLookup`), the user lacks the `RequiredPermission__c`, or the query selects a field the user may not read. "lookup-name is missing" in the list itself means the page did not pass `lookup-name`, `key-field` or `name-field`.

## A page stays empty, or the wizard waits

- The plan names a page that is not in `page-registry`: check the spelling, it is case-sensitive.
- The page never answered `handlePage`: it must always send `pagechange` (with its direction, or `error`). Pages on `wizardPageBase` always do.

## A condition never applies

A condition that cannot be read counts as `false` and is written to the browser console and the debug log once. Check quotes (`'text'`), `=` (not `==`), and the type: `'20'` is a text, `20` a number, and they are never equal.

## A validator does not run on one side

A validator must exist under the same name in the browser (the registry) and on the server (a `global` Apex class); the missing side is logged once. Use `"scope": "client"` or `"scope": "server"` for a validator that belongs to one side only.

## "Type cannot be serialized"

Your Apex called `JSON.serialize` or `JSON.deserialize` on a class of the package. Build the JSON from maps instead (see [Namespace](namespace.md)).

## The page shows old components after a deploy

Lightning caches components: reload with Ctrl+Shift+R.
