---
title: Framework Concepts
---

# Framework Concepts

This page explains the Wizard Framework runtime model for subscriber developers who are extending the package without access to package source code.

Use this page to understand how wizard type configuration, page components, registries, validation, navigation, and review behavior work together at runtime.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Review Mode](review-mode.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Runtime Building Blocks

The package runtime is centered around a few core artifacts:

- `Wizard__c` as the persisted wizard state container.
- `Wizard_Setup__mdt` as the wizard type and behavior configuration.
- The `wizard` and `wizardPageShare` container components.
- Subscriber page LWCs registered through a registry component.
- JavaScript and Apex validators connected through rules.
- Subscriber submit services that map wizard model data to business records.

A subscriber implementation usually defines one or more wizard types, then binds each type to page component names and validation rules through metadata and registry contracts.

## `Wizard__c` As State Container

At runtime, each wizard instance uses a `Wizard__c` record to store:

- wizard type selection;
- page model JSON in `Model__c`;
- navigation and progress context;
- review mode state and optional review-only settings;
- runtime status information.

Your page components should treat this model as the single source of truth for user input gathered across steps.

## Wizard Type Contract

A wizard type is a runtime contract between:

1. metadata configuration (`Wizard_Setup__mdt`);
2. registry keys for pages and validators;
3. subscriber page and validator implementations.

The type configuration determines which page names are expected, how navigation behaves, which validators run, and how submit logic should interpret the model.

If a page name in metadata does not match a registered key, the wizard cannot resolve and render that page.

## Page Definition and Registry Resolution

The framework resolves page artifacts by registry key:

- page component key -> LWC constructor;
- validator key -> JavaScript validator function or Apex validator type reference;
- optional page-field mappings for review and data shaping;
- optional labels and localized text mappings.

The recommended pattern is a self-contained registry LWC that prepares all maps and passes them into the package container component.

## Page Component Data Flow

A page component is responsible for:

- receiving the current page model state from the container;
- rendering controls based on that state;
- emitting model updates in the expected shape;
- respecting page mode (editable, read-only, review behavior when active).

The container orchestrates page transitions and validation. Page components focus on rendering and local interaction, not global wizard orchestration.

## Navigation and Lifecycle

Navigation behavior is driven by package runtime state and configuration:

- initial page resolution;
- next/previous transitions;
- page validity gates before transition;
- terminal submit readiness checks.

`WizardNavigationMode` values influence whether navigation can proceed freely, is validation-gated, or follows stricter progression rules for a given flow.

## Validation Pipeline

Validation runs as a layered pipeline:

1. field-level JavaScript validators;
2. page-level JavaScript validators (`registerPageValidator`);
3. server-side Apex validators (`IPageValidator`) when configured;
4. built-in rules such as pattern validation.

The pipeline can stop progression, surface inline errors, or return structured page errors depending on validator type and contract.

## Review Mode Concept

Review mode allows users to inspect entered data before submit and, depending on configuration, edit only selected paths.

`modifyOnlyList` supports path-based control over what remains editable. This includes list filters like:

- `items[id=1]`
- `items[id=1].name`

Use review mode for confirmation-heavy flows where users need a final inspection step without reopening full page editing.

## Subscriber Ownership Boundaries

The managed package owns runtime orchestration. Subscriber code owns implementation details:

- custom page LWCs;
- custom JavaScript and Apex validators;
- selector/domain/unit-of-work extensions where supported;
- submit mapping to subscriber business objects and services;
- org-specific security enforcement in custom logic.

Treat only documented contracts as stable extension points. Do not depend on undocumented internal behavior.

## Related Documentation

- [Getting Started](getting-started.md)
- [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md)
- [Validation](validation.md)
- [Data Model](data-model.md)
- [Review Mode](review-mode.md)
- [Apex Extension Points](apex-extension-points.md)
