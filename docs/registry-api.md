---
title: Registry API
---

# Registry API

This page will document the JavaScript registry contract used by subscriber LWCs.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Review Mode](review-mode.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

Planned content:

- Direct registry properties on `wizard`.
- Global registration helpers.
- `registerPage(name, constructor)`.
- `registerValidator(name, fn)`.
- `registerPageValidator(name, fn)`.
- `registerPageFieldMapping(pageName, mapping)`.
- `registerLabels(labelsObj)`.
- Error semantics and duplicate registration behavior.

Example references:

- [`examples/basic-wizard/lwc/basicWizardRegistry`](../examples/basic-wizard/lwc/basicWizardRegistry)
- [`examples/feedback-wizard/lwc/feedbackWizardRegistry`](../examples/feedback-wizard/lwc/feedbackWizardRegistry)
