---
title: Deployment, Security, and Testing
---

# Deployment, Security, and Testing

How the package treats data access, what your own code should do, and how to test it.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Access to Wizards

A wizard holds one user's answers, often personal data, so it is **private**:

- `prolet__Wizard__c` has a **Private** sharing model (internal and external users). Its owner is the user who created it, on the first **Next**.
- The package works with the user's sharing (`with sharing`). A wizard the user cannot see is treated as one that does not exist ("Wizard not found").
- Others see a wizard only when your org gives it: role hierarchy, sharing rules, manual sharing, or View All.

| Permission set                         | Gives                                                                                                                                                                                                                                                                                                                    |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `prolet__Wizard_Framework_User`        | The package's objects, fields and Apex; the user's own wizards (Create, Read, Edit). No Delete, no View All. From 0.2.0.5: no app, so it can be given to the users of an Experience Cloud site too (their licenses allow no assigned apps); up to 0.2.0.4 it gives the Wizard app, and a site user's license refuses it. |
| `prolet__Wizard_Framework_Back_Office` | Read and **View All** on `prolet__Wizard__c`, and the custom permission `Wizard_View_Other_Users` (to list another user's wizards). Read-only: it cannot change anyone's wizard. From 0.2.0.5 it also gives the Wizard app (the list of wizards). Assign it **together with** `Wizard_Framework_User`.                   |

`prolet__Wizard__c.prolet__State__c`, `prolet__Context__c` and `prolet__PathVersion__c` are read-only in the permission set: they change only through the package (`prolet.WizardApi.lock`, `unlock`, `updateContext`), so a user cannot unlock a submitted wizard or change a manager's decision through the API.

### As the User

A user's request reads and writes `prolet__Wizard__c` **as the user** (`USER_MODE`): their object and field permissions and sharing apply.

- A user without `prolet__Wizard_Framework_User` is refused. Without the permission set at all, Salesforce refuses before the package's code, because the user may not call the controller class: the message is the platform's ("The Apex request is invalid" on an LWR site). A user who may call the classes (by their profile, say) but not read or write `prolet__Wizard__c` or one of its fields gets "You do not have access to this form. Ask your administrator for the permission set Wizard Framework User." (`Wizard_err_no_access`).
- A wizard shared with a user to read only opens, but a move is refused: "You can view this form but not change it." (`Wizard_err_read_only`).
- `prolet.WizardApi`, `prolet.WizardVersionChange.startChange` and `prolet.WizardSelector` work in system mode, also when your Apex calls them within a user's request (a validator, a submit): your code decides who may do what.
- This protects the fields from **the user**, not from your org's Apex: Apex in system mode can still write them with plain DML. Use `WizardApi` for the state and the context, so the version and the lock stay right.

### The Type of a Wizard

A wizard's type does not change once it has one whose `Wizard_Setup__mdt` record exists, whoever writes it, also your Apex (`Wizard_err_type_fixed`): the type chose the plan and the rules the answers were checked by. Another type is a new wizard. The one exception is a repair: a wizard whose type has no record any more (it was renamed or deleted) may be given a known type, for example `update new prolet__Wizard__c(Id = id, prolet__Wizard_Type__c = 'NEW_NAME')` or with Data Loader. A locked wizard keeps its type while it stays locked: unlock it in the same save as the new type (`prolet__State__c = 'ACTIVE'`), then lock it again. A repair keeps the answers and the context as they are.

## Guest Users

Guest users (a public Experience Cloud site without login) are **not supported**, and the package refuses them: every request of the wizard says "Please sign in to use this form." (`Wizard_err_guest`), and a lookup gives its general message. The reason: a record a guest creates belongs to the site's default owner, so after the first **Next** the guest can no longer read their own wizard. A guest flow needs a design of its own (a sharing rule on a field, or a controller that checks a token), not a controller `without sharing`.

## A Process That Writes Someone Else's Wizard

A manager's decision or a review writes a wizard the manager does not own. The package does not give Modify All (in Salesforce it includes Delete). Your process decides who may act, checks it in its own Apex, and only then writes the wizard. The [expense example](https://github.com/itprolet/wizard-force-examples/tree/main/examples/expense) shows one way: access to the expense report decides, and the report-to-wizard link is set on the server and checked before anything is read.

## Your Own Apex

- Controllers `with sharing`, queries `WITH USER_MODE` (or `stripInaccessible`).
- A lookup class: keep `WITH USER_MODE`; the package also removes fields the user may not read from what it returns.
- `prolet__Smart_Lookup_Setting__mdt.prolet__RequiredPermission__c` limits a lookup to users with a custom permission (staff data on a customer site, say): a permission of your org by its name, given through a permission set or the profile.
- Validators and lookup classes are `global` (a lookup's `call` method too): the package does not find a `public` class of your org.

## Testing

- Tests of your Apex create wizards directly. Write the path from maps (Apex outside the package cannot serialize the package's classes), and use `prolet.WizardStates.ACTIVE` for the state:

```apex
prolet__Wizard__c wizard = new prolet__Wizard__c(
    prolet__Wizard_Type__c = 'Feedback',
    prolet__State__c = prolet.WizardStates.ACTIVE,
    prolet__Model__c = JSON.serialize(answers),
    prolet__Path__c = pathJson(path)
);
insert wizard;
```

- A type must have a `prolet__Wizard_Setup__mdt` record: deploy it with your tests.
- A test user needs `prolet__Wizard_Framework_User` (assign it inside `System.runAs`).
- `prolet.WizardApi.parsePageRules(page, rules, model)` reads your rules as the package does, for tests of conditions; put `'$ctx'` / `'$con'` into the model when a condition reads them.

The examples with Apex have their tests in `classes/tests` (clubMembership also one next to its lookup, in `classes/lookups`); vacation and embedded have no Apex.

## Installing and Upgrading

- The org needs **Lightning Web Security** (Setup › Session Settings, on by default in new orgs). With Lightning Locker the framework's table does not load in Lightning Experience: see [Troubleshooting](troubleshooting.md).
- 0.2.0 is not an upgrade of the 0.1.0 beta: a beta cannot be upgraded. Uninstall 0.1.0 first (that removes its wizards too), then install 0.2.0.
- `prolet__Wizard_Type__c` is a text field: a new type needs only its `Wizard_Setup__mdt` record.
- `prolet__Wizard__c` is Private: a user sees their own wizards. Give `prolet__Wizard_Framework_Back_Office` to the people who must read everyone's.
- A user needs `prolet__Wizard_Framework_User`: without it the wizard is refused (see [As the User](#as-the-user)) instead of working in system mode. An admin who deploys the examples from source, too.
- The [expense example](https://github.com/itprolet/wizard-force-examples/tree/main/examples/expense) now has a **Private** `Expense_Report__c` (it was Public Read/Write): a reviewer sees a report through the role hierarchy (above its owner) or a share. In an org that has the earlier copy, set up the roles or a sharing rule for the reviewers **before** you deploy the new one (try it in a sandbox): after it, a reviewer without them gets "Expense report not found" for every pending report. Its tests assume Private (they use `Expense_Report__Share`).
