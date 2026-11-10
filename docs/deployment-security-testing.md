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

| Permission set                         | Gives                                                                                                                                                                                                                                 |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prolet__Wizard_Framework_User`        | The package's objects, fields and Apex; the user's own wizards (Create, Read, Edit). No Delete, no View All.                                                                                                                          |
| `prolet__Wizard_Framework_Back_Office` | Read and **View All** on `prolet__Wizard__c`, and the custom permission `Wizard_View_Other_Users` (to list another user's wizards). Read-only: it cannot change anyone's wizard. Assign it **together with** `Wizard_Framework_User`. |

`prolet__Wizard__c.prolet__State__c` and `prolet__PathVersion__c` are read-only in the permission set: they change only through the package.

## Guest Users

Guest users (a public Experience Cloud site without login) are **not supported**: a record a guest creates belongs to the site's default owner, so after the first **Next** the guest can no longer read their own wizard. A guest flow needs a design of its own (a sharing rule on a field, or a controller that checks a token), not a controller `without sharing`.

## A Process That Writes Someone Else's Wizard

A manager's decision or a review writes a wizard the manager does not own. The package does not give Modify All (in Salesforce it includes Delete). Your process decides who may act, checks it in its own Apex, and only then writes the wizard. The [expense example](../examples/expense) shows one way: access to the expense report decides, and the report-to-wizard link is set on the server and checked before anything is read.

## Your Own Apex

- Controllers `with sharing`, queries `WITH USER_MODE` (or `stripInaccessible`).
- A lookup class: keep `WITH USER_MODE`; the package also removes fields the user may not read from what it returns.
- `prolet__Smart_Lookup_Setting__mdt.prolet__RequiredPermission__c` limits a lookup to users with a custom permission (staff data on a customer site, say).
- Validators and lookup classes are `global`, so the package can create them.

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

Each example has its tests in `classes/tests`.

## Installing and Upgrading

- 0.2.0 is not an upgrade of the 0.1.0 beta: a beta cannot be upgraded. Uninstall 0.1.0 first, then install 0.2.0.
- Wizards saved with a state from before 0.2.0 (`SIGNED`, `REVIEW`, `APPROVED`) count as locked.
- `prolet__Wizard_Type__c` is a text field in 0.2.0 (it was a picklist): a new type needs only its `Wizard_Setup__mdt` record.
- Moving `prolet__Wizard__c` to Private makes Salesforce recalculate sharing: users lose access to other users' wizards at once. Try it in a sandbox first, and give `Wizard_Framework_Back_Office` to the people who must see everything.
