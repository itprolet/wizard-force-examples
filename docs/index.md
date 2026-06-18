---
title: Wizard Framework
description: Developer documentation for the Wizard Framework Salesforce managed package.
---

# Wizard Framework

Wizard Framework is a Salesforce managed package for building configurable, multi-step wizard experiences. The package source is not public. This documentation repository is the public entry point for developers who want to evaluate the package, install it, and build subscriber-owned wizard implementations on top of its supported API.

This guide is written for Salesforce developers who already understand Apex, Lightning Web Components, metadata deployment, permission sets, layouts, and managed packages. It explains the package contract: which components, Apex interfaces, base classes, configuration records, validators, and extension patterns are available to subscriber code.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Review Mode](review-mode.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Repository Model

This public repository contains documentation and working examples, not the managed package implementation.

Repository structure:

```text
README.md
docs/
  index.md
  framework-concepts.md
  getting-started.md
  build-a-wizard.md
  registry-api.md
  apex-extension-points.md
  validation.md
  data-model.md
  lwc-components.md
  themes.md
  review-mode.md
  deployment-security-testing.md
  troubleshooting.md
examples/
  basic-wizard/
  feedback-wizard/
  complaint-wizard/
```

The root `README.md` introduces the package and links to the published GitHub Pages site. The `docs/` folder is the GitHub Pages source. The `examples/` folder contains deployable subscriber-style implementations that demonstrate the documented contracts.

Source links in the documentation should point to public example code. They should not point to private package implementation files. When a framework class or method is discussed, the docs should show the public signature and contract directly, then link to an example that uses it.

## What The Package Provides

| Area | Public contract to document | Example source to provide |
|---|---|---|
| Wizard runtime | How `Wizard__c` stores type, model, context, path, review data, and state | Example metadata and submit service |
| Wizard configuration | How `Wizard_Setup__mdt` defines the plan, rules, and title | Example `Wizard_Setup__mdt` records |
| Wizard container | How to place and configure the `wizard` component | Example registry component template |
| Shared page mode | How and when to use `wizardPageShare` | Experience Cloud example |
| Runtime registry | How to register page components, validators, labels, and review mappings | Example registry LWC |
| Page components | Required `@api` properties, events, and lifecycle expectations | Example wizard page LWCs |
| Validation | JavaScript validators, page validators, Apex validators, and built-in pattern validation | Example client and server validators |
| Apex extension points | Supported interfaces/base classes, abstract methods, virtual methods, return values, and examples | Example custom selector/service/validator classes |
| Reusable UI | Public `@api` surface of input, navigation, visualization, toast, tooltip, tile, and datatable components | Example pages using the components |
| Themes | Public color, shape, and personalization options | Example themed wizard |
| Review mode | `modifyOnlyList`, list filters, read-only rules, and change-required behavior | Example review flow |

## How To Read This Documentation

The documentation answers practical extension questions:

- If I want a custom wizard type, what metadata do I create?
- If I want custom pages, what LWC contract do they implement?
- If I want custom page validation, which JavaScript or Apex API do I use?
- If I want a custom server-side validator, which interface do I implement and what should `validate()` return?
- If I want custom data access, which selector base class or interface do I extend?
- If I want custom domain/service behavior, which base class do I inherit and which abstract or virtual methods must be implemented?
- If I want custom transaction handling, which unit-of-work API is supported?
- If I want to build SOQL safely with the package helper, how does the query builder chain and what does `toSOQL()` return?
- If I want review mode, how do I configure editable paths such as `items[id=1]` or `items[id=1].name`?

The goal is not to explain Apex or LWC from first principles. The goal is to make the package usable without access to the package source.

## Integration Pattern

A subscriber implementation usually adds four things around the installed package:

1. A `Wizard_Setup__mdt` record that defines the wizard type, page plan, and validation rules.
2. One or more custom LWC page components that implement the wizard page contract.
3. A registry LWC that connects the package runtime to subscriber page components, validators, labels, and review field mappings.
4. Subscriber-owned Apex or JavaScript submit logic that maps the wizard model to business records.

The recommended LWC pattern is a small registry component that renders the package `wizard` component and passes registries into it.

```js
import { LightningElement } from "lwc";
import FeedbackRating from "c/feedbackRating";
import FeedbackComment from "c/feedbackComment";
import FeedbackSummary from "c/feedbackSummary";
import { validateFeedbackEmail } from "c/validateFeedbackEmail";

export default class FeedbackWizardRegistry extends LightningElement {
  pageRegistry = {
    FeedbackRating,
    FeedbackComment,
    FeedbackSummary
  };

  validatorRegistry = {
    validateFeedbackEmail
  };
}
```

```html
<template>
  <c-wizard
    page-registry={pageRegistry}
    validator-registry={validatorRegistry}
    wizard-type-config="Feedback"
  >
  </c-wizard>
</template>
```

The examples include the source for this pattern, including registry LWCs, page LWCs, custom metadata, validators, and submit services.

## Apex Extension Documentation Style

Because the package source is private, Apex documentation should be contract-first. For each supported extension point, include:

- Purpose and intended use.
- Public signature.
- Constructor requirements.
- Abstract methods that must be implemented.
- Virtual methods that may be overridden.
- Parameter and return types.
- Success and error semantics.
- Minimal implementation example.
- Link to a public example class that uses the contract.

Example format:

```apex
global class MySelector extends WfSObjectSelector {
    // Document required overrides here.
}
```

The final API reference should make it clear which global artifacts are supported extension points and which artifacts are not intended for direct subscriber use.

## First Installation Checklist

For a subscriber org, the first integration normally needs:

- The installed `wizard-framework` managed package.
- The package permission set assigned to users who run wizards.
- Required page layout assignments if users need direct access to package records.
- A `Wizard_Setup__mdt` record for the custom wizard type.
- A registry LWC placed on the target Lightning or Experience page.
- Custom page LWCs registered under the same names used by `Plan__c`.
- Optional JavaScript and Apex validators referenced by `Rules__c`.
- Submit logic that maps `Wizard__c.Model__c` to subscriber-owned business records.

## Documentation Map

This documentation is intended to be published as a multi-page GitHub Pages site.

| Page | Purpose |
|---|---|
| [Framework Concepts](framework-concepts.md) | Runtime model, extension boundaries, lifecycle, and validation flow |
| [Getting Started](getting-started.md) | Installation prerequisites and the smallest working wizard |
| [Build a Wizard](build-a-wizard.md) | End-to-end implementation walkthrough |
| [Registry API](registry-api.md) | Registry patterns and JavaScript API contracts |
| [Apex Extension Points](apex-extension-points.md) | Supported global Apex extension contracts |
| [Validation](validation.md) | Client-side, page-level, and Apex validation |
| [Data Model](data-model.md) | DTOs, navigation data, path data, status data, and wizard data |
| [LWC Components](lwc-components.md) | Public component catalog and `@api` properties |
| [Themes](themes.md) | Color, shape, and personalization APIs |
| [Review Mode](review-mode.md) | Review mode, `modifyOnlyList`, and list filters |
| [Deployment, Security, and Testing](deployment-security-testing.md) | Subscriber deployment and ownership guidance |
| [Troubleshooting](troubleshooting.md) | Common integration failures and fixes |
| [GitHub Pages Setup](github-pages-setup.md) | How to publish this documentation from the `docs/` folder |

## Project Tracking

- Publication readiness checklist: [`../PUBLICATION_CHECKLIST.md`](../PUBLICATION_CHECKLIST.md)
- Docs progress tracker: [`../DOCS_PROGRESS.md`](../DOCS_PROGRESS.md)

## Next Step

Start with [Getting Started](getting-started.md) to create a minimal wizard, then use [Build a Wizard](build-a-wizard.md) for the full registration, validation, and submit flow.
