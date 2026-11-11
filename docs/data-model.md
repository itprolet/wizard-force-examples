---
title: Data Model
---

# Data Model

The records and values the wizard works with: the wizard record, its states and version, the URL parameters, and the single-page mode in which nothing is stored.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## `prolet__Wizard__c`

One record per wizard a user fills in. It is created on the first **Next**, not when the wizard opens, and its owner is the user who created it.

| Field                    | Type      | What it holds                                                                                                                                                                                                                                                           |
| ------------------------ | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prolet__Wizard_Type__c` | Text(40)  | The `DeveloperName` of a `prolet__Wizard_Setup__mdt` record. A type without one is refused (`Wizard_err_unknown_type`), also from a flow, an inline edit or Data Loader; an empty type too (`Wizard_err_type_required`). The comparison is exact: `test` is not `TEST`. |
| `prolet__Model__c`       | Long text | The answers, one JSON object per page: `{ "VacationDetails": { "startDate": "2026-12-01", "type": "sick" } }`.                                                                                                                                                          |
| `prolet__Context__c`     | Long text | The context of the process, as JSON: `$ctx` in the rules and in pages. Written by your Apex with `prolet.WizardApi.updateContext`, never by the user.                                                                                                                   |
| `prolet__State__c`       | Picklist  | `ACTIVE` or `LOCKED`. Anything but `ACTIVE` counts as locked. Read-only for users; see [Locked Wizards](locked-wizards.md).                                                                                                                                             |
| `prolet__Path__c`        | Long text | The pages gone through, as a JSON list of `{ "title", "page", "initParams" }`.                                                                                                                                                                                          |
| `prolet__PathVersion__c` | Number    | The version: one more on every real change of the path, the answers, the context, the state or the type, by any write. It never goes down. Read-only for users.                                                                                                         |

Each of the long text fields holds up to 131,072 characters; a write beyond that is refused.

## The Version and Two Tabs

Every move sends the version its tab knows. If anything changed the wizard in between (another tab, another browser, your own Apex), the server refuses the move with `WIZARD_PATH_VERSION_CONFLICT` and saves nothing. The wizard then reads the latest state and shows a warning; what the user typed on the page stays where the next move can save it.

When your Apex changes a wizard during a page's action (a submit, a calculation), wrap the writes so the page can send the change back with its refresh, and its own tab is not warned:

```apex
prolet.WizardVersionChange change = prolet.WizardVersionChange.startChange(wizardId);
try {
    // your writes of the wizard (WizardApi calls count as well)
} finally {
    change = change.finish();
}
return change; // the page sends it: refresh({ pageModel: null, versionChange: change })
```

`prolet.WizardApi` methods return a `WizardVersionChange` themselves.

## `prolet__Wizard_Setup__mdt`

One record per wizard type. Its `DeveloperName` is the type.

| Field              | What it holds                                                                                                                                                                                                                          |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prolet__Title__c` | The wizard's title: a label name (from the wizard's labels) or a text.                                                                                                                                                                 |
| `prolet__Plan__c`  | The steps, as JSON. Keys are step titles, values are page names or `{ "page": "Name", ...parameters }`. Conditions: `"if (...)"`, `"else if (...)"`, `"else"`.                                                                         |
| `prolet__Rules__c` | Per page name: `required`, `ticked`, `hidden`, `readOnly`, `patterns`, `hints`, `messages`, `validators`, `pageValidators`, `pageErrors`, `navigationByChild`, `hideProgress`; also under conditions. See [Validation](validation.md). |

The plan is checked when a wizard opens: a step without a page, a condition with a single value instead of an object, the same step twice in branches that can show together, or JSON that is not an object stop the wizard with `Invalid Wizard_Setup__mdt.Plan__c: ...`, listing every problem.

## Constants: `prolet__Wizard_Contstant__mdt`

A value per `DeveloperName` in `prolet__Value__c`, read as `$con.Name` in the plan and the rules (`"pattern": "$con.regex_cyrillic"`). Only the constants a wizard's plan or rules name reach the browser. Your Apex reads them directly (`prolet__Wizard_Contstant__mdt.getInstance('Name')`).

## The DTOs

Your Apex meets these global classes:

| Class                                              | What it is                                                                                                                                                                                          |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prolet.WizardPageData`                            | A step: `title`, `page`, `initParams` (texts) and `paramsJson` (the step's parameters with their types).                                                                                            |
| `prolet.WizardPageRules`                           | The rules of a page, read-only from outside the package: `required`, `hidden`, `readOnly`, `ticked`, `patterns`, `validators`, `pageValidators`, `pageErrors`, `navigationByChild`, `hideProgress`. |
| `prolet.WizardPageRules.ValidatorEntry`            | One validator in the rules: `validator`, `message`, `properties` (its other settings).                                                                                                              |
| `prolet.WizardData`, `prolet.WizardNavigationData` | What the wizard reads and what a move returns: the wizard, its pages, rules, version (`pathVersion`), `savedFields`, `noAdvance`.                                                                   |
| `prolet.WizardVersionChange`                       | `fromVersion` and `pathVersion` of a write; `startChange` / `finish`.                                                                                                                               |
| `prolet.WizardStates`                              | `ACTIVE`, `LOCKED`, `isLocked(state)`.                                                                                                                                                              |

## URL Parameters

| Parameter        | What it does                                                                                                                                                                 |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `c__wizardType`  | Starts a new wizard of this type, when there is no `c__wizardId`. Once its record exists, the wizard puts `c__wizardId` into the URL, so the page can be reloaded or shared. |
| `c__wizardId`    | Opens an existing wizard. With `wizard-type-config`, a comma-separated list for several wizards on one page: each takes the Id of its own type.                              |
| `c__currentId`   | The Id of a related record; pages receive it as `currentId`.                                                                                                                 |
| `app=commeditor` | Experience Builder: the wizard shows the record that `prolet__Wizard_Community_Editor_Map__mdt` maps to the current user, for previewing while editing the site.             |

With `wizard-type-config` the order is: the Id the tab remembers for this type, then `c__wizardId`, then a new wizard. Without it: `c__wizardId`, then `c__wizardType`.

## Single-Page Mode

A parent component can hold a one-page form itself: nothing is stored, no `prolet__Wizard__c` is created, nothing is sent to the server. The parent passes `plan-config` (one page), `rules-config` (usually with `"hideProgress": true` and `"navigationByChild": true`), `initial-model`, and optionally `wizard-title-config`, `context-config` (`$ctx`) and `constants-config` (`$con`). On every change the wizard sends `wizardchange` with `{ model, page, pageModel, valid, errors }`; `wizardcomplete` comes when the page sends `complete`. See the [embedded example](../examples/embedded).
