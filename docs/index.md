---
title: Wizard Framework
description: Developer documentation for the Wizard Framework Salesforce managed package.
---

# Wizard Framework

Wizard Framework is a Salesforce managed package (namespace `prolet`) for building configurable, multi-step wizards. The package source is not public. This repository is the public entry point for developers who want to evaluate the package, install it, and build their own wizards on top of its supported API.

This guide is written for Salesforce developers who already know Apex, Lightning Web Components, metadata deployment, permission sets and managed packages. It explains the package contract: which components, Apex classes, configuration records and extension points your own code can use.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Repository Model

This public repository contains documentation and working examples, not the managed package implementation.

```text
README.md
docs/                  GitHub Pages source (this site)
examples/
  vacation/            the smallest wizard: three pages, no Apex
  embedded/            a single form inside your own component, nothing stored
  feedback/            a full flow: own object, submit in Apex, a locked wizard
  serviceVisit/        a conditional page and lookups from metadata
  complaint/           labels, attachments, patterns, hints, page errors
  clubMembership/      a lookup written in Apex, ticked boxes, page validators, translations
  showcase/            every input and element of the package
  expense/             constants, server validators, two tabs, locking, a manager's review
  carRental/           an advanced look: tiles, photos, two objects
sfdx-project.json      one package directory per example
```

Every example is written for an org with the package installed: the framework's names carry the `prolet` namespace (`<prolet-wizard>`, `prolet/wizardPageBase`, `prolet.WizardApi`, `prolet__Wizard__c`), the example's own names do not. See [Namespace](namespace.md).

## What The Package Provides

| Area | What you use | Where it is documented |
|---|---|---|
| Wizard record | `prolet__Wizard__c`: type, answers, context, path, version and state of each wizard | [Data Model](data-model.md) |
| Wizard configuration | `prolet__Wizard_Setup__mdt`: the plan, the rules and the title of a wizard type | [Build a Wizard](build-a-wizard.md) |
| Wizard container | `<prolet-wizard>` and its attributes | [LWC Components](lwc-components.md) |
| Page base class | `prolet/wizardPageBase`: the page contract written once | [Registry API](registry-api.md) |
| Runtime registry | pages, validators and labels handed to the wizard | [Registry API](registry-api.md) |
| Validation | required, ticked, patterns, JavaScript and Apex validators, page validators | [Validation](validation.md) |
| Apex API | `prolet.WizardApi`, `prolet.WizardVersionChange`, `prolet.WizardStates`, `prolet.IValidator`, `prolet.IPageValidator` and the DTOs | [Apex Extension Points](apex-extension-points.md) |
| Reusable UI | inputs, alerts, datatable, tiles, progress | [LWC Components](lwc-components.md) |
| Lookups | `prolet__Smart_Lookup_Setting__mdt`: a query in metadata, or your own Apex class | [LWC Components](lwc-components.md) |
| Locking | `ACTIVE` / `LOCKED`, submit, unlock | [Locked Wizards](locked-wizards.md) |
| Themes | colours and shape | [Themes](themes.md) |

## How To Read This Documentation

The documentation answers practical questions:

- To add a wizard type, which metadata record do I create?
- What does a page LWC receive, and what does it send back?
- How do I make a field required, check a pattern, or run my own validator in the browser and on the server?
- How do I submit a wizard from Apex, lock it, and show it read-only afterwards?
- What happens when the same wizard is open in two tabs?
- Which names need the `prolet` namespace in my code?

It does not explain Apex or LWC from first principles. Its goal is to make the package usable without access to its source.

## Integration Pattern

A wizard in your org consists of:

1. A `prolet__Wizard_Setup__mdt` record: the wizard type, its plan of pages, and its rules.
2. Page LWCs, usually extending `prolet/wizardPageBase`.
3. A registry LWC that renders `<prolet-wizard>` and hands it your pages, validators and labels.
4. Optional Apex: a submit that turns the answers into your own records and locks the wizard.

The registry is a small component:

```js
import { LightningElement } from "lwc";
import FeedbackRating from "c/feedbackRating";
import FeedbackComment from "c/feedbackComment";
import WizardFeedbackSummary from "c/wizardFeedbackSummary";
import { validateFeedbackEmail } from "c/validatorFeedbackEmail";

export default class FeedbackWizardRegistry extends LightningElement {
  pageRegistry = {
    FeedbackRating,
    FeedbackComment,
    WizardFeedbackSummary
  };

  validatorRegistry = {
    validateFeedbackEmail
  };
}
```

```html
<template>
  <prolet-wizard
    page-registry={pageRegistry}
    validator-registry={validatorRegistry}
    wizard-type-config="Feedback"
  >
  </prolet-wizard>
</template>
```

Your own components stay in `c/`; only the package's are `prolet/`. The [feedback example](../examples/feedback) has the whole wizard: registry, pages, metadata, validator and submit.

## Supported Apex Surface

Only `global` Apex of the package can be used from your org. That is:

- `prolet.WizardApi`: `assertCompleted`, `lock`, `unlock`, `updateContext`, `likePattern`, `parsePageRules`;
- `prolet.WizardVersionChange`: `startChange` / `finish` around your own writes of a wizard;
- `prolet.WizardStates`: `ACTIVE`, `LOCKED`, `isLocked`;
- `prolet.WizardException` and its code `PATH_VERSION_CONFLICT`;
- `prolet.IValidator` and `prolet.IPageValidator`, for server-side validators;
- `prolet.WizardSelector.newInstance()` (`prolet.IWizardSelector`) to read wizards;
- the DTOs: `WizardPageData`, `WizardPageRules`, `WizardData`, `WizardNavigationData`, `WizardPathData`, `WizardStatusData`.

The package's internal classes (`WizardController`, `WizardService`, `WizardUtils`, `SmartLookupCtrl`, the `Wf*` selector / domain / unit-of-work classes) are not part of the contract. See [Apex Extension Points](apex-extension-points.md).

## First Installation Checklist

- Install the `Wizard Framework` package (see [Getting Started](getting-started.md)).
- Assign `prolet__Wizard_Framework_User` to everyone who fills in wizards.
- Assign `prolet__Wizard_Framework_Back_Office` to people who read other users' wizards.
- Create a `prolet__Wizard_Setup__mdt` record for your wizard type.
- Deploy your registry and page LWCs, and put the registry on a Lightning or Experience page.
- Add your submit logic, if the wizard creates records of your own.

## Documentation Map

| Page | Purpose |
|---|---|
| [Framework Concepts](framework-concepts.md) | Runtime model, lifecycle, navigation and the order of checks |
| [Getting Started](getting-started.md) | Installation and the smallest working wizard |
| [Build a Wizard](build-a-wizard.md) | End-to-end walkthrough |
| [Registry API](registry-api.md) | The registry, the page contract and `wizardPageBase` |
| [Apex Extension Points](apex-extension-points.md) | The global Apex API |
| [Validation](validation.md) | Rules, patterns, JavaScript and Apex validators |
| [Data Model](data-model.md) | `prolet__Wizard__c`, its states, URL parameters and the stateless mode |
| [LWC Components](lwc-components.md) | The components you can place in your pages |
| [Themes](themes.md) | Colours and shape |
| [Locked Wizards](locked-wizards.md) | `ACTIVE` / `LOCKED`, submit and unlock |
| [Namespace](namespace.md) | Which names need `prolet` in your code |
| [Deployment, Security, and Testing](deployment-security-testing.md) | Sharing, permissions, upgrades |
| [Troubleshooting](troubleshooting.md) | Common errors and what they mean |
| [GitHub Pages Setup](github-pages-setup.md) | Publishing this site from `docs/` |

## Next Step

Start with [Getting Started](getting-started.md) to install the package and run the vacation example, then use [Build a Wizard](build-a-wizard.md) for your own.
